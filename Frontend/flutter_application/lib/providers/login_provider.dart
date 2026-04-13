// --- lib/providers/login_provider.dart ---

import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/homepage/homepage.dart';

/// LoginProvider - Handles login screen state and business logic
class LoginProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State Variables ---
  bool _isPasswordVisible = false;
  bool _isUsernameValid = false;
  bool _isLoading = false;

  // --- Getters ---
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isUsernameValid => _isUsernameValid;
  bool get isLoading => _isLoading;

  // --- Setters with notifyListeners ---
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setUsernameValid(bool value) {
    if (_isUsernameValid != value) {
      _isUsernameValid = value;
      notifyListeners();
    }
  }

  // --- Validation ---
  bool validateUsername(String value) {
    return value.isNotEmpty && !value.contains(' ');
  }

  void onUsernameChanged(String value) {
    setUsernameValid(validateUsername(value));
  }

  // --- Login Logic ---
  Future<void> login({
    required String username,
    required String password,
    required GlobalKey<FormState> formKey,
    required BuildContext context,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final (String? token, String? errorMessage) = await _authService.loginParent(
        username: username,
        password: password,
      );

      if (!context.mounted) return;

      if (token != null) {
        // Reset loading state BEFORE navigating so the finally block's
        // notifyListeners() does not try to rebuild a deactivated widget.
        _isLoading = false;
        notifyListeners();

        // Navigate to home with fade transition
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      } else {
        // Error from server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage ?? 'بيانات الدخول غير صحيحة',
              style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
            ),
            backgroundColor: const Color(0xFFBF092F),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
            style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
          ),
          backgroundColor: const Color(0xFFBF092F),
        ),
      );
    } finally {
      // Only reset if not already reset by the success path above
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Reset provider state (useful when screen is disposed/re-opened)
  void reset() {
    _isPasswordVisible = false;
    _isUsernameValid = false;
    _isLoading = false;
    notifyListeners();
  }
}
