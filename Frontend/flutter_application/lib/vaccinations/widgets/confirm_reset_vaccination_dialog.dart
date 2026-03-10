// lib/vaccinations/widgets/confirm_reset_vaccination_dialog.dart
//
// "تهيئة ملف التطعيمات؟" — Confirmation dialog shown after
// selecting a child to retake the vaccination survey. Warns the
// user that existing vaccination data will be deleted.

import 'package:flutter/material.dart';

const Color _kRed = Color(0xFFFF0000);
const Color _kRedLight = Color(0x1AFF0000); // 10 %
const String _kFont = 'IBM Plex Sans Arabic';

/// Shows a confirmation dialog before resetting vaccination data.
///
/// Returns `true` if the user confirmed, `false` or `null` if cancelled.
Future<bool?> showConfirmResetVaccinationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _ConfirmResetDialog(),
  );
}

class _ConfirmResetDialog extends StatelessWidget {
  const _ConfirmResetDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Container(
          width: 318,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000), // ~15 %
                blurRadius: 15,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Close button (top-left in RTL) ─────
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0x1A000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Warning icon ─────────────────────────
                Container(
                  width: 75,
                  height: 75,
                  decoration: const BoxDecoration(
                    color: _kRedLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'images/Exclamation Mark.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ────────────────────────────────
                const Text(
                  'تهيئة ملف التطعيمات؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Description ──────────────────────────
                const Text(
                  'بمجرد ملئ استبيان التطعيمات من جديد\nسيتم حذف بيانات تطعيم الطفل الحالية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Buttons row ──────────────────────────
                Row(
                  children: [
                    // "لا, الغاء" — outlined
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.black.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'لا, الغاء',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // "نعم, موافق" — red filled
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRed,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'نعم, موافق',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
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
      ),
    );
  }
}
