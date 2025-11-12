import 'package:flutter/material.dart';


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
      initialRoute: '/',
      routes: {
      },
    );
  }
}