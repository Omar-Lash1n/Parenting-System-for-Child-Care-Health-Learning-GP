import 'package:flutter/material.dart';

class ConsultationOnboardingDialog extends StatefulWidget {
  const ConsultationOnboardingDialog({super.key});

  @override
  State<ConsultationOnboardingDialog> createState() =>
      _ConsultationOnboardingDialogState();
}

class _ConsultationOnboardingDialogState
    extends State<ConsultationOnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'images/consultations/img3.jpg',
      'title': 'راحتكم فى اطمئنانكم على طفلكم',
      'subtitle':
          'نحن هنا لنكون بجانبكم في رحلة رعاية\nأطفالكم، ونوفر لكم الدعم الطبي الموثوق',
      'alignment': Alignment.centerLeft, // Show the child on the left
    },
    {
      'image': 'images/consultations/img1.jpg',
      'title': 'عيادة الطبيب .. في منزلك',
      'subtitle':
          'استشر أفضل الأطباء والاختصاصيين عبر\nمكالمة فيديو آمنة ومباشرة',
    },
    {
      'image': 'images/consultations/img4.jpg',
      'title': 'كل تفاصيل الجلسة محفوظة',
      'subtitle': 'ستحصل على روشتة إلكترونية واضحة\nوتشخيص طبي',
    },
    {
      'image': 'images/consultations/img2.jpg',
      'title': 'يمكنكم ايضاً الحجز داخل العيادة',
      'subtitle': 'فريق دعم فني متواجد دائماً لخدمتكم\nومساعدتكم.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Close dialog on last step
    }
  }

  void _skip() {
    Navigator.pop(context); // Close dialog
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close Button at Top Right
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Top Right in RTL
                children: [
                  GestureDetector(
                    onTap: _skip,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9), // Light gray background
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Circular Image
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(page['image']!),
                                fit: BoxFit.cover,
                                alignment: page['alignment'] ?? Alignment.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Title
                          Text(
                            page['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans Arabic',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Text(
                            page['subtitle']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans Arabic',
                              fontSize: 14,
                              color: Color(0xFF475569), // Text gray
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFFBF092F) // Primary color
                          : const Color(0xFFF1C1C8), // Light pink
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  // Next Button (التالي) - Will be on the right in RTL because it's first
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBF092F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'ابدأ' : 'التالى',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Skip Button (تخطي) - Will be on the left in RTL because it's second
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: const BorderSide(
                            color: Color(0xFF64748B), width: 1), // Gray border
                      ),
                      child: const Text(
                        'تخطي',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans Arabic',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showConsultationOnboardingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: ConsultationOnboardingDialog(),
      );
    },
  );
}
