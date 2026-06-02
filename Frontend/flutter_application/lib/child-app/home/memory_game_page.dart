// --- lib/child-app/home/memory_game_page.dart ---
// A simple, kid-friendly "Memory Match" game (مطابقة الفواكه).
// Flip two cards, find the matching fruit. Fully self-contained:
// the win is a local celebration (raining stars + sound), it does NOT
// touch the global star counter (there is no game-reward endpoint).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';

// --- Constants (shared look with child_home_page.dart) ---
const String _kFontFamily = 'IBM Plex Sans Arabic';
const Color _kBgColorTop = Color(0x80B0CEE3);
const Color _kBgColorBottom = Color(0x00B0CEE3);
const Color _kGreenStart = Color(0xFF7BD88F);
const Color _kGreenEnd = Color(0xFF34A853);
const Color _kGreenDark = Color(0xFF1E7E34);
const Color _kCardBackTop = Color(0xFF7EC8E3);
const Color _kCardBackBottom = Color(0xFF4A90D9);
const Color _kOrangeStart = Color(0xFFFEA400);
const Color _kOrangeEnd = Color(0xFFFD5E00);
const Color _kOrangeBorder = Color(0xFFC84A00);

/// One fruit kind: its image + the sound it plays when matched.
class _Fruit {
  final String name;
  final String image;
  final String sound;
  const _Fruit(this.name, this.image, this.sound);
}

// Six fruits, each with an existing image AND a matching sound asset.
const List<_Fruit> _kFruits = [
  _Fruit('apple', 'images/apple.png', 'assets/sounds/apple.mp3'),
  _Fruit('banana', 'images/banana.png', 'assets/sounds/banana.mp3'),
  _Fruit('grapes', 'images/grapes.png', 'assets/sounds/grape.mp3'),
  _Fruit('lemon', 'images/lemon.png', 'assets/sounds/lemon.mp3'),
  _Fruit('pear', 'images/pear.png', 'assets/sounds/pear.mp3'),
  _Fruit('pineapple', 'images/pineapple.png', 'assets/sounds/pineapple.mp3'),
];

/// Difficulty levels (number of pairs).
enum _Level { easy, normal }

extension _LevelInfo on _Level {
  int get pairs => this == _Level.easy ? 3 : 6;
  int get columns => this == _Level.easy ? 3 : 3;
  String get label => this == _Level.easy ? 'سهل' : 'عادي';
}

/// Runtime model for a single card on the board.
class _CardModel {
  final int id; // unique per card
  final _Fruit fruit;
  bool isMatched = false;
  bool isFlipped = false;
  _CardModel(this.id, this.fruit);
}

