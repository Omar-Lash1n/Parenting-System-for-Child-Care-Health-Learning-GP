import 'package:flutter/material.dart';
import 'package:flutter_application/child-app/child-sign-in.dart';
// (تأكد من أن هذه المسارات صحيحة)
import 'package:flutter_application/signup-login-pages/continuesignup.dart'; 
import 'package:flutter_application/signup-login-pages/signup.dart';
import 'package:flutter_application/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AjialApp());
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
      locale: const Locale('ar'), // (هذا يضبط الاتجاه RTL للتطبيق كله)

      theme: ThemeData(
        fontFamily: 'IBM Plex Sans Arabic', // (ممتاز، هذا صحيح)
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // --- *** بداية التعديل المطلوب *** ---
      // (تم حذف الخاصية 'home:' بالكامل لأنها تتعارض مع 'initialRoute')
      // --- *** نهاية التعديل المطلوب *** ---

      initialRoute: '/child-login',
      routes: {
        '/splash': (context) => SplashScreen(),
        // (يمكنك إضافة باقي الصفحات هنا إذا أردت استخدام التنقل بالأسماء)
        // '/login': (context) => const LoginScreen(),
        // '/signup': (context) => const SignUpScreen(),
        '/child-login': (context) => const ChildLoginScreen(),
      },
    );
  }
}