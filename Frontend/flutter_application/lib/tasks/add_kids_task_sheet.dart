// lib/tasks/add_kids_task_sheet.dart
//
// Bottom sheet for assigning a task to a child.
// Uses real audio recording (record package), image_picker, and calls
// POST /api/ChildTask with multipart form-data.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/family/models/child_model.dart';
import 'package:Ajial/tasks/models/child_task_model.dart';
import 'package:Ajial/tasks/repositories/child_task_repository.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

// ─────────────────── Public entry points ─────────────────────────────────────

Future<void> showAddKidsTaskSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddKidsTaskSheet(preselectedChild: null),
  );
}

Future<void> showAssignTaskSheet(BuildContext context, ChildModel child) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddKidsTaskSheet(preselectedChild: child),
  );
}

// ─────────────────── Day mapping ─────────────────────────────────────────────

const List<String> _dayLabels = ['خ', 'ج', 'س', 'ح', 'ن', 'ث', 'ر'];
const List<String> _dayApiNames = [
  'thursday', 'friday', 'saturday', 'sunday', 'monday', 'tuesday', 'wednesday'
];

// ─────────────────── Main Sheet Widget ───────────────────────────────────────

class _AddKidsTaskSheet extends StatefulWidget {
  final ChildModel? preselectedChild;
  const _AddKidsTaskSheet({required this.preselectedChild});

  @override
  State<_AddKidsTaskSheet> createState() => _AddKidsTaskSheetState();
}

