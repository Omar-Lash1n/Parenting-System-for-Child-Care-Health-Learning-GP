// --- homepage.dart (Updated with Functional Logout Button) ---

import 'package:flutter/material.dart';
// --- 1. إضافة import لصفحة اللوجن وخدمة الـ API ---
import 'package:flutter_application/signup-login-pages/login.dart'; 
import 'package:flutter_application/api/auth_service.dart'; // (تأكد من المسار)

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

// --- (كلاس تأثير التلاشي كما هو) ---
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
// --- نهاية الإضافة ---


class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  // --- 2. إضافة نسخة من خدمة الـ API ---
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أهلاً بك في الصفحة الرئيسية!',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),

            // --- 5. زر تسجيل الخروج المضاف ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // (يمكنك تغييرها إلى 50 لو أردت)
                ),
              ),
              onPressed: () async { // (تحويلها إلى async)
                
                // --- 3. لوجيك تسجيل الخروج ---
                
                // (أولاً: استدعاء دالة مسح الـ Token)
                await _authService.logout();
                
                // (ثانياً: العودة لصفحة اللوجن)
                // (استخدام 'mounted' check لضمان الأمان)
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(child: const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}