import 'package:flutter/material.dart';

import 'role_selection.dart';

// تعريف كلاس مساعد لحفظ بيانات العنوان الملون
class ColoredTitle {
  final String fullText;
  final String? coloredWord;
  final Color? coloredWordColor;

  ColoredTitle({
    required this.fullText,
    this.coloredWord,
    this.coloredWordColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0; // لم نعد نحتاج PageController

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": ColoredTitle(
        fullText: "مرحباً بك في عالم رعاية الطفل!",
        coloredWord: "رعاية",
        coloredWordColor: Color(0xFFBF092F),
      ),
      "description": "نحن هنا لمساعدتك في إدارة مهامك بكفاءة وسهولة.",
      "imagePath": "images/onboarding_1.png",
    },
    {
      "title": ColoredTitle(
        fullText: "خطوات عملية لحياة يومية منظمة",
        coloredWord: "منظمة",
        coloredWordColor: Color(0xFFFF9D00),
      ),
      "description": "راقب إنجازاتك اليومية وحقق أهدافك خطوة بخطوة.",
      "imagePath": "images/onboarding_2.png",
    },
    {
      "title": ColoredTitle(
        fullText: "تعلم مهارات بالمرح والمكافأة!",
        coloredWord: "مهارات",
        coloredWordColor: Color(0xFF01A449),
      ),
      "description": "خصّص التطبيق ليناسب احتياجاتك وتفضيلاتك الشخصية.",
      "imagePath": "images/onboarding_3.png",
    },
    {
      "title": ColoredTitle(
        fullText: "دعم سلوكي من مجتمع موثوق",
        coloredWord: "مجتمع",
        coloredWordColor: Color(0xFFBF092F),
      ),
      "description": "لا تفوّت أي موعد مهم مع تذكيراتنا الذكية.",
      "imagePath": "images/onboarding_4.png",
    },
    {
      "title": ColoredTitle(
        fullText: "متخصصين فى رعاية الاطفال",
        coloredWord: "متخصصين",
        coloredWordColor: Color(0xFFFF9D00),
      ),
      "description": "انطلق في رحلتك نحو الإنتاجية القصوى معنا.",
      "imagePath": "images/onboarding_5.png",
    },
  ];

  void _goToNextPage() {
    setState(() {
      if (_currentPage < onboardingData.length - 1) {
        _currentPage++;
      } else {
        // الانتقال إلى الشاشة الرئيسية عند الوصول للصفحة الأخيرة
        Navigator.of(context).pushReplacement(
          // هذا هو التعديل لإضافة تأثير التلاشي
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RoleSelectionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = 0.0;
                  const end = 1.0;
                  const curve = Curves.ease;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return FadeTransition(
                    opacity: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(
              milliseconds: 700,
            ), // مدة تأثير التلاشي
          ),
        );
      }
    });
  }

  void _goToPreviousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  void _skipToLastPage() {
    setState(() {
      _currentPage = onboardingData.length - 1;
    });
  }

  // التنقل بالسحب الأفقي. في تخطيط RTL: السحب لليسار (سرعة سالبة) ينتقل
  // للصفحة التالية، والسحب لليمين (سرعة موجبة) يعود للصفحة السابقة.
  void _handleHorizontalSwipe(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    const double threshold = 250; // تجاهل السحبات الخفيفة العرضية

    if (velocity < -threshold) {
      _goToNextPage();
    } else if (velocity > threshold) {
      _goToPreviousPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    ColoredTitle currentTitleData =
        onboardingData[_currentPage]["title"] as ColoredTitle;

    return Scaffold(
      // يسمح بالتنقل بين الصفحات عبر السحب بالإصبع (وليس فقط زر "التالي").
      // التخطيط من اليمين لليسار: السحب لليسار = الصفحة التالية، لليمين = السابقة.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600), // مدة تأثير التلاشي
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            ); // تأثير التلاشي
          },
          child: OnboardingPage(
            // يجب أن يكون لكل صفحة مفتاح فريد لكي يعمل AnimatedSwitcher بشكل صحيح
            key: ValueKey<int>(_currentPage),
            titleData: currentTitleData,
            description: onboardingData[_currentPage]["description"]!,
            imagePath: onboardingData[_currentPage]["imagePath"]!,
            currentPage: _currentPage,
            totalPages: onboardingData.length,
            onNext: _goToNextPage,
            onSkip: _skipToLastPage,
            onBack: _goToPreviousPage,
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final ColoredTitle titleData;
  final String description;
  final String imagePath;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  const OnboardingPage({
    super.key,
    required this.titleData,
    required this.description,
    required this.imagePath,
    required int currentPage,
    required this.totalPages,
    this.onNext,
    this.onSkip,
    this.onBack,
  }) : currentPage = currentPage; // تم إصلاح التعيين هنا

  TextSpan _buildColoredTitle(
    String fullText,
    String? coloredWord,
    Color? coloredWordColor,
    Color defaultColor,
  ) {
    if (coloredWord == null || coloredWordColor == null) {
      return TextSpan(
        text: fullText,
        style: TextStyle(
          color: defaultColor,
          fontWeight: FontWeight.bold,
          fontSize: 26,
          height: 1.5,
        ),
      );
    }

    final List<TextSpan> spans = [];
    final List<String> parts = fullText.split(' ');

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (part.contains(coloredWord)) {
        final int startIndex = part.indexOf(coloredWord);
        if (startIndex != -1) {
          if (startIndex > 0) {
            spans.add(
              TextSpan(
                text: part.substring(0, startIndex),
                style: TextStyle(color: defaultColor),
              ),
            );
          }
          spans.add(
            TextSpan(
              text: coloredWord,
              style: TextStyle(color: coloredWordColor),
            ),
          );
          if (startIndex + coloredWord.length < part.length) {
            spans.add(
              TextSpan(
                text: part.substring(startIndex + coloredWord.length),
                style: TextStyle(color: defaultColor),
              ),
            );
          }
        } else {
          spans.add(
            TextSpan(
              text: part,
              style: TextStyle(color: defaultColor),
            ),
          );
        }
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: TextStyle(color: defaultColor),
          ),
        );
      }

      if (i < parts.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return TextSpan(
      children: spans,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 26,
        height: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color mainRed = Color(0xFFBF002D);
    const Color lightPink = Color(0xFFFFE7EC);
    const Color textBlack = Colors.black;
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    final bool isLastPage = currentPage == totalPages - 1;
    final bool isFirstPage = currentPage == 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24.0,
                        left: 24.0,
                        right: 24.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isFirstPage)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: lightPink,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: mainRed,
                                  size: 24,
                                ),
                                onPressed: onBack,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            )
                          else
                            const SizedBox(width: 40),
                          if (!isLastPage)
                            OutlinedButton(
                              onPressed: onSkip,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "تخطى",
                                    style: TextStyle(
                                      color: textBlack,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_left,
                                    size: 20,
                                    color: textBlack,
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Text.rich(
                            _buildColoredTitle(
                              titleData.fullText,
                              titleData.coloredWord,
                              titleData.coloredWordColor,
                              textBlack,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // المؤشر يبدأ من أقصى اليسار في الصفحة الأولى ويتحرك لليمين
                    // مع التقدّم — لذلك نفرض اتجاه LTR على صف النقاط فقط.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalPages, (index) {
                          bool isActive = index == currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 10,
                            width: isActive ? 24 : 10,
                            decoration: BoxDecoration(
                              color: isActive ? mainRed : Colors.pink[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: isLastPage
                              ? const Text(
                                  "ابدأ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "التالي",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.0),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
