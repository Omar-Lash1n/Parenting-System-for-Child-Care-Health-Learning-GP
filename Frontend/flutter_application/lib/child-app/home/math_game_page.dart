// --- lib/child-app/home/math_game_page.dart ---
// A fully native, kid-friendly math game (مغامرة الأرقام).
// Replaces the old web-iframe game (which never loaded on Android) with a
// self-contained Flutter implementation that runs on every platform.
//
// Flow:
//   1) Category screen: pick one of four operations (+, -, ×, ÷).
//   2) Quiz screen: solve a series of problems by tapping the correct answer
//      out of four choices. Score + progress are shown live.
//   3) Win dialog: celebration (raining stars + sound) with the final score.
//
// Like the other mini-games, the win is a purely local celebration; it does
// NOT touch the global star counter (there is no game-reward endpoint).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';

// --- Constants (shared look with child_home_page.dart) ---
const String _kFontFamily = 'IBM Plex Sans Arabic';
const Color _kBgColorTop = Color(0x80B0CEE3);
const Color _kBgColorBottom = Color(0x00B0CEE3);
const Color _kCyanStart = Color(0xFF11C2F4);
const Color _kCyanEnd = Color(0xFF0A8BC4);
const Color _kCyanDark = Color(0xFF086C97);
const Color _kGreenStart = Color(0xFF7BD88F);
const Color _kGreenEnd = Color(0xFF34A853);
const Color _kGreenDark = Color(0xFF1E7E34);
const Color _kOrangeStart = Color(0xFFFEA400);
const Color _kOrangeEnd = Color(0xFFFD5E00);
const Color _kOrangeBorder = Color(0xFFC84A00);
const Color _kRedStart = Color(0xFFFF6B6B);
const Color _kRedEnd = Color(0xFFE53935);

const int _kQuestionsPerRound = 10;

// --- Sound assets (already bundled, see assets/sounds/) ---
const String _kSoundCorrect = 'assets/sounds/success.mp3';
const String _kSoundWin = 'assets/sounds/collect_stars.mp3';

/// The four math operations the child can play.
enum _Operation { add, subtract, multiply, divide }

extension _OperationInfo on _Operation {
  /// Symbol shown to the child inside the problem (e.g. "3 + 4").
  String get symbol {
    switch (this) {
      case _Operation.add:
        return '+';
      case _Operation.subtract:
        return '−';
      case _Operation.multiply:
        return '×';
      case _Operation.divide:
        return '÷';
    }
  }

  /// Arabic name of the operation.
  String get label {
    switch (this) {
      case _Operation.add:
        return 'الجمع';
      case _Operation.subtract:
        return 'الطرح';
      case _Operation.multiply:
        return 'الضرب';
      case _Operation.divide:
        return 'القسمة';
    }
  }

  /// Card gradient on the category screen.
  List<Color> get gradient {
    switch (this) {
      case _Operation.add:
        return const [_kGreenStart, _kGreenEnd];
      case _Operation.subtract:
        return const [_kOrangeStart, _kOrangeEnd];
      case _Operation.multiply:
        return const [_kCyanStart, _kCyanEnd];
      case _Operation.divide:
        return const [_kRedStart, _kRedEnd];
    }
  }

  Color get shadow {
    switch (this) {
      case _Operation.add:
        return _kGreenDark;
      case _Operation.subtract:
        return _kOrangeBorder;
      case _Operation.multiply:
        return _kCyanDark;
      case _Operation.divide:
        return const Color(0xFFB71C1C);
    }
  }
}

/// A single generated problem: "a op b = answer", plus shuffled choices.
class _Problem {
  final int a;
  final int b;
  final _Operation op;
  final int answer;
  final List<int> choices;
  const _Problem({
    required this.a,
    required this.b,
    required this.op,
    required this.answer,
    required this.choices,
  });

  String get prompt => '$a ${op.symbol} $b';
}

/// Generates a random, solvable problem for the given operation.
/// All operands and answers are non-negative whole numbers so they stay
/// kid-appropriate (division is always exact).
_Problem _generateProblem(_Operation op, math.Random rand) {
  late int a, b, answer;

  switch (op) {
    case _Operation.add:
      a = rand.nextInt(20) + 1; // 1..20
      b = rand.nextInt(20) + 1; // 1..20
      answer = a + b;
      break;
    case _Operation.subtract:
      a = rand.nextInt(20) + 1; // 1..20
      b = rand.nextInt(a) + 1; // 1..a  → answer never negative
      answer = a - b;
      break;
    case _Operation.multiply:
      a = rand.nextInt(9) + 2; // 2..10
      b = rand.nextInt(9) + 2; // 2..10
      answer = a * b;
      break;
    case _Operation.divide:
      b = rand.nextInt(9) + 2; // divisor 2..10
      answer = rand.nextInt(9) + 2; // quotient 2..10
      a = b * answer; // dividend → exact division
      break;
  }

  // Build 4 unique choices: the correct answer + 3 plausible distractors.
  final choices = <int>{answer};
  var guard = 0;
  while (choices.length < 4 && guard < 50) {
    guard++;
    // Offset the correct answer by a small amount, clamped to >= 0.
    final delta = rand.nextInt(7) - 3; // -3..3
    if (delta == 0) continue;
    final candidate = answer + delta;
    if (candidate < 0) continue;
    choices.add(candidate);
  }
  // Fallback in case the loop couldn't find enough distinct distractors.
  var filler = answer + 1;
  while (choices.length < 4) {
    if (filler != answer && filler >= 0) choices.add(filler);
    filler++;
  }

  final shuffled = choices.toList()..shuffle(rand);

  return _Problem(
    a: a,
    b: b,
    op: op,
    answer: answer,
    choices: shuffled,
  );
}

