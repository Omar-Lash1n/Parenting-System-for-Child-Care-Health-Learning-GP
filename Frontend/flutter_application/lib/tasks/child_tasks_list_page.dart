// lib/tasks/child_tasks_list_page.dart
//
// Full task list for a single child.
// Uses GET /api/ChildTask/child/{childId}
// Toggle: PATCH /api/ChildTask/{taskId}/child/{childId}/complete
// Delete: DELETE /api/ChildTask/{taskId}/child/{childId}
// Detail: opens TaskDetailPage

import 'package:flutter/material.dart';
import 'package:Ajial/tasks/models/task_list_model.dart';
import 'package:Ajial/tasks/repositories/child_task_repository.dart';
import 'package:Ajial/tasks/task_detail_page.dart';
import 'package:Ajial/tasks/add_kids_task_sheet.dart';
import 'package:Ajial/family/models/child_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class ChildTasksListPage extends StatefulWidget {
  final String childId;
  final String fullName;
  final String? profileImageUrl;
  final String ageText; // e.g. "5 سنوات , 4 أشهر"

  const ChildTasksListPage({
    super.key,
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
    this.ageText = '',
  });

  @override
  State<ChildTasksListPage> createState() => _ChildTasksListPageState();
}

class _ChildTasksListPageState extends State<ChildTasksListPage> {
  final _repo = ChildTaskRepository();
  late Future<ChildTasksResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchChildTasks(widget.childId);
  }

  void _refresh() {
    setState(() => _future = _repo.fetchChildTasks(widget.childId));
  }

  String get _firstName => widget.fullName.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: FutureBuilder<ChildTasksResponse>(
            future: _future,
            builder: (context, snap) {
              return Column(
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  // ── Child mini-card ──────────────────────────────────────
                  if (snap.hasData)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ChildInfoCard(
                        fullName: widget.fullName,
                        profileImageUrl: widget.profileImageUrl,
                        totalStars: snap.data!.totalStars,
                        ageText: widget.ageText,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // ── Body ────────────────────────────────────────────────
                  Expanded(
                    child: _buildBody(snap),
                  ),
                ],
              );
            },
          ),
        ),
        // FAB — on visual right (startFloat in RTL)
        floatingActionButton: FloatingActionButton(
          backgroundColor: _kPrimary,
          shape: const CircleBorder(),
          child: Image.asset(
            'images/edit chat.png',
            width: 26,
            height: 26,
            color: Colors.white,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.edit_outlined, color: Colors.white, size: 26),
          ),
          onPressed: () {
            final stub = ChildModel(
              childId: widget.childId,
              fullName: widget.fullName,
              photoUrl: widget.profileImageUrl,
              age: 0,
              isActive: true,
              hasAccount: true,
              prizeCount: 0,
            );
            showAssignTaskSheet(context, stub).then((_) => _refresh());
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Close button — far right
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Title: "مهام [firstname]"
          Text(
            'مهام $_firstName',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<ChildTasksResponse> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (snap.hasError) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: _kPrimary, size: 48),
          const SizedBox(height: 12),
          Text(snap.error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _kFont, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50))),
            onPressed: _refresh,
            child: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: _kFont, color: Colors.white)),
          ),
        ]),
      );
    }
    final data = snap.data!;
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // ── Pending tasks ────────────────────────────────────────────────
          if (data.pendingTasks.isNotEmpty) ...[
            _SectionHeader(label: 'المهام الحالية'),
            const SizedBox(height: 12),
            ...data.pendingTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskCard(
                    task: t,
                    childId: widget.childId,
                    onToggle: () => _toggle(t),
                    onDelete: () => _confirmDelete(t),
                    onViewDetail: () => _openDetail(t.taskId),
                  ),
                )),
          ],
          // ── Completed tasks ──────────────────────────────────────────────
          if (data.completedTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionHeader(label: 'المهام المنجزة'),
            const SizedBox(height: 12),
            ...data.completedTasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: 0.5,
                    child: _TaskCard(
                      task: t,
                      childId: widget.childId,
                      onToggle: () => _toggle(t),
                      onDelete: () => _confirmDelete(t),
                      onViewDetail: () => _openDetail(t.taskId),
                    ),
                  ),
                )),
          ],
          if (data.pendingTasks.isEmpty && data.completedTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text('لا توجد مهام بعد',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        color: Colors.black54)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggle(TaskItem task) async {
    try {
      await _repo.toggleTaskComplete(task.taskId, widget.childId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontFamily: _kFont)),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  void _confirmDelete(TaskItem task) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DeleteConfirmDialog(
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context);
          await _deleteTask(task);
        },
      ),
    );
  }

  Future<void> _deleteTask(TaskItem task) async {
    try {
      await _repo.deleteTask(task.taskId, widget.childId);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontFamily: _kFont)),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  void _openDetail(String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(
          taskId: taskId,
          childId: widget.childId,
        ),
      ),
    ).then((_) => _refresh());
  }
}

// ─── Child info mini-card ─────────────────────────────────────────────────────

class _ChildInfoCard extends StatelessWidget {
  final String fullName;
  final String? profileImageUrl;
  final int totalStars;
  final String ageText;

  const _ChildInfoCard({
    required this.fullName,
    this.profileImageUrl,
    required this.totalStars,
    this.ageText = '',
  });

