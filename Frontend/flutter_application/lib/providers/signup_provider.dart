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
  double _passwordStrength = 0.0;

  // --- Getters ---
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isFullNameValid => _isFullNameValid;
  bool get isUsernameValid => _isUsernameValid;
  bool get isEmailValid => _isEmailValid;
  bool get has8Chars => _has8Chars;
  bool get hasNumber => _hasNumber;
  bool get hasSymbol => _hasSymbol;
  double get passwordStrength => _passwordStrength;

  // --- Toggle Password Visibility ---
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // --- Validation Methods ---
  bool validateName(String value) {
    if (value.isEmpty) return false;
    return !RegExp(r'[0-9!@#\$%^\&*(),.?":{}|<>]').hasMatch(value);
  }

  bool validateUsername(String value) {
    return value.length > 4 && !value.contains(' ');
  }

  bool validateEmail(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
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
    _hasSymbol = RegExp(r'[&*/]').hasMatch(password);
    
    int conditionsMet = 0;
    if (_has8Chars) conditionsMet++;
    if (_hasNumber) conditionsMet++;
    if (_hasSymbol) conditionsMet++;
    
    _passwordStrength = conditionsMet / 3.0;
    notifyListeners();
  }

  /// Check if password is strong enough
  bool isPasswordStrong() {
    return _has8Chars && _hasNumber && _hasSymbol;
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
    _passwordStrength = 0.0;
    notifyListeners();
  }
}
