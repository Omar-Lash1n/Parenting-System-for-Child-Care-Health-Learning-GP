import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/homepage/models/daily_question_model.dart';
import 'package:Ajial/homepage/providers/parent_home_provider.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class DailyQuestionCard extends StatelessWidget {
  const DailyQuestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentHomeProvider>(
      builder: (context, provider, _) {
        if (provider.dailyQuestionStatus == HomeDataStatus.loading ||
            provider.dailyQuestionStatus == HomeDataStatus.initial) {
          return const _DailyQuestionLoadingCard();
        }

        if (provider.dailyQuestionStatus == HomeDataStatus.error) {
          return _DailyQuestionShell(
            child: Column(
              children: [
                const _TitleRow(),
                const SizedBox(height: 8),
                Text(
                  provider.dailyQuestionError ?? 'تعذر تحميل سؤال اليوم',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _QuestionButton(
                  label: 'إعادة المحاولة',
                  onTap: provider.loadDailyQuestion,
                ),
              ],
            ),
          );
        }

        final question = provider.dailyQuestion;
        if (question == null) {
          return const SizedBox.shrink();
        }

        return _DailyQuestionLoadedCard(question: question);
      },
    );
  }
}

class _DailyQuestionLoadedCard extends StatelessWidget {
  final ActiveDailyQuestion question;

  const _DailyQuestionLoadedCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final buttonLabel = question.hasAnswered
        ? 'تمت الإجابة'
        : 'أجب السؤال ${question.starsReward}';

    return _DailyQuestionShell(
      child: Column(
        children: [
          const _TitleRow(),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _QuestionButton(
            label: buttonLabel,
            onTap: () => Navigator.pushNamed(context, '/daily-question'),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestionShell extends StatelessWidget {
  final Widget child;

  const _DailyQuestionShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x0DFE8401),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x40FE8401)),
      ),
      child: child,
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'سؤال اليوم',
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 8),
        Icon(
          Icons.chat_bubble_outline_rounded,
          color: Color(0xFFFE8401),
          size: 24,
        ),
      ],
    );
  }
}

class _QuestionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuestionButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: 40,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_border_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
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

class _DailyQuestionLoadingCard extends StatelessWidget {
  const _DailyQuestionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return _DailyQuestionShell(
      child: Column(
        children: [
          const _TitleRow(),
          const SizedBox(height: 8),
          _SkeletonLine(width: MediaQuery.of(context).size.width * 0.68),
          const SizedBox(height: 8),
          _SkeletonLine(width: MediaQuery.of(context).size.width * 0.52),
          const SizedBox(height: 16),
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0x1AFE8401),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0x1A000000),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
