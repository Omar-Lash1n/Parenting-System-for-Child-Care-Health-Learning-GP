// lib/prizes/widgets/prize_card_widget.dart
//
// One prize card: child avatar, prize image, title, completion text,
// task checklist, stars progress, deliver/edit actions.

import 'package:flutter/material.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';
import 'package:Ajial/prizes/models/prize_task_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kStarColor = Color(0xFFFE8401);
const Color _kCheck = Color(0xFF01A449);
const String _kFont = 'IBM Plex Sans Arabic';

class PrizeCardWidget extends StatefulWidget {
  final PrizeDetail prize;
  final bool isDelivering;
  final VoidCallback? onDeliver;
  final VoidCallback? onEdit;

  const PrizeCardWidget({
    super.key,
    required this.prize,
    this.isDelivering = false,
    this.onDeliver,
    this.onEdit,
  });

  @override
  State<PrizeCardWidget> createState() => _PrizeCardWidgetState();
}

class _PrizeCardWidgetState extends State<PrizeCardWidget> {
  bool _showAllTasks = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.prize;
    final isDelivered = p.isDelivered;
    final percent = p.totalRequiredTasks == 0
        ? 0
        : ((p.completedTasksCount / p.totalRequiredTasks) * 100).round();

    final subtitle = isDelivered || p.isReady
        ? 'تم اتمام المكافئة'
        : 'نسبة اتمام المكافئة $percent%';

    return GestureDetector(
      onTap: widget.onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              prize: p,
              subtitle: subtitle,
            ),
            const SizedBox(height: 16),
            ..._buildTaskRows(p),
            const SizedBox(height: 8),
            _StarsProgressRow(prize: p),
            const SizedBox(height: 12),
            _DeliveryButton(
              prize: p,
              isDelivering: widget.isDelivering,
              onTap: widget.onDeliver,
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: p.requiredTasks.length > 2
                  ? () => setState(() => _showAllTasks = !_showAllTasks)
                  : null,
              child: Container(
                width: double.infinity,
                height: 36,
                alignment: Alignment.center,
                child: Text(
                  p.requiredTasks.length > 2
                      ? (_showAllTasks ? 'إخفاء المهام' : 'عرض جميع المهام')
                      : 'عرض جميع المهام',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.requiredTasks.length > 2
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTaskRows(PrizeDetail p) {
    final tasks = _showAllTasks
        ? p.requiredTasks
        : p.requiredTasks.take(2).toList();
    return [
      for (final t in tasks)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TaskRow(task: t),
        ),
    ];
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final PrizeDetail prize;
  final String subtitle;
  const _Header({required this.prize, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ChildAvatar(
          fullName: prize.childFullName,
          imageUrl: prize.childProfileImageUrl,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prize.title,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PrizeImage(imageUrl: prize.imageUrl),
      ],
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  final String fullName;
  final String? imageUrl;
  const _ChildAvatar({required this.fullName, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final letter = fullName.isNotEmpty ? fullName.substring(0, 1) : '?';
    final isDefault =
        imageUrl == null || imageUrl!.isEmpty || imageUrl!.contains('/defaults/');
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kPrimary.withValues(alpha: 0.12),
      ),
      alignment: Alignment.center,
      child: isDefault
          ? Text(
              letter,
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            )
          : ClipOval(
              child: Image.network(
                imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  letter,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                ),
              ),
            ),
    );
  }
}

class _PrizeImage extends StatelessWidget {
  final String? imageUrl;
  const _PrizeImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final has = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF5F5F5),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: has
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: 55,
              height: 55,
              errorBuilder: (_, __, ___) => Image.asset(
                'images/gift.png',
                width: 26,
                height: 26,
                color: _kPrimary,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.card_giftcard, color: _kPrimary, size: 26),
              ),
            )
          : Image.asset(
              'images/gift.png',
              width: 26,
              height: 26,
              color: _kPrimary,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.card_giftcard, color: _kPrimary, size: 26),
            ),
    );
  }
}

// ─── Task row ───────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final PrizeTask task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              task.title,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: _kFont, fontSize: 14, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? _kCheck : Colors.transparent,
              border: task.isCompleted
                  ? null
                  : Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Stars progress row ────────────────────────────────────────────────────

class _StarsProgressRow extends StatelessWidget {
  final PrizeDetail prize;
  const _StarsProgressRow({required this.prize});

  @override
  Widget build(BuildContext context) {
    final isDone = prize.currentStars >= prize.requiredStars;
    final remainingText = isDone
        ? 'تم اتمام ${prize.requiredStars} نجمة'
        : 'متبقي ${prize.remainingStars} نجمة';
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Image.asset(
          'images/star shape.png',
          width: 22,
          height: 22,
          color: _kStarColor,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.star, color: _kStarColor, size: 22),
        ),
        const SizedBox(width: 6),
        Text(
          '${prize.currentStars}/${prize.requiredStars}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black),
        ),
        const Spacer(),
        Text(
          remainingText,
          textDirection: TextDirection.rtl,
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              color: isDone ? _kCheck : const Color(0xFF64748B)),
        ),
      ],
    );
  }
}

// ─── Delivery button ───────────────────────────────────────────────────────

class _DeliveryButton extends StatelessWidget {
  final PrizeDetail prize;
  final bool isDelivering;
  final VoidCallback? onTap;
  const _DeliveryButton({
    required this.prize,
    required this.isDelivering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final delivered = prize.isDelivered;
    final canDeliver = prize.canDeliver && !delivered;

    final label = delivered ? 'تم تسليم المكافئة' : 'تسليم المكافئة';
    final bg = delivered
        ? const Color(0xFFEFEFEF)
        : (canDeliver ? _kPrimary : Colors.white);
    final fg = delivered
        ? Colors.black54
        : (canDeliver ? Colors.white : Colors.black);
    final borderColor = (delivered || canDeliver)
        ? Colors.transparent
        : Colors.black.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: (delivered || isDelivering) ? null : onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(50),
          border: borderColor == Colors.transparent
              ? null
              : Border.all(color: borderColor),
        ),
        child: isDelivering
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: fg,
                  strokeWidth: 2.5,
                ),
              )
            : Text(label,
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: fg)),
      ),
    );
  }
}
