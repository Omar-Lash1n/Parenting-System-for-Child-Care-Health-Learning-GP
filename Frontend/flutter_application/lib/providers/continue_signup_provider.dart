// --- lib/providers/continue_signup_provider.dart ---

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/signup-login-pages/login.dart';

/// ContinueSignupProvider - Handles data entry page state and registration
class ContinueSignupProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // --- State Variables ---
  int? _selectedCityId;
  DateTime? _selectedDateOfBirth;
  String? _selectedRole; // 'أب', 'أم'
  bool _isLoading = false;

  // Cities list
  final List<Map<String, dynamic>> cities = [
    {"id": 1, "nameAr": "القاهرة"},
    {"id": 2, "nameAr": "الإسكندرية"},
    {"id": 3, "nameAr": "الجيزة"},
    {"id": 4, "nameAr": "شبرا الخيمة"},
    {"id": 5, "nameAr": "بورسعيد"},
  ];

  // --- Getters ---
  int? get selectedCityId => _selectedCityId;
  DateTime? get selectedDateOfBirth => _selectedDateOfBirth;
  String? get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;

  // --- Setters ---
  void setCity(int? cityId) {
    _selectedCityId = cityId;
    notifyListeners();
  }

  void setDateOfBirth(DateTime? date) {
    _selectedDateOfBirth = date;
    notifyListeners();
  }

  void setRole(String? role) {
    _selectedRole = role;
    notifyListeners();
  }

  // --- Helper Methods ---
  int _getGenderId(String? role) {
    if (role == 'أب') return 1;
    if (role == 'أم') return 2;
    return 0;
  }

  bool isFormValid() {
    return _selectedCityId != null && 
           _selectedDateOfBirth != null && 
           _selectedRole != null;
  }

  // --- Submit Registration ---
  Future<void> submitRegistration({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    if (!isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء تعبئة جميع الحقول المطلوبة',
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
      final String? error = await _authService.registerParent(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        cityId: _selectedCityId!,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
        gender: _getGenderId(_selectedRole),
      );

      if (!context.mounted) return;

      if (error == null) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم انشاء الحساب بنجاح!',
              style: TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } else {
        // Error from server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $error',
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
            'حدث خطأ غير معروف: $e',
            style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
          ),
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
    _selectedCityId = null;
    _selectedDateOfBirth = null;
    _selectedRole = null;
    _isLoading = false;
    notifyListeners();
  }
}
