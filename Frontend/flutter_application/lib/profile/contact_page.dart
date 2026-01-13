// --- lib/profile/contact_page.dart ---
// Contact Us Page

import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFBF092F);
const Color kBlue = Color(0xFF008CFF);
const Color kGreen = Color(0xFF01A449);
const String kFontFamily = 'IBM Plex Sans Arabic';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
                  // Contact Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_outlined,
                      size: 60,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تواصل معنا',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نحن هنا لمساعدتك',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0x99000000),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Contact Options
                  _buildContactOption(
                    icon: Icons.email_outlined,
                    iconColor: kBlue,
                    title: 'البريد الإلكتروني',
                    subtitle: 'support@ajial.app',
                    onTap: () {
                      // TODO: Launch email app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('سيتم فتح تطبيق البريد الإلكتروني'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildContactOption(
                    icon: Icons.phone_outlined,
                    iconColor: kGreen,
                    title: 'رقم الهاتف',
                    subtitle: '+20 XXX XXX XXXX',
                    onTap: () {
                      // TODO: Launch phone app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('سيتم فتح تطبيق الهاتف'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Social Media Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'تابعنا على',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _buildSocialButton(
                        icon: Icons.camera_alt_outlined,
                        color: const Color(0xFFE4405F),
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _buildSocialButton(
                        icon: Icons.alternate_email,
                        color: const Color(0xFF1DA1F2),
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Working Hours
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
                          'ساعات العمل',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'الأحد - الخميس: 9 صباحاً - 5 مساءً',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xBF000000),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'الجمعة - السبت: مغلق',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xBF000000),
                          ),
                        ),
                      ],
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
          'تواصل معنا',
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

  Widget _buildContactOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0x99000000),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
