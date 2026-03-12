import 'package:flutter/material.dart';

const Color _kGreen = Color(0xFF01A449);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Step 5: Success — Confirmation screen after submission
/// On "استمرار" → pops back to the login screen (avoids circular imports)
class StepSuccess extends StatelessWidget {
  const StepSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Title
            const Text(
              'تم ارسال البيانات بنجاح!',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'يرجى انتظار الرد فى اقرب وقت',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Large green send/paper-plane icon — rotated ~65° to point northwest
            SizedBox(
              width: 233,
              height: 233,
              child: Transform.rotate(
                angle: -65 * 3.14159265 / 180, // 65° clockwise
                child: const Icon(Icons.send_rounded, color: _kGreen, size: 180),
              ),
            ),
            const Spacer(),
            // Button to go to login — just pop Registration to go back to Login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Pop the Registration screen → returns to Login
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'استمرار',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
