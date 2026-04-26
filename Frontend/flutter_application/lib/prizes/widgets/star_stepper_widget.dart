// lib/prizes/widgets/star_stepper_widget.dart
//
// Number stepper for required stars: star icon | value | down | up.

import 'package:flutter/material.dart';

const Color _kStarColor = Color(0xFFFE8401);
const String _kFont = 'IBM Plex Sans Arabic';

class StarStepperWidget extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int>? onChanged;

  const StarStepperWidget({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Image.asset(
            'images/star shape.png',
            width: 22,
            height: 22,
            color: _kStarColor,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.star, color: _kStarColor, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$value',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.keyboard_arrow_down,
            onTap: onDecrement,
            enabled: value > 0,
          ),
          const SizedBox(width: 8),
          _StepBtn(
            icon: Icons.keyboard_arrow_up,
            onTap: onIncrement,
            enabled: true,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5F5F5),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: enabled ? Colors.black : Colors.black26,
        ),
      ),
    );
  }
}
