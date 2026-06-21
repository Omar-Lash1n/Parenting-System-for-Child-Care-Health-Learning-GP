import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/specialist_application_tracking_page.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_main_dashboard.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_profile_page.dart';

class SpecialistHomePage extends StatefulWidget {
  const SpecialistHomePage({super.key});

  @override
  State<SpecialistHomePage> createState() => _SpecialistHomePageState();
}

class _SpecialistHomePageState extends State<SpecialistHomePage> {
  int _currentIndex = 2; // Default to Home

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialistApplicationProvider>().loadCurrent().then((_) {
        if (!mounted) return;
        final current = context.read<SpecialistApplicationProvider>().current;
        if (current == null || current.status != 'Approved') {
          setState(() {
            _currentIndex = 1; // Default to tracking if not approved
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const SpecialistProfilePage(),
            const SpecialistApplicationTrackingPage(showBottomNav: false),
            const SafeArea(bottom: false, child: SpecialistMainDashboard()),
          ],
        ),
        bottomNavigationBar: SpecialistBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              final current = context.read<SpecialistApplicationProvider>().current;
              if (current == null || current.status != 'Approved') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرئيسية متاحة فقط بعد قبول طلب التقديم الخاص بك', style: TextStyle(fontFamily: specialistFont)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
            }
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

