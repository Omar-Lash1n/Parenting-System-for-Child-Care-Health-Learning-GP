// --- lib/profile/child_data_profile.dart ---
// Child Data Profile Screen - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/providers/confirm_delete_provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/family/models/child_model.dart';
import 'package:Ajial/profile/child_data_profile_form.dart';
import 'package:Ajial/profile/change_child_password.dart';
import 'package:Ajial/profile/making_child_account.dart';
import 'package:Ajial/profile/my_child_profile.dart';
import 'package:Ajial/profile/confirm_delete_child.dart';
import 'package:Ajial/providers/child_profile_provider.dart';

// --- CONSTANTS ---
const Color _kPrimaryRed = Color(0xFFBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kTextDark = Color(0xFF111517);
const Color _kTextGrey = Color(0xFF647887);
const Color _kBorderLight = Color(0xFFF3F4F6);
const Color _kDangerRed = Color(0xFFFF0000);
const Color _kSectionBg = Color(0xFFF5F5F5);
const String _kFontFamily = 'IBM Plex Sans Arabic';

class ChildDataProfilePage extends StatefulWidget {
  final String? childId;
  const ChildDataProfilePage({super.key, this.childId});

  @override
  State<ChildDataProfilePage> createState() => _ChildDataProfilePageState();
}

class _ChildDataProfilePageState extends State<ChildDataProfilePage> {
  @override
  void initState() {
    super.initState();
    if (widget.childId != null && widget.childId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChildDataProvider>().fetchFileData(widget.childId!);
      });
    }
  }

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
                                    const SizedBox(height: 24),
                                    _buildProgressCard(context, provider),
                                    const SizedBox(height: 24),
                                    _buildPersonalSection(context, provider),
                                    const SizedBox(height: 24),
                                    _buildMedicalSection(context, provider),
                                    const SizedBox(height: 24),
                                    _buildAccountSection(context, provider),
                                    const SizedBox(height: 24),
                                    // Rewards section (only when account exists)
                                    if (provider.isOlderChild &&
                                        provider.isAccountCreated)
                                      _buildRewardsSection(provider),
                                    if (provider.isOlderChild &&
                                        provider.isAccountCreated)
                                      const SizedBox(height: 24),
                                    // Account settings (show for all >=4 children)
                                    if (provider.isOlderChild)
                                      _buildAccountSettingsSection(
                                          context, provider),
                                    if (provider.isOlderChild)
                                      const SizedBox(height: 24),
                                    _buildDangerZone(context, provider),
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
  // ERROR / RETRY STATE
  // ============================================================
  Widget _buildErrorState(ChildDataProvider provider) {
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
                provider.fetchFileData(widget.childId!);
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
        GestureDetector(
          onTap: () => _showChildSelectorDropdown(context, provider),
          child: Container(
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
                  child: Stack(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kPrimaryRed.withOpacity(0.15),
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
                      // Green online dot
                      if (provider.isAccountActive)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF01A449),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
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
        ),
      ],
    );
  }

  // ============================================================
  // B. PROGRESS CARD (LTR wrapper for progress bar direction)
  // ============================================================
  Widget _buildProgressCard(BuildContext context, ChildDataProvider provider) {
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
  Widget _buildSectionHeader(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ChildDataProfileFormPage(),
          ),
        );
      },
      child: Container(
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
            // SECOND in RTL → LEFT: "Edit All" + arrow (flipped)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ChildDataStrings.editAll,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 24, color: Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // D. PROFILE INFO ROW (reusable)
  // RTL context: first child → RIGHT, second child → LEFT
  // ============================================================
  Widget _buildProfileInfoRow(ProfileInfoItem item, VoidCallback onEdit) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FIRST in RTL → RIGHT: Icon circle + Label + Value
          Expanded(
            child: Row(
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: item.value != null ? 12 : 14,
                          fontWeight: item.value != null
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: item.value != null
                              ? Colors.black.withOpacity(0.5)
                              : Colors.black,
                        ),
                      ),
                      if (item.value != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.value!,
                          style: const TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // SECOND in RTL → LEFT: Edit icon → bottom sheet
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: GestureDetector(
              onTap: onEdit,
              child: const Icon(Icons.edit_outlined,
                  size: 24, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // E. PERSONAL PROFILE SECTION
  // ============================================================
  Widget _buildPersonalSection(
      BuildContext context, ChildDataProvider provider) {
    final items = provider.personalItems;
    final editActions = [
      () => _showTextEditSheet(
              context, ChildDataStrings.nameLabel, provider.name, (v) async {
            provider.setName(v);
            _syncToProfile(context, provider);
            final (success, msg) =
                await provider.submitUpdates({'fullName': v});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg,
                      style: const TextStyle(fontFamily: _kFontFamily)),
                  backgroundColor:
                      success ? const Color(0xFF01A449) : _kDangerRed,
                ),
              );
            }
          }),
      () => _showDobWarningPopup(context, provider),
      () => _showGenderEditSheet(context, provider),
    ];
    return Column(
      children: [
        _buildSectionHeader(context, ChildDataStrings.personalProfileHeader),
        const SizedBox(height: 12),
        ...List.generate(items.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildProfileInfoRow(items[i], editActions[i]),
          );
        }),
      ],
    );
  }

  /// Push name, age, account state from ChildDataProvider → ChildProfileProvider
  void _syncToProfile(BuildContext context, ChildDataProvider p) {
    final profileProv =
        Provider.of<ChildProfileProvider>(context, listen: false);
    profileProv.setChildData(
      name: p.name.isNotEmpty ? p.name : p.childName,
      age: p.age,
    );
    profileProv.setAgeInYears(p.childAgeInYears);
    profileProv.setAccountCreated(p.isAccountCreated);
  }

  // ============================================================
  // F. MEDICAL PROFILE SECTION
  // ============================================================
  Widget _buildMedicalSection(
      BuildContext context, ChildDataProvider provider) {
    final items = provider.medicalItems;
    final editActions = [
      () => _showMeasurementEditSheet(
              context,
              ChildDataStrings.heightLabel,
              ChildDataStrings.formHeightHint,
              ChildDataStrings.formUnitCm,
              provider.heightVal, (v) async {
            provider.setHeight(v);
            final (success, msg) = await provider
                .submitUpdates({'height': double.tryParse(v) ?? 0.0});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(msg, style: const TextStyle(fontFamily: _kFontFamily)),
                backgroundColor:
                    success ? const Color(0xFF01A449) : _kDangerRed,
              ));
            }
          }),
      () => _showMeasurementEditSheet(
              context,
              ChildDataStrings.weightLabel,
              ChildDataStrings.formWeightHint,
              ChildDataStrings.formUnitKg,
              provider.weightVal, (v) async {
            provider.setWeight(v);
            final (success, msg) = await provider
                .submitUpdates({'weight': double.tryParse(v) ?? 0.0});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(msg, style: const TextStyle(fontFamily: _kFontFamily)),
                backgroundColor:
                    success ? const Color(0xFF01A449) : _kDangerRed,
              ));
            }
          }),
      () => _showMeasurementEditSheet(
              context,
              ChildDataStrings.headCircumferenceLabel,
              ChildDataStrings.formHeadCircHint,
              ChildDataStrings.formUnitCm,
              provider.headCircumference, (v) async {
            provider.setHeadCircumference(v);
            final (success, msg) = await provider.submitUpdates(
                {'headCircumference': double.tryParse(v) ?? 0.0});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(msg, style: const TextStyle(fontFamily: _kFontFamily)),
                backgroundColor:
                    success ? const Color(0xFF01A449) : _kDangerRed,
              ));
            }
          }),
      () => _showBloodTypeRadioPopup(context, provider),
      () => _showTextEditSheet(
              context, ChildDataStrings.medicalHistoryLabel, '', (v) async {
            final (success, msg) =
                await provider.submitUpdates({'medicalHistory': v});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(msg, style: const TextStyle(fontFamily: _kFontFamily)),
                backgroundColor:
                    success ? const Color(0xFF01A449) : _kDangerRed,
              ));
            }
          }),
    ];
    return Column(
      children: [
        _buildSectionHeader(context, ChildDataStrings.medicalProfileHeader),
        const SizedBox(height: 12),
        ...List.generate(items.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildProfileInfoRow(items[i], editActions[i]),
          );
        }),
      ],
    );
  }

  // ============================================================
  // G. ACCOUNT SECTION
  // ============================================================
  Widget _buildAccountSection(
      BuildContext context, ChildDataProvider provider) {
    // If account exists, show active status
    if (provider.isOlderChild && provider.isAccountCreated) {
      return Column(
        children: [
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
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF01A449),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isAccountActive ? 'الحساب مفعل' : 'الحساب معطل',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: provider.isAccountActive
                        ? const Color(0xFF01A449)
                        : _kDangerRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Original: not old enough OR old enough but no account yet
    if (provider.isOlderChild && !provider.isAccountCreated) {
      // Age >= 4 but no account → show "create account" card
      return Column(
        children: [
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ChildDataStrings.accountCardTitle(provider.childName),
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
                  ChildDataStrings.accountCardDescription(provider.childName),
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
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const MakingChildAccountPage(),
                      ),
                    );
                    if (result == true) {
                      _syncToProfile(context, provider);
                    }
                  },
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

    // Not old enough (< 4 years)
    return Column(
      children: [
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
            crossAxisAlignment: CrossAxisAlignment.end,
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
  // G2. REWARDS SECTION (Stars, Badges)
  // ============================================================
  Widget _buildRewardsSection(ChildDataProvider provider) {
    return Column(
      children: [
        // Rewards header (inline, no "edit all" button)
        Container(
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
              Text(
                ChildDataStrings.rewardsHeader,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                ChildDataStrings.editAll,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
          child: Row(
            children: [
              // Stars
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE8401).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFFE8401).withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          size: 28, color: Color(0xFFFE8401)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.starsCount}',
                            style: const TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            ChildDataStrings.starsUnit,
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Badges
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01A449).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF01A449).withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium,
                          size: 28, color: Color(0xFF01A449)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.badgesCount}',
                            style: const TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            ChildDataStrings.badgesUnit,
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
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
  // G3. ACCOUNT SETTINGS SECTION (Edit ID, Change Password, Deactivate)
  // ============================================================
  Widget _buildAccountSettingsSection(
      BuildContext context, ChildDataProvider provider) {
    return Column(
      children: [
        // Section header
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
              ChildDataStrings.accountSettingsHeader(provider.childName),
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

        // Settings rows
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
            children: [
              // Edit Child Code
              _buildSettingsRow(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF008CFF),
                iconBgColor: const Color(0xFF008CFF).withOpacity(0.1),
                label: ChildDataStrings.childCodeLabel,
                value: provider.childCode,
                onEdit: () {
                  final ctrl = TextEditingController(text: provider.childCode);
                  _showEditBottomSheet(
                    context,
                    title: ChildDataStrings.childCodeLabel,
                    content: Column(
                      children: [
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.black.withOpacity(0.25)),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: TextField(
                            controller: ctrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(
                                fontFamily: _kFontFamily, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'أدخل 4 أرقام',
                              counterText: '',
                              hintStyle: TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSheetSaveButton(context, () {
                          if (ctrl.text.length != 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يجب أن يتكون الكود من 4 أرقام',
                                    style: TextStyle(fontFamily: _kFontFamily)),
                              ),
                            );
                            return;
                          }
                          provider.setChildCode(ctrl.text);
                          Navigator.of(context).pop();
                        }),
                      ],
                    ),
                  );
                },
              ),
              Divider(color: Colors.black.withOpacity(0.05), height: 1),

              // Change Password
              _buildSettingsRow(
                icon: Icons.vpn_key,
                iconColor: const Color(0xFF01A449),
                iconBgColor: const Color(0xFF01A449).withOpacity(0.1),
                label: ChildDataStrings.changePasswordLabel,
                value: '•••••',
                onEdit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangeChildPasswordPage(),
                    ),
                  );
                },
              ),
              Divider(color: Colors.black.withOpacity(0.05), height: 1),

              // Deactivate / Reactivate Account
              _buildSettingsRow(
                icon: provider.isAccountActive
                    ? Icons.block
                    : Icons.check_circle_outline,
                iconColor: provider.isAccountActive
                    ? _kDangerRed
                    : const Color(0xFF01A449),
                iconBgColor: provider.isAccountActive
                    ? _kDangerRed.withOpacity(0.1)
                    : const Color(0xFF01A449).withOpacity(0.1),
                label: provider.isAccountActive
                    ? ChildDataStrings.deactivateAccountLabel
                    : 'اعادة تفعيل الحساب',
                value: '',
                isDestructive: provider.isAccountActive,
                onEdit: () => _showDeactivateConfirmPopup(context, provider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required VoidCallback onEdit,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, size: 18, color: iconColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDestructive ? _kDangerRed : Colors.black,
              ),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Icon(
              isDestructive ? Icons.arrow_forward_ios : Icons.edit,
              size: 16,
              color: isDestructive ? _kDangerRed : _kOrange,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // H. DANGER ZONE
  // RTL context: first child → RIGHT
  // ============================================================
  Widget _buildDangerZone(BuildContext context, ChildDataProvider provider) {
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
          // Delete button — opens confirmation popup
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  _showDeleteConfirmPopup(context, provider.childName),
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

  // ============================================================
  // POPUP: Delete confirmation
  // ============================================================
  void _showDeleteConfirmPopup(BuildContext context, String childName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 318,
              height: 301,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // ── X close button (top-RIGHT) ──────────────
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ),

                  // ── Red exclamation icon ───────────────────────────
                  Positioned(
                    top: 39,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0035).withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.priority_high_rounded,
                            size: 39,
                            color: Color(0xFFFF0035),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Title + Subtitle ───────────────────────────────
                  Positioned(
                    top: 122,
                    left: 15,
                    right: 15,
                    child: Column(
                      children: [
                        Text(
                          ConfirmDeleteStrings.popupTitle
                              .replaceAll('انس', childName),
                          style: const TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ConfirmDeleteStrings.popupSubtitle,
                          style: const TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // ── Buttons row ────────────────────────────────────
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Row(
                      children: [
                        // LEFT (second in RTL) — outline Cancel
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.black.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                'رجوع',
                                style: TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // RIGHT (first in RTL) — red OK → navigate
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop(); // close popup
                                // Navigate to confirm delete page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ConfirmDeleteChildPage(
                                      childId: widget.childId ?? '',
                                      childName: childName,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF0035),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'استمرار',
                                style: TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 18,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOB WARNING POPUP (Figma CSS)
  // ============================================================
  void _showDobWarningPopup(BuildContext context, ChildDataProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 318,
              height: 301,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Close button (top-left visual in RTL)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child:
                              Icon(Icons.close, size: 20, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    children: [
                      const SizedBox(height: 39),
                      // Red exclamation circle
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 39,
                            color: Color(0xFFFF0000),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      const Text(
                        'احذر سيتم تهيئة ملف الطفل',
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'لتغيير عمر الطفل سيتطلب مسح جميع\nبيانات الطفل و لايمكن استعادتها مرة اخرى',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      // Buttons row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // رجوع button (outlined)
                            GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                width: 131,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Center(
                                  child: Text(
                                    'رجوع',
                                    style: TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // استمرار button (red)
                            GestureDetector(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChildDataProfileFormPage(
                                            prefill: true),
                                  ),
                                );
                              },
                              child: Container(
                                width: 131,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Center(
                                  child: Text(
                                    'استمرار',
                                    style: TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DEACTIVATE ACCOUNT CONFIRMATION POPUP (Figma CSS)
  // ============================================================
  void _showDeactivateConfirmPopup(
      BuildContext context, ChildDataProvider provider) {
    final bool isActive = provider.isAccountActive;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 318,
              height: 301,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child:
                              Icon(Icons.close, size: 20, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    children: [
                      const SizedBox(height: 39),
                      // Red exclamation circle
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0035).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 39,
                            color: Color(0xFFFF0035),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        isActive ? 'تعطيل الحساب' : 'اعادة تفعيل الحساب',
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          isActive
                              ? 'هل أنت متأكد من تعطيل حساب الطفل؟\nلن يتمكن الطفل من تسجيل الدخول'
                              : 'هل تريد اعادة تفعيل حساب الطفل؟\nسيتمكن الطفل من تسجيل الدخول مرة اخرى',
                          style: const TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Spacer(),
                      // Buttons row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // رجوع button (outlined)
                            GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                width: 131,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Center(
                                  child: Text(
                                    'رجوع',
                                    style: TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // تأكيد button (red)
                            GestureDetector(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                if (isActive) {
                                  provider.deactivateAccount();
                                } else {
                                  provider.activateAccount();
                                }
                                _syncToProfile(context, provider);
                              },
                              child: Container(
                                width: 131,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: Text(
                                    isActive ? 'تعطيل' : 'تفعيل',
                                    style: const TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 18,
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BLOOD TYPE RADIO POPUP (Figma CSS)
  // ============================================================
  void _showBloodTypeRadioPopup(
      BuildContext context, ChildDataProvider provider) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String? selected =
        provider.bloodType.isNotEmpty ? provider.bloodType : null;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (_, setDialogState) => Container(
                width: 343,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ...bloodTypes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final type = entry.value;
                      final isSelected = selected == type;
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setDialogState(() => selected = type);
                              // Auto-save and close after picking
                              Future.delayed(const Duration(milliseconds: 200),
                                  () {
                                provider.setBloodType(type);
                                Navigator.of(ctx).pop();
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  // Radio circle
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? _kPrimaryRed
                                            : const Color(0xFFD9D9D9),
                                        width: isSelected ? 1 : 1.25,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: _kPrimaryRed,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (idx < bloodTypes.length - 1)
                            Divider(
                              color: Colors.black.withOpacity(0.05),
                              height: 8,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET HELPERS (Figma CSS: 34px top radius, white, shadow)
  // ============================================================

  void _showEditBottomSheet(BuildContext context,
      {required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + X button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.close, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              content,
            ],
          ),
        ),
      ),
    );
  }

  // ── Text field bottom sheet (Name, History) ─────────────────
  void _showTextEditSheet(BuildContext context, String title,
      String initialValue, void Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    _showEditBottomSheet(
      context,
      title: title,
      content: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
              decoration: InputDecoration(
                hintText: title,
                hintStyle: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSheetSaveButton(context, () {
            onSave(controller.text);
            Navigator.of(context).pop();
          }),
        ],
      ),
    );
  }

  // ── Measurement field bottom sheet (Height, Weight, Head Circ) ───
  void _showMeasurementEditSheet(
    BuildContext context,
    String title,
    String hint,
    String unit,
    String initialValue,
    void Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    _showEditBottomSheet(
      context,
      title: title,
      content: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style:
                        const TextStyle(fontFamily: _kFontFamily, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.5,
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSheetSaveButton(context, () {
            onSave(controller.text);
            Navigator.of(context).pop();
          }),
        ],
      ),
    );
  }

  // ── DOB bottom sheet (Day + Month dropdown + Year) ──────────
  void _showDobEditSheet(BuildContext context, ChildDataProvider provider) {
    final dayC = TextEditingController(text: provider.dobDay);
    final yearC = TextEditingController(text: provider.dobYear);
    String? selectedMonth =
        provider.dobMonth.isNotEmpty ? provider.dobMonth : null;

    _showEditBottomSheet(
      context,
      title: ChildDataStrings.formDobLabel.replaceAll('*', '').trim(),
      content: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            Row(
              children: [
                // Day
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextField(
                      controller: dayC,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontFamily: _kFontFamily, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: ChildDataStrings.formDobDay,
                        hintStyle: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                // Month dropdown
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down,
                            size: 20, color: Colors.black.withOpacity(0.5)),
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        hint: Text(
                          ChildDataStrings.formDobMonth,
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        items: ChildDataProvider.monthNames.map((m) {
                          return DropdownMenuItem(
                              value: m, child: Center(child: Text(m)));
                        }).toList(),
                        onChanged: (v) =>
                            setSheetState(() => selectedMonth = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                // Year
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextField(
                      controller: yearC,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontFamily: _kFontFamily, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: ChildDataStrings.formDobYear,
                        hintStyle: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSheetSaveButton(context, () {
              provider.setDob(dayC.text, selectedMonth ?? '', yearC.text);
              _syncToProfile(context, provider);
              Navigator.of(context).pop();
            }),
          ],
        ),
      ),
    );
  }

  // ── Gender toggle bottom sheet ──────────────────────────────
  void _showGenderEditSheet(BuildContext context, ChildDataProvider provider) {
    int selected = provider.selectedGenderIndex;
    _showEditBottomSheet(
      context,
      title: ChildDataStrings.formGenderLabel.replaceAll('*', '').trim(),
      content: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            Row(
              children: [
                _buildGenderSheetBtn(ChildDataStrings.formGenderMale, 0,
                    selected, (i) => setSheetState(() => selected = i)),
                const SizedBox(width: 11),
                _buildGenderSheetBtn(ChildDataStrings.formGenderFemale, 1,
                    selected, (i) => setSheetState(() => selected = i)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSheetSaveButton(context, () async {
              provider.setGender(selected);
              Navigator.of(context).pop();
              final String genderStr = selected == 0 ? 'ذكر' : 'أنثى';
              final (success, msg) =
                  await provider.submitUpdates({'gender': genderStr});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(msg,
                      style: const TextStyle(fontFamily: _kFontFamily)),
                  backgroundColor:
                      success ? const Color(0xFF01A449) : _kDangerRed,
                ));
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSheetBtn(
      String label, int index, int selected, void Function(int) onTap) {
    final isSelected = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD90000).withOpacity(0.05)
                : Colors.white,
            border: Border.all(
              color: isSelected ? _kPrimaryRed : Colors.black.withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color:
                    isSelected ? Colors.black : Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Blood type dropdown bottom sheet ────────────────────────
  void _showBloodTypeEditSheet(
      BuildContext context, ChildDataProvider provider) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String? selected =
        provider.bloodType.isNotEmpty ? provider.bloodType : null;

    _showEditBottomSheet(
      context,
      title: ChildDataStrings.bloodTypeLabel,
      content: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(50),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      size: 20, color: Colors.black.withOpacity(0.5)),
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  hint: Text(
                    ChildDataStrings.formBloodTypeHint,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  items: bloodTypes.map((t) {
                    return DropdownMenuItem(
                        value: t, child: Center(child: Text(t)));
                  }).toList(),
                  onChanged: (v) => setSheetState(() => selected = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSheetSaveButton(context, () {
              if (selected != null) provider.setBloodType(selected!);
              Navigator.of(context).pop();
            }),
          ],
        ),
      ),
    );
  }

  // ── Reusable red save button for bottom sheets ──────────────
  Widget _buildSheetSaveButton(BuildContext context, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 0,
        ),
        child: Text(
          ChildDataStrings.bottomSheetSave,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHILD SELECTOR DROPDOWN
  // ============================================================
  void _showChildSelectorDropdown(
      BuildContext context, ChildDataProvider provider) {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final children = familyProvider.children;

    if (children.isEmpty) {
      familyProvider.loadChildren();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل قائمة الأطفال...',
              style: TextStyle(fontFamily: _kFontFamily)),
          backgroundColor: Color(0xFFFE8401),
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
                      // Navigate to this child's data page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChildDataProfilePage(childId: child.childId),
                        ),
                      );
                    }
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF092F).withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: const Color(0xFFBF092F), width: 2)
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
                                    size: 20, color: Color(0xFFBF092F)),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.child_care,
                                size: 20, color: Color(0xFFBF092F)),
                          ),
                  ),
                  title: Text(
                    child.fullName,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? const Color(0xFFBF092F) : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    child.ageText,
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      color: Color(0xFF7C7C7C),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFFBF092F), size: 24)
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
