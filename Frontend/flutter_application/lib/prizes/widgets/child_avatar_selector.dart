// lib/prizes/widgets/child_avatar_selector.dart
//
// Horizontal row of selectable child avatars (74x74) with green check badge
// on the selected one. Used in the Add/Edit prize form.

import 'package:flutter/material.dart';
import 'package:Ajial/tasks/models/child_task_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kCheck = Color(0xFF01A449);
const String _kFont = 'IBM Plex Sans Arabic';

class ChildAvatarSelector extends StatelessWidget {
  final List<ChildTaskModel> children;
  final String? selectedChildId;
  final void Function(String childId) onSelect;
  final bool readOnly;

  const ChildAvatarSelector({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onSelect,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'لا يوجد أطفال يمكن إضافة مكافأة لهم',
          style: TextStyle(
              fontFamily: _kFont, fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = children[i];
          final selected = c.childId == selectedChildId;
          return GestureDetector(
            onTap: readOnly ? null : () => onSelect(c.childId),
            child: SizedBox(
              width: 74,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? _kCheck : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: _avatar(c),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: _kCheck,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(ChildTaskModel c) {
    final url = c.profileImageUrl;
    final isDefault = url == null || url.isEmpty || url.contains('/defaults/');
    if (isDefault) {
      final letter = c.fullName.isNotEmpty ? c.fullName.substring(0, 1) : '?';
      return Container(
        color: _kPrimary.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _kPrimary),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: 74,
      height: 74,
      errorBuilder: (_, __, ___) => Container(
        color: _kPrimary.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: const Icon(Icons.child_care, color: _kPrimary, size: 30),
      ),
    );
  }
}
