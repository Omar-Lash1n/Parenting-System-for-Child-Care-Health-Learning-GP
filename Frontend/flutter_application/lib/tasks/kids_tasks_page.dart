// lib/tasks/kids_tasks_page.dart
//
// "مهام أطفالي" tab — fetches from GET /api/ChildTask/parent/{parentId}/children
// Sorted: eligible → inactive account → no account → locked by age
// Card layout (RTL): photo on right | name+age in centre | stars on left

import 'package:flutter/material.dart';
import 'package:Ajial/tasks/models/child_task_model.dart';
import 'package:Ajial/tasks/repositories/child_task_repository.dart';
import 'package:Ajial/tasks/add_kids_task_sheet.dart';
import 'package:Ajial/family/models/child_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class KidsTasksPage extends StatefulWidget {
  const KidsTasksPage({super.key});

  @override
  State<KidsTasksPage> createState() => _KidsTasksPageState();
}

class _KidsTasksPageState extends State<KidsTasksPage> {
  final _repo = ChildTaskRepository();
  late Future<List<ChildTaskModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchChildren();
  }

  void _refresh() => setState(() => _future = _repo.fetchChildren());

  /// Sort: eligible → inactive account → no account → locked by age
  List<ChildTaskModel> _sorted(List<ChildTaskModel> raw) {
    int priority(ChildTaskModel c) {
      if (c.isEligible) return 0;
      if (c.needsAccountActivation) return 1;
      if (c.needsAccountCreation) return 2;
      return 3; // locked by age
    }

    final list = [...raw];
    list.sort((a, b) => priority(a).compareTo(priority(b)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildTaskModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kPrimary));
        }
        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: _refresh,
          );
        }

        final children = _sorted(snapshot.data ?? []);

        if (children.isEmpty) {
          return _EmptyKidsState(onAddChild: () => _showAddChildPopup(context));
        }

        return RefreshIndicator(
          color: _kPrimary,
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final child = children[i];
              if (child.isLockedByAge) return _LockedChildCard(child: child);
              if (child.needsAccountCreation) return _NoAccountChildCard(child: child);
              if (child.needsAccountActivation) return _InactiveAccountCard(child: child);
              return _ActiveChildCard(child: child, onAssign: _openAssign);
            },
          ),
        );
      },
    );
  }

  void _openAssign(ChildTaskModel child) {
    final stub = ChildModel(
      childId: child.childId,
      fullName: child.fullName,
      photoUrl: child.profileImageUrl,
      age: child.ageYears,
      isActive: true,
      hasAccount: true,
      prizeCount: child.totalStars,
    );
    showAssignTaskSheet(context, stub);
  }

  void _showAddChildPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const _AddChildPopup(),
    );
  }
}

// ─────────────────── Error View ──────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kPrimary, size: 48),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _kFont, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              onPressed: onRetry,
              child: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: _kFont, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Empty State ─────────────────────────────────────────────

class _EmptyKidsState extends StatelessWidget {
  final VoidCallback onAddChild;
  const _EmptyKidsState({required this.onAddChild});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onAddChild,
          child: Container(
            width: double.infinity,
            height: 172,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: CustomPaint(
                        painter: _DashedCirclePainter(),
                        child: Container(
                          width: 74,
                          height: 74,
                          color: Colors.transparent,
                          child: Center(
                            child: Image.asset(
                              'images/happy,happy face,smiley,emoji,smile,.png',
                              width: 34,
                              height: 34,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.sentiment_satisfied_alt,
                                  size: 34,
                                  color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('اضغط لاضافة طفلك',
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────── Shared card base ────────────────────────────────────────
// RTL layout: Photo (right) | Name+Age (centre) | Stars badge (left)

class _CardLayout extends StatelessWidget {
  final ChildTaskModel child;
  final bool showStars;
  final bool starsDimmed;
  final bool usePhotoAvatar; // true → network photo, false → baby icon
  final bool showOnlineDot;
  final List<Widget> bottomButtons;

  const _CardLayout({
    required this.child,
    this.showStars = true,
    this.starsDimmed = false,
    this.usePhotoAvatar = false,
    this.showOnlineDot = false,
    required this.bottomButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // ── Info row ──
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // Photo (right in RTL)
              if (usePhotoAvatar)
                Stack(children: [
                  _ChildAvatar(photoUrl: child.profileImageUrl, size: 80),
                  if (showOnlineDot)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Center(
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                                color: Color(0xFF01A449),
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                ])
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'images/happy,happy face,smiley,emoji,smile,.png',
                      width: 32,
                      height: 32,
                      color: _kPrimary,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.child_care,
                          size: 36,
                          color: _kPrimary),
                    ),
                  ),
                ),

              const SizedBox(width: 12),

              // Name + age (centre, expands)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      child.fullName,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(child.ageText,
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 14,
                                color: Color(0xFF64748B))),
                        const SizedBox(width: 4),
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Color(0xFF64748B)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Stars badge (left in RTL)
              if (showStars)
                Opacity(
                  opacity: starsDimmed ? 0.5 : 1.0,
                  child: _StarsBadge(count: child.totalStars),
                ),
            ],
          ),

          if (bottomButtons.isNotEmpty) ...[
            const SizedBox(height: 22),
            ...bottomButtons,
          ],
        ],
      ),
    );
  }
}

