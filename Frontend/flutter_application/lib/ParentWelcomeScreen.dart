// --- ParentWelcomeScreen.dart (Updated with Back Button Navigation) ---

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import 'package:Ajial/signup-login-pages/signup.dart';
// --- *** بداية التعديل المطلوب *** ---
// 1. إضافة import لصفحة اختيار الدور
// (يرجى التأكد من أن هذا المسار صحيح)
import 'package:Ajial/role_selection.dart'; 
// --- *** نهاية التعديل المطلوب *** ---


// --- الثوابت وكلاس التلاشي (كما هي) ---
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
          transitionDuration: const Duration(milliseconds: 300),
        );
}
// --- نهاية الإضافة ---

class ParentWelcomeScreen extends StatefulWidget {
  const ParentWelcomeScreen({super.key});

  @override
  State<ParentWelcomeScreen> createState() => _ParentWelcomeScreenState();
}

class _ParentWelcomeScreenState extends State<ParentWelcomeScreen> {
  late ConfettiController _confettiControllerTopRight;
  late ConfettiController _confettiControllerBottomLeft;

  // (جميع دوال initState, dispose, و _playConfettiTwice كما هي)
  @override
  void initState() {
    super.initState();
    _confettiControllerTopRight = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    _confettiControllerBottomLeft = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
    _playConfettiTwice();
  }

  void _playConfettiTwice() async {
    _confettiControllerTopRight.play();
    _confettiControllerBottomLeft.play();
    await Future.delayed(
      const Duration(milliseconds: 700),
    );
    _confettiControllerTopRight.play();
    _confettiControllerBottomLeft.play();
  }

  @override
  void dispose() {
    _confettiControllerTopRight.dispose();
    _confettiControllerBottomLeft.dispose();
    super.dispose();
  }

  Path _drawConfettiPath(Size size) {
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, 0);
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    const Color defaultButtonColor = kPrimaryColor;
    final Color lightPink = kPrimaryColor.withOpacity(0.1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. المحتوى القابل للـ Scroll ---
            Expanded(
              child: Stack(
                children: [
                  // --- (الـ Confetti كما هو) ---
                  Align(
                    alignment: Alignment.topRight,
                    child: ConfettiWidget(
                      confettiController: _confettiControllerTopRight,
                      // (باقي خصائص الـ Confetti)
                      blastDirection: pi * 0.75,
                      maxBlastForce: 25,
                      minBlastForce: 10,
                      emissionFrequency: 0.03,
                      numberOfParticles: 30,
                      gravity: 0.2,
                      shouldLoop: false,
                      colors: const [
                        Colors.red,
                        Colors.orange,
                        Colors.purple,
                        kPrimaryColor,
                      ],
                      createParticlePath: _drawConfettiPath,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: ConfettiWidget(
                      confettiController: _confettiControllerBottomLeft,
                      // (باقي خصائص الـ Confetti)
                      blastDirection: -pi * 0.25,
                      maxBlastForce: 25,
                      minBlastForce: 10,
                      emissionFrequency: 0.03,
                      numberOfParticles: 30,
                      gravity: 0.2,
                      shouldLoop: false,
                      colors: const [
                        Colors.green,
                        Colors.blue,
                        Colors.yellow,
                        Color(0xFF01A449),
                      ],
                      createParticlePath: _drawConfettiPath,
                    ),
                  ),
                  
                  // --- (النصوص في المنتصف كما هي) ---
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "مرحبًا بالوالدين!",
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "نهنئكم على انضمامكم لعالمنا المليء بالرعاية والنمو.",
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- *** بداية التعديل المطلوب *** ---
                  // --- (تحديث زر الرجوع) ---
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0, right: 24.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: lightPink,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: defaultButtonColor,
                            size: 24,
                          ),
                          onPressed: () {
                            // 2. تغيير الانتقال إلى RoleSelectionScreen
                            Navigator.pushReplacement(
                              context,
                              FadePageRoute(
                                child: const RoleSelectionScreen()),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ),
                  // --- *** نهاية التعديل المطلوب *** ---
                ],
              ),
            ),
            
            // --- 2. الزر الثابت في الأسفل (كما هو) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    print("الانتقال إلى الشاشة التالية");
                    Navigator.of(context).pushReplacement(
                      FadePageRoute(
                        child: const SignUpScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: defaultButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "التالي",
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}