class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key});

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage>
    with TickerProviderStateMixin {
  _Level _level = _Level.normal;
  List<_CardModel> _cards = [];
  int? _firstIndex; // index of the first flipped card awaiting a match
  bool _busy = false; // lock while a pair is being resolved
  int _moves = 0;
  int _matchedPairs = 0;
  bool _showWin = false;

  ChildHomeProvider? _provider;

  late final AnimationController _introController; // staggered board entrance

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _setupBoard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Grab the provider for sound playback only (safe-guarded).
    try {
      _provider = context.read<ChildHomeProvider>();
    } catch (_) {
      _provider = null;
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  // --- Sound helpers (delegate to the home provider's audio player) ---
  void _playClick() => _provider?.playClick();
  void _playSound(String path) => _provider?.playSound(path);

  void _setupBoard() {
    final chosen = _kFruits.take(_level.pairs).toList();
    final deck = <_CardModel>[];
    var id = 0;
    for (final fruit in chosen) {
      deck.add(_CardModel(id++, fruit));
      deck.add(_CardModel(id++, fruit));
    }
    deck.shuffle(math.Random());

    setState(() {
      _cards = deck;
      _firstIndex = null;
      _busy = false;
      _moves = 0;
      _matchedPairs = 0;
      _showWin = false;
    });

    _introController
      ..reset()
      ..forward();
  }

  void _changeLevel(_Level level) {
    if (_level == level && _cards.isNotEmpty) return;
    _playClick();
    _level = level;
    _setupBoard();
  }

  void _onCardTap(int index) {
    if (_busy) return;
    final card = _cards[index];
    if (card.isMatched || card.isFlipped) return;

    _playClick();
    setState(() => card.isFlipped = true);

    if (_firstIndex == null) {
      // First card of the pair.
      _firstIndex = index;
      return;
    }

    // Second card of the pair → evaluate.
    final firstCard = _cards[_firstIndex!];
    setState(() {
      _moves++;
      _busy = true;
    });

    if (firstCard.fruit.name == card.fruit.name) {
      // Match!
      _playSound(card.fruit.sound);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          firstCard.isMatched = true;
          card.isMatched = true;
          _matchedPairs++;
          _firstIndex = null;
          _busy = false;
        });
        if (_matchedPairs == _level.pairs) {
          _onWin();
        }
      });
    } else {
      // No match → flip both back after a short pause.
      _playSound('assets/sounds/error_wrong_fruits.mp3');
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() {
          firstCard.isFlipped = false;
          card.isFlipped = false;
          _firstIndex = null;
          _busy = false;
        });
      });
    }
  }

  void _onWin() {
    _playSound('assets/sounds/collect_stars.mp3');
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _showWin = true);
    });
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
              child: Column(
                children: [
                  _buildHeader(),
                  _buildLevelSelector(),
                  const SizedBox(height: 6),
                  Expanded(child: _buildBoard()),
                  const SizedBox(height: 12),
                ],
              ),
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

  // --- Header: back button + title + pairs counter ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _PillButton(
            onTap: () {
              _playClick();
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: _kGreenDark),
          ),
          // Title
          const Text(
            'لعبة الذاكرة',
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kGreenDark,
            ),
          ),
          // Pairs found counter
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kGreenStart, _kGreenEnd],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _kGreenDark, width: 2),
              boxShadow: const [
                BoxShadow(color: _kGreenDark, offset: Offset(2, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_matchedPairs/${_level.pairs}',
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
    );
  }

  // --- Level selector (easy / normal) + restart ---
  Widget _buildLevelSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _levelChip(_Level.easy),
          const SizedBox(width: 8),
          _levelChip(_Level.normal),
          const Spacer(),
          // Restart current board
          _PillButton(
            onTap: () {
              _playClick();
              _setupBoard();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 20, color: _kGreenDark),
                SizedBox(width: 6),
                Text(
                  'من جديد',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kGreenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelChip(_Level level) {
    final selected = _level == level;
    return GestureDetector(
      onTap: () => _changeLevel(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kOrangeStart, _kOrangeEnd],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? _kOrangeBorder : Colors.black26,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? _kOrangeBorder : Colors.black12,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          level.label,
          style: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // --- Board grid ---
  Widget _buildBoard() {
    final columns = _level.columns;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final card = _cards[index];
          // Staggered entrance per card.
          final start = (index / _cards.length) * 0.5;
          final anim = CurvedAnimation(
            parent: _introController,
            curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
                curve: Curves.easeOutBack),
          );
          return AnimatedBuilder(
            animation: anim,
            builder: (context, child) {
              return Transform.scale(
                scale: anim.value.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: anim.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _MemoryCard(
              fruit: card.fruit,
              isRevealed: card.isFlipped || card.isMatched,
              isMatched: card.isMatched,
              onTap: () => _onCardTap(index),
            ),
          );
        },
      ),
    );
  }

  // --- Win dialog ---
  Widget _buildWinDialog() {
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
            width: 290,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 25,
                ),
                BoxShadow(
                  color: _kGreenEnd,
                  offset: Offset(3, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Three celebratory stars
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
                    colors: [_kGreenStart, _kGreenEnd],
                  ).createShader(bounds),
                  child: const Text(
                    'أحسنت! 🎉',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'طابقت كل الفواكه في $_moves محاولة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 22),
                // Play again
                _BigButton(
                  label: 'العب مرة أخرى',
                  gradient: const [_kGreenStart, _kGreenEnd],
                  shadow: _kGreenDark,
                  onTap: () {
                    _playClick();
                    _setupBoard();
                  },
                ),
                const SizedBox(height: 12),
                // Back home
                _BigButton(
                  label: 'الرجوع',
                  gradient: const [_kOrangeStart, _kOrangeEnd],
                  shadow: _kOrangeBorder,
                  onTap: () {
                    _playClick();
                    Navigator.pop(context);
                  },
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
//  Single flip card with a 3D rotateY animation.
// ============================================================
class _MemoryCard extends StatefulWidget {
  final _Fruit fruit;
  final bool isRevealed;
  final bool isMatched;
  final VoidCallback onTap;

  const _MemoryCard({
    required this.fruit,
    required this.isRevealed,
    required this.isMatched,
    required this.onTap,
  });

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.isRevealed ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant _MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _flip.forward();
      } else {
        _flip.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, child) {
          final angle = _flip.value * math.pi;
          final showFront = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildFront(),
                  )
                : _buildBack(),
          );
        },
      ),
    );
  }

  // Card back (face-down): a friendly blue card with a question mark.
  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCardBackTop, _kCardBackBottom],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.question_mark_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  // Card front (face-up): the fruit. Glows green when matched.
  Widget _buildFront() {
    final matched = widget.isMatched;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: matched ? _kGreenEnd : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: matched ? _kGreenEnd.withAlpha(140) : const Color(0x22000000),
            offset: const Offset(0, 4),
            blurRadius: matched ? 14 : 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          widget.fruit.image,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.apple,
            size: 40,
            color: Colors.redAccent,
          ),
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
