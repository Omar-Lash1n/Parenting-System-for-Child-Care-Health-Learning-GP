// --- lib/profile/about_page.dart ---
// About the App Page

import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  // App Logo
                  Image.asset(
                    'images/main-logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.child_care,
                        size: 60,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  const Text(
                    'أجيال',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version
                  const Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0x99000000),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'حول التطبيق',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'تطبيق أجيال هو تطبيق متكامل للعناية بالأطفال ومتابعة تعليمهم وصحتهم. يساعد الآباء والأمهات على متابعة أطفالهم بطريقة سهلة وآمنة.',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xBF000000),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Developer Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'فريق التطوير',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'تم تطوير هذا التطبيق كمشروع تخرج من قبل فريق متخصص في تطوير تطبيقات الجوال.',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xBF000000),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Copyright
                  const Text(
                    '© 2026 أجيال. جميع الحقوق محفوظة.',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0x99000000),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 38),
        const Text(
          'حول التطبيق',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8.64),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20.73,
              color: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
