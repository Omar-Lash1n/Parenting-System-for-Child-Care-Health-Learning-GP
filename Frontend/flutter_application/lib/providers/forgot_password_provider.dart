// --- lib/providers/forgot_password_provider.dart ---

import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/signup-login-pages/verifyemail.dart';

/// ForgotPasswordProvider - Handles forgot password screen state and logic
class ForgotPasswordProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State Variables ---
  bool _isEmailValid = false;
  bool _isLoading = false;

  // --- Getters ---
  bool get isEmailValid => _isEmailValid;
  bool get isLoading => _isLoading;

  // --- Validation ---
  bool validateEmail(String value) {
    if (value.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
  }

  void onEmailChanged(String value) {
    final isValid = validateEmail(value);
    if (_isEmailValid != isValid) {
      _isEmailValid = isValid;
      notifyListeners();
    }
  }

  // --- Submit Forgot Password ---
  Future<void> submitForgotPassword({
    required String email,
    required GlobalKey<FormState> formKey,
    required BuildContext context,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final (bool success, String message) = await _authService.forgotPassword(
        email: email,
      );

      if (!context.mounted) return;

      if (success) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VerifyEmailScreen(email: email),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
            backgroundColor: const Color(0xFFBF092F),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic')),
          backgroundColor: const Color(0xFFBF092F),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset provider state
  void reset() {
    _isEmailValid = false;
    _isLoading = false;
    notifyListeners();
  }
}
