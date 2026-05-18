// --- lib/profile/parent_profile.dart ---
// Parent Profile Page - Following Figma CSS Specifications

import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/family/family_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/profile/profile_dialogs.dart';
import 'package:Ajial/profile/change_password_page.dart';
import 'package:Ajial/profile/change_email_page.dart';
import 'package:Ajial/profile/delete_account_page.dart';
import 'package:Ajial/profile/my_child_profile.dart';
import 'package:Ajial/add-child/add-child-flow.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/widgets/skeleton_loading.dart';
import 'package:Ajial/ranking/providers/ranking_provider.dart';
import 'package:Ajial/ranking/models/ranking_models.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFBF092F);
const Color kRedDelete = Color(0xFFD90000);
const Color kGreen = Color(0xFF01A449);
const Color kBlue = Color(0xFF008CFF);
const Color kOrange = Color(0xFFFE8401);
const String kFontFamily = 'IBM Plex Sans Arabic';

class ParentProfilePage extends StatefulWidget {
  const ParentProfilePage({super.key});

  @override
  State<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends State<ParentProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParentProfileProvider>().fetchProfile();
      context.read<RankingProvider>().loadMyBadges();
    });
  }

  @override
  void dispose() {
    // Stop polling when widget is disposed
    context.read<ParentProfileProvider>().stopVerificationPolling();
    super.dispose();
  }

  // Show verification success popup
  void _showVerificationSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kGreen.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: kGreen, size: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم تفعيل حسابكم',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'شكراً لتأكيد بريدك الإلكتروني',
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
                color: kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentProfileProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: ParentProfileSkeleton(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(provider),
                      const SizedBox(height: 24),
                      _buildProfileSection(provider),
                      const SizedBox(height: 24),
                      _buildEmailVerificationBanner(provider),
                      const SizedBox(height: 34),
                      _buildBadgesSection(context),
                      const SizedBox(height: 34),
                      _buildChildrenSection(provider),
                      const SizedBox(height: 34),
                      _buildPersonalDataSection(provider),
                      const SizedBox(height: 34),
                      _buildSettingsSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(provider),
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

  // --- Header ---
  Widget _buildHeader(ParentProfileProvider provider) {
    final firstName = provider.fullName.split(' ').first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Settings Icon
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.5)),
            ),
            child: const Icon(Icons.settings_outlined, size: 24),
          ),
        ),
        // Greeting
        Text(
          '$firstName مرحباً',
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Profile Section ---
  Widget _buildProfileSection(ParentProfileProvider provider) {
    final initial = provider.fullName.isNotEmpty ? provider.fullName[0] : 'م';
    return Column(
      children: [
        // Profile Image
        Stack(
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlue.withAlpha(25),
                border: Border.all(color: const Color(0xFFD9D9D9), width: 1.48),
              ),
              child: provider.profileImageUrl != null &&
                      provider.profileImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        provider.profileImageUrl!,
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: kBlue,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: kBlue,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: kBlue,
                        ),
                      ),
                    ),
            ),
            Positioned(
              right: 7,
              bottom: 8,
              child: GestureDetector(
                onTap: () => _handleImageUpload(provider),
                child: Container(
                  padding: const EdgeInsets.all(7.37),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.black.withOpacity(0.5), width: 0.74),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          provider.fullName,
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatCard('نقطة', '0', kPrimaryColor),
            const SizedBox(width: 16),
            Consumer<RankingProvider>(
              builder: (_, rp, __) =>
                  _buildStatCard('وسم', '${rp.myBadges.length}', kGreen),
            ),
            const SizedBox(width: 16),
            _buildStatCard(
                'طفل', '${provider.numberOfChildren}', const Color(0xFFFEA400)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- Handle Image Upload ---
  Future<void> _handleImageUpload(ParentProfileProvider provider) async {
    final ImagePicker picker = ImagePicker();

    // Show bottom sheet to choose source
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر مصدر الصورة',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'المعرض',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );

      // Read image bytes for web compatibility
      final imageBytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;
      final (success, message) =
          await provider.uploadProfileImage(imageBytes, fileName);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? kGreen : kPrimaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في اختيار الصورة'),
          backgroundColor: kPrimaryColor,
        ),
      );
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimaryColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Email Verification Banner ---
  Widget _buildEmailVerificationBanner(ParentProfileProvider provider) {
    // Don't show banner if email is already verified (status shown in email row)
    if (provider.isEmailVerified) {
      return const SizedBox.shrink();
    }

    // Show unverified state with button to send verification email
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC800).withAlpha(64),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'تأكيد الحساب',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded, color: kOrange, size: 24),
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
          // Show loading indicator or polling status
          if (provider.isPollingForVerification)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'في انتظار التفعيل...',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    color: Color(0x99000000),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kOrange,
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: provider.isSaving
                  ? null
                  : () async {
                      final (success, message) =
                          await provider.sendVerificationEmail();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );

                      // Start polling for verification status if send was successful
                      if (success) {
                        provider.startVerificationPolling(
                          onVerified: () {
                            if (mounted) {
                              _showVerificationSuccessDialog();
                            }
                          },
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
        ],
      ),
    );
  }

  // --- Badges Section ---
  Widget _buildBadgesSection(BuildContext context) {
    return Consumer<RankingProvider>(
      builder: (context, rp, _) {
        if (rp.isBadgesLoading) {
          return Column(
            children: [
              _buildSectionHeader('المكافآت', true),
              const SizedBox(height: 14),
              const SizedBox(
                  height: 80,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryColor, strokeWidth: 2))),
            ],
          );
        }
        if (rp.myBadges.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _buildSectionHeader('المكافآت', true),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: rp.myBadges.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildBadgeCard(rp.myBadges[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBadgeCard(ParentBadge badge) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 75,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _badgeBgColor(badge.badge),
                  ),
                  child: Icon(Icons.star,
                      color: _badgeIconColor(badge.badge), size: 32),
                ),
                Positioned(
                  bottom: 0,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_ribbonTail(), _ribbonTail()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.seasonName,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 11,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _ribbonTail() => Container(
        width: 8,
        height: 14,
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Color _badgeBgColor(String badge) {
    switch (badge) {
      case 'Gold':
        return const Color(0xFFFFF3C4);
      case 'Silver':
        return const Color(0xFFF0F0F0);
      case 'Bronze':
        return const Color(0xFFF5E6D3);
      default:
        return const Color(0xFFFFF3C4);
    }
  }

  Color _badgeIconColor(String badge) {
    switch (badge) {
      case 'Gold':
        return const Color(0xFFFFC107);
      case 'Silver':
        return const Color(0xFF9E9E9E);
      case 'Bronze':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFFFFC107);
    }
  }

  // --- Children Section ---
  Widget _buildChildrenSection(ParentProfileProvider provider) {
    final children = provider.children;
    return Column(
      children: [
        _buildSectionHeader(
          'الاطفال',
          true,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FamilyPage()),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 99,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: children.isEmpty ? 1 : children.length + 1,
            itemBuilder: (context, index) {
              // Add child button at the last position (left side)
              final isAddButton =
                  children.isEmpty ? index == 0 : index == children.length;

              if (isAddButton) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddChildFlow()),
                    );
                  },
                  child: Opacity(
                    opacity: 0.5,
                    child: Column(
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          padding: const EdgeInsets.all(25.9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.25),
                              width: 1.23,
                            ),
                          ),
                          child: const Icon(Icons.sentiment_satisfied_alt,
                              size: 22),
                        ),
                        const SizedBox(height: 4),
                        const Text('اضف طفل',
                            style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }
              // Display child from API
              final child = children[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyChildProfilePage(childId: child['childId']),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kBlue.withOpacity(0.1),
                          border: Border.all(
                              color: const Color(0xFFD9D9D9), width: 1.23),
                        ),
                        child: child['profileImageUrl'] != null &&
                                child['profileImageUrl'].toString().isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  child['profileImageUrl'],
                                  width: 74,
                                  height: 74,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, childWidget, loadingProgress) {
                                    if (loadingProgress == null)
                                      return childWidget;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: kBlue,
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      child['fullName']?[0] ?? 'ط',
                                      style: TextStyle(
                                        fontFamily: kFontFamily,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: kBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(child['fullName']?[0] ?? 'ط',
                                    style: TextStyle(
                                        fontFamily: kFontFamily,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: kBlue))),
                      ),
                      const SizedBox(height: 4),
                      Text(child['fullName'] ?? '',
                          style: const TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Personal Data Section ---
  Widget _buildPersonalDataSection(ParentProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('البيانات الشخصية', false),
        const SizedBox(height: 14),
        Column(
          children: [
            _buildDataRow(
              provider.fullName.isNotEmpty ? provider.fullName : 'الاسم',
              kPrimaryColor,
              Icons.person_outline,
              () => ProfileDialogs.showEditNameDialog(
                context,
                provider.fullName,
                (newValue) async {
                  final (success, message) =
                      await provider.updateProfile(fullName: newValue);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              provider.username.isNotEmpty ? provider.username : 'اسم المستخدم',
              kGreen,
              Icons.check_circle_outline,
              () => ProfileDialogs.showEditUsernameDialog(
                context,
                provider.username,
                (newValue) async {
                  final (success, message) =
                      await provider.updateProfile(username: newValue);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildEmailRow(provider),
            const SizedBox(height: 12),
            _buildDataRow(
              'كلمة المرور',
              kGreen,
              Icons.vpn_key_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              provider.role.isNotEmpty ? provider.role : 'الدور',
              kBlue,
              Icons.people_outline,
              () => ProfileDialogs.showEditRoleDialog(
                context,
                provider.roleCode,
                (newRoleCode) async {
                  // Refresh profile to get updated role
                  await provider.fetchProfile();
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              provider.cityName.isNotEmpty ? provider.cityName : 'المدينة',
              kRedDelete,
              Icons.location_on_outlined,
              () => ProfileDialogs.showEditCityDialog(
                context,
                provider.cityName,
                (cityId) async {
                  // Refresh profile to get updated city name
                  await provider.fetchProfile();
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              provider.dateOfBirth.isNotEmpty
                  ? _formatBirthDate(provider.dateOfBirth)
                  : 'تاريخ الميلاد',
              kBlue,
              Icons.calendar_month_outlined,
              () => ProfileDialogs.showEditBirthdayDialog(
                context,
                provider.dateOfBirth,
                (newValue) async {
                  // Refresh profile to get updated date
                  await provider.fetchProfile();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatBirthDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final age = DateTime.now().year - date.year;
      return '$age عام';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDataRow(
      String label, Color iconColor, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onTap,
          child: const Icon(Icons.edit_outlined, size: 24),
        ),
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailRow(ParentProfileProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangeEmailPage(),
            ),
          ).then((_) => provider.fetchProfile()),
          child: const Icon(Icons.edit_outlined, size: 24),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Show verification status badge
              if (provider.isEmailVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'مؤكد',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kGreen,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDBF),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'تاكيد الحساب',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kOrange,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  provider.email.isNotEmpty
                      ? provider.email
                      : 'البريد الإلكتروني',
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kOrange.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.email_outlined, color: kOrange, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Settings Section ---
  Widget _buildSettingsSection() {
    return _buildSectionHeader('الاعدادات العامة', false);
  }

  // --- Section Header ---
  Widget _buildSectionHeader(
    String title,
    bool showViewAll, {
    VoidCallback? onViewAll,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 47,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(showViewAll ? 50 : 25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          Text(
            title,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- Action Buttons ---
  Widget _buildActionButtons(ParentProfileProvider provider) {
    return Column(
      children: [
        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              // Clear stale in-memory category state so re-login fetches fresh data
              context.read<TasksProvider>().reset();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRedDelete,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
            ),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Delete Account Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeleteAccountPage(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kRedDelete.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
            ),
            child: Text(
              'حذف الحساب',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: kRedDelete,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
