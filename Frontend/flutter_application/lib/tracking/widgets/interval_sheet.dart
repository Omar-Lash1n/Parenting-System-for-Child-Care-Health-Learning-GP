import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

// Ordered discrete GPS-report-interval steps (in seconds)
// Range: 5 ث → 10 س, mixed seconds/minutes/hours to match Figma slider frames
const List<int> _kSteps = [
  5,    // 5 ث
  15,   // 15 ث
  30,   // 30 ث
  60,   // 1 دق
  300,  // 5 دق
  600,  // 10 دق
  900,  // 15 دق  ← default
  1200, // 20 دق
  1500, // 25 دق
  1800, // 30 دق
  3600, // 1 س
  7200, // 2 س
  18000,// 5 س
  36000,// 10 س
];

String _label(int seconds) {
  if (seconds < 60) return '$seconds ث';
  if (seconds < 3600) return '${seconds ~/ 60} دق';
  return '${seconds ~/ 3600} س';
}

/// Shows the "مدة تشغيل gps" bottom sheet.
/// [currentSeconds] is the existing interval; calls [onConfirm] with the new value.
Future<void> showIntervalSheet(
  BuildContext context, {
  required int currentSeconds,
  required void Function(int seconds) onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IntervalSheet(
      currentSeconds: currentSeconds,
      onConfirm: onConfirm,
    ),
  );
}

class _IntervalSheet extends StatefulWidget {
  const _IntervalSheet({
    required this.currentSeconds,
    required this.onConfirm,
  });

  final int currentSeconds;
  final void Function(int seconds) onConfirm;

  @override
  State<_IntervalSheet> createState() => _IntervalSheetState();
}

class _IntervalSheetState extends State<_IntervalSheet> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    // Find the step index closest to currentSeconds
    int best = 0;
    int bestDiff = (widget.currentSeconds - _kSteps[0]).abs();
    for (int i = 1; i < _kSteps.length; i++) {
      final diff = (widget.currentSeconds - _kSteps[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    _sliderValue = best.toDouble();
  }

  int get _selectedSeconds => _kSteps[_sliderValue.round()];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                // X close button (leftmost in RTL → visually right)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.black87),
                  ),
                ),
                const Spacer(),
                const Text(
                  'مدة تشغيل gps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kFont,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // ── Current value label ───────────────────────────────────────
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _label(_selectedSeconds),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: _kFont,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Slider ────────────────────────────────────────────────────
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _kRed,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: _kRed,
                overlayColor: _kRed.withAlpha(30),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: (_kSteps.length - 1).toDouble(),
                divisions: _kSteps.length - 1,
                onChanged: (v) => setState(() => _sliderValue = v),
              ),
            ),

            const SizedBox(height: 28),

            // ── Confirm button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(_selectedSeconds);
                },
                child: const Text(
                  'تاكيد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kFont,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
