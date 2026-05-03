import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Ajial/family/models/child_model.dart';
import 'package:Ajial/homepage/widgets/section_header.dart';
import 'package:Ajial/profile/my_child_profile.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kGreen = Color(0xFF01A449);
const String _kFont = 'IBM Plex Sans Arabic';

class ChildrenSection extends StatelessWidget {
  final List<ChildModel> children;
  final VoidCallback onAddChildTap;
  final VoidCallback onShowAllTap;

  const ChildrenSection({
    super.key,
    required this.children,
    required this.onAddChildTap,
    required this.onShowAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'الأطفال', onShowAllTap: onShowAllTap),
        Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: children.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == children.length) {
                  return _AddChildCard(onTap: onAddChildTap);
                }
                final child = children[index];
                return _ChildProfileCard(child: child);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  final ChildModel child;

  const _ChildProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyChildProfilePage(childId: child.childId)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 130,
        height: 160,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Column(
          children: [
            _ChildAvatar(
              imageUrl: child.photoUrl,
              name: child.fullName,
              isActive: child.isActive,
            ),
            const SizedBox(height: 6),
            Text(
              child.fullName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              child.ageText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w400,
                color: Color(0x80000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool isActive;

  const _ChildAvatar({
    required this.imageUrl,
    required this.name,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.substring(0, 1) : 'ط';
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0x26FE8401),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialCircle(initial: initial),
                  )
                : _InitialCircle(initial: initial),
          ),
          if (isActive)
            Positioned(
              right: 2,
              bottom: 8,
              child: Container(
                width: 16,
                height: 16,
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

class _InitialCircle extends StatelessWidget {
  final String initial;

  const _InitialCircle({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: _kFont,
          color: _kPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddChildCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChildCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: const Color(0xFFD9D9D9),
          radius: 12,
          dashWidth: 6,
          dashSpace: 5,
        ),
        child: SizedBox(
          width: 130,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                painter: _DashedCirclePainter(
                  color: const Color(0xFFD9D9D9),
                  dashWidth: 4,
                  dashSpace: 4,
                ),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    size: 34,
                    color: Color(0x80000000),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'اضف طفل',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0x80000000),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: math.min(size.width, size.height) / 2,
      ));
    _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint,
  double dashWidth,
  double dashSpace,
) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + dashWidth, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += dashWidth + dashSpace;
    }
  }
}
