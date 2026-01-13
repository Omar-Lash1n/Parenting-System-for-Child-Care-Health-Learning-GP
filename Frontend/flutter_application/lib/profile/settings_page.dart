// --- lib/profile/settings_page.dart ---
// Settings Page - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/settings_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/profile/about_page.dart';
import 'package:Ajial/profile/terms_page.dart';
import 'package:Ajial/profile/privacy_page.dart';
import 'package:Ajial/profile/contact_page.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFBF092F);
const Color kRedDelete = Color(0xFFD90000);
const Color kGreen = Color(0xFF01A449);
const Color kBlue = Color(0xFF008CFF);
const Color kOrange = Color(0xFFFE8401);
const Color kYellow = Color(0xFFFEA400);
const String kFontFamily = 'IBM Plex Sans Arabic';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load settings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, ParentProfileProvider>(
      builder: (context, settingsProvider, profileProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      // Account Verification Section (show only if not verified)
                      if (!profileProvider.isEmailVerified)
                        _buildVerificationCard(profileProvider),
                      if (!profileProvider.isEmailVerified)
                        const SizedBox(height: 24),
                      // Family Management Section
                      _buildSectionHeader('الادارة الاسرية'),
                      const SizedBox(height: 14),
                      _buildToggleRow(
                        label: 'تحقق دخول الطفل',
                        icon: Icons.verified_user_outlined,
                        iconColor: kGreen,
                        isOn: settingsProvider.childLoginVerification,
                        onToggle: () =>
                            settingsProvider.toggleChildLoginVerification(),
                      ),
                      const SizedBox(height: 24),
                      // Preferences Section
                      _buildSectionHeader('التفضيلات'),
                      const SizedBox(height: 14),
                      _buildToggleRow(
                        label: 'الاشعارات',
                        icon: Icons.notifications_outlined,
                        iconColor: kBlue,
                        isOn: settingsProvider.notificationsEnabled,
                        onToggle: () => settingsProvider.toggleNotifications(),
                      ),
                      const SizedBox(height: 24),
                      // Support & Information Section
                      _buildSectionHeader('الدعم و المعلومات'),
                      const SizedBox(height: 14),
                      _buildMenuRow(
                        label: 'حول التطبيق',
                        icon: Icons.help_outline,
                        iconColor: kRedDelete,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuRow(
                        label: 'شروط الاستخدام',
                        icon: Icons.check_circle_outline,
                        iconColor: kGreen,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuRow(
                        label: 'سياسية الخصوصية',
                        icon: Icons.shield_outlined,
                        iconColor: kBlue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuRow(
                        label: 'تواصل معنا',
                        icon: Icons.chat_bubble_outline,
                        iconColor: kPrimaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuRow(
                        label: 'تقييم التطبيق',
                        icon: Icons.star_outline,
                        iconColor: kYellow,
                        onTap: () => _showRateAppDialog(),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Header with Back Button ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 38), // Spacer for symmetry
        const Text(
          'الاعدادات',
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

  // --- Account Verification Card ---
  Widget _buildVerificationCard(ParentProfileProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: kOrange, size: 24),
              const SizedBox(width: 6),
              const Text(
                'تأكيد الحساب',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'قم بتفعيل الحساب لاستخدام اكثر اماناً',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xBF000000),
            ),
          ),
          const SizedBox(height: 12),
          if (provider.isPollingForVerification)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kOrange,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'في انتظار التفعيل...',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    color: Color(0x99000000),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: provider.isSaving
                    ? null
                    : () async {
                        final (success, message) =
                            await provider.sendVerificationEmail();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                        if (success) {
                          provider.startVerificationPolling();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'تأكيد الان',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Section Header ---
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 47,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // --- Toggle Row ---
  Widget _buildToggleRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isOn,
    required VoidCallback onToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon and Label (appears on RIGHT in RTL)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // Toggle Switch (appears on LEFT in RTL)
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 51,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isOn ? kPrimaryColor : const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 18.75,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Menu Row (for navigable items) ---
  Widget _buildMenuRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon and Label (appears on RIGHT in RTL)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          // Chevron Arrow (pointing right/outside)
          const Icon(
            Icons.chevron_right,
            size: 24,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  // --- Rate App Dialog ---
  void _showRateAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: kYellow, size: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'شكراً لاستخدامك التطبيق!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم فتح متجر التطبيقات للتقييم',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                color: Color(0x99000000),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'حسناً',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontWeight: FontWeight.w600,
                color: kYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
