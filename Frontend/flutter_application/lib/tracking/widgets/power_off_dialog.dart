import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

/// Shows the "ايقاف تشغيل القطعة؟" confirmation dialog.
/// Calls [onConfirm] when the user taps "نعم, ايقاف".
Future<void> showPowerOffDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PowerOffDialog(onConfirm: onConfirm),
  );
}

class _PowerOffDialog extends StatelessWidget {
  const _PowerOffDialog({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── X close ──────────────────────────────────────────────────
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GestureDetector(
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
              ),
              const SizedBox(height: 16),

              // ── Warning icon ─────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _kPinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: _kRed, size: 40),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────────────────
              const Text(
                'ايقاف تشغيل القطعة؟',
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
                'سوف يتم ايقاف تتبع الطفل الان فور ايقاف التشغيل وسيتطلب تشغيل مرة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                  fontFamily: _kFont,
                ),
              ),
              const SizedBox(height: 28),

              // ── Buttons ───────────────────────────────────────────────────
              Row(
                children: [
                  // "لا, ابقاء" – keep (outlined)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'لا, ابقاء',
                        style: TextStyle(
                          color: Colors.black87,
                          fontFamily: _kFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // "نعم, ايقاف" – confirm (red filled)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: const Text(
                        'نعم, ايقاف',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
