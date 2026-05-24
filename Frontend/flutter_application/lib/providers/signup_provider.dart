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
  double get passwordStrength => _passwordStrength;

  // --- Toggle Password Visibility ---
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // --- Validation Methods ---

  /// Full name: must be at least 2 words, no numbers/special chars,
  /// at least 4 characters total, allows Arabic + English letters
  bool validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 4) return false;
    // Only letters (Arabic+English), spaces, and hyphens allowed
    if (!RegExp(r'^[\u0600-\u06FF\u0750-\u077Fa-zA-Z\s\-]+$').hasMatch(trimmed)) {
      return false;
    }
    // Must contain at least 2 parts (first + last name)
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.length >= 2;
  }

  /// Username: 3-20 chars, letters/numbers/underscores/dots only, no spaces,
  /// must start with a letter
  bool validateUsername(String value) {
    if (value.isEmpty) return false;
    if (value.contains(' ')) return false;
    if (value.length < 3 || value.length > 20) return false;
    // Must start with a letter, then letters/numbers/underscore/dot
    return RegExp(r'^[a-zA-Z\u0600-\u06FF][a-zA-Z0-9\u0600-\u06FF_.]*$')
        .hasMatch(value);
  }

  /// Email: proper format with domain validation
  bool validateEmail(String value) {
    if (value.isEmpty) return false;
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
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`/\\]').hasMatch(value)) {
      return 'يجب أن تحتوي على رمز خاص واحد على الأقل';
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
    _hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`/\\]').hasMatch(password);
    _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);

    int conditionsMet = 0;
    if (_has8Chars) conditionsMet++;
    if (_hasNumber) conditionsMet++;
    if (_hasSymbol) conditionsMet++;
    if (_hasUppercase) conditionsMet++;

    _passwordStrength = conditionsMet / 4.0;
    notifyListeners();
  }

  /// Check if password is strong enough (all 4 criteria met)
  bool isPasswordStrong() {
    return _has8Chars && _hasNumber && _hasSymbol && _hasUppercase;
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
    _passwordStrength = 0.0;
    notifyListeners();
  }
}