// ─────────────────── Card 1: Active / Eligible ────────────────────────────────

class _ActiveChildCard extends StatelessWidget {
  final ChildTaskModel child;
  final void Function(ChildTaskModel) onAssign;
  const _ActiveChildCard({required this.child, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    return _CardLayout(
      child: child,
      starsDimmed: false,
      usePhotoAvatar: true,
      showOnlineDot: true,
      bottomButtons: [
        _OutlinedBtn(label: 'انساب مهمة', onTap: () => onAssign(child)),
        const SizedBox(height: 8),
        _PlainBtn(label: 'عرض جميع المهام', onTap: () {}),
      ],
    );
  }
}

// ─────────────────── Card 2: Account not activated ────────────────────────────

class _InactiveAccountCard extends StatelessWidget {
  final ChildTaskModel child;
  const _InactiveAccountCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return _CardLayout(
      child: child,
      starsDimmed: true,
      usePhotoAvatar: false,
      bottomButtons: [
        _OutlinedBtn(label: 'تفعيل الحساب', onTap: () {}),
        const SizedBox(height: 8),
        _PlainBtn(label: 'عرض جميع المهام', onTap: () {}),
      ],
    );
  }
}

// ─────────────────── Card 3: No account ──────────────────────────────────────

class _NoAccountChildCard extends StatelessWidget {
  final ChildTaskModel child;
  const _NoAccountChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return _CardLayout(
      child: child,
      showStars: true,
      starsDimmed: true,
      usePhotoAvatar: false,
      bottomButtons: [
        _OutlinedBtn(label: 'انشاء حساب', onTap: () {}),
      ],
    );
  }
}

// ─────────────────── Card 4: Locked (< 4 years) ──────────────────────────────

class _LockedChildCard extends StatelessWidget {
  final ChildTaskModel child;
  const _LockedChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _CardLayout(
          child: child,
          showStars: true,
          starsDimmed: true,
          usePhotoAvatar: true,
          bottomButtons: [
            _OutlinedBtn(label: 'فتح الملف', onTap: () {}),
          ],
        ),
        // Dark overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_outline,
                        size: 38, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.lockedReason ??
                        'ميزة المهام تفتح عند إتمام الطفل 4 سنوات',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── Shared sub-widgets ──────────────────────────────────────

class _StarsBadge extends StatelessWidget {
  final int count;
  const _StarsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFE8401).withValues(alpha: 0.05),
        border:
            Border.all(color: const Color(0xFFFE8401).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'images/star shape.png',
            width: 24,
            height: 24,
            color: const Color(0xFFFE8401),
            errorBuilder: (_, __, ___) => const Icon(Icons.star,
                size: 22, color: Color(0xFFFE8401)),
          ),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
        ],
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const _ChildAvatar({this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0E0E0),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: !hasPhoto
          ? ClipOval(
              child: Image.asset(
                'images/default image.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.child_care,
                    color: _kPrimary),
              ),
            )
          : null,
    );
  }
}

class _OutlinedBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlinedBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
      ),
    );
  }
}

class _PlainBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlainBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 40,
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
      ),
    );
  }
}

// ─────────────────── Add Child Popup ─────────────────────────────────────────

class _AddChildPopup extends StatelessWidget {
  const _AddChildPopup();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 318,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Center(
                  child: Image.asset(
                    'images/happy,happy face,smiley,emoji,smile,.png',
                    width: 39,
                    height: 39,
                    color: _kPrimary,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.child_care, size: 39, color: _kPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('اضف طفلك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'يمكنك انساب المهام لاطفالك الموجودين\nبالفعل على النظام و اكبر من 4 اعوام',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('الغاء',
                          style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/add-child');
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(50)),
                      alignment: Alignment.center,
                      child: const Text('اضف طفل',
                          style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Custom painters ─────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0, dashSpace = 4.0;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(24)));
    _dash(canvas, path, paint, dashWidth, dashSpace);
  }

  void _dash(Canvas c, Path p, Paint paint, double dw, double ds) {
    final total = dw + ds;
    for (final m in p.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final len = (d + dw).clamp(0.0, m.length);
        c.drawPath(m.extractPath(d, len), paint);
        d += total;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2,
        Paint()..color = Colors.black.withValues(alpha: 0.05));
    const dashCount = 24;
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2 - 1;
    const step = 3.14159 * 2 / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          i * step, step * 0.7, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
