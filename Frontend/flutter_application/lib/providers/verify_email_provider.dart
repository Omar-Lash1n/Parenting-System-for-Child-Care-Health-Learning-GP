// --- lib/providers/verify_email_provider.dart ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/signup-login-pages/enternewpassword.dart';

/// VerifyEmailProvider - Handles OTP verification screen state and logic
class VerifyEmailProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State Variables ---
  String _otpCode = "";
  int _timerStart = 30;
  bool _isTimerActive = false;
  bool _isLoading = false;
  Timer? _timer;

  // --- Getters ---
  String get otpCode => _otpCode;
  int get timerStart => _timerStart;
  bool get isTimerActive => _isTimerActive;
  bool get isLoading => _isLoading;

  // --- Setters ---
  void setOtpCode(String code) {
    _otpCode = code;
    notifyListeners();
  }

  // --- Timer Logic ---
  void startTimer() {
    if (_isTimerActive) return;
    _isTimerActive = true;
    _timerStart = 30;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_timerStart == 0) {
        _isTimerActive = false;
        timer.cancel();
        notifyListeners();
      } else {
        _timerStart--;
        notifyListeners();
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _isTimerActive = false;
  }

  // --- Helper ---
  String maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final name = parts[0];
      final domain = parts[1];
      if (name.length <= 4) {
        return '${name.substring(0, 1)}****@$domain';
      }
      return '${name.substring(0, 3)}****@$domain';
    } catch (e) {
      return '****@****.com';
    }
  }

  // --- Submit OTP ---
  Future<void> submitOtp({
    required BuildContext context,
  }) async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء ادخال الرمز المكون من 6 أرقام',
            style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
          ),
          backgroundColor: Color(0xFFBF092F),
        ),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final (bool success, String message) = await _authService.verifyOtp(
        otpCode: _otpCode,
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

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => EnterNewPasswordScreen(otpCode: _otpCode),
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
    _otpCode = "";
    _timerStart = 30;
    _isTimerActive = false;
    _isLoading = false;
    cancelTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    cancelTimer();
    super.dispose();
  }
}
