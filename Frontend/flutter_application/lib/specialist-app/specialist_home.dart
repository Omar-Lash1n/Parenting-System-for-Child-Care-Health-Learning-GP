import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/specialist_application_tracking_page.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_main_dashboard.dart';
import 'package:Ajial/role_selection.dart';

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
            const _ProfilePlaceholder(),
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

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'الملف الشخصي (قريباً)',
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // ── Logout Button ─────────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
                      (route) => false, // Clear entire stack
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBF092F), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Color(0xFFBF092F), size: 20),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBF092F),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
