import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

/// Shows the "يرجي تشغيل القطعة" info dialog (frame 160).
/// Displayed when the user tries to start tracking but the device is offline.
Future<void> showPowerOnDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _PowerOnDialog(),
  );
}

class _PowerOnDialog extends StatelessWidget {
  const _PowerOnDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Power icon ───────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _kPinkLight,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.power_settings_new, color: _kRed, size: 40),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────────────────
              const Text(
                'يرجي تشغيل القطعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: _kFont,
                ),
              ),
              const SizedBox(height: 12),

              // ── Body ─────────────────────────────────────────────────────
              const Text(
                'حاول ان تضغط على زر الطاقة في القطعة حق يمكن الاستمرار و بدء تشغيل gps',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.6,
                  fontFamily: _kFont,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'حسناً',
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
      ),
    );
  }
}
