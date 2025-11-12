import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/signup.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ must come before SharedPreferences
  runApp(AjialApp());
}



class AjialApp extends StatelessWidget {
  const AjialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // // --- بداية التعديل ---
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: [
      //   const Locale('ar', 'AE'), // إضافة اللغة العربية
      //   const Locale('en', 'US'), // اللغة الإنجليزية لو موجودة
      // ],
      // locale: const Locale('ar', 'AE'), // تحديد العربية كلغة افتراضية للـ components
      // // --- نهاية التعديل ---
      initialRoute: '/signup',
      routes: {
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}