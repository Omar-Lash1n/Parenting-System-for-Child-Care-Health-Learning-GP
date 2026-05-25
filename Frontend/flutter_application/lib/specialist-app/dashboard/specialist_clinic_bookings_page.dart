import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_page.dart';
import 'package:Ajial/specialist-app/dashboard/providers/clinic_remote_provider.dart';

class SpecialistClinicBookingsPage extends StatelessWidget {
  const SpecialistClinicBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FAF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: specialistGreen,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'حجوزات العيادة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              
              // Empty State Body
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/specialist_box.png',
                        width: 100,
                        height: 100,
                        color: Colors.black.withValues(alpha: 0.4),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'يبدو انه لا يتوفر عيادات تم اضافتها,',
                        style: TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط اضافة عيادة جديدة',
                        style: TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () async {
                      final provider = context.read<ClinicRemoteProvider>();
                      final clinicId = await provider.createClinic();
                      if (clinicId != null && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SpecialistAddClinicPage(
                              clinicId: clinicId,
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'اضافة عيادة جديدة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
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
