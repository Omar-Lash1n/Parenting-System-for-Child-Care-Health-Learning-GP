// --- lib/profile/parent_profile.dart ---
// Parent Profile Page - Following Figma CSS Specifications

import 'package:flutter/material.dart';
import 'package:Ajial/profile/profile_dialogs.dart';
import 'package:Ajial/add-child/add-child-flow.dart';

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
  // --- Mock Data ---
  Map<String, dynamic> profileData = {
    'fullName': 'حازم محمد',
    'username': 'hazem225',
    'email': 'hazem225@gmail.com',
    'role': 'ولي أمر',
    'city': 'القاهرة',
    'birthDate': '25 عام',
    'numberOfChildren': 0,
    'badges': 5,
    'points': 25,
    'isEmailVerified': false,
    'profileImageUrl': null,
  };

  List<Map<String, dynamic>> mockChildren = [];

  List<Map<String, dynamic>> mockRewards = [
    {'name': 'اسم الوسام', 'icon': Icons.star, 'color': Colors.amber},
    {'name': 'اسم الوسام', 'icon': Icons.star, 'color': Colors.amber},
    {'name': 'اسم الوسام', 'icon': Icons.star, 'color': Colors.amber},
    {'name': 'اسم الوسام', 'icon': Icons.star, 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
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
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildProfileSection(),
                  const SizedBox(height: 24),
                  if (!profileData['isEmailVerified'])
                    _buildEmailVerificationBanner(),
                  if (!profileData['isEmailVerified'])
                    const SizedBox(height: 34),
                  _buildRewardsSection(),
                  const SizedBox(height: 34),
                  _buildChildrenSection(),
                  const SizedBox(height: 34),
                  _buildPersonalDataSection(),
                  const SizedBox(height: 34),
                  _buildSettingsSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Settings Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.5)),
          ),
          child: const Icon(Icons.settings_outlined, size: 24),
        ),
        // Greeting
        const Text(
          'مرحباً حازم',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Profile Section ---
  Widget _buildProfileSection() {
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
                color: kBlue.withOpacity(0.1),
                border: Border.all(color: const Color(0xFFD9D9D9), width: 1.48),
              ),
              child: Center(
                child: Text(
                  'ح',
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
          ],
        ),
        const SizedBox(height: 4),
        Text(
          profileData['fullName'],
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
            _buildStatCard('نقطة', '25', kPrimaryColor),
            const SizedBox(width: 16),
            _buildStatCard('وسم', '5', kGreen),
            const SizedBox(width: 16),
            _buildStatCard('طفل', '0', const Color(0xFFFEA400)),
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

  // --- Email Verification Banner ---
  Widget _buildEmailVerificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC800).withOpacity(0.25),
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
          ElevatedButton(
            onPressed: () {
              ProfileDialogs.showEmailVerificationDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            child: const Text(
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

  // --- Rewards Section ---
  Widget _buildRewardsSection() {
    return Column(
      children: [
        _buildSectionHeader('المكافئات', true),
        const SizedBox(height: 14),
        SizedBox(
          height: 99,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: mockRewards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final reward = mockRewards[index];
              return Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: (reward['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      reward['icon'] as IconData,
                      color: reward['color'] as Color,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward['name'],
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Children Section ---
  Widget _buildChildrenSection() {
    return Column(
      children: [
        _buildSectionHeader('الاطفال', true),
        const SizedBox(height: 14),
        SizedBox(
          height: 99,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
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
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child:
                            const Icon(Icons.sentiment_satisfied_alt, size: 22),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'اضف طفل',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
  Widget _buildPersonalDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('البيانات الشخصية', false),
        const SizedBox(height: 14),
        Column(
          children: [
            _buildDataRow(
              'حازم محمد',
              kPrimaryColor,
              Icons.person_outline,
              () => ProfileDialogs.showEditNameDialog(
                context,
                profileData['fullName'],
                (newValue) =>
                    setState(() => profileData['fullName'] = newValue),
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              'hazem225',
              kGreen,
              Icons.check_circle_outline,
              () => ProfileDialogs.showEditUsernameDialog(
                context,
                profileData['username'],
                (newValue) =>
                    setState(() => profileData['username'] = newValue),
              ),
            ),
            const SizedBox(height: 12),
            _buildEmailRow(),
            const SizedBox(height: 12),
            _buildDataRow(
              'كلمة المرور',
              kGreen,
              Icons.vpn_key_outlined,
              () => ProfileDialogs.showChangePasswordDialog(context),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              'اب',
              kBlue,
              Icons.people_outline,
              () => ProfileDialogs.showEditRoleDialog(
                context,
                profileData['role'],
                (newValue) => setState(() => profileData['role'] = newValue),
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              'القاهرة',
              kRedDelete,
              Icons.location_on_outlined,
              () => ProfileDialogs.showEditCityDialog(
                context,
                profileData['city'],
                (newValue) => setState(() => profileData['city'] = newValue),
              ),
            ),
            const SizedBox(height: 12),
            _buildDataRow(
              '25 عام',
              kBlue,
              Icons.calendar_month_outlined,
              () => ProfileDialogs.showEditBirthdayDialog(
                context,
                profileData['birthDate'],
                (newValue) =>
                    setState(() => profileData['birthDate'] = newValue),
              ),
            ),
          ],
        ),
      ],
    );
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

  Widget _buildEmailRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => ProfileDialogs.showChangeEmailDialog(
            context,
            profileData['email'],
            (newValue) => setState(() => profileData['email'] = newValue),
          ),
          child: const Icon(Icons.edit_outlined, size: 24),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            const SizedBox(width: 4),
            const Text(
              'hazem225@gmail.com',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email_outlined, color: kOrange, size: 24),
            ),
          ],
        ),
      ],
    );
  }

  // --- Settings Section ---
  Widget _buildSettingsSection() {
    return _buildSectionHeader('الاعدادات العامة', false);
  }

  // --- Section Header ---
  Widget _buildSectionHeader(String title, bool showViewAll) {
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
            const Row(
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
            )
          else
            const Icon(Icons.arrow_back_ios, size: 12),
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
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Logout Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
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
            onPressed: () {
              ProfileDialogs.showDeleteAccountDialog(context);
            },
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

  // --- Bottom Navigation ---
  Widget _buildBottomNav() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('الملف الشخصى', Icons.person, true),
            _buildNavItem('مجتمع', Icons.people_outline, false),
            _buildNavItem('موارد', Icons.grid_view_rounded, false),
            _buildNavItem('الرئيسية', Icons.home_outlined, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Container(
            width: 74,
            height: 4,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ),
        const SizedBox(height: 8),
        Opacity(
          opacity: isActive ? 1.0 : 0.5,
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? kPrimaryColor : Colors.black,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
