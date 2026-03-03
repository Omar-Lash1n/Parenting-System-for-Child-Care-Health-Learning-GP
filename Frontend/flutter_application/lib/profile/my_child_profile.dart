// --- lib/profile/my_child_profile.dart ---
// Child Profile Screen - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/providers/child_profile_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/profile/child_data_profile.dart';
import 'package:Ajial/profile/child_data_profile_form.dart';
import 'package:Ajial/profile/making_child_account.dart';
import 'package:Ajial/providers/child_data_provider.dart';

// --- CONSTANTS ---
const Color _kPrimaryRed = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kTextDark = Color(0xFF111517);
const Color _kTextGrey = Color(0xFF647887);
const Color _kBorderLight = Color(0xFFF3F4F6);
const Color _kCardBorder = Color(0xFFF1F5F9);
const String _kFontFamily = 'IBM Plex Sans Arabic';

class MyChildProfilePage extends StatefulWidget {
  final String? childId;
  const MyChildProfilePage({super.key, this.childId});

  @override
  State<MyChildProfilePage> createState() => _MyChildProfilePageState();
}

class _MyChildProfilePageState extends State<MyChildProfilePage> {
  @override
  void initState() {
    super.initState();
    // Fetch from API if childId is provided
    if (widget.childId != null && widget.childId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<ChildProfileProvider>()
            .fetchProfileSummary(widget.childId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  // --- Scrollable Content ---
                  Expanded(
                    child: provider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _kPrimaryRed,
                            ),
                          )
                        : provider.hasError
                            ? _buildErrorState(provider)
                            : SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    _buildHeader(context, provider),
                                    const SizedBox(height: 16),
                                    _buildHeroSection(provider),
                                    const SizedBox(height: 16),
                                    // Account card based on accountAction
                                    _buildAccountCardSection(context, provider),
                                    _buildProgressCard(context, provider),
                                    const SizedBox(height: 12),
                                    _buildDashboardGrid(context, provider),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                  ),
                  // --- Bottom Nav Bar ---
                  const AppBottomNavBar(currentIndex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR / RETRY STATE
  // ============================================================
  Widget _buildErrorState(ChildProfileProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: _kPrimaryRed),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 16,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (widget.childId != null) {
                provider.fetchProfileSummary(widget.childId!);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimaryRed,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: _kFontFamily,
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

  // ============================================================
  // A. HEADER
  // ============================================================
  Widget _buildHeader(BuildContext context, ChildProfileProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Right: Back button + Title
        Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kPrimaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  // Force LTR so the icon physically points right in RTL context
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: _kPrimaryRed,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ملف ${provider.childName}',
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),

        // Left: Child selector dropdown pill
        GestureDetector(
          onTap: () => _showChildSelectorDropdown(context, provider),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.black.withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Child avatar circle — show network image if available
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kPrimaryRed.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: provider.profileImageUrl != null &&
                          provider.profileImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            provider.profileImageUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.child_care,
                                  size: 16, color: _kPrimaryRed),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.child_care,
                              size: 16, color: _kPrimaryRed),
                        ),
                ),
                const SizedBox(width: 4),
                // Name + dropdown arrow
                Text(
                  provider.childName,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // B. CENTRAL HERO SECTION
  // ============================================================
  Widget _buildHeroSection(ChildProfileProvider provider) {
    final isOlder = provider.isOlderChild;
    final frameImage =
        isOlder ? 'images/decorative_old.png' : 'images/decorative_little.png';

    return Column(
      children: [
        // --- Large Avatar with decorative frame ---
        SizedBox(
          width: 150,
          height: 154,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Decorative frame
              Image.asset(
                frameImage,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),

              // Inner avatar circle
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: isOlder
                      ? const Color(0xFFF6E4D0)
                      : _kPrimaryRed.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: provider.profileImageUrl != null &&
                        provider.profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          provider.profileImageUrl!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: _kPrimaryRed,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.child_care,
                              size: 32,
                              color: _kPrimaryRed,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.child_care,
                          size: 32,
                          color: _kPrimaryRed,
                        ),
                      ),
              ),

              // Camera button at bottom center
              Positioned(
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _showPhotoBottomSheet(context, provider),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _kPrimaryRed.withOpacity(0.25),
                        width: 0.89,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: _kPrimaryRed,
                      ),
                    ),
                  ),
                ),
              ),

              // Green online indicator (only if account active)
              if (isOlder && provider.isAccountActive)
                Positioned(
                  left: 112,
                  top: 99,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color(0xFF01A449),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Name
        Text(
          provider.childName,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 2),

        // Age
        Text(
          provider.childAge,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),

        // Gamification stats (only if account created)
        if (isOlder && provider.isAccountCreated) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badges pill
              _buildStatPill(
                icon: Icons.workspace_premium,
                iconColor: const Color(0xFF01A449),
                bgColor: const Color(0xFF01A449).withOpacity(0.05),
                borderColor: const Color(0xFF01A449).withOpacity(0.25),
                text: '${provider.badgesCount} وسام',
              ),
              const SizedBox(width: 12),
              // Stars pill
              _buildStatPill(
                icon: Icons.star,
                iconColor: const Color(0xFFFE8401),
                bgColor: const Color(0xFFFE8401).withOpacity(0.05),
                borderColor: const Color(0xFFFE8401).withOpacity(0.25),
                text: '${provider.starsCount} نجمة',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 24, color: iconColor),
        ],
      ),
    );
  }

  // ============================================================
  // B2. ACCOUNT CARD — driven by accountAction from API
  // ============================================================
  Widget _buildAccountCardSection(
      BuildContext context, ChildProfileProvider provider) {
    final action = provider.accountAction;

    // not_eligible → under 4: show nothing (or disabled card inline in progress)
    if (action == 'not_eligible') {
      return const SizedBox.shrink();
    }

    // create_account → 4+, no account: red gradient invite card
    if (action == 'create_account') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color(0xFFBF092F),
                Color(0xB3BF092F), // 70% opacity
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider.accountStatusMessage.isNotEmpty
                    ? provider.accountStatusMessage
                    : ChildDataStrings.accountCardTitle(provider.childName),
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              Text(
                ChildDataStrings.accountCardDescription(provider.childName),
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.25,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const MakingChildAccountPage(),
                    ),
                  );
                  if (result == true) {
                    provider.setAccountCreated(true);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'انشاء حساب',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimaryRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // view_account → has account: show "view details" button
    if (action == 'view_account') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color(0xFF01A449),
                Color(0xB301A449),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider.accountStatusMessage.isNotEmpty
                    ? provider.accountStatusMessage
                    : ChildDataStrings.accountCardTitle(provider.childName),
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Navigate to child data profile (account settings)
                  Navigator.pushNamed(context, '/child-data');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'عرض تفاصيل الحساب',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF01A449),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // C. PROGRESS CARD
  // ============================================================
  Widget _buildProgressCard(
      BuildContext context, ChildProfileProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      // ↓ Escape the page-level RTL so we get full manual control
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title row: percentage LEFT | title RIGHT ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT: percentage
                Text(
                  provider.completionPercentText,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                // RIGHT: Arabic title
                Text(
                  'إتمام ملف ${provider.childName}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- Progress bar: fills LEFT → RIGHT ---
            SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background track
                  Container(
                    decoration: BoxDecoration(
                      color: _kOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  // Orange fill — explicitly left-aligned in LTR context
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: provider.profileCompletionPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kOrange,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- Subtitle: Arabic text right-aligned ---
            SizedBox(
              width: double.infinity,
              child: Text(
                provider.vaccinationStatusText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: _kTextGrey,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // --- "ملئ البيانات" button: RIGHT side ---
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChildDataProfileFormPage(prefill: true),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'ملئ البيانات',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // D. DASHBOARD GRID
  // ============================================================
  Widget _buildDashboardGrid(
      BuildContext context, ChildProfileProvider provider) {
    final items = provider.dashboardItems;
    return Column(
      children: [
        // Row 1: بيانات الطفل (left) | التطعيمات (right)
        _buildDashboardRow(context, items[1], items[0], provider),
        const SizedBox(height: 12),
        // Row 2: المكافآت (left) | المهام (right)
        _buildDashboardRow(context, items[3], items[2], provider),
        const SizedBox(height: 12),
        // Row 3: سجل النمو (left) | السجل الطبي (right)
        _buildDashboardRow(context, items[5], items[4], provider),
      ],
    );
  }

  Widget _buildDashboardRow(BuildContext context, DashboardItem left,
      DashboardItem right, ChildProfileProvider provider) {
    return Row(
      children: [
        Expanded(child: _buildDashboardCard(context, left, provider)),
        const SizedBox(width: 12),
        Expanded(child: _buildDashboardCard(context, right, provider)),
      ],
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, DashboardItem item, ChildProfileProvider provider) {
    return GestureDetector(
      onTap: item.isLocked
          ? null
          : () {
              if (item.title == 'بيانات الطفل') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChildDataProfilePage(childId: widget.childId),
                  ),
                );
              } else if (item.title == 'التطعيمات') {
                Navigator.pushNamed(
                  context,
                  '/vaccination-welcome',
                  arguments: {'childId': widget.childId},
                );
              }
              // Other dashboard items can be wired here
            },
      child: Opacity(
        opacity: item.isLocked ? 0.5 : 1.0,
        child: Container(
          height: 114,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: item.iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Label
              Text(
                item.title,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO BOTTOM SHEET (Change / Delete)
  // ============================================================
  void _showPhotoBottomSheet(
      BuildContext context, ChildProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'صورة الطفل',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'الكاميرا',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadImage(ImageSource.camera, provider);
                    },
                  ),
                  // Gallery
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'المعرض',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUploadImage(ImageSource.gallery, provider);
                    },
                  ),
                  // Delete photo
                  if (provider.profileImageUrl != null &&
                      provider.profileImageUrl!.isNotEmpty)
                    _buildImageSourceOption(
                      icon: Icons.delete_outline,
                      label: 'حذف الصورة',
                      color: const Color(0xFFFF0000),
                      onTap: () {
                        Navigator.pop(ctx);
                        // TODO: Call delete child photo API when available
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('حذف صورة الطفل غير متاح حالياً',
                                style: TextStyle(fontFamily: _kFontFamily)),
                            backgroundColor: _kOrange,
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _kPrimaryRed,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(
      ImageSource source, ChildProfileProvider provider) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile == null || !mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: _kPrimaryRed),
        ),
      );

      final bytes = await pickedFile.readAsBytes();
      final (success, message) =
          await provider.uploadChildImage(bytes, pickedFile.name);

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message, style: const TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: success ? const Color(0xFF01A449) : _kPrimaryRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في اختيار الصورة',
              style: TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: _kPrimaryRed,
        ),
      );
    }
  }

  // ============================================================
  // CHILD SELECTOR DROPDOWN
  // ============================================================
  void _showChildSelectorDropdown(
      BuildContext context, ChildProfileProvider provider) {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final children = familyProvider.children;

    if (children.isEmpty) {
      // If children list not loaded yet, try loading
      familyProvider.loadChildren();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل قائمة الأطفال...',
              style: TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: _kOrange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر طفلاً',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...children.map((child) {
                final isSelected = child.childId == widget.childId;
                return ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!isSelected) {
                      // Navigate to this child's profile
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MyChildProfilePage(childId: child.childId),
                        ),
                      );
                    }
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kPrimaryRed.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: _kPrimaryRed, width: 2)
                          : null,
                    ),
                    child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              child.photoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.child_care,
                                    size: 20, color: _kPrimaryRed),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.child_care,
                                size: 20, color: _kPrimaryRed),
                          ),
                  ),
                  title: Text(
                    child.fullName,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _kPrimaryRed : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    child.ageText,
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      color: _kTextGrey,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: _kPrimaryRed, size: 24)
                      : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
