import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/dashboard_card.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinics_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_telemedicine_page.dart';

class SpecialistMainDashboard extends StatelessWidget {
  const SpecialistMainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpecialistApplicationProvider>(
      builder: (context, provider, _) {
        final current = provider.current;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 34),
          child: Column(
            children: [
              SpecialistHeaderWidget(
                name: provider.specialistName,
                specialtyName: current?.specialtyName ?? '',
                imageUrl: current?.personalPhotoUrl,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DashboardCard(
                      title: 'العيادات',
                      subtitle: 'قم بمتابعة عيادتك',
                      iconAsset: 'images/specialist_notes.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpecialistClinicsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DashboardCard(
                      title: 'الكشف عن بعد',
                      subtitle: 'قم بمتابعة استشاراتك',
                      iconAsset: 'images/specialist_notes.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SpecialistTelemedicinePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