class _AddKidsTaskSheetState extends State<_AddKidsTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _starsCtrl = TextEditingController(text: '0');

  // Task image
  File? _taskImage;
  final _picker = ImagePicker();

  // Audio recording
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordTimer;

  // Stars (0–300), step 5
  int _stars = 0;

  // Date & Time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Recurrence
  bool _isRecurring = false;
  Set<int> _repeatDays = {};
  TimeOfDay? _repeatTime;

  // Selected children (all shown, first preselected)
  final Set<String> _selectedChildIds = {};

  // Submit state
  bool _isSubmitting = false;

  // Eligible children loaded from ChildTaskRepository
  // (childTasksLocked == false AND isAccountActive == true)
  List<ChildTaskModel> _eligibleChildren = [];

  @override
  void initState() {
    super.initState();
    // Pre-select the preselected child immediately
    if (widget.preselectedChild != null) {
      _selectedChildIds.add(widget.preselectedChild!.childId);
    }
    // Load eligible children from the task-specific endpoint
    _loadEligibleChildren();
  }

  Future<void> _loadEligibleChildren() async {
    try {
      final all = await ChildTaskRepository().fetchChildren();
      if (!mounted) return;
      setState(() {
        // Only children where tasks are unlocked AND account is active
        _eligibleChildren =
            all.where((c) => !c.childTasksLocked && c.isAccountActive).toList();
      });
    } catch (_) {
      // Silently ignore — list stays empty, user sees the empty state text
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _starsCtrl.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _firstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Image picker ─────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final xf = await _picker.pickImage(
        source: source, maxWidth: 1024, imageQuality: 85);
    if (xf != null && mounted) {
      setState(() => _taskImage = File(xf.path));
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _ImagePickerPopup(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ── Audio recording ──────────────────────────────────────────────────────────

  // Guard to prevent double-tap race conditions
  bool _recordingBusy = false;

  Future<void> _startRecording() async {
    if (_recordingBusy || _isRecording) return;
    _recordingBusy = true;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission || !mounted) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/task_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: path);
      if (!mounted) return;

      _recordingPath = path;
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    } finally {
      _recordingBusy = false;
    }
  }

  Future<void> _stopRecording() async {
    if (_recordingBusy || !_isRecording) return;
    _recordingBusy = true;
    try {
      _recordTimer?.cancel();
      _recordTimer = null;
      // Check if actually recording before calling stop
      final isActuallyRecording = await _recorder.isRecording();
      if (isActuallyRecording) await _recorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _hasRecording = _recordingDuration.inSeconds > 0;
      });
    } finally {
      _recordingBusy = false;
    }
  }

  void _confirmDeleteRecording() {
    _showRecordingActionSheet(
      title: 'حذف التسجيل؟',
      confirmLabel: 'نعم, حذف',
      onConfirm: () {
        Navigator.pop(context);
        _deleteRecording();
      },
    );
  }

  void _confirmRestartRecording() {
    _showRecordingActionSheet(
      title: 'حذف التسجيل؟',
      confirmLabel: 'نعم, حذف',
      onConfirm: () {
        Navigator.pop(context);
        _deleteRecording();
        _startRecording();
      },
    );
  }

  void _deleteRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = false;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
    });
  }

  void _showRecordingActionSheet({
    required String title,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => _RecordingConfirmSheet(
        title: title,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ── Stars ────────────────────────────────────────────────────────────────────

  void _incrementStars() {
    if (_stars < 300) {
      setState(() {
        _stars = (_stars + 5).clamp(0, 300);
        _starsCtrl.text = '$_stars';
      });
    }
  }

  void _decrementStars() {
    if (_stars > 0) {
      setState(() {
        _stars = (_stars - 5).clamp(0, 300);
        _starsCtrl.text = '$_stars';
      });
    }
  }

  // ── Date/Time ────────────────────────────────────────────────────────────────

  void _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ar'),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  void _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null && mounted) setState(() => _selectedTime = t);
  }

  // ── Recurrence ───────────────────────────────────────────────────────────────

  void _pickRepeatTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null && mounted) setState(() => _repeatTime = t);
  }

  String _repeatDaysDisplay() {
    if (_repeatDays.isEmpty) return 'تكرار';
    final labels = _repeatDays.map((i) => _dayLabels[i]).join(',');
    final timeStr = _repeatTime != null ? ' ${_repeatTime!.format(context)}' : '';
    return 'تكرار $labels$timeStr';
  }

  // ── Cancel confirmation ───────────────────────────────────────────────────────

  void _confirmCancel() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => _CancelConfirmDialog(
        onConfirm: () {
          Navigator.pop(context); // close dialog
          Navigator.pop(context); // close sheet
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('عنوان المهمة مطلوب', isError: true);
      return;
    }
    if (_selectedChildIds.isEmpty) {
      _showSnack('اختر طفلاً على الأقل', isError: true);
      return;
    }
    if (!_hasRecording || _recordingPath == null) {
      _showSnack('تسجيل وصف المهمة مطلوب', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = AuthService();
      final token = await authService.getToken();
      final parentId = await authService.getSavedParentId();

      if (token == null || parentId == null) throw Exception('لا يوجد رمز مصادقة');

      final dio = Dio(BaseOptions(
        baseUrl:
            'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api',
        headers: {'Authorization': 'Bearer $token'},
      ));

      final formData = FormData();

      formData.fields.add(MapEntry('Title', title));
      formData.fields.add(MapEntry('Stars', '$_stars'));

      for (final id in _selectedChildIds) {
        formData.fields.add(MapEntry('SelectedChildIds', id));
      }

      if (_selectedDate != null) {
        final startDt = _selectedDate!.copyWith(
          hour: _selectedTime?.hour ?? 0,
          minute: _selectedTime?.minute ?? 0,
        );
        formData.fields
            .add(MapEntry('StartDate', startDt.toUtc().toIso8601String()));
        formData.fields
            .add(MapEntry('DueDate', startDt.toUtc().toIso8601String()));
      }

      if (_isRecurring && _repeatDays.isNotEmpty) {
        formData.fields.add(const MapEntry('IsRecurring', 'true'));
        final daysStr =
            _repeatDays.map((i) => _dayApiNames[i]).join(',');
        formData.fields.add(MapEntry('RepeatDays', daysStr));
        if (_repeatTime != null) {
          final hh = _repeatTime!.hour.toString().padLeft(2, '0');
          final mm = _repeatTime!.minute.toString().padLeft(2, '0');
          formData.fields.add(MapEntry('RepeatTime', '$hh:$mm'));
        }
      }

      if (_taskImage != null) {
        formData.files.add(MapEntry(
          'TaskImage',
          await MultipartFile.fromFile(_taskImage!.path,
              filename: 'task_image.jpg'),
        ));
      }

      if (_hasRecording && _recordingPath != null) {
        formData.files.add(MapEntry(
          'Recording',
          await MultipartFile.fromFile(_recordingPath!,
              filename: 'recording.m4a'),
        ));
      }

      await dio.post('/ChildTask', data: formData);

      if (mounted) {
        _showSnack('تم إضافة المهمة بنجاح!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
            e.toString().replaceFirst('Exception: ', '').replaceFirst('DioException', 'خطأ'),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: _kFont, color: Colors.white)),
      backgroundColor: isError ? _kPrimary : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    // ignore FamilyProvider for the children list — we use _eligibleChildren instead

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        padding: EdgeInsets.only(bottom: bottomPad + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
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

              // ── Header: close (right) | title ──
              _buildHeader(),
              const SizedBox(height: 16),

              // ── Task image circle ──
              _buildTaskIcon(),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // عنوان المهمة
                    _label('عنوان المهمة'),
                    const SizedBox(height: 8),
                    _buildTitleField(),
                    const SizedBox(height: 16),

                    // تسجيل وصف المهمة (مطلوب)
                    _requiredLabel('تسجيل وصف المهمة'),
                    const SizedBox(height: 8),
                    _isRecording
                        ? _buildRecordingInProgress()
                        : _hasRecording
                            ? _buildRecordingResult()
                            : _buildVoiceRow(),
                    const SizedBox(height: 16),

                    // عدد نجوم المهمة
                    _label('عدد نجوم المهمة'),
                    const SizedBox(height: 8),
                    _buildStarsRow(),
                    const SizedBox(height: 16),

                    // التاريخ | الوقت  (icons on left, text RTL)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerCol(
                            label: 'موعد البدء',
                            display: _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'اختر التاريخ',
                            icon: Icons.calendar_today_outlined,
                            hasValue: _selectedDate != null,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerCol(
                            label: 'الوقت',
                            display: _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'اختر الوقت',
                            icon: Icons.alarm,
                            hasValue: _selectedTime != null,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // التكرار
                    _label('التكرار'),
                    const SizedBox(height: 8),
                    _buildRepeatSection(),
                    const SizedBox(height: 16),

                    // اختر الاطفال
                    _label('اختر الاطفال'),
                    const SizedBox(height: 8),
                    _buildChildrenRow(),
                    const SizedBox(height: 24),

                    // أضف المهمة
                    _buildSubmitButton(),
                    const SizedBox(height: 12),
                    _buildCancelButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-builders ─────────────────────────────────────────────────────────────

  /// Header: close button on the RIGHT, title text immediately after it
  Widget _buildHeader() {
    final title = widget.preselectedChild != null
        ? 'انساب مهمة'
        : 'مهمة جديدة';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Close icon (rightmost in RTL)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: _showImagePickerDialog,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
            ),
            child: ClipOval(
              child: _taskImage != null
                  ? Image.file(_taskImage!, fit: BoxFit.cover)
                  : Image.asset(
                      'images/image.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          size: 50,
                          color: _kPrimary),
                    ),
            ),
          ),
        ),
        // Camera button
        Positioned(
          bottom: 8,
          left: 8,
          child: GestureDetector(
            onTap: _showImagePickerDialog,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.5), width: 0.74),
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  size: 16, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerRight,
        child: Text(text,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
      );

  Widget _requiredLabel(String text) => Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
            const SizedBox(width: 4),
            const Text('*',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
          ],
        ),
      );

  Widget _buildTitleField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: _titleCtrl,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: _kFont, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'مثل اغسل يديك',
          hintStyle: TextStyle(
              fontFamily: _kFont,
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  /// Voice row: "بدء تسجيل" button on LEFT, counter on right
  Widget _buildVoiceRow() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        textDirection: TextDirection.ltr, // LTR so button stays on actual left
        children: [
          // "بدء تسجيل" button — actual left side of the row
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isRecording ? const Color(0xFF8B0000) : _kPrimary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isRecording ? Icons.stop : Icons.mic,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _isRecording ? 'ايقاف' : 'بدء تسجيل',
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // Counter / hint — right side
          Expanded(
            child: Text(
              _isRecording
                  ? _formatDuration(_recordingDuration)
                  : 'اضغط بدء تسجيل',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  /// Recording in-progress row: shows live timer + stop/confirm button + cancel
  Widget _buildRecordingInProgress() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kPrimary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        textDirection: TextDirection.ltr, // LTR so buttons stay on actual left
        children: [
          // "تأكيد" (Confirm/Stop) button — actual left side
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32), // Green for confirm
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'تأكيد',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Cancel button
          GestureDetector(
            onTap: _deleteRecording,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.black54),
            ),
          ),
          // Timer + recording indicator — right side
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                const SizedBox(width: 8),
                // Pulsing red dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Recording result row: play | duration (right) | trash | refresh (left)
  Widget _buildRecordingResult() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Right side: play + duration
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, size: 24, color: Colors.black),
                const SizedBox(width: 8),
                Text(_formatDuration(_recordingDuration),
                    style: const TextStyle(fontFamily: _kFont, fontSize: 14)),
              ],
            ),
            const Spacer(),
            // Left side: refresh + trash
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _confirmRestartRecording,
                  child: const Icon(Icons.refresh,
                      size: 24, color: Colors.black54),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _confirmDeleteRecording,
                  child: const Icon(Icons.delete_outline,
                      size: 24, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Stars: stepper on RIGHT (increments by 5), editable field in centre
  Widget _buildStarsRow() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // Increment (+5) — rightmost
        _StepperButton(
          icon: Icons.keyboard_arrow_up,
          onTap: _incrementStars,
          enabled: _stars < 300,
        ),
        const SizedBox(width: 8),
        // Decrement (-5)
        _StepperButton(
          icon: Icons.keyboard_arrow_down,
          onTap: _decrementStars,
          enabled: _stars > 0,
        ),
        const SizedBox(width: 8),
        // Stars display + editable input
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/star shape.png',
                  width: 24,
                  height: 24,
                  color: const Color(0xFFFE8401),
                  errorBuilder: (_, __, ___) => const Icon(Icons.star,
                      size: 24, color: Color(0xFFFE8401)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _starsCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _MaxValueInputFormatter(300),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 0 && n <= 300) {
                        setState(() => _stars = n);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCol({
    required String label,
    required String display,
    required IconData icon,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                // Icon on actual LEFT (LTR), text flows from RIGHT
                textDirection: TextDirection.ltr,
                children: [
                  Icon(icon,
                      size: 20,
                      color: hasValue
                          ? _kPrimary
                          : Colors.black.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(display,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 13,
                            color: hasValue
                                ? Colors.black
                                : Colors.black.withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      children: [
        // Toggle row
        GestureDetector(
          onTap: () => setState(() => _isRecurring = !_isRecurring),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _isRecurring
                  ? _kPrimary.withValues(alpha: 0.06)
                  : Colors.white,
              border: Border.all(
                color: _isRecurring
                    ? _kPrimary
                    : Colors.black.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.repeat,
                      size: 20,
                      color: _isRecurring
                          ? _kPrimary
                          : Colors.black.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isRecurring ? _repeatDaysDisplay() : 'تكرار',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          color: _isRecurring
                              ? Colors.black
                              : Colors.black.withValues(alpha: 0.5)),
                    ),
                  ),
                  Switch(
                    value: _isRecurring,
                    activeColor: _kPrimary,
                    onChanged: (v) => setState(() => _isRecurring = v),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Days + time picker (expanded)
        if (_isRecurring) ...[
          const SizedBox(height: 12),
          // Day selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_dayLabels.length, (i) {
              final sel = _repeatDays.contains(i);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel) {
                    _repeatDays.remove(i);
                  } else {
                    _repeatDays.add(i);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: sel ? _kPrimary : const Color(0xFFD9D9D9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(_dayLabels[i],
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          color: sel ? Colors.white : Colors.black)),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Time picker for repeat
          GestureDetector(
            onTap: _pickRepeatTime,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: Colors.black.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Icon(Icons.alarm,
                        size: 20,
                        color: _repeatTime != null
                            ? _kPrimary
                            : Colors.black.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _repeatTime != null
                            ? _repeatTime!.format(context)
                            : 'اختر وقت التكرار',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            color: _repeatTime != null
                                ? Colors.black
                                : Colors.black.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Shows only eligible children (childTasksLocked == false, isAccountActive == true).
  /// Default-selects the preselected one. Displays first name below each avatar.
  Widget _buildChildrenRow() {
    if (_eligibleChildren.isEmpty) {
      return const Text('لا يوجد أطفال مؤهلون لإسناد المهام',
          style: TextStyle(
              fontFamily: _kFont, fontSize: 13, color: Color(0xFF888888)),
          textAlign: TextAlign.center);
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL order
        itemCount: _eligibleChildren.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final child = _eligibleChildren[i];
          final isSelected = _selectedChildIds.contains(child.childId);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedChildIds.remove(child.childId);
              } else {
                _selectedChildIds.add(child.childId);
              }
            }),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF01A449), width: 2.5)
                            : null,
                      ),
                      child: _ChildLetterAvatar(
                        photoUrl: child.profileImageUrl,
                        fullName: child.fullName,
                        size: 68,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: Color(0xFF01A449),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _firstName(child.fullName),
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12,
                      color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('اضف المهمة',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _confirmCancel,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
        ),
        child: const Text('الغاء',
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
      ),
    );
  }
}

// ─────────────────── Child Letter Avatar ─────────────────────────────────────
// Shows a real network photo when the URL is a genuine user upload.
// Falls back to the first letter of the name when:
//   • photoUrl is null / empty
//   • photoUrl contains "/defaults/" (server-side placeholder)

class _ChildLetterAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fullName;
  final double size;

  const _ChildLetterAvatar({
    required this.photoUrl,
    required this.fullName,
    required this.size,
  });

  /// Returns true when the URL is a default/placeholder image from the server.
  bool get _isDefaultUrl {
    if (photoUrl == null || photoUrl!.isEmpty) return true;
    return photoUrl!.contains('/defaults/');
  }

  String get _firstLetter {
    final name = fullName.trim();
    return name.isNotEmpty ? name.substring(0, 1) : '؟';
  }

  @override
  Widget build(BuildContext context) {
    if (_isDefaultUrl) {
      // Show coloured circle with the first letter
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: _kPrimary.withValues(alpha: 0.15),
        child: Text(
          _firstLetter,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      );
    }

    // Real photo — load from network with a letter fallback on error
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE0E0E0),
      child: ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: size / 2,
            backgroundColor: _kPrimary.withValues(alpha: 0.15),
            child: Text(
              _firstLetter,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Image Picker Popup ──────────────────────────────────────
// Matches the Figma design: red image icon, title "تاكيد الحساب" (actual copy
// was for image selection), two action buttons + close.

class _ImagePickerPopup extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onCancel;

  const _ImagePickerPopup({
    required this.onCamera,
    required this.onGallery,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 318,
          height: 301,
          child: Stack(
            children: [
              // ── Content ──
              Column(
                children: [
                  const SizedBox(height: 39),
                  // Red image icon in circle
                  Center(
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'images/image.png',
                          width: 39,
                          height: 39,
                          color: _kPrimary,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 39,
                              color: _kPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title + subtitle
                  const Text('اختر صورة',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'اختر مصدر الصورة من الكاميرا أو معرض الصور',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          height: 1.5),
                    ),
                  ),
                  const Spacer(),
                  // Buttons row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onGallery,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color:
                                        Colors.black.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              alignment: Alignment.center,
                              child: const Text('المعرض',
                                  style: TextStyle(
                                      fontFamily: _kFont,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: onCamera,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              alignment: Alignment.center,
                              child: const Text('الكاميرا',
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

              // ── Close button (top-left per Figma, RTL → visual right) ──
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
                      shape: BoxShape.circle,
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

// ─────────────────── Recording Confirm Sheet ──────────────────────────────────
// Matches Figma "alert" design: red title, dividers, "نعم, حذف" / "لا, الغاء"

class _RecordingConfirmSheet extends StatelessWidget {
  final String title;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _RecordingConfirmSheet({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 343,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), blurRadius: 15)
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.red)),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: onConfirm,
                  child: const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'نعم, حذف',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1, color: Color(0xFFD9D9D9)),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: onCancel,
                  child: const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'لا, الغاء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
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

// ─────────────────── Cancel Confirm Dialog ────────────────────────────────────

class _CancelConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _CancelConfirmDialog(
      {required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل تريد الخروج؟',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('سيتم فقدان البيانات المدخلة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w300)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: Colors.black.withValues(alpha: 0.5)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('لا',
                            style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onConfirm,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: const Text('نعم, خروج',
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Reusable small widgets ───────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: enabled
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(icon,
            size: 24,
            color: enabled ? Colors.black : Colors.black26),
      ),
    );
  }
}

// ─────────────────── Input Formatter ─────────────────────────────────────────

class _MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;
  _MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null || n > maxValue) return oldValue;
    return newValue;
  }
}
