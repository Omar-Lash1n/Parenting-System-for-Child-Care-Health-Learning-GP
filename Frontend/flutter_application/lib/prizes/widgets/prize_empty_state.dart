// lib/prizes/widgets/prize_empty_state.dart
//
// Empty state for the prize store list — gift icon + message + dotted arrow
// pointing to the FAB at the bottom-right.

import 'package:flutter/material.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class PrizeEmptyState extends StatelessWidget {
  const PrizeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'images/gift.png',
              width: 70,
              height: 70,
              color: const Color(0xFFBBBBBB),
              errorBuilder: (_, __, ___) => Icon(
                Icons.card_giftcard,
                size: 70,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'يبدو انه لا يتوفر مكافئات تم اضافتها,\nاضغط على دائرة اضافة مكافئة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
