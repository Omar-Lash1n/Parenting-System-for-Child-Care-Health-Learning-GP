import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kRed = Color(0xFFBF092F);
const Color _kPinkLight = Color(0xFFF8E8EB);
const String _kFont = 'IBM Plex Sans Arabic';

/// Shows the "خرج الطفل من سور الحماية" breach alert dialog.
/// [sim] is dialed when the parent taps "اتصل بالطفل".
Future<void> showBreachDialog(
  BuildContext context, {
  required String sim,
  VoidCallback? onAcknowledge,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BreachDialog(sim: sim, onAcknowledge: onAcknowledge),
  );
}

class _BreachDialog extends StatelessWidget {
  const _BreachDialog({required this.sim, this.onAcknowledge});

  final String sim;
  final VoidCallback? onAcknowledge;

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: sim);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // X close — aligns to start (right in RTL)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onAcknowledge?.call();
                  },
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
              const SizedBox(height: 12),

              // Warning icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: _kPinkLight, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: _kRed, size: 40),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'خرج الطفل من سور الحماية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: _kFont,
                ),
              ),
              const SizedBox(height: 12),

              // Body
              const Text(
                'يمكنك سرعة التصرف عن طريق الاتصال بالقطعة مباشرة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                  fontFamily: _kFont,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // "اعلم ذلك" — dismiss
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAcknowledge?.call();
                      },
                      child: const Text(
                        'اعلم ذلك',
                        style: TextStyle(
                            color: Colors.black87,
                            fontFamily: _kFont,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // "اتصل بالطفل" — call
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _call();
                      },
                      child: const Text(
                        'اتصل بالطفل',
                        style: TextStyle(
                            fontFamily: _kFont, fontWeight: FontWeight.bold),
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
