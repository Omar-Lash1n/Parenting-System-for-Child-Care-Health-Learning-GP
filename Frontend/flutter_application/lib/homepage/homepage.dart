// --- homepage.dart (Updated with Logout Button) ---

import 'package:flutter/material.dart';
// --- *** 1. اعمل امبورت لصفحة اللوجن *** ---
// (عدل المسار ده لو صفحة اللوجن عندك في مكان مختلف)
import 'package:flutter_application/signup-login-pages/login.dart'; 

// --- Global Constants ---
const Color kPrimaryColor = Color(0xFFBF092F); // (اللون الأساسي للزر)
const String kFontFamily = 'IBM Plex Sans Arabic';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // --- 2. حولنا الـ Center لـ Column عشان نحط النص والزر ---
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 3. النص الأصلي بتاعك ---
            const Text(
              'أهلاً بك في الصفحة الرئيسية!',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40), // --- 4. مسافة فاصلة ---

            // --- 5. زر تسجيل الخروج المضاف ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor, // اللون الأساسي للتطبيق
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // --- 6. لوجيك تسجيل الخروج ---
                // هيمسح كل الصفحات ويرجع لصفحة تسجيل الدخول
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false, // بيمسح كل اللي فات
                );
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