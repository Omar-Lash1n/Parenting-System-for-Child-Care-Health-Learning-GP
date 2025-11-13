import 'package:flutter/material.dart';
import 'package:flutter_application/signup-login-pages/continuesignup.dart';
import 'package:flutter_application/signup-login-pages/signup.dart';
import 'package:flutter_application/splash_screen.dart';
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
      // تهيئة دعم اللغة العربية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],

      theme: ThemeData(
        // ⬅️ الإعداد صحيح: تعيين الخط الافتراضي لـ IBM Plex Sans Arabic
        fontFamily: 'IBM Plex Sans Arabic',
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // 3. تشغيل الصفحة وتحديد الاتجاه الافتراضي RTL
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DataEntryPage(), // ⬅️ الإعداد صحيح: استخدام DataEntryPage
      ),
      initialRoute: '/splash',
      routes: {'/splash': (context) => SplashScreen()},
    );
  }
}
