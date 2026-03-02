// lib/family/family_page.dart
//
// Family / Children List Page — connected to GET /Parents/children via
// FamilyProvider. Supports loading, error, empty, and populated states.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/family/models/child_model.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x1ABF092F); // 10% opacity
const Color _kGreen = Color(0xFF01A449);
const Color _kGreenLight = Color(0x1A01A449); // 10% opacity
const Color _kDeleteRed = Color(0xFFFF0000);
const Color _kDarkText = Color(0xFF1E293B);
const Color _kGreyText = Color(0xFF64748B);
const Color _kBorder = Color(0x1A000000); // 10% black
const Color _kDashedBorder = Color(0x40000000); // 25% black
const String _kFont = 'IBM Plex Sans Arabic';

// ─────────────────────────────────────────────
// FamilyPage — Entry Widget
// ─────────────────────────────────────────────
class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  @override
  void initState() {
    super.initState();
    // Fetch children from the API as soon as the page opens.
    // Using addPostFrameCallback to ensure the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().loadChildren();
    });
  }

  void _deleteChild(ChildModel child) {
    context.read<FamilyProvider>().removeChild(child.childId);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Consumer<FamilyProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // ── Header ──────────────────────────────────
                  const _FamilyHeader(),
                  const SizedBox(height: 16),

                  // ── Content Area ───────────────────────────────
                  Expanded(
                    child: _buildContent(provider),
                  ),

                  // ── Primary CTA ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _PrimaryActionButton(
                      onTap: () {}, // TODO: navigate to add-child flow
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the correct content widget based on [FamilyProvider] state.
  Widget _buildContent(FamilyProvider provider) {
    switch (provider.status) {
      // ── Loading ──────────────────────────────────
      case FamilyStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: _kPrimary),
        );

      // ── Error ─────────────────────────────────────
      case FamilyStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 64, color: _kGreyText),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage ?? 'حدث خطأ غير متوقع',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    color: _kGreyText,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<FamilyProvider>().loadChildren(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة',
                      style: TextStyle(fontFamily: _kFont)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ],
            ),
          ),
        );

      // ── Loaded with children ───────────────────────
      case FamilyStatus.loaded when provider.hasChildren:
        return _ChildrenList(
          children: provider.children,
          onDelete: _deleteChild,
        );

      // ── Empty (loaded but no children) | initial ───
      default:
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 172,
            child: const _EmptyChildrenState(),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────
