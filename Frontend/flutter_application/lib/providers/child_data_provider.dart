// --- lib/providers/child_data_provider.dart ---
// Child Data Provider - State & Strings for Child Data Profile Screen

import 'package:flutter/material.dart';

/// All Arabic strings centralized for future localization
class ChildDataStrings {
  // Header
  static String headerTitle(String name) => 'بيانات $name';

  // Progress Card
  static String progressTitle(String name) => 'إتمام ملف $name';
  static const String fillDataButton = 'ملئ البيانات';
  static String vaccinationStatus(int completed, int total) =>
      'تم اتمام $completed من $total تطعيمات أساسية للعام الأول';

  // Personal Profile Section
  static const String personalProfileHeader = 'الملف الشخصي';
  static const String viewAll = 'عرض الكل';
  static const String nameLabel = 'الاسم';
  static const String ageLabel = 'العمر';
  static const String genderLabel = 'الجنس';

  // Medical Profile Section
  static const String medicalProfileHeader = 'الملف الطبي';
  static const String heightLabel = 'الطول';
  static const String weightLabel = 'الوزن';
  static const String headCircumferenceLabel = 'محيط الرأس';
  static const String bloodTypeLabel = 'فصيلة الدم';
  static const String medicalHistoryLabel = 'التاريخ الطبي';

  // Account Section
  static String accountHeader(String name) => 'حساب $name';
  static String accountNotOldEnough(String name) =>
      'يبدو ان $name لم يتم 4 اعوام';
  static String accountDescription(String name) =>
      'قريباً! باذن الله عندما يبلغ $name ٤ اعوام، سيكون له واجهة خاصة مليئة بالألعاب والمهام المحفزة.';
  static const String createAccountButton = 'انشاء حساب';

  // Danger Zone
  static const String dangerZoneTitle = 'منطقة خطر';
  static const String dangerZoneSubtitle = 'إجراء لا يمكن التراجع عنه';
  static const String dangerZoneDescription =
      'يرجى الحذر، إن حذف الطفل سيؤدي إلى مسح جميع البيانات السريرية وسجل التطعيمات الخاص به نهائياً ولا يمكن استعادتها مرة أخرى.';
  static String deleteChildButton(String name) => 'حذف ملف $name';
}

/// Model for a single profile info row
class ProfileInfoItem {
  final String label;
  final String? value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const ProfileInfoItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.value,
  });
}

class ChildDataProvider extends ChangeNotifier {
  // --- State ---
  String _childName = 'ابراهيم';
  double _profileCompletionPercent = 0.25;
  int _completedVaccinations = 2;
  int _totalVaccinations = 8;

  // Personal profile data
  String _name = 'ابراهيم';
  String _age = '25 يوم';
  String _gender = 'ذكر';

  // Medical profile data
  String _height = '';
  String _weight = '';
  String _headCircumference = '';
  String _bloodType = '';
  String _medicalHistory = '';

  // --- Getters ---
  String get childName => _childName;
  double get profileCompletionPercent => _profileCompletionPercent;
  int get completedVaccinations => _completedVaccinations;
  int get totalVaccinations => _totalVaccinations;

  String get completionPercentText =>
      '${(_profileCompletionPercent * 100).toInt()}%';

  String get vaccinationStatusText => ChildDataStrings.vaccinationStatus(
      _completedVaccinations, _totalVaccinations);

  // --- Personal Profile Items ---
  List<ProfileInfoItem> get personalItems => [
        ProfileInfoItem(
          label: _name.isNotEmpty ? _name : ChildDataStrings.nameLabel,
          icon: Icons.person_outline,
          iconColor: const Color(0xFFBF092F),
          iconBgColor: const Color(0x1ABF092F),
        ),
        ProfileInfoItem(
          label: _age.isNotEmpty ? _age : ChildDataStrings.ageLabel,
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF008CFF),
          iconBgColor: const Color(0x1A008CFF),
        ),
        ProfileInfoItem(
          label: _gender.isNotEmpty ? _gender : ChildDataStrings.genderLabel,
          icon: Icons.child_care,
          iconColor: const Color(0xFFFE8401),
          iconBgColor: const Color(0x1AFE8401),
        ),
      ];

  // --- Medical Profile Items ---
  List<ProfileInfoItem> get medicalItems => [
        ProfileInfoItem(
          label: _height.isNotEmpty ? _height : ChildDataStrings.heightLabel,
          icon: Icons.height,
          iconColor: const Color(0xFFBF092F),
          iconBgColor: const Color(0x1ABF092F),
        ),
        ProfileInfoItem(
          label: _weight.isNotEmpty ? _weight : ChildDataStrings.weightLabel,
          icon: Icons.monitor_weight_outlined,
          iconColor: const Color(0xFF01A449),
          iconBgColor: const Color(0x1A01A449),
        ),
        ProfileInfoItem(
          label: _headCircumference.isNotEmpty
              ? _headCircumference
              : ChildDataStrings.headCircumferenceLabel,
          icon: Icons.circle_outlined,
          iconColor: const Color(0xFF008CFF),
          iconBgColor: const Color(0x1A008CFF),
        ),
        ProfileInfoItem(
          label: _bloodType.isNotEmpty
              ? _bloodType
              : ChildDataStrings.bloodTypeLabel,
          icon: Icons.bloodtype_outlined,
          iconColor: const Color(0xFFFF0000),
          iconBgColor: const Color(0x0DFF0000),
        ),
        ProfileInfoItem(
          label: _medicalHistory.isNotEmpty
              ? _medicalHistory
              : ChildDataStrings.medicalHistoryLabel,
          icon: Icons.monitor_heart_outlined,
          iconColor: const Color(0xFFFE8401),
          iconBgColor: const Color(0x1AFE8401),
        ),
      ];
}
