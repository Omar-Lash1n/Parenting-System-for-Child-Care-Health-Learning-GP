import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/homepage/models/daily_question_model.dart';
import 'package:Ajial/homepage/providers/parent_home_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const String _kFont = 'IBM Plex Sans Arabic';

class DailyQuestionPage extends StatefulWidget {
  const DailyQuestionPage({super.key});

  @override
  State<DailyQuestionPage> createState() => _DailyQuestionPageState();
}

class _DailyQuestionPageState extends State<DailyQuestionPage> {
  String? _selectedOptionId;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ParentHomeProvider>();
      if (provider.dailyQuestionStatus == HomeDataStatus.initial ||
          provider.dailyQuestion == null) {
        provider.loadDailyQuestion();
      } else {
        _setPreviousSelection(provider.dailyQuestion);
      }
    });
  }

  void _setPreviousSelection(ActiveDailyQuestion? question) {
    final selected = question?.previousAnswer?.selectedOptionId;
    if (selected != null && selected.isNotEmpty && _selectedOptionId == null) {
      setState(() => _selectedOptionId = selected);
    }
  }

  Future<void> _submit(ActiveDailyQuestion question) async {
    if (question.hasAnswered) {
      await showDailyQuestionInfoDialog(
        context,
        title: 'تمت الإجابة مسبقاً',
        message: 'لقد أجبت على هذا السؤال مسبقاً',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    final optionId = _selectedOptionId;
    if (optionId == null || optionId.isEmpty) {
      await showNoDailyQuestionAnswerDialog(context);
      return;
    }

    try {
      final result = await context
          .read<ParentHomeProvider>()
          .submitDailyQuestionAnswer(
            questionId: question.id,
            selectedOptionId: optionId,
          );

      if (!mounted) return;
      if (result.isCorrect) {
        setState(() => _showCelebration = true);
        await showDailyQuestionSuccessDialog(
          context,
          starsEarned: result.starsEarned,
        );
        if (mounted) setState(() => _showCelebration = false);
      } else {
        await showDailyQuestionInfoDialog(
          context,
          title: 'إجابة خاطئة',
          message: result.message.isNotEmpty
              ? result.message
              : 'إجابة خاطئة، حاول في السؤال القادم!',
          icon: Icons.close_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showDailyQuestionInfoDialog(
        context,
        title: 'تعذر إرسال الإجابة',
        message: e.toString().replaceFirst('Exception: ', ''),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<ParentHomeProvider>(
            builder: (context, provider, _) {
              final question = provider.dailyQuestion;

              return Stack(
                children: [
                  if (_showCelebration)
                    const Positioned.fill(child: _CelebrationLayer()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 32),
                        Expanded(
                          child: _buildBody(provider, question),
                        ),
                        if (question != null)
                          _SubmitButton(
                            reward: question.starsReward,
                            isLoading: provider.isSubmittingDailyQuestion,
                            onTap: provider.isSubmittingDailyQuestion
                                ? null
                                : () => _submit(question),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    ParentHomeProvider provider,
    ActiveDailyQuestion? question,
  ) {
    if (provider.dailyQuestionStatus == HomeDataStatus.loading ||
        provider.dailyQuestionStatus == HomeDataStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimary),
      );
    }

    if (provider.dailyQuestionStatus == HomeDataStatus.error) {
      return _CenterMessage(
        message: provider.dailyQuestionError ?? 'تعذر تحميل سؤال اليوم',
        actionLabel: 'إعادة المحاولة',
        onAction: provider.loadDailyQuestion,
      );
    }

    if (question == null) {
      return const _CenterMessage(message: 'لا يوجد سؤال نشط حالياً');
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _QuestionTextBox(text: question.questionText),
        const SizedBox(height: 16),
        ...question.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OptionTile(
              option: option,
              isSelected: option.id ==
                  (_selectedOptionId ??
                      question.previousAnswer?.selectedOptionId),
              isAnswered: question.hasAnswered,
              isCorrect: question.previousAnswer?.correctOptionId == option.id,
              onTap: question.hasAnswered
                  ? null
                  : () => setState(() => _selectedOptionId = option.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'سؤال اليوم',
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _QuestionTextBox extends StatelessWidget {
  final String text;

  const _QuestionTextBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0x0DBF092F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66BF092F)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.5,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final DailyQuestionOption option;
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
    final borderColor = isCorrect
        ? const Color(0xFF01A449)
        : isSelected
            ? _kOrange
            : const Color(0xFFE2E2E2);
    final backgroundColor = isSelected
        ? const Color(0x0DFE8401)
        : isCorrect
            ? const Color(0x0D01A449)
            : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 50,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.optionText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            if (isSelected || isCorrect) ...[
              const SizedBox(width: 8),
              Icon(
                isCorrect && isAnswered
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_checked_rounded,
                color: isCorrect && isAnswered
                    ? const Color(0xFF01A449)
                    : _kOrange,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final int reward;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SubmitButton({
    required this.reward,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEA400), Color(0xFFFD5E00)],
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_border_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      'أجب السؤال $reward',
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenterMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: _kFont,
                  color: _kPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showNoDailyQuestionAnswerDialog(BuildContext context) {
  return showDailyQuestionInfoDialog(
    context,
    title: 'لم يتم اختيار إجابة',
    message: 'يرجى اختيار إجابة من الأجوبة والضغط على أجب السؤال',
    icon: Icons.error_outline_rounded,
  );
}

Future<void> showDailyQuestionInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DailyQuestionDialog(
      title: title,
      message: message,
      icon: icon,
      iconColor: _kPrimary,
      iconBackground: const Color(0x1ABF092F),
    ),
  );
}

Future<void> showDailyQuestionSuccessDialog(
  BuildContext context, {
  required int starsEarned,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DailyQuestionDialog(
      title: 'تم اضافة $starsEarned نجمة',
      message: 'تم اضافة عدد النقاط الى محفظة نقاطك تجدها في الملف الشخصي',
      icon: Icons.star_border_rounded,
      iconColor: _kOrange,
      iconBackground: Colors.transparent,
      topAccent: true,
    ),
  );
}

class _DailyQuestionDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool topAccent;

  const _DailyQuestionDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.topAccent = false,
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
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (topAccent) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LinearProgressIndicator(
                    value: 0.85,
                    minHeight: 12,
                    backgroundColor: Color(0xFFFFDCB4),
                    valueColor: AlwaysStoppedAnimation<Color>(_kOrange),
                  ),
                ),
                const SizedBox(height: 28),
              ],
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: topAccent ? 56 : 38, color: iconColor),
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
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF444444),
                  height: 1.45,
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
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
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

class _CelebrationLayer extends StatefulWidget {
  const _CelebrationLayer();

  @override
  State<_CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<_CelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF54C7C9),
      Color(0xFFF45D5D),
      Color(0xFF53A8F1),
      Color(0xFFF2B94B),
      Color(0xFF61BE93),
    ];
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 26; i++) {
      paint.color = colors[i % colors.length].withValues(alpha: 0.95);
      final leftSide = i.isEven;
      final baseX = leftSide ? 12.0 + (i % 5) * 16 : size.width - 88 + (i % 5) * 18;
      final baseY = leftSide ? 44.0 + (i % 7) * 28 : size.height * 0.45 + (i % 8) * 30;
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
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
