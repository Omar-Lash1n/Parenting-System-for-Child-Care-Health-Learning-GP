import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_data_page.dart';

class SpecialistTelemedicineSuccessPage extends StatelessWidget {
  const SpecialistTelemedicineSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                
                // Title
                const Text(
                  'تم ارسال بيانات الكشف بنجاح!',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'يرجى انتظار الرد فى اقرب وقت حول\nاضافة الكشف',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 16,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 2),
                
                // Icon (Green paper plane as requested by design)
                Image.asset(
                  'images/telemedicine_success.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                
                const Spacer(flex: 3),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (globalDraftTelemedicine != null && !globalTelemedicineList.contains(globalDraftTelemedicine!)) {
                        globalTelemedicineList.add(globalDraftTelemedicine!);
                      }
                      globalDraftTelemedicine = null;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: specialistGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'استمرار',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