// _FamilyHeader
// ─────────────────────────────────────────────
class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Title + Back Button — FIRST = rightmost in RTL
          Row(
            children: [
              // Arrow circle — FIRST = rightmost in RTL
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
              // Title — LAST = left of arrow in RTL
              const Text(
                'عائلتي',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          // ── "اضف طفل" pill button — LAST = leftmost in RTL
          _AddChildPill(onTap: () {}),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _AddChildPill
// ─────────────────────────────────────────────
class _AddChildPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChildPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kDashedBorder),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اضف طفل',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.emoji_emotions_outlined,
                color: _kPrimary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _EmptyChildrenState — State 1
// ─────────────────────────────────────────────
class _EmptyChildrenState extends StatelessWidget {
  const _EmptyChildrenState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: _kDashedBorder,
          radius: 24,
          dashWidth: 6,
          dashSpace: 5,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                'اضغط لاضافة طفلك',
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
// _ChildrenList — State 2 / 3 (list of cards)
// ─────────────────────────────────────────────
class _ChildrenList extends StatelessWidget {
  final List<ChildModel> children;
  final void Function(ChildModel) onDelete;
  const _ChildrenList({required this.children, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _ChildCard(
        child: children[index],
        onDelete: () => onDelete(children[index]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ChildCard — The core child card component
// ─────────────────────────────────────────────
class _ChildCard extends StatelessWidget {
  final ChildModel child;
  final VoidCallback onDelete;
  const _ChildCard({required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar — FIRST = rightmost in RTL
                _ChildAvatar(
                  // photoUrl from API — null shows placeholder icon
                  avatarUrl: child.photoUrl,
                  // isActive from API — true = show green dot, false = hide it
                  isOnline: child.isActive,
                ),

                const SizedBox(width: 12),

                // ── Name + Age
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // fullName from API
                          child.fullName,
                          style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _kDarkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: _kGreyText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              child.ageText,
                              style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: _kGreyText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── ⋮ Menu — LAST = leftmost in RTL
                _CardPopupMenu(
                  childName: child.fullName,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Bottom row: Badge pill (right) | فتح الملف button (left)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show badge only when child has at least one prize
              if (child.prizeCount > 0)
                _BadgePill(count: child.prizeCount)
              else
                const SizedBox.shrink(),
              GestureDetector(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'فتح الملف',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 12,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ChildAvatar — 80×80 circle with online dot
// ─────────────────────────────────────────────
class _ChildAvatar extends StatelessWidget {
  final String? avatarUrl; // nullable — loaded from DB
  final bool isOnline; // true = green dot is shown
  const _ChildAvatar({required this.avatarUrl, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Avatar circle — shows network image when URL is available,
          // falls back to a grey placeholder icon from DB URL not yet loaded.
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: const Color(0xFFF0F0F0), // placeholder bg
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? (avatarUrl!.startsWith('http')
                      // Network URL (from DB)
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 44,
                            color: Color(0xFFBDBDBD),
                          ),
                        )
                      // Local asset path
                      : Image.asset(
                          avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 44,
                            color: Color(0xFFBDBDBD),
                          ),
                        ))
                  : const Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: Color(0xFFBDBDBD),
                    ),
            ),
          ),
          // Green online dot — only shown when child is currently active
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 4,
              child: Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: _kGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _BadgePill — green pill with ribbon icon + count
// ─────────────────────────────────────────────
class _BadgePill extends StatelessWidget {
  final int count;
  const _BadgePill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kGreenLight,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal icon — FIRST = rightmost in RTL
          const Icon(Icons.workspace_premium_outlined,
              color: _kGreen, size: 18),
          const SizedBox(width: 4),
          // Count text — LAST = left of icon in RTL
          Text(
            '$count وسام إنجاز',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _CardPopupMenu — The ⋮ ellipsis menu (State 3)
// ─────────────────────────────────────────────
class _CardPopupMenu extends StatelessWidget {
  final String childName;
  final VoidCallback onDelete;
  const _CardPopupMenu({required this.childName, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert, color: Colors.black87, size: 24),
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: const Color(0x40000000),
      color: Colors.white,
      itemBuilder: (context) => [
        // ── 1. فتح الملف
        const PopupMenuItem<String>(
          value: 'open',
          child: _PopupRow(
            label: 'فتح الملف',
            icon: Icons.open_in_new_rounded,
            color: Colors.black,
          ),
        ),
        // ── Divider
        const PopupMenuDivider(height: 1),
        // ── 2. تعديل البيانات
        const PopupMenuItem<String>(
          value: 'edit',
          child: _PopupRow(
            label: 'تعديل البيانات',
            icon: Icons.edit_outlined,
            color: Colors.black,
          ),
        ),
        // ── Divider
        const PopupMenuDivider(height: 1),
        // ── 3. حذف ملف الطفل (red)
        const PopupMenuItem<String>(
          value: 'delete',
          child: _PopupRow(
            label: 'حذف ملف الطفل',
            icon: Icons.delete_outline_rounded,
            color: _kDeleteRed,
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'open':
            debugPrint('Open profile: $childName');
            break;
          case 'edit':
            debugPrint('Edit data: $childName');
            break;
          case 'delete':
            // Removes this child's card from the list.
            // If this was the last child, the empty state is shown automatically.
            onDelete();
            break;
        }
      },
    );
  }
}

// ─────────────────────────────────────────────
// _PopupRow — Shared popup menu item row
// ─────────────────────────────────────────────
class _PopupRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _PopupRow({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, color: color, size: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _PrimaryActionButton
// ─────────────────────────────────────────────
class _PrimaryActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryActionButton({required this.onTap});

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
        child: const Text(
          'اضف طفلك',
          style: TextStyle(
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
// CustomPainters
// ─────────────────────────────────────────────

/// Dashed rounded rectangle border (for the empty state outer card).
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

/// Dashed circle border (for the smiley icon frame in the empty state).
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
