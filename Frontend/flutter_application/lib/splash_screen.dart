import 'package:flutter/material.dart';
import 'dart:async';

// تأكد من استيراد ملف onboarding_page.dart بشكل صحيح
import 'onboarding_page.dart'; // هذا هو ملف OnboardingScreen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // إعداد الـ AnimationController وتأثير التلاشي لظهور الشعار
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // مدة انيميشن ظهور الشعار
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // نوع انيميشن ظهور الشعار
    );

    _controller.forward(); // بدء انيميشن ظهور الشعار

    // تحديد مدة عرض Splashscreen ثم الانتقال إلى OnboardingScreen بتأثير تلاشي
    Timer(const Duration(seconds: 4), () {
      // يمكنك تعديل هذه المدة الإجمالية
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // هنا نطبق تأثير التلاشي على الصفحة الجديدة (OnboardingScreen)
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(
            milliseconds: 1000,
          ), // مدة تأثير التلاشي للصفحة الجديدة
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // التخلص من الـ controller عند انتهاء الـ widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBF092F), // لون الخلفية المطلوب #BF092F
      body: Center(
        child: FadeTransition(
          // استخدام FadeTransition لإضافة انيميشن ظهور الشعار
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'images/logo.png', // تأكد من وجود ملف logo.png في مجلد assets
                width: 250, // يمكنك تعديل عرض الصورة حسب الحاجة
                height: 250, // يمكنك تعديل ارتفاع الصورة حسب الحاجة
              ),
            ],
          ),
        ),
      ),
    );
  }
}
