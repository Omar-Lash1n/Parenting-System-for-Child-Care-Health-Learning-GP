// lib/prizes/widgets/task_selector_dropdown.dart
//
// Dropdown trigger + bottom-sheet menu used to pick required tasks.

import 'package:flutter/material.dart';
import 'package:Ajial/tasks/models/task_list_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kCheck = Color(0xFF01A449);
const String _kFont = 'IBM Plex Sans Arabic';

class TaskSelectorDropdown extends StatelessWidget {
  final List<TaskItem> tasks;
  final Set<String> selectedTaskIds;
  final void Function(String taskId) onToggle;
  final VoidCallback? onAddNewTask;
  final bool loading;
  final bool enabled;

  const TaskSelectorDropdown({
    super.key,
    required this.tasks,
    required this.selectedTaskIds,
    required this.onToggle,
    this.onAddNewTask,
    this.loading = false,
    this.enabled = true,
  });

  String _displayText() {
    if (selectedTaskIds.isEmpty) return 'اختر المهام';
    final names = tasks
        .where((t) => selectedTaskIds.contains(t.taskId))
        .map((t) => t.title)
        .toList();
    if (names.isEmpty) return 'اختر المهام';
    return names.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !enabled
          ? null
          : () => _openSheet(context),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Text(
                _displayText(),
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: selectedTaskIds.isEmpty
                      ? const Color(0xFF999999)
                      : Colors.black,
                ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary),
              )
            else
              const Icon(Icons.keyboard_arrow_down,
                  color: Colors.black54, size: 22),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _TaskSelectorSheet(
        tasks: tasks,
        selectedTaskIds: Set<String>.from(selectedTaskIds),
        onToggle: onToggle,
        onAddNewTask: onAddNewTask,
      ),
    );
  }
}

class _TaskSelectorSheet extends StatefulWidget {
  final List<TaskItem> tasks;
  final Set<String> selectedTaskIds;
  final void Function(String taskId) onToggle;
  final VoidCallback? onAddNewTask;

  const _TaskSelectorSheet({
    required this.tasks,
    required this.selectedTaskIds,
    required this.onToggle,
    this.onAddNewTask,
  });

  @override
  State<_TaskSelectorSheet> createState() => _TaskSelectorSheetState();
}

class _TaskSelectorSheetState extends State<_TaskSelectorSheet> {
  late Set<String> _local;

  @override
  void initState() {
    super.initState();
    _local = Set<String>.from(widget.selectedTaskIds);
  }

  void _toggle(String id) {
    setState(() {
      if (_local.contains(id)) {
        _local.remove(id);
      } else {
        _local.add(id);
      }
    });
    widget.onToggle(id);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            if (widget.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'لا توجد مهام متاحة لهذا الطفل',
                  style: TextStyle(
                      fontFamily: _kFont, fontSize: 14, color: Colors.black54),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.tasks.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 1, color: Color(0x14000000)),
                  itemBuilder: (context, i) {
                    final t = widget.tasks[i];
                    final isChecked = _local.contains(t.taskId);
                    return InkWell(
                      onTap: () => _toggle(t.taskId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 14,
                                    color: Colors.black),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isChecked ? _kCheck : Colors.transparent,
                                border: Border.all(
                                  color: isChecked
                                      ? _kCheck
                                      : Colors.black.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (widget.onAddNewTask != null) ...[
              const Divider(height: 1, thickness: 1, color: Color(0x14000000)),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddNewTask?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: const [
                      Expanded(
                        child: Text(
                          'اضافة مهمة جديدة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 14,
                              color: Colors.black),
                        ),
                      ),
                      Icon(Icons.add_task_outlined,
                          size: 22, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'تم',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
