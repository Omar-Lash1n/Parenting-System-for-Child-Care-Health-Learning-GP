// --- lib/providers/signup_provider.dart ---

import 'package:flutter/material.dart';

/// SignupProvider - Handles signup screen state and business logic
class SignupProvider extends ChangeNotifier {
  // --- State Variables ---
  bool _isPasswordVisible = false;
  bool _isFullNameValid = false;
  bool _isUsernameValid = false;
  bool _isEmailValid = false;

  // Password strength
  bool _has8Chars = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  double _passwordStrength = 0.0;

  // --- Getters ---
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isFullNameValid => _isFullNameValid;
  bool get isUsernameValid => _isUsernameValid;
  bool get isEmailValid => _isEmailValid;
  bool get has8Chars => _has8Chars;
  bool get hasNumber => _hasNumber;
  bool get hasSymbol => _hasSymbol;
  bool get hasUppercase => _hasUppercase;
  bool get hasLowercase => _hasLowercase;
  double get passwordStrength => _passwordStrength;

  // --- Toggle Password Visibility ---
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // --- Validation Methods ---

  /// Full name: 3-100 characters, no leading/trailing spaces,
  /// can contain letters, spaces, Arabic characters only
  bool validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 3 || trimmed.length > 100) return false;
    // No leading/trailing spaces (compare with original)
    if (value != trimmed) return false;
    // Only letters (Arabic+English) and spaces allowed
    if (!RegExp(r'^[\u0600-\u06FF\u0750-\u077Fa-zA-Z\s]+$').hasMatch(trimmed)) {
      return false;
    }
    return true;
  }

  /// Username: 3-50 chars, alphanumeric + underscore only, no spaces
  bool validateUsername(String value) {
    if (value.isEmpty) return false;
    if (value.contains(' ')) return false;
    if (value.length < 3 || value.length > 50) return false;
    // Alphanumeric and underscore only
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value);
  }

  /// Email: valid format, max 100 characters, must be unique (server-side)
  bool validateEmail(String value) {
    if (value.isEmpty) return false;
    if (value.length > 100) return false;
    // RFC 5322 simplified — ensures TLD has at least 2 chars
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z]{2,})+$',
    ).hasMatch(value);
  }

  /// Inline password validation message (for the TextFormField validator)
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!RegExp(r'[@$!%*?&#]').hasMatch(value)) {
      return 'يجب أن تحتوي على رمز خاص واحد على الأقل (@\$!%*?&#)';
    }
    return null;
  }

  // --- Listeners for text changes ---
  void onFullNameChanged(String value) {
    final isValid = validateName(value);
    if (_isFullNameValid != isValid) {
      _isFullNameValid = isValid;
      notifyListeners();
    }
  }

  void onUsernameChanged(String value) {
    final isValid = validateUsername(value);
    if (_isUsernameValid != isValid) {
      _isUsernameValid = isValid;
      notifyListeners();
    }
  }

  void onEmailChanged(String value) {
    final isValid = validateEmail(value);
    if (_isEmailValid != isValid) {
      _isEmailValid = isValid;
      notifyListeners();
    }
  }

  // --- Password Strength ---
  void updatePasswordStrength(String password) {
    _has8Chars = password.length >= 8;
    _hasNumber = RegExp(r'[0-9]').hasMatch(password);
    _hasSymbol = RegExp(r'[@$!%*?&#]').hasMatch(password);
    _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    _hasLowercase = RegExp(r'[a-z]').hasMatch(password);

    int conditionsMet = 0;
    if (_has8Chars) conditionsMet++;
    if (_hasNumber) conditionsMet++;
    if (_hasSymbol) conditionsMet++;
    if (_hasUppercase) conditionsMet++;
    if (_hasLowercase) conditionsMet++;

    _passwordStrength = conditionsMet / 5.0;
    notifyListeners();
  }

  /// Check if password is strong enough (all 5 criteria met)
  bool isPasswordStrong() {
    return _has8Chars && _hasNumber && _hasSymbol && _hasUppercase && _hasLowercase;
  }

  /// Reset provider state
  void reset() {
    _isPasswordVisible = false;
    _isFullNameValid = false;
    _isUsernameValid = false;
    _isEmailValid = false;
    _has8Chars = false;
    _hasNumber = false;
    _hasSymbol = false;
    _hasUppercase = false;
    _hasLowercase = false;
    _passwordStrength = 0.0;
    notifyListeners();
  }
}
