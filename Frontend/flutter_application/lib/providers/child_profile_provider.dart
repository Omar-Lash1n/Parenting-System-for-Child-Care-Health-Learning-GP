// --- lib/providers/child_profile_provider.dart ---
// Child Profile Provider - State Management for Child Profile Screen

import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';

/// Model for a single dashboard item on the child profile screen
class DashboardItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isLocked;

  const DashboardItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isLocked = false,
  });
}

class ChildProfileProvider extends ChangeNotifier {
  // --- State ---
  String _childId = '';
  String _childName = '';
  String _childAge = '';
  String? _profileImageUrl;
  double _profileCompletionPercent = 0.0;
  int _completedVaccinations = 0;
  int _totalVaccinations = 8;

  // Loading / Error
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Account / Age state
  int _childAgeInYears = 0;
  bool _isAccountCreated = false;
  bool _isAccountActive = false;
  int _starsCount = 0;
  int _badgesCount = 0;

  // Backend account fields
  String _accountAction =
      'not_eligible'; // not_eligible | create_account | view_account
  String _accountStatusMessage = '';

  // --- Getters ---
  String get childId => _childId;
  String get childName => _childName;
  String get childAge => _childAge;
  String? get profileImageUrl => _profileImageUrl;
  double get profileCompletionPercent => _profileCompletionPercent;
  int get completedVaccinations => _completedVaccinations;
  int get totalVaccinations => _totalVaccinations;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int get childAgeInYears => _childAgeInYears;
  bool get isOlderChild => _childAgeInYears >= 4;
  bool get isAccountCreated => _isAccountCreated;
  bool get isAccountActive => _isAccountActive;
  int get starsCount => _starsCount;
  int get badgesCount => _badgesCount;
  String get accountAction => _accountAction;
  String get accountStatusMessage => _accountStatusMessage;

  String get completionPercentText =>
      '${(_profileCompletionPercent * 100).toInt()}%';

  String get vaccinationStatusText =>
      'تم اتمام $_completedVaccinations من $_totalVaccinations تطعيمات أساسية للعام الأول';

  // --- Dashboard Items ---
  List<DashboardItem> get dashboardItems => [
        const DashboardItem(
          title: 'التطعيمات',
          icon: Icons.vaccines,
          iconColor: Color(0xFFBF092F),
          bgColor: Color(0xFFFEF2F2),
        ),
        const DashboardItem(
          title: 'بيانات الطفل',
          icon: Icons.child_care,
          iconColor: Color(0xFFFE8401),
          bgColor: Color(0x0DFE8401),
        ),
        const DashboardItem(
          title: 'المهام',
          icon: Icons.assignment_outlined,
          iconColor: Color(0xFFFE8401),
          bgColor: Color(0x0DFE8401),
        ),
        DashboardItem(
          title: 'المكافآت',
          icon: _isAccountCreated ? Icons.emoji_events : Icons.lock_outline,
          iconColor: _isAccountCreated
              ? const Color(0xFF0EA5E9)
              : const Color(0xFF000000),
          bgColor: const Color(0x0D0EA5E9),
          isLocked: !_isAccountCreated,
        ),
        const DashboardItem(
          title: 'السجل الطبي',
          icon: Icons.medical_services_outlined,
          iconColor: Color(0xFF0EA5E9),
          bgColor: Color(0x0D0EA5E9),
        ),
        const DashboardItem(
          title: 'سجل النمو',
          icon: Icons.trending_up,
          iconColor: Color(0xFF01A449),
          bgColor: Color(0x0D01A449),
        ),
      ];

  // --- API Methods ---

  /// Fetch child profile summary from backend
  Future<void> fetchProfileSummary(String childId) async {
    _childId = childId;
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await AuthService().getChildProfileSummary(childId);

      if (data != null) {
        _childName = (data['firstName'] ?? '').toString();

        // Build age string from parts
        final years = data['ageYears'] as int? ?? 0;
        final months = data['ageMonths'] as int? ?? 0;
        final days = data['ageDays'] as int? ?? 0;
        _childAge = _formatAge(years, months, days);
        _childAgeInYears = years;

        _profileImageUrl = data['profileImageUrl'] as String?;
        final pct = data['profileCompletionPercentage'] as num? ?? 0;
        _profileCompletionPercent = pct / 100.0;

        // Account status from backend
        _accountAction = (data['accountAction'] ?? 'not_eligible').toString();
        _accountStatusMessage = (data['accountStatusMessage'] ?? '').toString();
        _isAccountCreated = _accountAction == 'view_account';
        _isAccountActive = _isAccountCreated;

        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'فشل في جلب بيانات الطفل';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'خطأ في الاتصال';
      notifyListeners();
    }
  }

  /// Format age from year/month/day parts
  String _formatAge(int years, int months, int days) {
    final parts = <String>[];
    if (years > 0) parts.add('$years سنة');
    if (months > 0) parts.add('$months شهر');
    if (days > 0) parts.add('$days يوم');
    return parts.isEmpty ? '0 يوم' : parts.join(' ');
  }

  // --- Manual Setters (kept for local UI updates) ---
  void setChildData({
    required String name,
    required String age,
    String? imageUrl,
  }) {
    _childName = name;
    _childAge = age;
    _profileImageUrl = imageUrl;
    notifyListeners();
  }

  void updateCompletion(double percent, int completed, int total) {
    _profileCompletionPercent = percent;
    _completedVaccinations = completed;
    _totalVaccinations = total;
    notifyListeners();
  }

  void setAgeInYears(int years) {
    _childAgeInYears = years;
    notifyListeners();
  }

  void setAccountCreated(bool value) {
    _isAccountCreated = value;
    _isAccountActive = value;
    notifyListeners();
  }

  void setAccountActive(bool value) {
    _isAccountActive = value;
    notifyListeners();
  }

  void setStarsAndBadges(int stars, int badges) {
    _starsCount = stars;
    _badgesCount = badges;
    notifyListeners();
  }

  /// Update completion % from API response without re-fetching
  void updateCompletionFromApi(int percentage) {
    _profileCompletionPercent = percentage / 100.0;
    notifyListeners();
  }

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