class MathGamePage extends StatefulWidget {
  const MathGamePage({super.key});

  @override
  State<MathGamePage> createState() => _MathGamePageState();
}

class _MathGamePageState extends State<MathGamePage> {
  final _rand = math.Random();

  // null → showing the category picker; non-null → a round is in progress.
  _Operation? _operation;

  late List<_Problem> _problems;
  int _index = 0;
  int _score = 0;
  int? _selectedChoice; // the choice the child tapped (for feedback colors)
  bool _locked = false; // lock input while feedback is showing
  bool _showWin = false;

  ChildHomeProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _provider = context.read<ChildHomeProvider>();
    } catch (_) {
      _provider = null;
    }
  }

  // --- Sound helpers (delegate to the home provider's audio player) ---
  void _playClick() => _provider?.playClick();
  void _playSound(String path) => _provider?.playSound(path);

  // --- Round lifecycle ---
  void _startRound(_Operation op) {
    _playClick();
    setState(() {
      _operation = op;
      _problems =
          List.generate(_kQuestionsPerRound, (_) => _generateProblem(op, _rand));
      _index = 0;
      _score = 0;
      _selectedChoice = null;
      _locked = false;
      _showWin = false;
    });
  }

  void _exitToCategories() {
    _playClick();
    setState(() {
      _operation = null;
      _showWin = false;
    });
  }

  void _onChoiceTap(int choice) {
    if (_locked) return;
    final problem = _problems[_index];
    final correct = choice == problem.answer;

    setState(() {
      _selectedChoice = choice;
      _locked = true;
      if (correct) _score++;
    });

    if (correct) _playSound(_kSoundCorrect);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_index >= _problems.length - 1) {
        _onWin();
      } else {
        setState(() {
          _index++;
          _selectedChoice = null;
          _locked = false;
        });
      }
    });
  }

  void _onWin() {
    _playSound(_kSoundWin);
    setState(() => _showWin = true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: _operation == null
                  ? _buildCategoryScreen()
                  : _buildQuizScreen(),
            ),
            if (_showWin) ...[
              const _StarRain(),
              _buildWinDialog(),
            ],
          ],
        ),
      ),
    );
  }

  // --- Background ---
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kBgColorTop, _kBgColorBottom],
        ),
      ),
    );
  }

  // ============================================================
  //  Category picker
  // ============================================================
  Widget _buildCategoryScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PillButton(
                onTap: () {
                  _playClick();
                  Navigator.pop(context);
                },
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 20, color: _kCyanDark),
              ),
              const Text(
                'مغامرة الأرقام',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _kCyanDark,
                ),
              ),
              const SizedBox(width: 48), // balances the back button
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'اختر نوع اللعبة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 1.0,
              children: _Operation.values
                  .map((op) => _CategoryCard(
                        operation: op,
                        onTap: () => _startRound(op),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  Quiz screen
  // ============================================================
  Widget _buildQuizScreen() {
    final op = _operation!;
    final problem = _problems[_index];

    return Column(
      children: [
        // Header: back + title + score
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PillButton(
                onTap: _exitToCategories,
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 20, color: _kCyanDark),
              ),
              Text(
                op.label,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kCyanDark,
                ),
              ),
              // Score chip
              Container(
                constraints: const BoxConstraints(minWidth: 64),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kOrangeStart, _kOrangeEnd],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _kOrangeBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: _kOrangeBorder, offset: Offset(2, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _starIcon(18),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Progress bar + counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _problems.length,
                  minHeight: 10,
                  backgroundColor: Colors.white,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_kCyanStart),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'سؤال ${_index + 1} من ${_problems.length}',
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),

        // Problem card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProblemCard(problem),
                const SizedBox(height: 28),
                // Answer choices (2×2 grid)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.9,
                  children: problem.choices
                      .map((c) => _AnswerButton(
                            value: c,
                            state: _choiceState(problem, c),
                            onTap: () => _onChoiceTap(c),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Resolves the visual state of a choice button (used for feedback colors).
  _ChoiceState _choiceState(_Problem problem, int choice) {
    if (!_locked) return _ChoiceState.idle;
    if (choice == problem.answer) return _ChoiceState.correct;
    if (choice == _selectedChoice) return _ChoiceState.wrong;
    return _ChoiceState.idle;
  }

  Widget _buildProblemCard(_Problem problem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _operation!.gradient,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _operation!.shadow,
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
          const BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: FittedBox(
        child: Text(
          '${problem.prompt} = ؟',
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 54,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(color: Color(0x55000000), offset: Offset(0, 3)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Win dialog ---
  Widget _buildWinDialog() {
    final total = _problems.length;
    final allRight = _score == total;
    return Container(
      color: const Color(0x66000000),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 300,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 25),
                BoxShadow(color: _kCyanEnd, offset: Offset(3, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _starIcon(48),
                    _starIcon(64),
                    _starIcon(48),
                  ],
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kCyanStart, _kCyanEnd],
                  ).createShader(bounds),
                  child: Text(
                    allRight ? 'ممتاز! 🎉' : 'أحسنت! 👏',
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'إجاباتك الصحيحة: $_score من $total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 22),
                // Play same operation again
                _BigButton(
                  label: 'العب مرة أخرى',
                  gradient: const [_kCyanStart, _kCyanEnd],
                  shadow: _kCyanDark,
                  onTap: () => _startRound(_operation!),
                ),
                const SizedBox(height: 12),
                // Back to category picker
                _BigButton(
                  label: 'الألعاب الأخرى',
                  gradient: const [_kOrangeStart, _kOrangeEnd],
                  shadow: _kOrangeBorder,
                  onTap: _exitToCategories,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _starIcon(double size) {
    return Image.asset(
      'images/stars.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.star, size: size, color: Colors.amber),
    );
  }
}

// ============================================================
//  Category card (big operator symbol + Arabic name).
// ============================================================
class _CategoryCard extends StatelessWidget {
  final _Operation operation;
  final VoidCallback onTap;
  const _CategoryCard({required this.operation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: operation.gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: operation.shadow, offset: const Offset(0, 6)),
            const BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, 8),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              operation.symbol,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
                shadows: [
                  Shadow(color: Color(0x55000000), offset: Offset(0, 3)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              operation.label,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Answer choice button with correct/wrong feedback states.
// ============================================================
enum _ChoiceState { idle, correct, wrong }

class _AnswerButton extends StatelessWidget {
  final int value;
  final _ChoiceState state;
  final VoidCallback onTap;
  const _AnswerButton({
    required this.value,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    late List<Color> gradient;
    late Color shadow;
    Widget? badge;

    switch (state) {
      case _ChoiceState.idle:
        gradient = const [Colors.white, Color(0xFFF1F6FB)];
        shadow = Colors.black12;
        break;
      case _ChoiceState.correct:
        gradient = const [_kGreenStart, _kGreenEnd];
        shadow = _kGreenDark;
        badge = const Icon(Icons.check_circle,
            color: Colors.white, size: 22);
        break;
      case _ChoiceState.wrong:
        gradient = const [_kRedStart, _kRedEnd];
        shadow = const Color(0xFFB71C1C);
        badge =
            const Icon(Icons.cancel, color: Colors.white, size: 22);
        break;
    }

    final isIdle = state == _ChoiceState.idle;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isIdle ? Colors.black12 : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: shadow, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: isIdle ? _kCyanDark : Colors.white,
                ),
              ),
            ),
            if (badge != null)
              Positioned(top: 6, left: 6, child: badge),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Raining stars celebration overlay.
// ============================================================
class _StarRain extends StatefulWidget {
  const _StarRain();

  @override
  State<_StarRain> createState() => _StarRainState();
}

class _StarRainState extends State<_StarRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(22, (i) {
      return _Particle(
        x: _rand.nextDouble(),
        delay: _rand.nextDouble() * 0.6,
        speed: 0.6 + _rand.nextDouble() * 0.7,
        size: 18 + _rand.nextDouble() * 26,
        rotationSpeed: (_rand.nextDouble() - 0.5) * 6,
        drift: (_rand.nextDouble() - 0.5) * 0.15,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: _particles.map((p) {
              final t = ((_controller.value - p.delay) * p.speed) % 1.0;
              if (t < 0) return const SizedBox.shrink();
              final top = t * (size.height + 80) - 60;
              final left = (p.x + p.drift * t) * size.width;
              return Positioned(
                top: top,
                left: left,
                child: Transform.rotate(
                  angle: t * p.rotationSpeed,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Image.asset(
                      'images/stars.png',
                      width: p.size,
                      height: p.size,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.star,
                        size: p.size,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x; // 0..1 horizontal start
  final double delay; // 0..1 start offset
  final double speed;
  final double size;
  final double rotationSpeed;
  final double drift;
  const _Particle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.drift,
  });
}

// ============================================================
//  Small shared widgets.
// ============================================================
class _PillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PillButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black26, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(2, 2)),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final Color shadow;
  final VoidCallback onTap;
  const _BigButton({
    required this.label,
    required this.gradient,
    required this.shadow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: shadow, offset: const Offset(3, 5)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
