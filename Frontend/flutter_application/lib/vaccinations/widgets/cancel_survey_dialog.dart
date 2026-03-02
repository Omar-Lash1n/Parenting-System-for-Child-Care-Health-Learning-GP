// --- lib/vaccinations/widgets/cancel_survey_dialog.dart ---

import 'package:flutter/material.dart';

// ─────────────────────── Design Tokens ───────────────────────────────────────
const String _kFontFamily = 'IBM Plex Sans Arabic';
const Color _kRedColor = Color(0xFFFF0000);

/// Shows a confirmation dialog asking whether the user wants to cancel the
/// vaccination survey and return to the profile page.
///
/// Returns `true` if the user confirmed cancellation, `false` otherwise.
///
/// - "نعم, الغاء" button → returns `true`
/// - "لا, استمرار" button / close icon / tap outside → returns `false`
Future<bool> showCancelSurveyDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true, // tap outside dismisses
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (context) => const _CancelSurveyDialog(),
  );
  return result ?? false;
}

// ─────────────────────── Dialog Widget ────────────────────────────────────────

class _CancelSurveyDialog extends StatelessWidget {
  const _CancelSurveyDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 318,
          padding:
              const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000), // rgba(0,0,0,0.15)
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Close (×) button — top right ─────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Warning icon ─────────────────────────────────────────────
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: _kRedColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: _kRedColor,
                    size: 39,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Title ────────────────────────────────────────────────────
              const Text(
                'الغاء الاستبيان؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 30 / 20,
                  color: Color(0xFF000000),
                ),
              ),

              const SizedBox(height: 6),

              // ── Subtitle ─────────────────────────────────────────────────
              const SizedBox(
                width: 217,
                child: Text(
                  'سيتم فقد التطعيمات التى تم تحديدها\nوالعودة الى الملف الشخصى',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontWeight: FontWeight.w300,
                    fontSize: 14,
                    height: 21 / 14,
                    color: Color(0xFF000000),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Action buttons ───────────────────────────────────────────
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "نعم, الغاء" — red filled (right side in RTL)
                    SizedBox(
                      width: 131,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRedColor,
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'نعم, الغاء',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            height: 27 / 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // "لا, استمرار" — outlined (left side in RTL)
                    SizedBox(
                      width: 131,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.black.withOpacity(0.5), width: 1),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'لا, استمرار',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            height: 27 / 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
