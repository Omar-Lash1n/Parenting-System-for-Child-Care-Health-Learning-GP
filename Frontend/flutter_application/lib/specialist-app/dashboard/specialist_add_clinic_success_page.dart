import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/providers/clinic_remote_provider.dart';

class SpecialistAddClinicSuccessPage extends StatelessWidget {
  final String clinicId;

  const SpecialistAddClinicSuccessPage({super.key, required this.clinicId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicRemoteProvider>();

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
                  'تم ارسال بيانات العيادة بنجاح!',
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
                  'يرجى انتظار الرد فى اقرب وقت حول\nاضافة العيادة',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 16,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 2),
                
                // Icon
                Image.asset(
                  'images/specialist_success.png',
                  height: 200,
                  fit: BoxFit.contain,
                ),
                
                const Spacer(flex: 3),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
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
