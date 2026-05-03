import 'package:flutter/material.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class DailyQuestionCard extends StatelessWidget {
  const DailyQuestionCard({super.key});

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
      child: Column(
        children: [
          const Row(
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
              Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFFFE8401), size: 24),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'ما هو عدد ساعات النوم الطبيعية للطفل من عمر عام أو أكثر خلال اليوم؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 6),
                  Text(
                    'اجب السؤال 25',
                    style: TextStyle(
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
        ],
      ),
    );
  }
}
