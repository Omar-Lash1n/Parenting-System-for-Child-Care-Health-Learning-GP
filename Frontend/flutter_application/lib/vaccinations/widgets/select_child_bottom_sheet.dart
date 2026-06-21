// lib/vaccinations/widgets/select_child_bottom_sheet.dart
//
// "اختر الطفل" bottom sheet — shown when the user taps
// "اعادة ملئ استبيان التطعيم". Loads children from FamilyProvider
// and lets the user pick which child to continue with.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/family/models/child_model.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x1ABF092F); // 10 %
const Color _kDashedBorder = Color(0x40000000); // 25 % black
const Color _kGreyText = Color(0xFF64748B);
const String _kFont = 'IBM Plex Sans Arabic';

// ─────────────────────────────────────────────
// Public API — call this from anywhere
// ─────────────────────────────────────────────

/// Shows the "اختر الطفل" modal bottom sheet.
///
/// [actionLabel] is the confirm-button text (defaults to the survey flow).
/// When [appendChildName] is true, the selected child's name is appended
/// (e.g. "... ل أحمد"); set it to false to keep the label fixed.
///
/// Returns the selected [ChildModel] or `null` if dismissed.
Future<ChildModel?> showSelectChildSheet(
  BuildContext context, {
  String actionLabel = 'اعادة استبيان التطعيم',
  bool appendChildName = true,
}) {
  // Make sure children are loaded
  final familyProvider = context.read<FamilyProvider>();
  if (familyProvider.status == FamilyStatus.initial) {
    familyProvider.loadChildren();
  }

  return showModalBottomSheet<ChildModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectChildSheet(
      actionLabel: actionLabel,
      appendChildName: appendChildName,
    ),
  );
}

// ─────────────────────────────────────────────
// _SelectChildSheet — The sheet content
// ─────────────────────────────────────────────
class _SelectChildSheet extends StatefulWidget {
  final String actionLabel;
  final bool appendChildName;

  const _SelectChildSheet({
    required this.actionLabel,
    required this.appendChildName,
  });

  @override
  State<_SelectChildSheet> createState() => _SelectChildSheetState();
}

class _SelectChildSheetState extends State<_SelectChildSheet> {
  ChildModel? _selectedChild;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FamilyProvider>();
      if (provider.status == FamilyStatus.initial ||
          provider.status == FamilyStatus.error) {
        provider.loadChildren();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000), // ~15 %
                blurRadius: 15,
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // ── Header (non-scrollable) ──────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _buildHeader(context),
                ),
                const SizedBox(height: 16),

                // ── Scrollable content ───────────────────
                Expanded(
                  child: Consumer<FamilyProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: _kPrimary),
                        );
                      }
                      if (!provider.hasChildren) {
                        return _buildEmptyState(context, scrollController);
                      }
                      return _buildChildrenList(
                          provider.children, scrollController);
                    },
                  ),
                ),

                // ── CTA button (non-scrollable) ─────────
                Consumer<FamilyProvider>(
                  builder: (context, provider, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: _buildCTA(context, provider),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title
        const Text(
          'اختر الطفل',
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        // Close button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0x1A000000), // 10 % black
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 20, color: Colors.black),
          ),
        ),
      ],
    );
  }

  // ── Empty state (no children) ──────────────────────────────

  Widget _buildEmptyState(
      BuildContext context, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // close sheet
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
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: const Text(
                'اضغط لاضافة طفلك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Children list (scrollable cards) ───────────────────────

  Widget _buildChildrenList(
      List<ChildModel> children, ScrollController scrollController) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final child = children[index];
        final isSelected = _selectedChild?.childId == child.childId;
        return _ChildSelectionCard(
          child: child,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedChild = child),
        );
      },
    );
  }

  // ── CTA button ─────────────────────────────────────────────

  Widget _buildCTA(BuildContext context, FamilyProvider provider) {
    final hasSelection = _selectedChild != null;
    final buttonLabel = hasSelection
        ? (widget.appendChildName
            ? '${widget.actionLabel} ل ${_selectedChild!.fullName}'
            : widget.actionLabel)
        : (provider.hasChildren ? widget.actionLabel : 'اضف طفلك');
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (!provider.hasChildren) {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/add-child');
          } else if (_selectedChild != null) {
            Navigator.pop(context, _selectedChild);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          buttonLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ChildSelectionCard — single child card with radio
// ─────────────────────────────────────────────
class _ChildSelectionCard extends StatelessWidget {
  final ChildModel child;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChildSelectionCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryLight : Colors.white,
          border: Border.all(
            color: isSelected ? _kPrimary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kPrimary : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? _kPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                    ? Image.network(
                        child.photoUrl!,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: Color(0xFFBDBDBD),
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Color(0xFFBDBDBD),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + age
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    child.ageText,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _kGreyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dashed Rect Painter (for the empty card)
// ─────────────────────────────────────────────
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
