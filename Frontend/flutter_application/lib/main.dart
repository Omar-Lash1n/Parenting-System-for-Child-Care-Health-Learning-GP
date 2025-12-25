import 'package:Ajial/add-child/add-child-flow.dart';
import 'package:Ajial/homepage/homepage.dart';
import 'package:Ajial/signup-login-pages/login.dart';
import 'package:flutter/material.dart';
import 'package:Ajial/child-app/child-sign-in.dart';
import 'package:Ajial/splash_screen.dart';
import 'package:Ajial/profile/parent_profile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- Provider Imports ---
import 'package:provider/provider.dart';
import 'package:Ajial/providers/login_provider.dart';
import 'package:Ajial/providers/signup_provider.dart';
import 'package:Ajial/providers/continue_signup_provider.dart';
import 'package:Ajial/providers/forgot_password_provider.dart';
import 'package:Ajial/providers/verify_email_provider.dart';
import 'package:Ajial/providers/home_provider.dart';
import 'package:Ajial/providers/add_child_flow_provider.dart';
import 'package:Ajial/providers/child_login_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';
import 'package:Ajial/child-app/home/child_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => ContinueSignupProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => VerifyEmailProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AddChildFlowProvider()),
        ChangeNotifierProvider(create: (_) => ChildLoginProvider()),
        ChangeNotifierProvider(create: (_) => ParentProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChildHomeProvider()),
      ],
      child: const AjialApp(),
    ),
  );
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

      initialRoute:
          '/splash', // (يمكنك تغيير هذه الصفحة الافتراضية حسب الحاجة)
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/child-login': (context) => const ChildLoginScreen(),
        '/child-home': (context) => const ChildHomePage(),
        '/home': (context) => HomeScreen(),
        '/add-child': (context) => const AddChildFlow(),
        '/profile': (context) => const ParentProfilePage(),
      },
    );
  }
}

