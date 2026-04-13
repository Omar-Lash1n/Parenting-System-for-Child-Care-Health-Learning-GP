// --- lib/tasks/tasks_categories_page.dart ---
// Page for managing task categories: view, add, edit, delete.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class TasksCategoriesPage extends StatelessWidget {
  const TasksCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TasksCategoriesView();
  }
}

class _TasksCategoriesView extends StatefulWidget {
  const _TasksCategoriesView();

  @override
  State<_TasksCategoriesView> createState() => _TasksCategoriesViewState();
}

class _TasksCategoriesViewState extends State<_TasksCategoriesView> {
  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        title: 'اضافة تصنيف',
        buttonLabel: 'اضف',
        onSave: (name) async {
          try {
            await context.read<TasksProvider>().addCategory(name);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar('تم اضافة تصنيف "$name"'),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildErrorSnackBar('فشل إضافة التصنيف: ${e.toString().replaceFirst('Exception: ', '')}'),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditSheet(String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        title: 'تحديث التصنيف',
        buttonLabel: 'حفظ',
        initialValue: current,
        onSave: (name) async {
          try {
            await context.read<TasksProvider>().renameCategory(current, name);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildSnackBar('تم التغيير الى "$name"'),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _buildErrorSnackBar('فشل تعديل التصنيف: ${e.toString().replaceFirst('Exception: ', '')}'),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DeleteCategoryDialog(categoryName: name),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<TasksProvider>().removeCategory(name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('تم حذف التصنيف بنجاح'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar('فشل حذف التصنيف: ${e.toString().replaceFirst('Exception: ', '')}'),
          );
        }
      }
    }
  }

  SnackBar _buildSnackBar(String message) {
    return SnackBar(
      backgroundColor: const Color(0xFF01A449),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 84),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
      content: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.check, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      backgroundColor: const Color(0xFFBF092F),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 84),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      content: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasksProvider>();
    // All categories except "الكل"
    final cats = provider.categories.where((c) => c != 'الكل').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      // Back button — far RIGHT
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
                            Icons.arrow_back,
                            color: _kPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'التصنيفات',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Category list ──────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (context, i) {
                      final cat = cats[i];
                      final count = provider.countForCategory(cat);
                      return _CategoryRow(
                        name: cat,
                        count: count,
                        onEdit: () => _showEditSheet(cat),
                        onDelete: () => _confirmDelete(cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── FAB (tag icon) ─────────────────────────────────────────────
          Positioned(
            bottom: 80,
            right: 16,
            child: GestureDetector(
              onTap: _showAddSheet,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.25),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'images/tag.png',
                    width: 26,
                    height: 26,
                    color: Colors.white,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.label_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Nav ────────────────────────────────────────────────
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
}

// ── Category row ───────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.name,
    required this.count,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(color: _kPrimary, width: 4),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          // No Directionality override — use explicit LTR so left=icons, right=text
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LEFT side: edit icon then delete icon
            Row(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Image.asset(
                    'images/Pen.png',
                    width: 22,
                    height: 22,
                    color: Colors.black,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.edit_outlined,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onDelete,
                  child: Image.asset(
                    'images/Recycle Bin.png',
                    width: 22,
                    height: 22,
                    color: const Color(0xFFFF0000),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.delete_outline,
                      size: 22,
                      color: Color(0xFFFF0000),
                    ),
                  ),
                ),
              ],
            ),

            // RIGHT side: name then count badge
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                // Count badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit category bottom sheet ──────────────────────────────────────────

class _CategorySheet extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final String? initialValue;
  final void Function(String name) onSave;

  const _CategorySheet({
    required this.title,
    required this.buttonLabel,
    required this.onSave,
    this.initialValue,
  });

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late TextEditingController _ctrl;
  static const int _max = 25;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    widget.onSave(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(bottom: bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 15,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  // Spacer balance
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 16),
              // Input
              TextField(
                controller: _ctrl,
                textDirection: TextDirection.rtl,
                maxLength: _max,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'كتب دراسية',
                  hintStyle: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  counterText: '',
                  suffixText: '$_max/${_ctrl.text.length}',
                  suffixStyle: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                        BorderSide(color: Colors.black.withValues(alpha: 0.5)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      widget.buttonLabel,
                      style: const TextStyle(
                        fontFamily: _kFont,
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
        ),
      ),
    );
  }
}

// ── Delete category confirm dialog ────────────────────────────────────────────

class _DeleteCategoryDialog extends StatelessWidget {
  final String categoryName;
  const _DeleteCategoryDialog({required this.categoryName});

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
                    // Warning icon
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
                      'حذف التصنيف؟',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'سوف يتم حذف التصنيف نهائياً\nولا يمكن استعادته مرة اخرى',
                      style: TextStyle(
                        fontFamily: _kFont,
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
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                'لا, الغاء',
                                style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                  fontFamily: _kFont,
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
              // Close X
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
                    child: const Icon(Icons.close, size: 20),
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
