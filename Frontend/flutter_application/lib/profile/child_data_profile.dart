// --- lib/profile/child_data_profile.dart ---
// Child Data Profile Screen - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';

// --- CONSTANTS ---
const Color _kPrimaryRed = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kTextDark = Color(0xFF111517);
const Color _kTextGrey = Color(0xFF647887);
const Color _kBorderLight = Color(0xFFF3F4F6);
const Color _kDangerRed = Color(0xFFFF0000);
const Color _kSectionBg = Color(0xFFF5F5F5);
const String _kFontFamily = 'IBM Plex Sans Arabic';

class ChildDataProfilePage extends StatelessWidget {
  const ChildDataProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildDataProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(context, provider),
                          const SizedBox(height: 24),
                          _buildProgressCard(provider),
                          const SizedBox(height: 24),
                          _buildPersonalSection(provider),
                          const SizedBox(height: 24),
                          _buildMedicalSection(provider),
                          const SizedBox(height: 24),
                          _buildAccountSection(provider),
                          const SizedBox(height: 24),
                          _buildDangerZone(provider),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
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
  Widget _buildHeader(BuildContext context, ChildDataProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // FIRST in RTL → visually RIGHT: Back button + Title
        Row(
          children: [
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
              ChildDataStrings.headerTitle(provider.childName),
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // SECOND in RTL → visually LEFT: Child selector pill
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.black.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimaryRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.child_care, size: 16, color: _kPrimaryRed),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                provider.childName,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // B. PROGRESS CARD (LTR wrapper for progress bar direction)
  // ============================================================
  Widget _buildProgressCard(ChildDataProvider provider) {
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
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.completionPercentText,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  ChildDataStrings.progressTitle(provider.childName),
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
            SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _kOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
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
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _kOrange,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  ChildDataStrings.fillDataButton,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
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
      ),
    );
  }

  // ============================================================
  // C. SECTION HEADER (reusable)
  // RTL context: first child → RIGHT, second child → LEFT
  // ============================================================
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kSectionBg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FIRST in RTL → RIGHT: Section title
          Text(
            title,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          // SECOND in RTL → LEFT: "View All" + arrow
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ChildDataStrings.viewAll,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.chevron_left, size: 24, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // D. PROFILE INFO ROW (reusable)
  // RTL context: first child → RIGHT, second child → LEFT
  // ============================================================
  Widget _buildProfileInfoRow(ProfileInfoItem item) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FIRST in RTL → RIGHT: Icon circle + Label
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(item.icon, size: 24, color: item.iconColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          // SECOND in RTL → LEFT: Edit icon
          const Icon(Icons.edit_outlined, size: 24, color: Colors.black),
        ],
      ),
    );
  }

  // ============================================================
  // E. PERSONAL PROFILE SECTION
  // ============================================================
  Widget _buildPersonalSection(ChildDataProvider provider) {
    final items = provider.personalItems;
    return Column(
      children: [
        _buildSectionHeader(ChildDataStrings.personalProfileHeader),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildProfileInfoRow(item),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // F. MEDICAL PROFILE SECTION
  // ============================================================
  Widget _buildMedicalSection(ChildDataProvider provider) {
    final items = provider.medicalItems;
    return Column(
      children: [
        _buildSectionHeader(ChildDataStrings.medicalProfileHeader),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildProfileInfoRow(item),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // G. ACCOUNT SECTION
  // ============================================================
  Widget _buildAccountSection(ChildDataProvider provider) {
    return Column(
      children: [
        // Header (right-aligned title, no "view all")
        Container(
          width: double.infinity,
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _kSectionBg,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              ChildDataStrings.accountHeader(provider.childName),
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Card
        Container(
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
          child: Column(
            // start = RIGHT in RTL
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ChildDataStrings.accountNotOldEnough(provider.childName),
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              Text(
                ChildDataStrings.accountDescription(provider.childName),
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _kTextGrey,
                  height: 1.25,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              // Create Account button (dimmed)
              Opacity(
                opacity: 0.5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kPrimaryRed,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    ChildDataStrings.createAccountButton,
                    style: const TextStyle(
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
        ),
      ],
    );
  }

  // ============================================================
  // H. DANGER ZONE
  // RTL context: first child → RIGHT
  // ============================================================
  Widget _buildDangerZone(ChildDataProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimaryRed.withOpacity(0.05),
        border: Border.all(
          color: _kPrimaryRed.withOpacity(0.25),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        // start = RIGHT in RTL
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon RIGHT, title LEFT
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // start = RIGHT in RTL
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // FIRST in RTL → RIGHT: Warning icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFFFE2E2),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0xFFFFE2E2),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 24,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // SECOND in RTL → LEFT of icon: Title + subtitle
              Column(
                // start = RIGHT in RTL
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ChildDataStrings.dangerZoneTitle,
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryRed,
                      height: 1.75,
                    ),
                  ),
                  Text(
                    ChildDataStrings.dangerZoneSubtitle,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.75),
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 23.3),
          // Description
          Opacity(
            opacity: 0.8,
            child: Text(
              ChildDataStrings.dangerZoneDescription,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black.withOpacity(0.75),
                height: 1.64,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 23.3),
          // Delete button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Show confirmation dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDangerRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: Text(
                ChildDataStrings.deleteChildButton(provider.childName),
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 18,
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
}