  bool get _isDefault =>
      profileImageUrl == null ||
      profileImageUrl!.isEmpty ||
      profileImageUrl!.contains('/defaults/');

  String get _firstLetter {
    final n = fullName.trim();
    return n.isNotEmpty ? n.substring(0, 1) : '؟';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Photo or letter avatar — far right
          Stack(
            children: [
              _isDefault
                  ? Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _firstLetter,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Image.network(
                        profileImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: _kPrimary.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: Text(
                            _firstLetter,
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary),
                          ),
                        ),
                      ),
                    ),
              // Online green dot
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
                          color: Color(0xFF01A449), shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + age (right-aligned, grows)
          Expanded(
            child: Column(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (ageText.isNotEmpty) ...
                  [
                    const SizedBox(height: 2),
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ageText,
                          style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Stars badge — far left
          _StarsBadge(count: totalStars),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_arrow_up, size: 24),
          const SizedBox(width: 4),
          Text(label,
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

// ─── Task card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final String childId;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onViewDetail;
  const _TaskCard({
    required this.task,
    required this.childId,
    required this.onToggle,
    required this.onDelete,
    required this.onViewDetail,
  });

  String _dateLabel() {
    if (task.recurrenceSummary != null && task.recurrenceSummary!.isNotEmpty) {
      return task.recurrenceSummary!;
    }
    if (task.dueDate != null) {
      final d = task.dueDate!;
      return '${d.day}/${d.month}/${d.year}';
    }
    return 'بدون موعد';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: _kPrimary, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Top row: menu | title + check ──────────────────────────────
            Row(
              textDirection: TextDirection.rtl,
              children: [
                // Title + check (right side)
                Expanded(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Check toggle
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isCompleted
                                ? const Color(0xFF01A449)
                                : Colors.transparent,
                            border: task.isCompleted
                                ? null
                                : Border.all(
                                    color: const Color(0xFFD9D9D9), width: 1.5),
                          ),
                          child: task.isCompleted
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Three-dots menu — left
                _TaskMenuButton(
                  onViewDetail: onViewDetail,
                  onDelete: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Bottom row: date (right) | stars (left) ──────────────────
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date / recurrence — RIGHT
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dateLabel(),
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 12,
                          color: Colors.black),
                    ),
                    const SizedBox(width: 4),
                    const Opacity(
                        opacity: 0.5,
                        child: Icon(Icons.calendar_today_outlined, size: 16)),
                  ],
                ),
                // Stars badge — LEFT
                _StarsBadgeSm(count: task.stars),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Three-dots menu button ───────────────────────────────────────────────────

class _TaskMenuButton extends StatelessWidget {
  final VoidCallback onViewDetail;
  final VoidCallback onDelete;
  const _TaskMenuButton(
      {required this.onViewDetail, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: const Opacity(
        opacity: 0.5,
        child: Icon(Icons.more_horiz, size: 24),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: pos,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'detail',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('عرض التفاصيل',
                    style: TextStyle(fontFamily: _kFont, fontSize: 14)),
                SizedBox(width: 8),
                Opacity(
                    opacity: 0.5, child: Icon(Icons.edit_outlined, size: 20)),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text('حذف',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        color: Colors.red)),
                SizedBox(width: 8),
                Icon(Icons.delete_outline, size: 20, color: Colors.red),
              ],
            ),
          ),
        ),
      ],
    ).then((val) {
      if (val == 'detail') onViewDetail();
      if (val == 'delete') onDelete();
    });
  }
}

// ─── Delete confirmation dialog ───────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _DeleteConfirmDialog(
      {required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 318,
          height: 301,
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Stack(
              children: [
                // Close button — top left (LTR)
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child:
                          const Icon(Icons.close, size: 20, color: Colors.black),
                    ),
                  ),
                ),
                // Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 39),
                    // Red icon
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded,
                          size: 39, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    const Text('حذف المهمة؟',
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'هل أنت متأكد من حذف هذه المهمة؟\nلا يمكن التراجع عن هذا الإجراء.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Cancel
                          Expanded(
                            child: GestureDetector(
                              onTap: onCancel,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        color:
                                            Colors.black.withValues(alpha: 0.5))),
                                alignment: Alignment.center,
                                child: const Text('حسناً',
                                    style: TextStyle(
                                        fontFamily: _kFont,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Confirm delete
                          Expanded(
                            child: GestureDetector(
                              onTap: onConfirm,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(50)),
                                alignment: Alignment.center,
                                child: const Text('نعم, حذف',
                                    style: TextStyle(
                                        fontFamily: _kFont,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

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
          Image.asset('images/star shape.png',
              width: 24,
              height: 24,
              color: const Color(0xFFFE8401),
              errorBuilder: (_, __, ___) => const Icon(Icons.star,
                  size: 22, color: Color(0xFFFE8401))),
          const SizedBox(width: 4),
          Text('$count نجمة',
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

class _StarsBadgeSm extends StatelessWidget {
  final int count;
  const _StarsBadgeSm({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFE8401).withValues(alpha: 0.05),
        border:
            Border.all(color: const Color(0xFFFE8401).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('images/star shape.png',
              width: 16,
              height: 16,
              color: const Color(0xFFFE8401),
              errorBuilder: (_, __, ___) => const Icon(Icons.star,
                  size: 14, color: Color(0xFFFE8401))),
          const SizedBox(width: 2),
          Text('$count',
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
        ],
      ),
    );
  }
}
