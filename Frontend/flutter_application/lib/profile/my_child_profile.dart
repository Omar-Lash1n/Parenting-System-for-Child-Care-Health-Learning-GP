// --- lib/profile/my_child_profile.dart ---
// Child Profile Screen - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/child_profile_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';

// --- CONSTANTS ---
const Color _kPrimaryRed = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kTextDark = Color(0xFF111517);
const Color _kTextGrey = Color(0xFF647887);
const Color _kBorderLight = Color(0xFFF3F4F6);
const Color _kCardBorder = Color(0xFFF1F5F9);
const String _kFontFamily = 'IBM Plex Sans Arabic';

class MyChildProfilePage extends StatelessWidget {
  const MyChildProfilePage({super.key});

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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(context, provider),
                          const SizedBox(height: 16),
                          _buildHeroSection(provider),
                          const SizedBox(height: 16),
                          _buildProgressCard(provider),
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
        Container(
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
              // Child avatar circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimaryRed.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.child_care,
                    size: 16,
                    color: _kPrimaryRed,
                  ),
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
      ],
    );
  }

  // ============================================================
  // B. CENTRAL HERO SECTION
  // ============================================================
  Widget _buildHeroSection(ChildProfileProvider provider) {
    return Column(
      children: [
        // --- Large Avatar with decorative frame ---
        SizedBox(
          width: 142,
          height: 142,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer container (for frame overlay later)
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),

              // Inner avatar circle
              Container(
                width: 103.85,
                height: 103.85,
                decoration: BoxDecoration(
                  color: _kPrimaryRed.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: provider.profileImageUrl != null &&
                        provider.profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          provider.profileImageUrl!,
                          width: 103.85,
                          height: 103.85,
                          fit: BoxFit.cover,
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
      ],
    );
  }

  // ============================================================
  // C. PROGRESS CARD
  // ============================================================
  Widget _buildProgressCard(ChildProfileProvider provider) {
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
                  // TODO: Navigate to fill data
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
        _buildDashboardRow(context, items[1], items[0]),
        const SizedBox(height: 12),
        // Row 2: المكافآت (left) | المهام (right)
        _buildDashboardRow(context, items[3], items[2]),
        const SizedBox(height: 12),
        // Row 3: سجل النمو (left) | السجل الطبي (right)
        _buildDashboardRow(context, items[5], items[4]),
      ],
    );
  }

  Widget _buildDashboardRow(
      BuildContext context, DashboardItem left, DashboardItem right) {
    return Row(
      children: [
        Expanded(child: _buildDashboardCard(context, left)),
        const SizedBox(width: 12),
        Expanded(child: _buildDashboardCard(context, right)),
      ],
    );
  }

  // Route mapping for dashboard cards
  static const Map<String, String> _dashboardRoutes = {
    'بيانات الطفل': '/child-data',
  };

  Widget _buildDashboardCard(BuildContext context, DashboardItem item) {
    return GestureDetector(
      onTap: item.isLocked
          ? null
          : () {
              final route = _dashboardRoutes[item.title];
              if (route != null) {
                Navigator.pushNamed(context, route);
              }
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
}
