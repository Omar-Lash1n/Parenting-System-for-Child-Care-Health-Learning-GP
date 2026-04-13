// --- lib/tasks/tasks_done_page.dart ---
// Page showing all completed tasks, grouped by completion date.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/tasks/models/task_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class TasksDonePage extends StatefulWidget {
  const TasksDonePage({super.key});

  @override
  State<TasksDonePage> createState() => _TasksDonePageState();
}

class _TasksDonePageState extends State<TasksDonePage> {

  String _monthName(int m) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[m];
  }

  String _formatDate(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

  Map<String, List<TaskModel>> _groupByDate(List<TaskModel> tasks) {
    final Map<String, List<TaskModel>> map = {};
    for (final t in tasks) {
      final key = t.date != null ? _formatDate(t.date!) : _formatDate(t.createdAt);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TasksProvider>().loadDoneTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasksProvider>();
    final doneTasks = provider.allTasks.where((t) => t.isCompleted).toList();
    final grouped = _groupByDate(doneTasks);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Expanded(
                        child: Text(
                          'المهام المنجزة',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: _kPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Task list ────────────────────────────────────────────────
                Expanded(
                  child: doneTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد مهام منجزة بعد',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 14,
                              color: Color(0xFF888888),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                          children: _buildSections(grouped),
                        ),
                ),
              ],
            ),
          ),

          // ── Bottom Nav ────────────────────────────────────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavBar(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(Map<String, List<TaskModel>> grouped) {
    final List<Widget> widgets = [];
    for (final entry in grouped.entries) {
      // Section header
      widgets.add(_SectionHeader(dateLabel: entry.key));
      widgets.add(const SizedBox(height: 12));
      for (final task in entry.value) {
        widgets.add(_DoneTaskCard(task: task));
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String dateLabel;
  const _SectionHeader({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Opacity(
        opacity: 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_up, size: 22, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              dateLabel,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
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

// ── Done task card ─────────────────────────────────────────────────────────────

class _DoneTaskCard extends StatelessWidget {
  final TaskModel task;
  const _DoneTaskCard({required this.task});

  String _monthName(int m) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = task.date != null;
    final hasAssignees = task.assignees.isNotEmpty;

    return Opacity(
      opacity: 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            right: BorderSide(color: task.color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: dots | title + check
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Three dots (decorative)
                  const Icon(
                    Icons.more_horiz,
                    size: 22,
                    color: Color(0x80000000),
                  ),
                  // Title + check badge
                  Row(
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gray check circle
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0x80000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Row: assignees + date (only if at least one exists)
              if (hasDate || hasAssignees) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date info
                    if (hasDate)
                      Opacity(
                        opacity: 0.5,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.date!.day} ${_monthName(task.date!.month)} ${task.date!.year}',
                              style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Assignee stacked avatars
                    if (hasAssignees) _StackedAvatars(task: task),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stacked assignee avatars ───────────────────────────────────────────────────

class _StackedAvatars extends StatelessWidget {
  final TaskModel task;
  const _StackedAvatars({required this.task});

  @override
  Widget build(BuildContext context) {
    const double size = 34.0;
    const double shift = 14.0;
    final assignees = task.assignees;
    final count = assignees.length;
    final totalWidth = size + (count - 1) * shift;

    return SizedBox(
      width: totalWidth.clamp(size, 120.0),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final a = assignees[i];
          return Positioned(
            right: i * shift,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                color: const Color(0xFFE0E0E0),
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: task.color.withValues(alpha: 0.2),
                backgroundImage:
                    a.imageUrl != null ? NetworkImage(a.imageUrl!) : null,
                child: a.imageUrl == null
                    ? (a.isSelf
                        ? const Icon(Icons.person, size: 16, color: Colors.white)
                        : Text(
                            a.name.characters.first,
                            style: const TextStyle(
                              fontFamily: _kFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ))
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
