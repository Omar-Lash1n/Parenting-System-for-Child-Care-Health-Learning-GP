// --- lib/tasks/add_task_sheet.dart ---
// Bottom sheet for creating a new task.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/tasks/models/task_model.dart';

const Color _kPrimaryColor = Color(0xFFBF092F);
const String _kFontFamily = 'IBM Plex Sans Arabic';

// Exact colors from the design
const List<Color> _kTaskColors = [
  Color(0xFFBF092F), // dark red
  Color(0xFF4CAF50), // green
  Color(0xFF00BCD4), // cyan
  Color(0xFFE91E63), // pink
  Color(0xFFE53935), // red
  Color(0xFFFF9800), // orange
  Color(0xFF2E7D32), // dark green
  Color(0xFF1A237E), // dark navy
  Color(0xFF37474F), // dark gray-blue
];

/// Opens the add-task bottom sheet.
Future<void> showAddTaskSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final int _maxTitleLength = 25;
  final _categoryFieldKey = GlobalKey();

  String? _selectedCategory;
  final Set<String> _selectedAssigneeIds = {};
  Color _selectedColor = _kTaskColors[0];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _showDetails = false;

  OverlayEntry? _categoryOverlay;

  // Mock assignees — will be replaced with API data
  final List<Assignee> _assignees = const [
    Assignee(id: 'self', name: 'حسابي', isSelf: true),
    Assignee(id: 'child1', name: 'طفل ١'),
    Assignee(id: 'child2', name: 'طفل ٢'),
    Assignee(id: 'child3', name: 'طفل ٣'),
  ];

  @override
  void dispose() {
    _removeCategoryOverlay();
    _titleController.dispose();
    super.dispose();
  }

  void _removeCategoryOverlay() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
  }

  void _toggleCategoryDropdown() {
    if (_categoryOverlay != null) {
      _removeCategoryOverlay();
      setState(() {});
      return;
    }

    final renderBox =
        _categoryFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final provider = context.read<TasksProvider>();
    final cats = provider.categories.where((c) => c != 'الكل').toList();

    _categoryOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        onTap: () {
          _removeCategoryOverlay();
          setState(() {});
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent barrier
            Positioned.fill(child: Container(color: Colors.transparent)),
            // Dropdown card
            Positioned(
              top: offset.dy + size.height + 4,
              left: offset.dx,
              width: size.width,
              child: Material(
                color: Colors.transparent,
                child: _buildCategoryDropdownContent(cats),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_categoryOverlay!);
    setState(() {});
  }

  Widget _buildCategoryDropdownContent(List<String> cats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...cats.map((cat) {
            final isSelected = _selectedCategory == cat;
            return InkWell(
              onTap: () {
                _removeCategoryOverlay();
                setState(() => _selectedCategory = cat);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? _kPrimaryColor
                              : const Color(0xFFCCCCCC),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kPrimaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      cat,
                      style: const TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          InkWell(
            onTap: () {
              _removeCategoryOverlay();
              _showAddCategoryDialog();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                textDirection: TextDirection.rtl,
                children: const [
                  Icon(Icons.label_outline, size: 20, color: Color(0xFF666666)),
                  SizedBox(width: 10),
                  Text(
                    'اضافة تصنيف جديد',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
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

  void _pickDate() async {
    final result = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DateQuickPickerSheet(),
    );

    if (result == null) return; // dismissed

    if (result.year == 0) {
      // "لا يوجد موعد" → clear date
      setState(() => _selectedDate = null);
    } else if (result.year == 1) {
      // "موعد اخر" → open the standard date picker
      if (!mounted) return;
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(now.year + 2),
        locale: const Locale('ar'),
      );
      if (date != null) setState(() => _selectedDate = date);
    } else {
      setState(() => _selectedDate = result);
    }
  }

  void _pickTime() async {
    final now = TimeOfDay.now();
    final time = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (time != null) {
      final today = DateTime.now();
      if (_selectedDate != null &&
          _selectedDate!.year == today.year &&
          _selectedDate!.month == today.month &&
          _selectedDate!.day == today.day) {
        final nowMinutes = today.hour * 60 + today.minute;
        final pickedMinutes = time.hour * 60 + time.minute;
        if (pickedMinutes < nowMinutes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن اختيار وقت فات')),
          );
          return;
        }
      }
      setState(() => _selectedTime = time);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان المهمة')),
      );
      return;
    }

    final provider = context.read<TasksProvider>();
    final category = _selectedCategory ?? provider.categories[0];
    // Don't default to self; keep empty if nothing was selected
    final selectedIds = _selectedAssigneeIds;

    // Empty list means no assignee chosen — keep it empty
    final assignees = selectedIds
        .map((id) => _assignees.firstWhere((a) => a.id == id))
        .toList();

    // ONE task, with all selected assignees
    final task = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      assignees: assignees,
      color: _selectedColor,
      date: _selectedDate,   // null if not chosen
      time: _selectedTime,   // null if not chosen
    );
    provider.addTask(task);

    if (!mounted) return;
    // Show green success toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'تم اضافة المهمة بنجاح!',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _showAddCategoryDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: const Icon(Icons.close, size: 18, color: Color(0xFF666666)),
                            ),
                          ),
                        ),
                        const Text(
                          'اضافة تصنيف',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller,
                      maxLength: 25,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        color: Color(0xFF333333),
                      ),
                      decoration: InputDecoration(
                        hintText: 'كتب دراسية',
                        hintStyle: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF999999)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        counterText: '',
                        suffixText: '25/${controller.text.length}',
                        suffixStyle: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) Navigator.pop(ctx, name);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'اضف',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
    if (result != null && mounted) {
      context.read<TasksProvider>().addCategory(result);
      setState(() => _selectedCategory = result);
    }
  }

  Widget _separator() {
    return const Divider(color: Color(0xFFE0E0E0), height: 24, thickness: 1);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _header(),
                _separator(),

                _sectionLabel('عنوان المهمة'),
                const SizedBox(height: 8),
                _titleField(),
                _separator(),

                _sectionLabel('التصنيف'),
                const SizedBox(height: 8),
                _categoryField(),
                _separator(),

                _sectionLabel('من أجل'),
                const SizedBox(height: 8),
                _assigneeRow(),

                if (!_showDetails) ...[
                  _separator(),
                  _submitButton(),
                  const SizedBox(height: 12),
                  _showDetailsToggle(),
                ],

                if (_showDetails) ...[
                  _separator(),
                  _sectionLabel('لون المهمة'),
                  const SizedBox(height: 8),
                  _colorRow(),
                  _separator(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionLabel('الموعد'),
                            const SizedBox(height: 8),
                            _dateButton(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionLabel('الوقت'),
                            const SizedBox(height: 8),
                            _timeButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _separator(),
                  _submitButton(),
                  const SizedBox(height: 10),
                  _cancelButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Text(
          'مهمة جديدة',
          style: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        Positioned(
          left: 0,
          child: GestureDetector(
            onTap: () {
              _removeCategoryOverlay();
              Navigator.pop(context);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child:
                  const Icon(Icons.close, size: 18, color: Color(0xFF666666)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: _kFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _titleField() {
    return TextField(
      controller: _titleController,
      maxLength: _maxTitleLength,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontFamily: _kFontFamily,
        fontSize: 14,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: 'مثل شراء متطلبات الطفل',
        hintStyle: TextStyle(
          fontFamily: _kFontFamily,
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF999999)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '',
        suffixText: '$_maxTitleLength/${_titleController.text.length}',
        suffixStyle: TextStyle(
          fontFamily: _kFontFamily,
          fontSize: 12,
          color: Colors.grey.shade400,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _categoryField() {
    return GestureDetector(
      key: _categoryFieldKey,
      onTap: _toggleCategoryDropdown,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCategory ?? 'دواء/كشف طبيب/طلبات....',
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  color: _selectedCategory != null
                      ? const Color(0xFF333333)
                      : Colors.grey.shade400,
                ),
              ),
            ),
            Icon(
              _categoryOverlay != null
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 22,
              color: const Color(0xFF888888),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assigneeRow() {
    return SizedBox(
      height: 75,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _assignees.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final a = _assignees[index];
          final isSelected = _selectedAssigneeIds.contains(a.id);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedAssigneeIds.remove(a.id);
                } else {
                  _selectedAssigneeIds.add(a.id);
                }
              });
            },
            child: SizedBox(
              width: 60,
              height: 75,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFE0E0E0),
                      child: a.isSelf
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 28)
                          : Text(
                              a.name.characters.first,
                              style: const TextStyle(
                                fontFamily: _kFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  // Green checkmark badge
                  if (isSelected)
                    Positioned(
                      bottom: 4,
                      right: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
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
    );
  }

  Widget _colorRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kTaskColors.map((c) {
        final isSelected = _selectedColor == c;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = c),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF333333) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateButton() {
    final hasValue = _selectedDate != null;
    final label = hasValue
        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
        : 'اختر التاريخ';
    return _pickerButton(
        label, Icons.calendar_today_outlined, _pickDate, hasValue);
  }

  Widget _timeButton() {
    final hasValue = _selectedTime != null;
    final label = hasValue ? _selectedTime!.format(context) : 'اختر الوقت';
    return _pickerButton(
        label, Icons.access_time_outlined, _pickTime, hasValue);
  }

  Widget _pickerButton(
      String label, IconData icon, VoidCallback onTap, bool hasValue) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF888888)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 13,
                color: hasValue
                    ? const Color(0xFF333333)
                    : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: const Text(
          'أضف المهمة',
          style: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _cancelButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _showCancelConfirmation,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'الغاء',
          style: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmation() async {
    _removeCategoryOverlay();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // X button top-right (acts like الغاء → return to form)
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Warning icon in pink circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 36,
                    color: _kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'تجاهل المهمة؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'سوف يتم حذف البيانات وتجاهل اضافة المهمة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 13,
                    color: Color(0xFF888888),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons row: تأكيد (red, right) | الغاء (outlined, left)
                Row(
                  children: [
                    // تأكيد — red, confirms cancel
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'تاكيد',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // الغاء — outlined, returns to form
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'الغاء',
                          style: TextStyle(
                            fontFamily: _kFontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF555555),
                          ),
                        ),
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

    if (confirmed == true && mounted) {
      Navigator.pop(context); // close the add-task sheet
    }
  }

  Widget _showDetailsToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
            SizedBox(width: 4),
            Text(
              'عرض تفاصيل اكثر',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Date Quick Picker Sheet ─────────────────────────────────

class _DateQuickPickerSheet extends StatelessWidget {
  const _DateQuickPickerSheet();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'تحديد الموعد',
                  style: TextStyle(
                    fontFamily: _kFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF666666)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick options row: اليوم · غدا · بعد يومين
            Row(
              children: [
                Expanded(
                  child: _quickOption(
                    context,
                    label: 'اليوم',
                    onTap: () => Navigator.pop(context, today),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickOption(
                    context,
                    label: 'غداً',
                    onTap: () => Navigator.pop(context, tomorrow),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickOption(
                    context,
                    label: 'بعد يومين',
                    onTap: () => Navigator.pop(context, dayAfter),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Second row: لا يوجد موعد · موعد اخر
            Row(
              children: [
                Expanded(
                  child: _quickOption(
                    context,
                    label: 'لا يوجد موعد',
                    onTap: () => Navigator.pop(context, DateTime(0)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickOption(
                    context,
                    label: 'موعد اخر',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => Navigator.pop(context, DateTime(1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickOption(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF888888)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
