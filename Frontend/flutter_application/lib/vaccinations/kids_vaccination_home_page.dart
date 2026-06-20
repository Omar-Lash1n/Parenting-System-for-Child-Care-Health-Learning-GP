// lib/vaccinations/kids_vaccination_home_page.dart
//
// Kids Vaccination Home Page — the main entry point for the
// vaccination feature. Shows a child placeholder card, quick-access
// feature grid, and a primary CTA to retake the vaccination survey.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/family/models/child_model.dart';
import 'package:Ajial/vaccinations/widgets/select_child_bottom_sheet.dart';
import 'package:Ajial/vaccinations/widgets/confirm_reset_vaccination_dialog.dart';
import 'package:Ajial/api/auth_service.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x1ABF092F); // 10 %
const Color _kOrange = Color(0xFFFE8401);
const Color _kGreen = Color(0xFF01A449);
const Color _kBlue = Color(0xFF0EA5E9);
const Color _kDashedBorder = Color(0x40000000); // 25 % black
const String _kFont = 'IBM Plex Sans Arabic';

// ─────────────────────────────────────────────
// KidsVaccinationHomePage — Entry Widget
// ─────────────────────────────────────────────
class KidsVaccinationHomePage extends StatefulWidget {
  const KidsVaccinationHomePage({super.key});

  @override
  State<KidsVaccinationHomePage> createState() =>
      _KidsVaccinationHomePageState();
}

