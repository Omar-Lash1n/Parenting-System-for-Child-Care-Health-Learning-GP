import 'package:flutter/material.dart';
import 'package:flutter_application/child-app/child-sign-in.dart';

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // الخلفية
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kBgColorTop, kBgColorBottom],
                ),
              ),
            ),
            
            // المحتوى
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "أهلاً بك في منزلك!",
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // زر تسجيل خروج (GameButton بلون أحمر)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GameButton(
                      text: "تسجيل خروج",
                      color: const Color(0xFFE53935), // أحمر
                      shadowColor: const Color(0xFFB71C1C), // أحمر غامق
                      onTap: () {
                        // العودة لصفحة الدخول ومسح كل الصفحات السابقة
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const ChildLoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}