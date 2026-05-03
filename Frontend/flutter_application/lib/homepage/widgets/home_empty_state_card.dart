import 'package:flutter/material.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class HomeEmptyStateCard extends StatelessWidget {
  final String text;

  const HomeEmptyStateCard({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 2.5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0x0D000000),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 24,
              color: Color(0x80000000),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0x80000000),
            ),
          ),
        ],
      ),
    );
  }
}
