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
  static const String editAll = 'تعديل الكل';
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

  // Rewards Section
  static const String rewardsHeader = 'المكافئات';
  static const String viewAll = 'عرض الكل';
  static const String starsUnit = 'نجمة';
  static const String badgesUnit = 'وسام';

  // Account Settings Section
  static String accountSettingsHeader(String name) => 'حساب $name';
  static const String childCodeLabel = 'كود الطفل';
  static const String changePasswordLabel = 'كلمة المرور';
  static const String deactivateAccountLabel = 'تعطيل الحساب';

  // Making Child Account Screen
  static const String makingAccountTitle = 'انشاء حساب للطفل';
  static const String makingAccountSubtitle =
      'يمكنكم وضع كود للطفل وكلمة مرور يمكن من خلالهم الطفل استخدام حسابه الخاص';
  static const String childCodeFieldLabel = 'كود الطفل*';
  static const String childCodeHint = 'اسم المستخدم';
  static const String fruitPasswordLabel = 'كلمة المرور*';
  static const String skipButton = 'تخطى';

  // Change Password Screen
  static String changePasswordTitle(String name) => 'تغيير كلمة مرور $name';
  static const String oldPasswordLabel = 'كلمة المرور القديمة*';
  static const String newPasswordLabel = 'كلمة المرور الجديدة*';
  static const String confirmPasswordLabel = 'تاكيد كلمة المرور الجديدة*';
  static const String changePasswordButton = 'تغيير كلمة المرور';

  // My Child Profile 4+ account card
  static String accountCardTitle(String name) =>
      'يبدو ان $name اتم 4 اعوام بحمدالله';
  static String accountCardDescription(String name) =>
      'يمكنكم انشاء حساب ل$name حيث يكون له واجهته الخاصة المليئة بالمهام والالعاب التعليمية المرحة';

  // ── Form Screen Strings ─────────────────────────
  static const String formNameLabel = 'الاسم*';
  static const String formNameHint = 'اسم المستخدم';
  static const String formDobLabel = 'تاريخ الميلاد*';
  static const String formDobYear = 'عام';
  static const String formDobMonth = 'شهر';
  static const String formDobDay = 'يوم';
  static const String formGenderLabel = 'النوع*';
  static const String formGenderMale = 'ذكر';
  static const String formGenderFemale = 'أنثى';
  static const String formHeightLabel = 'الطول (اختيارى)';
  static const String formHeightHint = 'اكتب وزن الطفل';
  static const String formWeightLabel = 'الوزن (اختيارى)';
  static const String formWeightHint = 'اكتب وزن الطفل';
  static const String formBloodTypeLabel = 'فصيلة الدم (اختيارى)';
  static const String formBloodTypeHint = 'اختر من القائمة';
  static const String formHeadCircLabel = 'محيط الدماغ (اختيارى)';
  static const String formHeadCircHint = 'اكتب محيط الدماغ';
  static const String formUnitKg = 'كجم';
  static const String formUnitCm = 'سم';
  static const String formSaveButton = 'حفظ';
  static const String formSkipButton = 'تخطى';
  static const String formSaveAll = 'حفظ البيانات';
  static const String bottomSheetSave = 'حفظ';
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

  // Date of birth components
  String _dobDay = '5';
  String _dobMonth = 'يناير';
  String _dobYear = '2025';

  // Medical profile data
  String _height = '30';
  String _weight = '3.5';
  String _headCircumference = '35';
  String _bloodType = 'A+';
  String _medicalHistory = '';

  // Selected gender for form toggle (0 = male, 1 = female)
  int _selectedGenderIndex = 0;

  // Child Account data
  bool _isAccountCreated = false;
  bool _isAccountActive = false;
  String _childCode = '';
  List<String> _fruitPasswordCodes = [];
  List<String> _fruitPasswordImages = [];
  int _starsCount = 25;
  int _badgesCount = 25;
  int _childAgeInYears = 0;

  // Arabic month names
  static const List<String> monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Clear all fields for the "Fill Data" fresh-start flow
  void clearForFillData() {
    _name = '';
    _age = '';
    _gender = '';
    _selectedGenderIndex = -1;
    _dobDay = '';
    _dobMonth = '';
    _dobYear = '';
    _height = '';
    _weight = '';
    _headCircumference = '';
    _bloodType = '';
    _medicalHistory = '';
    _profileCompletionPercent = 0.0;
    notifyListeners();
  }

  // --- Getters ---
  String get childName => _childName;
  double get profileCompletionPercent => _profileCompletionPercent;
  int get completedVaccinations => _completedVaccinations;
  int get totalVaccinations => _totalVaccinations;

  String get completionPercentText =>
      '${(_profileCompletionPercent * 100).toInt()}%';

  String get vaccinationStatusText => ChildDataStrings.vaccinationStatus(
      _completedVaccinations, _totalVaccinations);

  String get name => _name;
  String get age => _age;
  String get gender => _gender;
  String get heightVal => _height;
  String get weightVal => _weight;
  String get headCircumference => _headCircumference;
  String get bloodType => _bloodType;
  String get dobDay => _dobDay;
  String get dobMonth => _dobMonth;
  String get dobYear => _dobYear;
  int get selectedGenderIndex => _selectedGenderIndex;

  // Account getters
  bool get isAccountCreated => _isAccountCreated;
  bool get isAccountActive => _isAccountActive;
  String get childCode => _childCode;
  List<String> get fruitPasswordCodes => _fruitPasswordCodes;
  List<String> get fruitPasswordImages => _fruitPasswordImages;
  int get starsCount => _starsCount;
  int get badgesCount => _badgesCount;
  int get childAgeInYears => _childAgeInYears;
  bool get isOlderChild => _childAgeInYears >= 4;

  // --- Setters ---
  void setName(String v) {
    _name = v;
    _childName = v;
    notifyListeners();
  }

  void setGender(int index) {
    _selectedGenderIndex = index;
    _gender = index == 0 ? 'ذكر' : 'أنثى';
    notifyListeners();
  }

  void setHeight(String v) {
    _height = v;
    notifyListeners();
  }

  void setWeight(String v) {
    _weight = v;
    notifyListeners();
  }

  void setHeadCircumference(String v) {
    _headCircumference = v;
    notifyListeners();
  }

  void setBloodType(String v) {
    _bloodType = v;
    notifyListeners();
  }

  void setDob(String day, String month, String year) {
    _dobDay = day;
    _dobMonth = month;
    _dobYear = year;
    // Auto-calculate age from DOB
    _recalculateAge();
    notifyListeners();
  }

  void _recalculateAge() {
    final int? d = int.tryParse(_dobDay);
    final int? y = int.tryParse(_dobYear);
    if (d == null || y == null || _dobMonth.isEmpty) return;

    // Find month index
    int mIndex = monthNames.indexOf(_dobMonth);
    if (mIndex < 0) return;
    mIndex += 1; // 1-based

    final dob = DateTime(y, mIndex, d);
    final now = DateTime.now();
    if (dob.isAfter(now)) return;

    int ageYears = now.year - dob.year;
    int ageMonths = now.month - dob.month;
    if (now.day < dob.day) ageMonths--;
    if (ageMonths < 0) {
      ageYears--;
      ageMonths += 12;
    }

    _childAgeInYears = ageYears;

    if (ageYears > 0) {
      if (ageMonths > 0) {
        _age = '$ageYears سنوات , $ageMonths اشهر';
      } else {
        _age = '$ageYears سنوات';
      }
    } else if (ageMonths > 0) {
      final days = now.difference(dob).inDays % 30;
      _age = '$ageMonths اشهر , $days يوم';
    } else {
      final days = now.difference(dob).inDays;
      _age = '$days يوم';
    }
  }

  // Account setters
  void setChildCode(String v) {
    _childCode = v;
    notifyListeners();
  }

  void setFruitPassword(List<String> codes, List<String> images) {
    _fruitPasswordCodes = codes;
    _fruitPasswordImages = images;
    notifyListeners();
  }

  void createAccount(
      String code, List<String> fruitCodes, List<String> fruitImages) {
    _childCode = code;
    _fruitPasswordCodes = fruitCodes;
    _fruitPasswordImages = fruitImages;
    _isAccountCreated = true;
    _isAccountActive = true;
    notifyListeners();
  }

  void deactivateAccount() {
    _isAccountActive = false;
    notifyListeners();
  }

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
