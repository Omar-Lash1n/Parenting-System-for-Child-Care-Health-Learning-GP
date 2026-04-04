// --- lib/tasks/widgets/task_instruction_overlay.dart ---
// Spotlight overlay with tooltip for first-time task instructions.

import 'package:flutter/material.dart';

const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

// ── Step data ────────────────────────────────────────────────────────────────

class _StepInfo {
  final String message;
  final String primaryLabel;
  const _StepInfo(this.message, this.primaryLabel);
}

const _steps = [
  _StepInfo('يمكنك التحكم فى مهامك\nمن هنا فى قسم "مهامي"', 'التالى'),
  _StepInfo('يمكنك التحكم فى مهام اطفالك\nمن هنا فى قسم "مهام اطفالي"', 'التالى'),
  _StepInfo('يمكنك الضغط على الدائرة\nلاضافة مهمة جديدة', 'انهاء'),
];

// ── Main overlay widget ──────────────────────────────────────────────────────

class TaskInstructionOverlay extends StatelessWidget {
  final Rect spotlightRect;
  final int step;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const TaskInstructionOverlay({
    super.key,
    required this.spotlightRect,
    required this.step,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final info = _steps[step];
    final padded = spotlightRect.inflate(6);
    final radius = step < 2 ? 22.0 : 28.0;

    return GestureDetector(
      onTap: () {}, // block taps
      child: Stack(
        children: [
          // Dark overlay with spotlight hole
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(rect: padded, borderRadius: radius),
            ),
          ),

          // Tooltip card
          _positionedTooltip(context, info),
        ],
      ),
    );
  }

  Widget _positionedTooltip(BuildContext context, _StepInfo info) {
    const double tooltipWidth = 260;
    final screenWidth = MediaQuery.of(context).size.width;
    const double margin = 16;

    if (step < 2) {
      // Calculate left so tooltip stays fully on-screen.
      double left;
      if (step == 1) {
        // "مهام اطفالي" tab (left side) — start near tab's left edge
        left = spotlightRect.left - 6;
      } else {
        // "مهامي" tab (right side) — align tooltip's right near tab's right
        left = spotlightRect.right - tooltipWidth + 6;
      }
      // Clamp within screen bounds
      left = left.clamp(margin, screenWidth - tooltipWidth - margin);

      return Positioned(
        top: spotlightRect.bottom + 14,
        left: left,
        child: _TooltipCard(
          step: step,
          width: tooltipWidth,
          message: info.message,
          primaryLabel: info.primaryLabel,
          onPrimary: onNext,
          onSkip: onSkip,
        ),
      );
    } else {
      // FAB → tooltip above the spotlight
      return Positioned(
        bottom: MediaQuery.of(context).size.height - spotlightRect.top + 14,
        right: margin,
        child: _TooltipCard(
          step: step,
          width: tooltipWidth,
          message: info.message,
          primaryLabel: info.primaryLabel,
          onPrimary: onNext,
          onSkip: onSkip,
        ),
      );
    }
  }
}

// ── Spotlight painter ────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  final double borderRadius;

  _SpotlightPainter({required this.rect, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, Paint()..color = const Color(0x99000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.rect != rect || old.borderRadius != borderRadius;
}

// ── Tooltip card ─────────────────────────────────────────────────────────────

class _TooltipCard extends StatelessWidget {
  final int step;
  final double width;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  const _TooltipCard({
    required this.step,
    required this.width,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            bottomLeft: const Radius.circular(20),
            bottomRight: step == 2 ? Radius.zero : const Radius.circular(20),
            topRight: step == 2 ? const Radius.circular(20) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close X — top-right in RTL is Alignment.topRight or AlignmentDirectional.topStart.
            // Alignment.topRight ignores directionality, placing it strictly top-right.
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onSkip,
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF555555)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Message — centered
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Buttons — centered 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      elevation: 0,
                    ),
                    child: Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF999999)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF444444),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
