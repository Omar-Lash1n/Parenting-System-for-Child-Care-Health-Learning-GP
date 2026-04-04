// --- lib/tasks/tasks_main_page.dart ---
// Main Tasks page with tabs, filters, empty state, FAB, and spotlight instructions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/tasks/widgets/task_instruction_overlay.dart';
import 'package:Ajial/tasks/add_task_sheet.dart';
import 'package:Ajial/tasks/models/task_model.dart';

const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

class TasksMainPage extends StatefulWidget {
  const TasksMainPage({super.key});

  @override
  State<TasksMainPage> createState() => _TasksMainPageState();
}

class _TasksMainPageState extends State<TasksMainPage> {
  // GlobalKeys for spotlight targeting
  final GlobalKey _kidsTabKey = GlobalKey();
  final GlobalKey _myTabKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  Rect? _spotlightRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TasksProvider>().checkInstructionsSeen();
    });
  }

  GlobalKey _keyForStep(int step) {
    switch (step) {
      case 0:
        return _myTabKey;
      case 1:
        return _kidsTabKey;
      default:
        return _fabKey;
    }
  }

  Rect? _measureKey(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        if (provider.showInstructions) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final rect = _measureKey(_keyForStep(provider.instructionStep));
            if (rect != null && rect != _spotlightRect) {
              setState(() => _spotlightRect = rect);
            }
          });
        } else if (_spotlightRect != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _spotlightRect = null);
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _TabBarSection(
                      activeTab: provider.activeTab,
                      onTabChanged:
                          provider.showInstructions ? null : provider.switchTab,
                      kidsTabKey: _kidsTabKey,
                      myTabKey: _myTabKey,
                    ),
                    const SizedBox(height: 12),
                    _FilterChipsRow(
                      activeFilter: provider.activeFilter,
                      onFilterChanged:
                          provider.showInstructions ? null : provider.setFilter,
                    ),
                    Expanded(
                      child: provider.filteredTasks.isEmpty
                          ? _EmptyState(
                              activeFilter: provider.activeFilter,
                              filterName: provider.categories[provider.activeFilter],
                            )
                          : _TaskListView(grouped: provider.groupedTasks),
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),

              // ── Dashed arrow: starts from center text, points to FAB ──
              if (provider.filteredTasks.isEmpty && !provider.showInstructions)
                Positioned(
                  bottom: 120,
                  right: 48,
                  width: 140,
                  height: 220,
                  child: Image.asset(
                    'images/task_dashed_arrow.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),

              // ── FAB ──
              Positioned(
                bottom: 80,
                right: 16,
                child: _TaskFab(
                  fabKey: _fabKey,
                  onPressed: provider.showInstructions
                      ? null
                      : () => showAddTaskSheet(context),
                ),
              ),

              // ── Bottom Nav ──
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AppBottomNavBar(currentIndex: 1),
              ),

              // ── Spotlight overlay ──
              if (provider.showInstructions && _spotlightRect != null)
                Positioned.fill(
                  child: TaskInstructionOverlay(
                    spotlightRect: _spotlightRect!,
                    step: provider.instructionStep,
                    onNext: provider.nextInstructionStep,
                    onSkip: provider.skipInstructions,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────── Tab Bar ─────────────────────────────────────────────────

class _TabBarSection extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int>? onTabChanged;
  final GlobalKey kidsTabKey;
  final GlobalKey myTabKey;

  const _TabBarSection({
    required this.activeTab,
    required this.onTabChanged,
    required this.kidsTabKey,
    required this.myTabKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.more_vert, color: Color(0xFF666666), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      tabKey: myTabKey,
                      label: 'مهامي',
                      isActive: activeTab == 0,
                      onTap:
                          onTabChanged != null ? () => onTabChanged!(0) : null,
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      tabKey: kidsTabKey,
                      label: 'مهام اطفالي',
                      isActive: activeTab == 1,
                      onTap:
                          onTabChanged != null ? () => onTabChanged!(1) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final GlobalKey tabKey;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _TabButton({
    required this.tabKey,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: tabKey,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive ? _kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Filter Chips ────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  final int activeFilter;
  final ValueChanged<int>? onFilterChanged;

  const _FilterChipsRow({
    required this.activeFilter,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasksProvider>();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: false,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = activeFilter == index;
          final label = provider.categories[index];
          final count = provider.countForFilter(index);
          return GestureDetector(
            onTap:
                onFilterChanged != null ? () => onFilterChanged!(index) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? _kPrimaryColor : const Color(0xFFF2F2F2),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? _kPrimaryColor
                          : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? _kPrimaryColor
                          : const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────── Task List View (Grouped) ─────────────────────────────────

class _TaskListView extends StatefulWidget {
  final Map<TaskGroup, List<TaskModel>> grouped;

  const _TaskListView({required this.grouped});

  @override
  State<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<_TaskListView> {
  // All sections start expanded
  final Set<TaskGroup> _collapsed = {};

  void _toggle(TaskGroup g) {
    setState(() {
      if (_collapsed.contains(g)) {
        _collapsed.remove(g);
      } else {
        _collapsed.add(g);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TasksProvider>();

    final sections = TaskGroup.values;
    final List<Widget> children = [];

    for (final group in sections) {
      final tasks = widget.grouped[group] ?? [];
      if (tasks.isEmpty) continue;

      final isCollapsed = _collapsed.contains(group);

      // Section header
      children.add(_sectionHeader(group, tasks.length, isCollapsed));

      if (!isCollapsed) {
        for (final task in tasks) {
          final isPast = group == TaskGroup.past || group == TaskGroup.yesterday;
          children.add(
            _TaskCard(
              task: task,
              isPast: isPast,
              onToggleComplete: () {
                final newValue = !task.isCompleted;
                provider.toggleComplete(task.id);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (newValue) {
                  // Task Completed SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10A142),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: const Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'رائع! تم انجاز مهمة جديدة اليوم',
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.check, color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Task Un-completed SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1A1A1A),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              'تم الغاء انجاز "${task.title}"',
                              style: const TextStyle(
                                fontFamily: _kFontFamily,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              provider.toggleComplete(task.id);
                            },
                            child: const Text(
                              'تراجع',
                              style: TextStyle(
                                fontFamily: _kFontFamily,
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          );
          children.add(const SizedBox(height: 8));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: children,
    );
  }

  Widget _sectionHeader(TaskGroup group, int count, bool isCollapsed) {
    return GestureDetector(
      onTap: () => _toggle(group),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Arrow icon
            Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_left
                  : Icons.keyboard_arrow_up,
              size: 20,
              color: const Color(0xFF888888),
            ),
            const SizedBox(width: 6),
            Text(
              group.label,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isPast;
  final VoidCallback onToggleComplete;

  const _TaskCard({
    required this.task,
    required this.isPast,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final date = task.date;
    final dateStr = date != null
        ? '${date.day} ${_monthName(date.month)} ${date.year}'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          right: BorderSide(
            color: task.isCompleted
                ? task.color.withValues(alpha: 0.4) // Faded color when completed
                : task.color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── RIGHT: completion circle + title + date ──────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Completion circle — tapping toggles done
                    GestureDetector(
                      onTap: onToggleComplete,
                      child: Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2, left: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isCompleted
                              ? const Color(0xFFC4C4C4)
                              : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted
                                ? const Color(0xFFC4C4C4)
                                : const Color(0xFFBBBBBB),
                            width: 2,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                    ),

                    // Title + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: task.isCompleted
                                  ? const Color(0xFFAAAAAA)
                                  : const Color(0xFF333333),
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: const Color(0xFFAAAAAA),
                            ),
                          ),
                          if (dateStr != null) ...[  // hide if no date
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 12,
                                    color: (isPast && !task.isCompleted)
                                        ? const Color(0xFFFF0000)
                                        : const Color(0xFF888888)),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 11,
                                    color: task.isCompleted
                                        ? const Color(0xFFAAAAAA)
                                        : (isPast
                                            ? const Color(0xFFFF0000)
                                            : const Color(0xFF888888)),
                                    fontWeight: (isPast && !task.isCompleted)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── LEFT: three-dot menu (top) + assignee avatars (below) ────
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Three horizontal dots menu
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 22, color: Color(0xFF888888)),
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      offset: const Offset(0, 30),
                      onSelected: (value) {
                        if (value == 'delete') {
                          context.read<TasksProvider>().removeTask(task.id);
                        } else if (value == 'details') {
                          // Details logic to be added later
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          height: 40,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: const [
                                Icon(Icons.edit_outlined, size: 18, color: Color(0xFF666666)),
                                SizedBox(width: 10),
                                Text(
                                  'عرض التفاصيل',
                                  style: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'delete',
                          height: 40,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: const [
                                Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF0000)),
                                SizedBox(width: 10),
                                Text(
                                  'حذف',
                                  style: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    color: Color(0xFFFF0000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Assignee stacked avatars — hide when none selected
                  if (task.assignees.isNotEmpty) _assigneeAvatars(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assigneeAvatars() {
    const double avatarRadius = 14.0;
    const double overlap = 10.0; // how much each avatar shifts left
    final assignees = task.assignees;
    final count = assignees.length;
    final totalWidth = avatarRadius * 2 + (count - 1) * overlap;

    return SizedBox(
      width: totalWidth.clamp(28.0, 100.0),
      height: avatarRadius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final a = assignees[i];
          // Each subsequent avatar shifts left by overlap px
          return Positioned(
            left: i * overlap,
            child: Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: task.color.withValues(alpha: 0.2),
                backgroundImage: a.imageUrl != null
                    ? NetworkImage(a.imageUrl!)
                    : null,
                child: a.imageUrl == null
                    ? (a.isSelf
                        ? Icon(Icons.person, size: 14, color: task.color)
                        : Text(
                            a.name.characters.first,
                            style: TextStyle(
                              fontFamily: _kFontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: task.color,
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



  String _monthName(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }
}


// ─────────────────── Empty State ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int activeFilter;
  final String filterName;

  const _EmptyState({
    required this.activeFilter,
    required this.filterName,
  });

  String _getMessage() {
    if (activeFilter == 0) {
      return 'يبدو انه لا يتوفر مهام تم اضافتها،\nاضغط على دائرة اضافة مهمة';
    }
    return 'يبدو انه لا يتوفر مهام في تصنيف\n"$filterName"';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Box icon image
          Image.asset(
            'images/task_box.png',
            width: 70,
            height: 70,
            color: const Color(0xFFBBBBBB),
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.inventory_2_outlined,
              size: 70,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          // Filter-dependent message
          Text(
            _getMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── FAB ─────────────────────────────────────────────────────

class _TaskFab extends StatelessWidget {
  final GlobalKey fabKey;
  final VoidCallback? onPressed;

  const _TaskFab({required this.fabKey, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        key: fabKey,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _kPrimaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimaryColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'images/task_vector_icon.png',
            width: 26,
            height: 26,
            color: Colors.white,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.post_add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
