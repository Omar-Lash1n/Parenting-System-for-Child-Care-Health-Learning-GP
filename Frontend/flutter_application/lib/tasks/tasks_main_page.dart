// --- lib/tasks/tasks_main_page.dart ---
// Main Tasks page with tabs, filters, empty state, FAB, and spotlight instructions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/tasks/widgets/task_instruction_overlay.dart';
import 'package:Ajial/tasks/add_task_sheet.dart';
import 'package:Ajial/tasks/add_kids_task_sheet.dart';
import 'package:Ajial/tasks/kids_tasks_page.dart';
import 'package:Ajial/tasks/models/task_model.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';

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
      final provider = context.read<TasksProvider>();
      provider.checkInstructionsSeen();
      // Always reload from the API each time this page is entered,
      // so newly added categories are visible even after navigation.
      provider.reloadCategories();
      provider.reloadTasks(); // Fetch tasks on init
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

                    // ── Tab content ──────────────────────────────────────────
                    if (provider.activeTab == 1) ...
                      [
                        // "مهام أطفالي" has its own page
                        const Expanded(child: KidsTasksPage()),
                        const SizedBox(height: 70),
                      ]
                    else ...
                      [
                        // "مهامي" — filter chips + task list
                        _FilterChipsRow(
                          activeFilter: provider.activeFilter,
                          onFilterChanged:
                              provider.showInstructions ? null : provider.setFilter,
                        ),
                        Expanded(
                          child: provider.filteredTasks.isEmpty
                              ? _EmptyState(
                                  activeFilter: provider.activeFilter,
                                  filterName:
                                      provider.categories[provider.activeFilter],
                                )
                              : _TaskListView(grouped: provider.groupedTasks),
                        ),
                        const SizedBox(height: 70),
                      ],
                  ],
                ),
              ),

              // ── Dashed arrow (مهامي only, when empty) ──
              if (provider.activeTab == 0 &&
                  provider.filteredTasks.isEmpty &&
                  !provider.showInstructions)
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

              // ── FAB: gift (kids tab) ──
              if (provider.activeTab == 1)
                Positioned(
                  bottom: 148,
                  right: 16,
                  child: _GiftFab(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/prizes'),
                  ),
                ),

              Positioned(
                bottom: 80,
                right: 16,
                child: _TaskFab(
                  fabKey: _fabKey,
                  onPressed: provider.showInstructions
                      ? null
                      : provider.activeTab == 0
                          ? () => showAddTaskSheet(context)
                          : () => showAddKidsTaskSheet(context),
                ),
              ),

              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AppBottomNavBar(currentIndex: 2),
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

  void _showTabMenu(BuildContext context, GlobalKey iconKey) {
    final box = iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: 16,
            top: offset.dy + box.size.height + 4,
            child: Material(
              color: Colors.transparent,
              child: _TabMenuCard(
                onDismiss: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moreKey = GlobalKey();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
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
          const SizedBox(width: 8),
          GestureDetector(
            key: moreKey,
            onTap: () => _showTabMenu(context, moreKey),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.more_vert, color: Color(0xFF666666), size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Three-item menu card ──────────────────────────────────────────────────────

class _TabMenuCard extends StatelessWidget {
  final VoidCallback onDismiss;
  const _TabMenuCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 189,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MenuItem(
            label: 'المهام المنجزة',
            iconAsset: 'images/complete task.png',
            fallbackIcon: Icons.check_circle_outline,
            onTap: () {
              onDismiss();
              Navigator.pushNamed(context, '/tasks-done');
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: Color(0x0D000000)),
          ),
          _MenuItem(
            label: 'اضافة مهمة جديدة',
            iconAsset: 'images/task_vector_icon.png',
            fallbackIcon: Icons.add_task,
            onTap: () {
              onDismiss();
              showAddTaskSheet(context);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: Color(0x0D000000)),
          ),
          _MenuItem(
            label: 'التصنيفات',
            iconAsset: 'images/tag.png',
            fallbackIcon: Icons.label_outline,
            onTap: () {
              onDismiss();
              Navigator.pushNamed(context, '/tasks-categories');
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final String iconAsset;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconAsset,
            width: 20,
            height: 20,
            color: Colors.black.withValues(alpha: 0.5),
            errorBuilder: (_, __, ___) => Icon(
              fallbackIcon,
              size: 20,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              letterSpacing: 0.1,
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
                      color:
                          isActive ? _kPrimaryColor : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isActive ? _kPrimaryColor : const Color(0xFF999999),
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
          final isPast =
              group == TaskGroup.past || group == TaskGroup.yesterday;
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
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
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
                            onTap: () => ScaffoldMessenger.of(context)
                                .hideCurrentSnackBar(),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
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
              isCollapsed ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_up,
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
                ? task.color
                    .withValues(alpha: 0.4) // Faded color when completed
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
                          if (dateStr != null) ...[
                            // hide if no date
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
                      icon: const Icon(Icons.more_horiz,
                          size: 22, color: Color(0xFF888888)),
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      offset: const Offset(0, 30),
                      onSelected: (value) {
                        if (value == 'delete') {
                          context.read<TasksProvider>().removeTask(task.id);
                        } else if (value == 'details') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _TaskDetailSheet(task: task),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          height: 44,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/Pen.png',
                                  width: 18,
                                  height: 18,
                                  color: const Color(0xFF666666),
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
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
                          height: 44,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/Recycle Bin.png',
                                  width: 18,
                                  height: 18,
                                  color: const Color(0xFFFF0000),
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Color(0xFFFF0000),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
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
                backgroundImage:
                    a.imageUrl != null ? NetworkImage(a.imageUrl!) : null,
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
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
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
            errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.post_add_rounded,
                color: Colors.white,
                size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Task Detail / Edit Sheet ────────────────────────────────

const List<Color> _kTaskColors = [
  Color(0xFF94A3B8), // slate
  Color(0xFFBEDBFF), // light blue
  Color(0xFF5D8666), // dark green
  Color(0xFFFE8401), // orange
  Color(0xFFEF4444), // red
  Color(0xFF0EA5E9), // sky blue  ← selected in design
  Color(0xFF22C55E), // green
  Color(0xFFBF092F), // primary red
];

class _TaskDetailSheet extends StatefulWidget {
  final TaskModel task;
  const _TaskDetailSheet({required this.task});

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  late TextEditingController _titleController;
  late Color _selectedColor;
  late String? _selectedCategory;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late Set<String> _selectedAssigneeIds;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _selectedColor = t.color;
    _selectedCategory = t.category;
    _selectedDate = t.date;
    _selectedTime = t.time;
    _selectedAssigneeIds = t.assignees.map((a) {
      if (a.isSelf) return 'self';
      return a.id;
    }).toSet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final familyProv = context.read<FamilyProvider>();
      if (familyProv.status == FamilyStatus.initial) {
        familyProv.loadChildren();
      }
      final parentProv = context.read<ParentProfileProvider>();
      if (parentProv.profileData == null && !parentProv.isLoading) {
        parentProv.fetchProfile();
      }
    });
  }

  List<Assignee> _getComputedAssignees({bool listen = true}) {
    final parentProvider = Provider.of<ParentProfileProvider>(context, listen: listen);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: listen);
    
    final parentName = parentProvider.fullName.isNotEmpty ? parentProvider.fullName : 'حسابي';
    final parentImage = parentProvider.profileImageUrl;
    final assigneesList = <Assignee>[
      Assignee(id: 'self', name: parentName, imageUrl: parentImage, isSelf: true),
    ];

    if (familyProvider.children.isNotEmpty) {
      for (var child in familyProvider.children) {
        assigneesList.add(Assignee(
          id: child.childId,
          name: child.fullName,
          imageUrl: child.photoUrl,
          isSelf: false,
        ));
      }
    } else if (parentProvider.children.isNotEmpty) {
      for (var child in parentProvider.children) {
        assigneesList.add(Assignee(
          id: child['id']?.toString() ?? '',
          name: child['fullName']?.toString() ?? 'طفل',
          imageUrl: child['profileImageUrl']?.toString(),
          isSelf: false,
        ));
      }
    }
    return assigneesList;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _monthName(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month];
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'اختر من القائمة';
    return '${d.day} ${_monthName(d.month)} ${d.year}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'اختر';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'ص' : 'م';
    return '$h:$m $period';
  }

  void _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _save(BuildContext ctx) {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان المهمة')),
      );
      return;
    }
    final provider = ctx.read<TasksProvider>();
    
    // Resolve dynamic categoryId if the name changed
    String catName = _selectedCategory ?? widget.task.category;
    String? catId = widget.task.categoryId;
    if (catName != widget.task.category) {
      if (catName == 'الكل') {
        catId = null;
      } else {
        try {
          final catModel = provider.categoryModels.firstWhere((c) => c.name == catName);
          catId = catModel.id;
        } catch (_) {}
      }
    }

    final assignees = _selectedAssigneeIds
        .map((id) => _getComputedAssignees(listen: false).firstWhere((a) => a.id == id, orElse: () => _getComputedAssignees(listen: false).first))
        .toList();
    final updated = widget.task.copyWith(
      title: title,
      category: catName,
      categoryId: catId, // Include the resolved ID so updateTask has it
      color: _selectedColor,
      date: _selectedDate,
      time: _selectedTime,
      assignees: assignees,
    );
    provider.updateTask(updated);
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF01A449),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 84),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: const Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.check, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم حفظ البيانات الجديدة بنجاح!',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DeleteConfirmDialog(task: widget.task),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<TasksProvider>().removeTask(widget.task.id);
      Navigator.pop(ctx); // close detail sheet
    }
  }

  Widget _separator() =>
      const Divider(color: Color(0xFFE0E0E0), height: 1, thickness: 1);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TasksProvider>();
    final cats = provider.categories.where((c) => c != 'الكل').toList();
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final currentAssignees = _getComputedAssignees();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomPad),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    // Close button (left in RTL = visually right)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.black),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'تعديل المهمة',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 12),

                // ── Title ──────────────────────────────────────────────────
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'عنوان المهمة',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  maxLength: 50,
                  style: const TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color(0x40000000)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color(0x80000000)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 12),

                // ── Category ───────────────────────────────────────────────
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'التصنيف',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0x40000000)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      alignment: AlignmentDirectional.centerEnd,
                      value: _selectedCategory != null &&
                              cats.contains(_selectedCategory)
                          ? _selectedCategory
                          : null,
                      hint: const Text(
                        'اختر من القائمة',
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 22,
                        color: Color(0x80000000),
                      ),
                      items: cats
                          .map((c) => DropdownMenuItem(
                                value: c,
                                alignment: AlignmentDirectional.centerEnd,
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 12),

                // ── Assignees ──────────────────────────────────────────────
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'من اجل',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 79,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: currentAssignees.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final a = currentAssignees[index];
                      final isSelected = _selectedAssigneeIds.contains(a.id);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedAssigneeIds.remove(a.id);
                          } else {
                            _selectedAssigneeIds.add(a.id);
                          }
                        }),
                        child: SizedBox(
                          width: 74,
                          height: 79,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF01A449)
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  backgroundImage: a.imageUrl != null
                                      ? NetworkImage(a.imageUrl!)
                                      : null,
                                  child: a.imageUrl == null
                                      ? (a.isSelf
                                          ? const Icon(Icons.person,
                                              color: Colors.white, size: 32)
                                          : Text(
                                              a.name.characters.first,
                                              style: const TextStyle(
                                                fontFamily: _kFontFamily,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ))
                                      : null,
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF01A449),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 12),

                // ── Color ──────────────────────────────────────────────────
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'اللون',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: _kTaskColors.map((c) {
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 12),

                // ── Date & Time ────────────────────────────────────────────
                Row(
                  children: [
                    // Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'الوقت',
                              style: TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border:
                                    Border.all(color: const Color(0x40000000)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.alarm,
                                    size: 20,
                                    color: Color(0x80000000),
                                  ),
                                  Text(
                                    _formatTime(_selectedTime),
                                    style: const TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'الموعد',
                              style: TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border:
                                    Border.all(color: const Color(0x40000000)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: Color(0x80000000),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _formatDate(_selectedDate),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: _kFontFamily,
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 16),

                // ── Save button ────────────────────────────────────────────
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => _save(ctx),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _kPrimaryColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Delete task button ───────────────────────────────────--
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => _confirmDelete(ctx),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0x80FF0000),
                        ),
                      ),
                      child: const Text(
                        'حذف المهمة',
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF0000),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Delete Confirm Dialog ────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final TaskModel task;
  const _DeleteConfirmDialog({required this.task});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 318,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 39, 15, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning icon circle
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFF0000),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'images/Exclamation Mark.png',
                          width: 39,
                          height: 39,
                          color: const Color(0xFFFF0000),
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.warning_amber_rounded,
                            size: 40,
                            color: Color(0xFFFF0000),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'حذف المهمة؟',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'سوف يتم حذف المهمة نهائياً ولا يمكن\nاستعادتها مرة اخرى',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 33),
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: const Color(0x80000000),
                                ),
                              ),
                              child: const Text(
                                'لا, الغاء',
                                style: TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete confirm button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, true),
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                'نعم, حذف',
                                style: TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close X button (top-left in RTL = visually top-right)
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                    child:
                        const Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Gift FAB (kids tab) ────────────────────────────────────

/// Orange gradient gift FAB — shown in مهام أطفالي tab.
class _GiftFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GiftFab({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEA400), Color(0xFFFD5E00)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 22,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'images/gift.png',
            width: 26,
            height: 26,
            color: Colors.white,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.card_giftcard, size: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
