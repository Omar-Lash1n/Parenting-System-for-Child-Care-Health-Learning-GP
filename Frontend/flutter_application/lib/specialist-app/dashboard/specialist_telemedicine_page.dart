import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/dashboard_card.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_bookings_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_data_page.dart';

class SpecialistTelemedicinePage extends StatelessWidget {
  const SpecialistTelemedicinePage({super.key});

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
                      'الكشف عن بعد',
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
              
              // Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DashboardCard(
                      title: 'حجوزات الكشف عن بعد',
                      subtitle: 'قم بمتابعة حجوزاتك',
                      iconAsset: 'images/specialist_notes.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpecialistTelemedicineBookingsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'بيانات الكشف عن بعد',
                      subtitle: 'يمكنك تعديل الكشف',
                      iconAsset: 'images/specialist_notes.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpecialistTelemedicineDataPage(),
                          ),
                        );
                      },
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
