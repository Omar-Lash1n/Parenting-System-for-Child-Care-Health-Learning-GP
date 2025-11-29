// --- addnewchild.dart (Refactored & Fixed Navigation) ---

import 'package:Ajial/add-child/add-child-flow.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// **الخطوة 1: استيراد ملف صفحة الأسئلة**

// (يمكنك إضافة استيراد لصفحة Home إذا أردت تشغيل زر التخطي)
// import 'home_screen.dart';

class OnboardingSlide {
  final String imagePath;
  OnboardingSlide({required this.imagePath});
}

class AddNewChildFirstPage extends StatefulWidget {
  const AddNewChildFirstPage({Key? key}) : super(key: key);

  @override
  State<AddNewChildFirstPage> createState() =>
      _AddNewChildFirstPageState();
}

class _AddNewChildFirstPageState
    extends State<AddNewChildFirstPage> {
  final String _staticTitle = 'ابدأ في اضافة طفلك';
  final String _staticDescription =
      'احصل على واستشارات مع متخصصين موثقين، \nوتبادل الخبرات في المجتمع الآمن.';

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(imagePath: 'images/onboarding_1.png'),
    OnboardingSlide(imagePath: 'images/onboarding_2.png'),
    OnboardingSlide(imagePath: 'images/onboarding_3.png'),
  ];

  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;
  static const int _autoScrollDuration = 3;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: _autoScrollDuration),
        (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int nextPage = _currentPage + 1;
      if (nextPage >= _slides.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSlideContent(OnboardingSlide slide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Image.asset(
              slide.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_pin,
                    size: 150,
                    color: Color(0xFFC00030),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 10.0,
          width: _currentPage == index ? 30.0 : 10.0,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFFC00030)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5.0),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 30.0, right: 24.0, left: 24.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _staticTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _staticDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 10,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildSlideContent(_slides[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: _buildPageIndicator(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 30.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          print(
                              'Add Child Button Pressed! Navigating to QuestionPage.');
                          // **تعديل: الانتقال إلى QuestionPage (من onboardingpage.dart)**
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddChildFlow()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC00030),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('اضافة طفل'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          print('Skip Onboarding (Bottom) Pressed!');
                          // هنا يمكنك الانتقال للصفحة الرئيسية (HomePage) مباشرة
                          // Navigator.pushReplacement(...)
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: BorderSide(
                              color: Colors.grey.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('تخطي'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
