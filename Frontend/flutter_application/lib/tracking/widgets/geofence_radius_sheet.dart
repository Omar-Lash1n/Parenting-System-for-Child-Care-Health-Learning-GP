import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

const _kRadiusOptions = [100.0, 250.0, 500.0, 1000.0, 2000.0, 5000.0];

/// Label for a radius in meters: 100–999 → "X متر", 1000 → "1 كم".
String geofenceRadiusLabel(double meters) {
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(0)} كم';
  return '${meters.toStringAsFixed(0)} متر';
}

/// "مساحة سور الحماية" — modal sheet with a slider from 100 m to 1 000 m.
/// [currentRadius] is the initial value in meters.
/// [onConfirm] is called with the chosen radius in meters.
Future<void> showGeofenceRadiusSheet(
  BuildContext context, {
  required double currentRadius,
  required ValueChanged<double> onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _GeofenceRadiusSheet(
      currentRadius: currentRadius,
      onConfirm: onConfirm,
    ),
  );
}

class _GeofenceRadiusSheet extends StatefulWidget {
  const _GeofenceRadiusSheet({
    required this.currentRadius,
    required this.onConfirm,
  });

  final double currentRadius;
  final ValueChanged<double> onConfirm;

  @override
  State<_GeofenceRadiusSheet> createState() => _GeofenceRadiusSheetState();
}

class _GeofenceRadiusSheetState extends State<_GeofenceRadiusSheet> {
  late double _radius;

  @override
  void initState() {
    super.initState();
    final clamped = widget.currentRadius.clamp(100.0, 5000.0);
    _radius = _kRadiusOptions.reduce((a, b) =>
        (a - clamped).abs() <= (b - clamped).abs() ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
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
                  'مساحة سور الحماية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: _kFont,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // ── Section label ────────────────────────────────────────────────
            const Text(
              'نطاق سور الحماية',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontFamily: _kFont, color: Colors.black54),
            ),
            const SizedBox(height: 10),

            // ── Radius chips ─────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: _kRadiusOptions.map((r) {
                  final selected = r == _radius;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _radius = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? _kRed : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          geofenceRadiusLabel(r),
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: _kFont,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // ── Confirm button ────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(_radius);
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
