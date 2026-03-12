import 'package:flutter/material.dart';

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Reusable 4-step indicator widget for the specialist registration flow.
/// Active/completed steps show green fill; pending steps show dashed borders.
/// Lines between completed steps are solid green; others are dashed black.
class StepIndicator extends StatelessWidget {
  /// 0-indexed current step (0 = step 1 active, 3 = step 4 active, 4 = success).
  final int currentStep;

  const StepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 278,
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step 1 (rightmost in RTL)
          _buildCircle(0),
          _buildLine(0),
          _buildCircle(1),
          _buildLine(1),
          _buildCircle(2),
          _buildLine(2),
          _buildCircle(3),
        ],
      ),
    );
  }

  Widget _buildCircle(int stepIndex) {
    final isCompleted = currentStep > stepIndex;
    final isActive = currentStep == stepIndex;

    if (isCompleted) {
      // Green circle with checkmark
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _kGreen,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.check, color: Colors.white, size: 16),
        ),
      );
    } else if (isActive) {
      // Green circle with number
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _kGreen,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${stepIndex + 1}',
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      // Dashed border circle with number
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Opacity(
          opacity: 0.5,
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLine(int afterStepIndex) {
    // Line between step [afterStepIndex] and [afterStepIndex+1]
    // Solid green if step afterStepIndex is completed, otherwise dashed black
    final isCompleted = currentStep > afterStepIndex;

    if (isCompleted) {
      return Container(
        width: 50,
        height: 1,
        color: _kGreen,
      );
    } else {
      // Dashed line
      return SizedBox(
        width: 50,
        height: 1,
        child: CustomPaint(
          painter: _DashedLinePainter(),
        ),
      );
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
