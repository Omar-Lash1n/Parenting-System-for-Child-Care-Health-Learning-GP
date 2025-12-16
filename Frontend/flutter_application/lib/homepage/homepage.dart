// --- homepage.dart (Refactored with Provider Pattern) ---

import 'package:Ajial/add-child/add-child-flow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/home_provider.dart';

const Color kPrimaryColor = Color(0xFFBF092F);
const String kFontFamily = 'IBM Plex Sans Arabic';

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
          transitionDuration: const Duration(milliseconds: 700),
        );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, provider, _) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'images/main-logo.png',
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home,
                      size: 100,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome Message
                  const Text(
                    'مرحباً بك في الصفحة الرئيسية!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: kFontFamily,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'هذه صفحة مؤقتة، سيتم تطويرها لاحقاً',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: kFontFamily,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Add Child Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoggingOut ? null : () {
                        Navigator.push(
                          context,
                          FadePageRoute(child: const AddChildFlow()),
                        );
                      },
                      icon: const Icon(Icons.child_care, color: Colors.white),
                      label: const Text(
                        'أضف طفلاً جديداً',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: provider.isLoggingOut
                        ? const CircularProgressIndicator(color: kPrimaryColor)
                        : OutlinedButton.icon(
                            onPressed: () => provider.logout(context),
                            icon: const Icon(Icons.logout, color: kPrimaryColor),
                            label: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 18,
                                color: kPrimaryColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kPrimaryColor),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
