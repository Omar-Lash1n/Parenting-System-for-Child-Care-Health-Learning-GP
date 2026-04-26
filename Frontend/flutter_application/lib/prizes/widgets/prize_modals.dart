// lib/prizes/widgets/prize_modals.dart
//
// All confirmation/result dialogs for the prizes feature.

import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kSuccess = Color(0xFF01A449);
const String _kFont = 'IBM Plex Sans Arabic';

// ─── Shared building blocks ──────────────────────────────────────────────────

class _DialogShell extends StatelessWidget {
  final Widget child;
  const _DialogShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(width: 318, child: child),
      ),
    );
  }
}

class _CloseBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.1),
        ),
        child: const Icon(Icons.close, size: 20, color: Colors.black),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final Color background;
  final Widget child;
  const _IconCircle({required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
      ),
    );
  }
}

// ─── 1. Success after create ─────────────────────────────────────────────────

enum CreateSuccessAction { view, edit }

Future<CreateSuccessAction?> showPrizeCreateSuccessDialog(
  BuildContext context, {
  required String childFullName,
}) {
  return showDialog<CreateSuccessAction>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DialogShell(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 39, 15, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconCircle(
                  background: _kSuccess.withValues(alpha: 0.1),
                  child: const Icon(Icons.check_circle,
                      color: _kSuccess, size: 48),
                ),
                const SizedBox(height: 22),
                Text(
                  'تم اضافة مكافئة عند $childFullName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black),
                ),
                const SizedBox(height: 6),
                const Text(
                  'يمكنك متابعة اتمام الطفل من\nمتجر مكافئات الاطفال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                      height: 1.5),
                ),
                const SizedBox(height: 33),
                Row(children: [
                  Expanded(
                    child: _OutlineBtn(
                      label: 'تعديل المكافئة',
                      onTap: () => Navigator.pop(
                          context, CreateSuccessAction.edit),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryBtn(
                      label: 'عرض المكافئة',
                      color: _kSuccess,
                      textColor: Colors.white,
                      onTap: () => Navigator.pop(
                          context, CreateSuccessAction.view),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _CloseBadge(onTap: () => Navigator.pop(context)),
          ),
        ],
      ),
    ),
  );
}

// ─── 2. Confirm delete ──────────────────────────────────────────────────────

Future<bool> showPrizeDeleteConfirmDialog(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DialogShell(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 39, 15, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconCircle(
                  background: const Color(0xFFFF0000).withValues(alpha: 0.1),
                  child: Image.asset(
                    'images/Exclamation Mark.png',
                    width: 39,
                    height: 39,
                    color: const Color(0xFFFF0000),
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: Color(0xFFFF0000)),
                  ),
                ),
                const SizedBox(height: 22),
                const Text('حذف المكافأة؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                const SizedBox(height: 6),
                const Text(
                  'سوف يتم حذف المكافأة من هنا ومن عند\nالطفل كذلك و عدم استرجاعها مرة اخرى',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                      height: 1.5),
                ),
                const SizedBox(height: 33),
                Row(children: [
                  Expanded(
                    child: _OutlineBtn(
                      label: 'لا, الغاء',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryBtn(
                      label: 'نعم, حذف',
                      color: const Color(0xFFFF0000),
                      textColor: Colors.white,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _CloseBadge(onTap: () => Navigator.pop(context, false)),
          ),
        ],
      ),
    ),
  );
  return res ?? false;
}

// ─── 3. Confirm deliver ────────────────────────────────────────────────────

Future<bool> showPrizeDeliverConfirmDialog(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DialogShell(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 39, 15, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconCircle(
                  background: _kPrimary.withValues(alpha: 0.1),
                  child: Image.asset(
                    'images/gift.png',
                    width: 36,
                    height: 36,
                    color: _kPrimary,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.card_giftcard,
                            size: 36, color: _kPrimary),
                  ),
                ),
                const SizedBox(height: 22),
                const Text('تأكيد تسليم المكافأة؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                const SizedBox(height: 6),
                const Text(
                  'سيتم تسليم المكافأة للطفل مع تقيد\nمعلش للطفل بالمكافأة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                      height: 1.5),
                ),
                const SizedBox(height: 33),
                Row(children: [
                  Expanded(
                    child: _OutlineBtn(
                      label: 'لا, الغاء',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryBtn(
                      label: 'نعم, تسليم',
                      color: _kPrimary,
                      textColor: Colors.white,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _CloseBadge(onTap: () => Navigator.pop(context, false)),
          ),
        ],
      ),
    ),
  );
  return res ?? false;
}

// ─── 4. Generic info / error modal (single OK button) ──────────────────────

Future<void> showPrizeDeliveryCelebrationDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: SizedBox(
              width: 318,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.75, end: 1),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'images/zeina.png',
                            height: 150,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _IconCircle(
                              background: _kSuccess.withValues(alpha: 0.1),
                              child: const Icon(Icons.celebration,
                                  color: _kSuccess, size: 46),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'تم تسليم المكافأة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'احتفل مع الطفل بإنجازه الرائع',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _PrimaryBtn(
                          label: 'حسناً',
                          color: _kSuccess,
                          textColor: Colors.white,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _CloseBadge(onTap: () => Navigator.pop(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showPrizeInfoDialog(
  BuildContext context, {
  required String message,
  String okLabel = 'حسناً',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _DialogShell(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 39, 15, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconCircle(
                  background: _kPrimary.withValues(alpha: 0.1),
                  child: const Icon(Icons.info_outline,
                      size: 40, color: _kPrimary),
                ),
                const SizedBox(height: 22),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.5)),
                const SizedBox(height: 24),
                _PrimaryBtn(
                  label: okLabel,
                  color: _kPrimary,
                  textColor: Colors.white,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _CloseBadge(onTap: () => Navigator.pop(context)),
          ),
        ],
      ),
    ),
  );
}
