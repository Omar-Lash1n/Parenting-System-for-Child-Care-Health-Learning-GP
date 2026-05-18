import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/lessons/models/lesson_models.dart';
import 'package:Ajial/lessons/providers/lesson_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const String _kFont = 'IBM Plex Sans Arabic';

class LessonQuizScreen extends StatefulWidget {
  const LessonQuizScreen({super.key});

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  String? _lessonId;
  bool _initialized = false;
  int _currentIndex = 0;
  bool _showCelebration = false;
  bool _isSubmitting = false;

  // questionId → selected optionId (persists across submission)
  final Map<String, String> _selections = {};

  // questionId → LessonAnswerResult (set after successful submit)
  final Map<String, LessonAnswerResult> _results = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _lessonId = args['lessonId'] as String?;
    }

    // Pre-populate selections for already-answered questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final questions = context.read<LessonProvider>().quizQuestions;
      for (final q in questions) {
        if (q.hasAnswered && q.previousAnswer != null) {
          _selections[q.id] = q.previousAnswer!.selectedOptionId;
        }
      }
      if (mounted) setState(() {});
    });
  }

  List<LessonQuizQuestionModel> get _questions =>
      context.read<LessonProvider>().quizQuestions;

  LessonQuizQuestionModel? get _currentQuestion {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return null;
    return _questions[_currentIndex];
  }

  bool _isAnswered(LessonQuizQuestionModel q) =>
      q.hasAnswered || _results.containsKey(q.id);

  String? _correctOptionFor(LessonQuizQuestionModel q) {
    if (_results.containsKey(q.id)) return _results[q.id]!.correctOptionId;
    if (q.hasAnswered) return q.previousAnswer?.correctOptionId;
    return null;
  }

  Future<void> _goNext() async {
    final question = _currentQuestion;
    if (question == null) return;

    if (_isAnswered(question)) {
      // Already answered — just advance or close if at end
      if (_currentIndex < _questions.length - 1) {
        setState(() => _currentIndex++);
      }
      return;
    }

    final selectedOptionId = _selections[question.id];
    if (selectedOptionId == null || selectedOptionId.isEmpty) {
      await _showNoAnswerDialog();
      return;
    }

    if (_lessonId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await context.read<LessonProvider>().submitAnswer(
            lessonId: _lessonId!,
            questionId: question.id,
            selectedOptionId: selectedOptionId,
          );

      if (!mounted) return;
      setState(() {
        _results[question.id] = result;
        _isSubmitting = false;
      });

      if (result.isCorrect) {
        setState(() => _showCelebration = true);
        await _showStarsDialog(result.starsEarned);
        if (mounted) setState(() => _showCelebration = false);
      } else {
        await _showIncorrectDialog();
      }

      if (!mounted) return;

      if (result.isQuizCompleted) {
        await _showCompletionDialog(result.totalLessonStarsEarned);
        if (mounted) Navigator.pop(context);
        return;
      }

      if (_currentIndex < _questions.length - 1) {
        setState(() => _currentIndex++);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  Future<void> _onClose() async {
    final shouldExit = await _showExitDialog();
    if (shouldExit == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final shouldPop = await _showExitDialog();
        if (shouldPop == true && mounted) nav.pop();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Consumer<LessonProvider>(
              builder: (context, provider, _) {
                final questions = provider.quizQuestions;
                if (questions.isEmpty) {
                  return _buildEmptyState(context);
                }
                final safeIndex = _currentIndex.clamp(0, questions.length - 1);
                if (_currentIndex != safeIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _currentIndex = safeIndex);
                  });
                }
                return Stack(
                  children: [
                    if (_showCelebration)
                      const Positioned.fill(child: _CelebrationLayer()),
                    _buildMainContent(context, questions),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: _buildHeaderRow(context, 0, 0),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'لا يوجد أسئلة لهذا الدرس',
              style: TextStyle(fontFamily: _kFont, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    List<LessonQuizQuestionModel> questions,
  ) {
    final question = questions[_currentIndex.clamp(0, questions.length - 1)];
    final isAnswered = _isAnswered(question);
    final isLast = _currentIndex >= questions.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          _buildHeaderRow(context, _currentIndex + 1, questions.length),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildQuestionBox(question, _currentIndex + 1),
                const SizedBox(height: 16),
                ...question.options.map((opt) {
                  final selectedId = _selections[question.id];
                  final correctId = _correctOptionFor(question);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      option: opt,
                      isSelected: opt.id == selectedId,
                      isAnswered: isAnswered,
                      isCorrect: opt.id == correctId,
                      onTap: isAnswered
                          ? null
                          : () => setState(
                              () => _selections[question.id] = opt.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          _buildNavButtons(isLast, isAnswered),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, int current, int total) {
    return Row(
      children: [
        // Question counter on the RIGHT (first child in RTL)
        if (total > 0)
          Text(
            '$current / $total',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        const SizedBox(width: 8),
        // Title in the middle
        const Expanded(
          child: Text(
            'أسئلة تربوية',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Close button on the LEFT (last child in RTL)
        GestureDetector(
          onTap: _onClose,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBox(LessonQuizQuestionModel question, int number) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x0DBF092F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x55BF092F)),
      ),
      child: Text(
        '$number. ${question.questionText}',
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildNavButtons(bool isLast, bool isCurrentAnswered) {
    final primaryLabel =
        isLast && !isCurrentAnswered ? 'تأكيد' : 'التالي';

    return Column(
      children: [
        const SizedBox(height: 12),
        InkWell(
          onTap: _isSubmitting ? null : _goNext,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 50,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(50),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _currentIndex > 0 ? _goPrevious : null,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 50,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: _currentIndex > 0
                    ? const Color(0xFFD9D9D9)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              'السابق',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _currentIndex > 0 ? Colors.black87 : Colors.black26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  Future<void> _showNoAnswerDialog() {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _QuizDialog(
        title: 'لم يتم اختيار إجابة',
        message: 'يرجى اختيار إجابة من الأجوبة والضغط على التالي',
        icon: Icons.error_outline_rounded,
        iconColor: _kPrimary,
        buttonLabel: 'حسناً',
      ),
    );
  }

  Future<void> _showStarsDialog(int stars) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _QuizDialog(
        title: 'تم اضافة $stars نجمة',
        message: 'تم اضافة عدد النقاط الى محفظة نقاطك تجدها في الملف الشخصي',
        icon: Icons.star_border_rounded,
        iconColor: _kOrange,
        buttonLabel: 'حسناً',
        showAccent: true,
      ),
    );
  }

  Future<void> _showIncorrectDialog() {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const _QuizDialog(
        title: 'إجابة خاطئة',
        message: 'إجابة خاطئة، حاول في السؤال القادم!',
        icon: Icons.close_rounded,
        iconColor: _kPrimary,
        buttonLabel: 'حسناً',
      ),
    );
  }

  Future<void> _showCompletionDialog(int totalStars) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _QuizDialog(
        title: 'أحسنت! أكملت الدرس',
        message: 'لقد حصلت على $totalStars نجمة من هذا الدرس',
        icon: Icons.emoji_events_rounded,
        iconColor: _kOrange,
        buttonLabel: 'رائع',
        showAccent: true,
      ),
    );
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _QuizDialog(
        title: 'تعذر إرسال الإجابة',
        message: message,
        icon: Icons.error_outline_rounded,
        iconColor: _kPrimary,
        buttonLabel: 'حسناً',
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x1ABF092F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    size: 28,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سيتم الخروج من الأسئلة التربوية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يمكنك البحث عن الإجابة على الإنترنت للمعرفة الصواب الصحيح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, false),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border:
                                Border.all(color: const Color(0xFFD9D9D9)),
                          ),
                          child: const Text(
                            'بقاء',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'خروج',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Option tile ────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final LessonQuizOptionModel option;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    IconData? trailingIcon;
    Color? iconColor;

    if (isAnswered && isCorrect) {
      borderColor = const Color(0xFF01A449);
      bgColor = const Color(0x0D01A449);
      trailingIcon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF01A449);
    } else if (isAnswered && isSelected && !isCorrect) {
      borderColor = _kPrimary;
      bgColor = const Color(0x0DBF092F);
      trailingIcon = Icons.cancel_rounded;
      iconColor = _kPrimary;
    } else if (!isAnswered && isSelected) {
      borderColor = _kOrange;
      bgColor = const Color(0x0DFE8401);
      trailingIcon = Icons.radio_button_checked_rounded;
      iconColor = _kOrange;
    } else {
      borderColor = const Color(0xFFE2E2E2);
      bgColor = Colors.white;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.optionText,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: iconColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _QuizDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String buttonLabel;
  final bool showAccent;

  const _QuizDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.buttonLabel,
    this.showAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAccent) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LinearProgressIndicator(
                    value: 0.85,
                    minHeight: 12,
                    backgroundColor: Color(0xFFFFDCB4),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_kOrange),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: showAccent
                      ? Colors.transparent
                      : iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: showAccent ? 54 : 36,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confetti celebration ───────────────────────────────────────────────────────

class _CelebrationLayer extends StatefulWidget {
  const _CelebrationLayer();

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) =>
            CustomPaint(painter: _ConfettiPainter(progress: _ctrl.value)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  const _ConfettiPainter({required this.progress});

  static const _colors = [
    Color(0xFF54C7C9),
    Color(0xFFF45D5D),
    Color(0xFF53A8F1),
    Color(0xFFF2B94B),
    Color(0xFF61BE93),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 26; i++) {
      paint.color = _colors[i % _colors.length].withValues(alpha: 0.95);
      final leftSide = i.isEven;
      final baseX = leftSide
          ? 12.0 + (i % 5) * 16
          : size.width - 88 + (i % 5) * 18;
      final baseY = leftSide
          ? 44.0 + (i % 7) * 28
          : size.height * 0.45 + (i % 8) * 30;
      final fall = progress * (80 + (i % 4) * 24);
      final drift = math.sin(progress * math.pi + i) * 22;
      final center = Offset(baseX + drift, baseY + fall);
      final path = Path()
        ..moveTo(center.dx, center.dy - 13)
        ..lineTo(center.dx + 14, center.dy + 13)
        ..lineTo(center.dx - 14, center.dy + 13)
        ..close();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((progress * 2.2 + i) * 0.5);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