class _KidsVaccinationHomePageState extends State<KidsVaccinationHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().loadChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              const _VaccinationHeader(),
              const SizedBox(height: 16),

              // ── Content (scrollable) ────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Kids profile section (dynamic) ──────
                      Consumer<FamilyProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading) {
                            return const SizedBox(
                              height: 99,
                              child: Center(
                                child:
                                    CircularProgressIndicator(color: _kPrimary),
                              ),
                            );
                          }
                          if (provider.hasChildren) {
                            return _ChildrenRow(children: provider.children);
                          }
                          return const _EmptyChildCard();
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Section title ───────────────────────
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'اهم ما تحتاجه',
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 2×2 Feature Grid ────────────────────
                      const _FeatureGrid(),
                    ],
                  ),
                ),
              ),

              // ── Primary CTA ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _PrimaryCTA(
                  label: 'اعادة ملئ استبيان التطعيم',
                  onTap: () async {
                    final selectedChild = await showSelectChildSheet(context);
                    if (selectedChild != null && context.mounted) {
                      // Show confirmation dialog
                      final confirmed =
                          await showConfirmResetVaccinationDialog(context);
                      if (confirmed == true && context.mounted) {
                        Navigator.pushNamed(
                          context,
                          '/vaccination-welcome',
                          arguments: {
                            'childId': selectedChild.childId,
                            'childName': selectedChild.fullName,
                            'childProfileImageUrl': selectedChild.photoUrl,
                          },
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _VaccinationHeader
// ─────────────────────────────────────────────
class _VaccinationHeader extends StatelessWidget {
  const _VaccinationHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button (rightmost in RTL)
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: _kPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title
          const Text(
            'التطعيمات',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _EmptyChildCard — dashed border placeholder
// ─────────────────────────────────────────────
class _EmptyChildCard extends StatelessWidget {
  const _EmptyChildCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/add-child');
      },
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: _kDashedBorder,
          radius: 24,
          dashWidth: 6,
          dashSpace: 5,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dashed circle with smiley icon
              Opacity(
                opacity: 0.5,
                child: CustomPaint(
                  painter: _DashedCirclePainter(
                    color: _kDashedBorder,
                    dashWidth: 4,
                    dashSpace: 4,
                  ),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Color(0x0D000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: 34,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'اضغط لاضافة طفلك لاستخدام التطعيمات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ChildrenRow — horizontal scrollable avatars
// ─────────────────────────────────────────────
class _ChildrenRow extends StatelessWidget {
  final List<ChildModel> children;
  const _ChildrenRow({required this.children});

  /// Handles tapping a child avatar:
  /// 1. Calls GET /api/Vaccination/welcome/{childId}
  /// 2. Routes based on [hasCompletedVaccinationSurvey]
  Future<void> _onChildTapped(BuildContext context, ChildModel child) async {
    // Show a loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _kPrimary),
      ),
    );

    try {
      final data =
          await AuthService().getVaccinationWelcome(child.childId);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      if (data == null) {
        // API failed — fall back to welcome page
        Navigator.pushNamed(
          context,
          '/vaccination-welcome',
          arguments: {
            'childId': child.childId,
            'childName': child.fullName,
            'childProfileImageUrl': child.photoUrl,
          },
        );
        return;
      }

      final bool hasCompleted =
          data['hasCompletedVaccinationSurvey'] == true;

      if (hasCompleted) {
        // TODO: Navigate to the vaccination summary / dashboard page
        // (route will be provided by the user — placeholder for now)
        Navigator.pushNamed(
          context,
          '/vaccination-dashboard', // ← placeholder route
          arguments: {
            'childId': child.childId,
            'childName': child.fullName,
            'childProfileImageUrl': child.photoUrl,
          },
        );
      } else {
        Navigator.pushNamed(
          context,
          '/vaccination-welcome',
          arguments: {
            'childId': child.childId,
            'childName': child.fullName,
            'childProfileImageUrl': child.photoUrl,
          },
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      // On error, fallback to welcome page
      Navigator.pushNamed(
        context,
        '/vaccination-welcome',
        arguments: {
          'childId': child.childId,
          'childName': child.fullName,
          'childProfileImageUrl': child.photoUrl,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 99,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // RTL is already set by parent Directionality
        children: [
          // ── Child avatars (rightmost in RTL) ─────
          ...children.map((child) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _ChildAvatar(
                  child: child,
                  onTap: () => _onChildTapped(context, child),
                ),
              )),

          // ── "اضف طفل" dashed circle (leftmost in RTL) ──
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _AddChildAvatar(
              onTap: () => Navigator.pushNamed(context, '/add-child'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _AddChildAvatar — dashed circle with smiley + label
// ─────────────────────────────────────────────
class _AddChildAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChildAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.5,
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dashed circle with smiley
              CustomPaint(
                painter: _DashedCirclePainter(
                  color: _kDashedBorder,
                  dashWidth: 4,
                  dashSpace: 4,
                ),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0x0D000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    size: 34,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'اضف طفل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ChildAvatar — circular photo + name
// ─────────────────────────────────────────────
class _ChildAvatar extends StatelessWidget {
  final ChildModel child;
  final VoidCallback? onTap;
  const _ChildAvatar({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo circle
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                    ? Image.network(
                        child.photoUrl!,
                        fit: BoxFit.cover,
                        width: 74,
                        height: 74,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 34,
                          color: Color(0xFFBDBDBD),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: Color(0xFFBDBDBD),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            // Name
            Text(
              child.fullName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _FeatureGrid — 2×2 quick-access buttons
// ─────────────────────────────────────────────
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Row 1 ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _FeatureButton(
                label: 'مراكز تطعيم',
                imagePath: 'images/location pin.png',
                iconColor: _kOrange,
                bgColor: _kOrange.withOpacity(0.05),
                onTap: () {
                  Navigator.pushNamed(context, '/health-unit-search');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureButton(
                label: 'ملخص التطعيمات',
                imagePath: 'images/medical file.png',
                iconColor: _kPrimary,
                bgColor: _kPrimary.withOpacity(0.05),
                onTap: () {
                  // TODO: navigate to vaccination summary
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ── Row 2 ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _FeatureButton(
                label: 'استشر طبيب',
                imagePath: 'images/typing.png',
                iconColor: _kBlue,
                bgColor: _kBlue.withOpacity(0.05),
                onTap: () {
                  Navigator.pushNamed(context, '/parent-consultations');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureButton(
                label: 'جدول التطعيمات',
                imagePath: 'images/download file.png',
                iconColor: _kGreen,
                bgColor: _kGreen.withOpacity(0.05),
                onTap: () {
                  // TODO: navigate to vaccination schedule
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _FeatureButton — single grid card
// ─────────────────────────────────────────────
class _FeatureButton extends StatelessWidget {
  final String label;
  final String imagePath;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.label,
    required this.imagePath,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 114,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // ~10 % black
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _PrimaryCTA — full-width red button
// ─────────────────────────────────────────────
class _PrimaryCTA extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryCTA({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainters (same logic used in family_page)
// ─────────────────────────────────────────────

/// Dashed rounded rectangle border.
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  const _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => false;
}

/// Dashed circle border.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const _DashedCirclePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final actualDash = dashWidth / radius;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * 2 * math.pi / dashCount;
      final sweepAngle = actualDash;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}
