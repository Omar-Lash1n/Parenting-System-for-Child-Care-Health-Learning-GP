// --- lib/providers/home_provider.dart ---

import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/signup-login-pages/login.dart';

/// HomeProvider - Handles home screen state and logout logic
class HomeProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State Variables ---
  bool _isLoggingOut = false;

  // --- Getters ---
  bool get isLoggingOut => _isLoggingOut;

  // --- Logout Logic ---
  Future<void> logout(BuildContext context) async {
    _isLoggingOut = true;
    notifyListeners();

    try {
      await _authService.logout();

      if (!context.mounted) return;

      // Navigate to login and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (Route<dynamic> route) => false,
      );
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Reset provider state
  void reset() {
    _isLoggingOut = false;
    notifyListeners();
  }
}
