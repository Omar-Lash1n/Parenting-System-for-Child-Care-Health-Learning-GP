// lib/prizes/prize_onboarding_overlay.dart
//
// 4-step onboarding shown the first time a parent opens the prize store.
// Renders as a centered card on top of a dimmed background, with "تخطي"
// (skip) and "التالي" (next) actions and dot indicators.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

const String _kPrefSeenKey = 'ajial_prizes_onboarding_seen_v1';

class _Step {
  final String image;
  final String title;
  final String description;
  const _Step(this.image, this.title, this.description);
}

const String _kImgBase =
    'images/olive-green-wall 1';

const List<_Step> _kSteps = [
  _Step(
    '$_kImgBase (2).png',
    'ابني ثقة حقيقية',
    'قم بتسليم الطفل المكافئات التي تم اسبابها اليه',
  ),
  _Step(
    '$_kImgBase (3).png',
    'قم بمتابعة الطفل',
    'يمكنك متابعة تقدم الطفل للمهام المنسبة اليه',
  ),
  _Step(
    '$_kImgBase (4).png',
    'اضف المكافئة',
    'اضف مكافئة بدوية من خلالك حيث سيتم اظهارها عند جانب الطفل',
  ),
  _Step(
    '$_kImgBase (5).png',
    'قم بمكافأة طفلك على انجازاته',
    'يمكنك اضافة مكافئات لطفلك للتشجيع على تنفيذ المهام المنسبة اليهم',
  ),
];

/// Returns true if the onboarding has not been seen yet.
Future<bool> shouldShowPrizesOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kPrefSeenKey) ?? false);
}

Future<void> markPrizesOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPrefSeenKey, true);
}

/// Shows the prize store onboarding modal. Resolves when the user finishes
/// or skips. Marks the flow as "seen" so it won't appear again.
Future<void> showPrizesOnboarding(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    barrierDismissible: false,
    builder: (_) => const _PrizesOnboardingDialog(),
  );
  await markPrizesOnboardingSeen();
}

class _PrizesOnboardingDialog extends StatefulWidget {
  const _PrizesOnboardingDialog();

  @override
  State<_PrizesOnboardingDialog> createState() =>
      _PrizesOnboardingDialogState();
}

class _PrizesOnboardingDialogState extends State<_PrizesOnboardingDialog> {
  int _index = 0;

  void _next() {
    if (_index < _kSteps.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.pop(context);
    }
  }

  void _skip() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final step = _kSteps[_index];
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 318,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 39, 15, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image circle
                    Container(
                      width: 130,
                      height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE3EA),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        step.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.card_giftcard,
                          color: _kPrimary,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_kSteps.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? _kPrimary
                                : _kPrimary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _skip,
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'تخطي',
                              style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _next,
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              _index == _kSteps.length - 1 ? 'ابدأ' : 'التالي',
                              style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              // Top-left close badge
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: _skip,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.close,
                        size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
