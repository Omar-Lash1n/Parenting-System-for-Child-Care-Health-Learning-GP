import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class SpecialistApplicationSubmitSuccessPage extends StatelessWidget {
  const SpecialistApplicationSubmitSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 118),
                const Text(
                  'تم ارسال البيانات بنجاح!',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى انتظار الرد في أقرب وقت',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.58),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Transform.rotate(
                  angle: -0.78,
                  child: const Icon(
                    Icons.send_outlined,
                    color: specialistGreen,
                    size: 210,
                  ),
                ),
                const Spacer(),
                PrimaryGreenButton(
                  label: 'استمرار',
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
