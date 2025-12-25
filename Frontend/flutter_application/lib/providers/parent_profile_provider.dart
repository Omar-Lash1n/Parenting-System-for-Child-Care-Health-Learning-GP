// --- lib/providers/parent_profile_provider.dart ---
// Parent Profile Provider - State Management for Profile

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';

class ParentProfileProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State ---
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // --- Email Verification Polling ---
  Timer? _verificationPollingTimer;
  bool _isPollingForVerification = false;
  VoidCallback? _onEmailVerified; // Callback when email gets verified

  // --- Getters ---
  Map<String, dynamic>? get profileData => _profileData;
  List<Map<String, dynamic>> get children => _children;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Profile data getters
  String get fullName => _profileData?['fullName'] ?? '';
  String get username => _profileData?['username'] ?? '';
  String get email => _profileData?['email'] ?? '';
  String get cityName =>
      _profileData?['cityNameAr'] ?? _profileData?['cityName'] ?? '';
  String get dateOfBirth => _profileData?['dateOfBirth'] ?? '';
  String get gender => _profileData?['gender'] ?? '';
  String? get profileImageUrl => _profileData?['profileImageUrl'];
  int get numberOfChildren => _profileData?['numberOfChildren'] ?? 0;
  bool get isEmailVerified => _profileData?['isEmailVerified'] ?? false;
  String get emailVerificationStatus =>
      _profileData?['emailVerificationStatus'] ?? '';
  int get roleCode => _profileData?['roleCode'] ?? 0;
  String get role => _profileData?['role'] ?? '';

  // --- Fetch Profile ---
  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.getParentProfile();
      if (data != null) {
        _profileData = data;
        _children = (data['children'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
      } else {
        _errorMessage = 'فشل في تحميل البيانات';
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ في الاتصال';
      print('Error fetching profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Update Profile ---
  Future<(bool, String)> updateProfile({
    String? fullName,
    String? username,
    String? email,
    int? cityId,
    String? dateOfBirth,
    int? role,
  }) async {
    _isSaving = true;
    notifyListeners();

    final (success, message) = await _authService.updateParentProfile(
      fullName: fullName,
      username: username,
      email: email,
      cityId: cityId,
      dateOfBirth: dateOfBirth,
      role: role,
    );

    if (success) {
      // Update local state
      if (fullName != null) _profileData?['fullName'] = fullName;
      if (username != null) _profileData?['username'] = username;
      if (email != null) _profileData?['email'] = email;
      if (dateOfBirth != null) _profileData?['dateOfBirth'] = dateOfBirth;
    }

    _isSaving = false;
    notifyListeners();

    return (success, message);
  }

  // --- Change Password ---
  Future<(bool, String)> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _isSaving = true;
    notifyListeners();

    final result = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );

    _isSaving = false;
    notifyListeners();

    return result;
  }

  // --- Upload Profile Image ---
  Future<(bool, String)> uploadProfileImage(
    List<int> imageBytes,
    String fileName,
  ) async {
    _isSaving = true;
    notifyListeners();

    final (success, message, imageUrl) =
        await _authService.uploadProfileImage(imageBytes, fileName);

    if (success && imageUrl != null) {
      _profileData?['profileImageUrl'] = imageUrl;
    }

    _isSaving = false;
    notifyListeners();

    return (success, message);
  }

  // --- Send Verification Email ---
  Future<(bool, String)> sendVerificationEmail() async {
    _isSaving = true;
    notifyListeners();

    final result = await _authService.sendVerificationEmail();

    _isSaving = false;
    notifyListeners();

    return result;
  }

  // --- Clear Error ---
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Reset State ---
  void reset() {
    stopVerificationPolling(); // Stop polling when resetting
    _profileData = null;
    _children = [];
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }

  // --- Email Verification Polling Methods ---

  /// Starts polling for email verification status changes.
  /// [onVerified] callback is called when email gets verified.
  /// Polls every 5 seconds by default.
  void startVerificationPolling({VoidCallback? onVerified}) {
    // Don't start if already verified or already polling
    if (isEmailVerified || _isPollingForVerification) {
      return;
    }

    _onEmailVerified = onVerified;
    _isPollingForVerification = true;

    // Poll every 5 seconds
    _verificationPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerificationStatus(),
    );

    print('Email verification polling started');
  }

  /// Stops the email verification polling.
  void stopVerificationPolling() {
    _verificationPollingTimer?.cancel();
    _verificationPollingTimer = null;
    _isPollingForVerification = false;
    _onEmailVerified = null;
    print('Email verification polling stopped');
  }

  /// Checks the current verification status from the API.
  /// Triggers callback and stops polling if verified.
  Future<void> _checkVerificationStatus() async {
    if (!_isPollingForVerification) return;

    try {
      final wasVerified = isEmailVerified;
      final data = await _authService.getParentProfile();

      if (data != null) {
        _profileData = data;
        _children = (data['children'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

        // Check if email just got verified
        final nowVerified = data['isEmailVerified'] ?? false;
        if (!wasVerified && nowVerified) {
          print('Email verification detected!');
          notifyListeners();

          // Trigger callback
          _onEmailVerified?.call();

          // Stop polling - no longer needed
          stopVerificationPolling();
        }
      }
    } catch (e) {
      print('Error checking verification status: $e');
      // Don't stop polling on error - will retry next interval
    }
  }

  /// Getter for polling status
  bool get isPollingForVerification => _isPollingForVerification;

  /// Delete the parent account with confirmation text
  Future<(bool, String)> deleteAccount(String confirmationText) async {
    return await _authService.deleteAccount(confirmationText);
  }

  @override
  void dispose() {
    stopVerificationPolling();
    super.dispose();
  }
}
