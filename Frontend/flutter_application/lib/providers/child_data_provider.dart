// --- lib/providers/child_data_provider.dart ---
// Child Data Provider - State & Strings for Child Data Profile Screen

import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';

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

  // Rewards
  static const String rewardsHeader = 'المكافآت';

  // Account Settings
  static String accountSettingsHeader(String name) => 'اعدادات حساب $name';
  static const String childCodeLabel = 'كود الطفل';
  static const String fruitPasswordLabel = 'كلمة المرور';
  static const String changePasswordLabel = 'تغيير كلمة المرور';
  static const String deactivateAccountLabel = 'تعطيل الحساب';
  static const String accountActiveLabel = 'مفعّل';
  static const String accountInactiveLabel = 'غير مفعّل';

  // Form labels
  static const String formNameLabel = 'الاسم الثلاثي';
  static const String formDobLabel = 'تاريخ الميلاد';
  static const String formDobDay = 'اليوم';
  static const String formDobMonth = 'الشهر';
  static const String formDobYear = 'السنة';
  static const String formGenderLabel = 'الجنس';
  static const String formHeightHint = 'أدخل الطول';
  static const String formWeightHint = 'أدخل الوزن';
  static const String formHeadCircHint = 'أدخل محيط الرأس';
  static const String formBloodTypeHint = 'اختر فصيلة الدم';
  static const String formUnitCm = 'سم';
  static const String formUnitKg = 'كجم';
  static const String formSaveBtn = 'حفظ';

  // Account card (for >= 4 years, no account yet)
  static String accountCardTitle(String name) =>
      'يبدو ان $name اتم 4 اعوام بحمدالله';
  static String accountCardDescription(String name) =>
      'الان يستطيع $name تسجيل الدخول والتفاعل مع المهام التعليمية والألعاب التفاعلية';

  // Change password
  static String changePasswordTitle(String name) => 'تغيير كلمة مرور $name';

  // Missing constants used across screens
  static const String starsUnit = 'نجمة';
  static const String badgesUnit = 'وسام';
  static const String formGenderMale = 'ذكر';
  static const String formGenderFemale = 'أنثى';
  static const String bottomSheetSave = 'حفظ';
  static const String oldPasswordLabel = 'كلمة المرور القديمة';
  static const String newPasswordLabel = 'كلمة المرور الجديدة';
  static const String confirmPasswordLabel = 'تأكيد كلمة المرور';
  static const String changePasswordButton = 'تغيير كلمة المرور';
  static const String formNameHint = 'أدخل الاسم الثلاثي';
  static const String formHeightLabel = 'الطول (سم)';
  static const String formWeightLabel = 'الوزن (كجم)';
  static const String formBloodTypeLabel = 'فصيلة الدم';
  static const String formHeadCircLabel = 'محيط الرأس (سم)';
  static const String formSaveAll = 'حفظ الكل';
  static const String formSkipButton = 'تخطي';
  static const String makingAccountTitle = 'انشاء حساب للطفل';
  static const String makingAccountSubtitle = 'أدخل كود الطفل وكلمة المرور';
  static const String childCodeFieldLabel = 'كود الطفل';
  static const String childCodeHint = 'أدخل كود مكون من 4 أرقام';
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
  String _childId = '';
  String _childName = '';
  String _fullName = '';
  double _profileCompletionPercent = 0.0;
  int _completedVaccinations = 0;
  int _totalVaccinations = 8;

  // Loading / Error
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSaving = false;

  // Personal profile data
  String _name = '';
  String _age = '';
  String _gender = '';
  String? _profileImageUrl;

  // Date of birth components
  String _dobDay = '';
  String _dobMonth = '';
  String _dobYear = '';

  // Medical profile data — raw values (without units)
  String _height = '';
  String _weight = '';
  String _headCircumference = '';
  String _bloodType = '';
  String _medicalHistory = '';

  // Selected gender for form toggle (0 = male, 1 = female)
  int _selectedGenderIndex = 0;

  // Child Account data
  bool _isAccountCreated = false;
  bool _isAccountActive = false;
  String _childCode = '';
  List<String> _fruitPasswordCodes = [];
  List<String> _fruitPasswordImages = [];
  int _starsCount = 0;
  int _badgesCount = 0;
  int _childAgeInYears = 0;

  // Backend account fields
  String _accountAction = 'not_eligible';
  String _accountStatusMessage = '';

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
    _childName = '';
    _fullName = '';
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
    _profileImageUrl = null;
    notifyListeners();
  }

  // --- Getters ---
  String get childId => _childId;
  String get childName => _childName;
  String get fullName => _fullName;
  double get profileCompletionPercent => _profileCompletionPercent;
  int get completedVaccinations => _completedVaccinations;
  int get totalVaccinations => _totalVaccinations;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  String get completionPercentText =>
      '${(_profileCompletionPercent * 100).toInt()}%';

  String get vaccinationStatusText => ChildDataStrings.vaccinationStatus(
      _completedVaccinations, _totalVaccinations);

  String get name => _name;
  String get age => _age;
  String get gender => _gender;
  String? get profileImageUrl => _profileImageUrl;
  String get heightVal => _height;
  String get weightVal => _weight;
  String get headCircumference => _headCircumference;
  String get bloodType => _bloodType;
  String get medicalHistory => _medicalHistory;
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
  String get accountAction => _accountAction;
  String get accountStatusMessage => _accountStatusMessage;

  // --- API Methods ---

  /// Fetch file data from backend
  Future<void> fetchFileData(String childId) async {
    _childId = childId;
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';

    // Clear out old data from previous profile immediately to prevent stale data
    // appearing in forms if clicked quickly before the API response arrives.
    clearForFillData();

    try {
      final data = await AuthService().getChildFileData(childId);

      if (data != null) {
        _childName = (data['firstName'] ?? '').toString();
        _fullName = (data['fullName'] ?? '').toString();
        _name = _fullName.isNotEmpty ? _fullName : _childName;

        // Age
        final years = data['ageYears'] as int? ?? 0;
        final months = data['ageMonths'] as int? ?? 0;
        final days = data['ageDays'] as int? ?? 0;
        _childAgeInYears = years;
        _age = _formatAge(years, months, days);

        // Gender
        final rawGender = (data['gender'] ?? '').toString().toLowerCase();
        if (rawGender == 'female' || rawGender == 'أنثى') {
          _gender = 'أنثى';
          _selectedGenderIndex = 1;
        } else if (rawGender == 'male' || rawGender == 'ذكر') {
          _gender = 'ذكر';
          _selectedGenderIndex = 0;
        } else {
          _gender = 'غير محدد';
          _selectedGenderIndex = 0;
        }

        // Date of Birth
        final birthDateStr = data['birthDate']?.toString();
        if (birthDateStr != null && birthDateStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(birthDateStr);
            _dobDay = dt.day.toString();
            _dobYear = dt.year.toString();
            if (dt.month >= 1 && dt.month <= 12) {
              _dobMonth = monthNames[dt.month - 1];
            }
          } catch (e) {
            // ignore
          }
        }

        // Medical — backend returns values WITH units or null
        _height = _extractNumericValue(data['height']);
        _weight = _extractNumericValue(data['weight']);
        _headCircumference = _extractNumericValue(data['headCircumference']);
        _bloodType = (data['bloodType'] ?? '').toString();
        _medicalHistory = (data['medicalHistory'] ?? '').toString();

        // Profile image
        _profileImageUrl = data['profileImageUrl']?.toString();

        // Completion
        final pct = data['profileCompletionPercentage'] as num? ?? 0;
        _profileCompletionPercent = pct / 100.0;

        // Account status
        _accountAction = (data['accountAction'] ?? 'not_eligible').toString();
        _accountStatusMessage = (data['accountStatusMessage'] ?? '').toString();
        _isAccountCreated = data['hasAccount'] == true;
        _isAccountActive = _isAccountCreated;

        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'فشل في جلب بيانات ملف الطفل';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'خطأ في الاتصال';
      notifyListeners();
    }
  }

  /// Extract numeric value from backend string like "90 سم" → "90"
  String _extractNumericValue(dynamic val) {
    if (val == null) return '';
    final s = val.toString().trim();
    // Remove Arabic units
    return s
        .replaceAll('سم', '')
        .replaceAll('كجم', '')
        .replaceAll('cm', '')
        .replaceAll('kg', '')
        .trim();
  }

  /// Format age from year/month/day parts
  String _formatAge(int years, int months, int days) {
    final parts = <String>[];
    if (years > 0) parts.add('$years سنة');
    if (months > 0) parts.add('$months شهر');
    if (days > 0) parts.add('$days يوم');
    return parts.isEmpty ? '0 يوم' : parts.join(' ');
  }

  /// Submit updates to backend (only changed fields)
  Future<(bool, String)> submitUpdates(Map<String, dynamic> body) async {
    if (_childId.isEmpty) return (false, 'معرف الطفل غير موجود');

    _isSaving = true;
    notifyListeners();

    try {
      final (success, message, data) =
          await AuthService().updateChildMedicalData(_childId, body);

      _isSaving = false;

      if (success && data != null) {
        // Update completion % from response
        final pct = data['profileCompletionPercentage'] as num? ?? 0;
        _profileCompletionPercent = pct / 100.0;
      }

      notifyListeners();
      return (success, message);
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return (false, 'حدث خطأ في الاتصال');
    }
  }

  /// Delete child from backend
  Future<(bool, String)> deleteChild() async {
    if (_childId.isEmpty) return (false, 'معرف الطفل غير موجود');

    _isSaving = true;
    notifyListeners();

    try {
      final result = await AuthService().deleteChild(_childId);
      _isSaving = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return (false, 'خطأ في الاتصال');
    }
  }

  // --- Local Setters ---

  void setName(String v) {
    _name = v;
    _childName = v.split(' ').first;
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
    _recalculateAge();
    notifyListeners();
  }

  void _recalculateAge() {
    if (_dobDay.isEmpty || _dobMonth.isEmpty || _dobYear.isEmpty) return;
    final monthIndex = monthNames.indexOf(_dobMonth);
    if (monthIndex == -1) return;
    final day = int.tryParse(_dobDay);
    final year = int.tryParse(_dobYear);
    if (day == null || year == null) return;

    final dob = DateTime(year, monthIndex + 1, day);
    final now = DateTime.now();
    if (dob.isAfter(now)) return;

    int years = now.year - dob.year;
    int months = now.month - dob.month;
    int days = now.day - dob.day;

    if (days < 0) {
      months--;
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    _childAgeInYears = years;
    _age = _formatAge(years, months, days);
  }

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

  void activateAccount() {
    _isAccountActive = true;
    notifyListeners();
  }

  // --- API Account Editing Bridges ---

  Future<(bool, String)> updateAccountLoginId(String newId) async {
    if (_childId.isEmpty) return (false, 'معرف الطفل غير موجود');
    final result = await AuthService().updateChildLoginId(
      childId: _childId,
      newChildLoginId: newId,
    );
    if (result.$1) {
      setChildCode(newId);
    }
    return result;
  }

  Future<(bool, String)> updateAccountPassword(
      List<String> oldCodes,
      List<String> newCodes,
      List<String> confirmCodes,
      List<String> newImages) async {
    if (_childId.isEmpty) return (false, 'معرف الطفل غير موجود');
    final result = await AuthService().updateChildPassword(
      childId: _childId,
      oldFruitPasswordCodes: oldCodes,
      newFruitPasswordCodes: newCodes,
      confirmFruitPasswordCodes: confirmCodes,
    );
    if (result.$1) {
      setFruitPassword(newCodes, newImages);
    }
    return result;
  }

  Future<(bool, String)> toggleAccountStatus(bool isActive) async {
    if (_childId.isEmpty) return (false, 'معرف الطفل غير موجود');
    final result = await AuthService().toggleChildAccount(
      childId: _childId,
      isActive: isActive,
    );
    if (result.$1) {
      if (isActive) {
        activateAccount();
      } else {
        deactivateAccount();
      }
    }
    return result;
  } // --- Personal Profile Items ---

  List<ProfileInfoItem> get personalItems => [
        ProfileInfoItem(
          label: ChildDataStrings.nameLabel,
          value: _name.isNotEmpty ? _name : null,
          icon: Icons.person_outline,
          iconColor: const Color(0xFFBF092F),
          iconBgColor: const Color(0x1ABF092F),
        ),
        ProfileInfoItem(
          label: ChildDataStrings.ageLabel,
          value: _age.isNotEmpty ? _age : null,
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF008CFF),
          iconBgColor: const Color(0x1A008CFF),
        ),
        ProfileInfoItem(
          label: ChildDataStrings.genderLabel,
          value: _gender.isNotEmpty ? _gender : null,
          icon: Icons.child_care,
          iconColor: const Color(0xFFFE8401),
          iconBgColor: const Color(0x1AFE8401),
        ),
      ];

  // --- Medical Profile Items ---
  List<ProfileInfoItem> get medicalItems => [
        ProfileInfoItem(
          label: ChildDataStrings.heightLabel,
          value: _height.isNotEmpty ? '$_height سم' : null,
          icon: Icons.height,
          iconColor: const Color(0xFFBF092F),
          iconBgColor: const Color(0x1ABF092F),
        ),
        ProfileInfoItem(
          label: ChildDataStrings.weightLabel,
          value: _weight.isNotEmpty ? '$_weight كجم' : null,
          icon: Icons.monitor_weight_outlined,
          iconColor: const Color(0xFF01A449),
          iconBgColor: const Color(0x1A01A449),
        ),
        ProfileInfoItem(
          label: ChildDataStrings.headCircumferenceLabel,
          value:
              _headCircumference.isNotEmpty ? '$_headCircumference سم' : null,
          icon: Icons.circle_outlined,
          iconColor: const Color(0xFF008CFF),
          iconBgColor: const Color(0x1A008CFF),
        ),
        ProfileInfoItem(
          label: ChildDataStrings.bloodTypeLabel,
          value: _bloodType.isNotEmpty ? _bloodType : null,
          icon: Icons.bloodtype_outlined,
          iconColor: const Color(0xFFFF0000),
          iconBgColor: const Color(0x0DFF0000),
        ),
        ProfileInfoItem(
          label: ChildDataStrings.medicalHistoryLabel,
          value: _medicalHistory.isNotEmpty ? _medicalHistory : null,
          icon: Icons.monitor_heart_outlined,
          iconColor: const Color(0xFFFE8401),
          iconBgColor: const Color(0x1AFE8401),
        ),
      ];

  /// Upload child profile image
  Future<(bool, String)> uploadChildImage(
      List<int> imageBytes, String fileName) async {
    if (_childId.isEmpty) return (false, 'معرف الطفل غير موجود');

    final (success, message, imageUrl) = await AuthService()
        .uploadChildProfileImage(_childId, imageBytes, fileName);

    if (success && imageUrl != null) {
      _profileImageUrl = imageUrl;
      notifyListeners();
    }

    return (success, message);
  }
}
