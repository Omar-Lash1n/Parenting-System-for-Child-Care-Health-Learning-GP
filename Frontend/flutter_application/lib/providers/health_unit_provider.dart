import 'package:flutter/foundation.dart';
import 'package:Ajial/api/auth_service.dart';

class HealthUnitProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State
  List<Map<String, dynamic>> _healthUnits = [];
  Map<String, dynamic>? _selectedUnit;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _activeFilter = 'الكل';
  String _searchKeyword = '';
  double? _userLatitude;
  double? _userLongitude;
  bool _locationPermissionGranted = false;
  bool _showSearchHintDialog = true;
  bool _showLocationHintDialog = true;
  int _totalCount = 0;

  // Getters
  List<Map<String, dynamic>> get healthUnits => _healthUnits;
  Map<String, dynamic>? get selectedUnit => _selectedUnit;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get activeFilter => _activeFilter;
  String get searchKeyword => _searchKeyword;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get showSearchHintDialog => _showSearchHintDialog;
  bool get showLocationHintDialog => _showLocationHintDialog;
  int get totalCount => _totalCount;

  /// البحث عن الوحدات الصحية
  Future<void> searchHealthUnits({
    String? keyword,
    String? type,
    int? cityId,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';

    // Entering keyword mode: clear location state so the next request is a
    // pure keyword search with no radius filter, and drop the 'قريب' chip.
    if (keyword != null && keyword.isNotEmpty) {
      _searchKeyword = keyword;
      _userLatitude = null;
      _userLongitude = null;
      if (_activeFilter == 'قريب') _activeFilter = 'الكل';
    } else if (keyword != null) {
      _searchKeyword = keyword;
    }
    notifyListeners();

    // Only send coordinates when explicitly passed — don't fall back to stored
    // location for keyword searches, otherwise the radius filter silently
    // hides results that are far from the user.
    final result = await _authService.searchHealthUnits(
      latitude: latitude,
      longitude: longitude,
      keyword: keyword ?? (_searchKeyword.isNotEmpty ? _searchKeyword : null),
      type: type ?? _getTypeFromFilter(),
      cityId: cityId,
    );

    if (result != null && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      _healthUnits =
          List<Map<String, dynamic>>.from(data['items'] as List? ?? []);
      _totalCount = data['totalCount'] as int? ?? 0;
      _isLoading = false;
      _hasError = false;
    } else {
      _healthUnits = [];
      _totalCount = 0;
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'عذراً لم نتمكن من ألان الوصول';
    }
    notifyListeners();
  }

  /// جلب تفاصيل وحدة صحية
  Future<void> getHealthUnitDetail(int id) async {
    final result = await _authService.getHealthUnitDetail(
      id,
      latitude: _userLatitude,
      longitude: _userLongitude,
    );

    if (result != null) {
      _selectedUnit = result;
      notifyListeners();
    }
  }

  /// تعيين الفلتر النشط
  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();

    if (filter == 'قريب') {
      if (_locationPermissionGranted &&
          _userLatitude != null &&
          _userLongitude != null) {
        _searchKeyword = ''; // clear stale keyword — location search has no text filter
        searchHealthUnits(
          latitude: _userLatitude,
          longitude: _userLongitude,
        );
      }
      return;
    }

    if (filter == 'مفتوح') {
      searchHealthUnits().then((_) {
        _healthUnits = _healthUnits
            .where((u) => u['isActive'] == true)
            .toList();
        notifyListeners();
      });
      return;
    }

    searchHealthUnits();
  }

  /// تحديث موقع المستخدم
  void updateUserLocation(double lat, double lng) {
    _userLatitude = lat;
    _userLongitude = lng;
    _locationPermissionGranted = true;
    _searchKeyword = ''; // clear stale keyword — location search has no text filter
    notifyListeners();
    searchHealthUnits(latitude: lat, longitude: lng);
  }

  /// مسح البحث
  void clearSearch() {
    _searchKeyword = '';
    _healthUnits = [];
    _totalCount = 0;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  /// إخفاء حوار تلميح البحث
  void dismissSearchHint() {
    _showSearchHintDialog = false;
    notifyListeners();
  }

  /// إخفاء حوار تلميح الموقع
  void dismissLocationHint() {
    _showLocationHintDialog = false;
    notifyListeners();
  }

  /// تحديد وحدة صحية
  void selectUnit(Map<String, dynamic> unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  /// تحويل اسم الفلتر إلى نوع API
  String? _getTypeFromFilter() {
    switch (_activeFilter) {
      case 'مستشفى':
        return 'Hospital';
      case 'وحدة صحية':
        return 'HealthUnit';
      default:
        return null;
    }
  }
}
