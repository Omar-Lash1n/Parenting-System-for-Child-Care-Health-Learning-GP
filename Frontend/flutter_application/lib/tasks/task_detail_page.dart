// lib/tasks/task_detail_page.dart
//
// Task detail / edit page.
// Loads GET /api/ChildTask/{taskId}/child/{childId}
// Saves PUT /api/ChildTask/{taskId}/child/{childId}   (multipart)
// Deletes DELETE /api/ChildTask/{taskId}/child/{childId}

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:Ajial/tasks/models/task_list_model.dart';
import 'package:Ajial/tasks/repositories/child_task_repository.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  final String childId;

  const TaskDetailPage(
      {super.key, required this.taskId, required this.childId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _repo = ChildTaskRepository();
  bool _isLoadingDetail = true;
  bool _isSaving = false;

  // ── Form fields ─────────────────────────────────────────────────────────────
  late final TextEditingController _titleCtrl;
  int _stars = 0;
  DateTime? _startDate;
  TimeOfDay? _startTime;

  // Image
  File? _newImage;
  String? _existingImageUrl;

  // Recording
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  String? _existingRecordingUrl;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  // Assigned children — readonly display only
  List<AssignedChild> _assignedChildren = [];

  // ── Init ────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _loadDetail();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final detail =
          await _repo.fetchTaskDetail(widget.taskId, widget.childId);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = detail.title;
        _stars = detail.stars;
        _existingImageUrl = detail.taskImageUrl;
        _existingRecordingUrl = detail.recordingUrl;
        _assignedChildren = detail.assignedChildren;
        if (detail.startDate != null) {
          _startDate = detail.startDate;
          _startTime = TimeOfDay.fromDateTime(detail.startDate!);
        }
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetail = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Recording logic ─────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/task_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordDuration = Duration.zero;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
  }

  void _deleteRecording() {
    setState(() {
      _recordingPath = null;
      _existingRecordingUrl = null;
    });
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Image ────────────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _newImage = File(picked.path));
  }

  void _deleteImage() {
    setState(() {
      _newImage = null;
      _existingImageUrl = null;
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('يرجى إدخال عنوان المهمة');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final fields = <String, dynamic>{
        'Title': title,
        'Stars': '$_stars',
      };
      if (_startDate != null) {
        final t = _startTime ?? TimeOfDay.now();
        final combined = DateTime(
            _startDate!.year, _startDate!.month, _startDate!.day, t.hour, t.minute);
        fields['StartDate'] = combined.toIso8601String();
        fields['DueDate'] = combined.toIso8601String();
      }
      // Image
      if (_newImage != null) {
        fields['TaskImage'] =
            await MultipartFile.fromFile(_newImage!.path, filename: 'task_image.jpg');
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        fields['ExistingTaskImageUrl'] = _existingImageUrl;
      } else {
        fields['ExistingTaskImageUrl'] = '';
      }
      // Recording
      if (_recordingPath != null) {
        fields['Recording'] =
            await MultipartFile.fromFile(_recordingPath!, filename: 'recording.m4a');
      } else if (_existingRecordingUrl != null &&
          _existingRecordingUrl!.isNotEmpty) {
        fields['ExistingRecordingUrl'] = _existingRecordingUrl;
      } else {
        fields['ExistingRecordingUrl'] = '';
      }

      final formData = FormData.fromMap(fields);
      await _repo.updateTask(widget.taskId, widget.childId, formData);
      if (!mounted) return;
      _showSnack('تم تحديث المهمة بنجاح');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DeleteDialog(
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await _repo.deleteTask(widget.taskId, widget.childId);
            if (!mounted) return;
            Navigator.pop(context);
          } catch (e) {
            if (!mounted) return;
            _showSnack(e.toString().replaceFirst('Exception: ', ''));
          }
        },
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: _kFont)),
      backgroundColor: _kPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Date / Time pickers ──────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  String get _dateLabel => _startDate != null
      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
      : 'اختر من القائمة';

  String get _timeLabel =>
      _startTime != null ? _startTime!.format(context) : 'اختر من القائمة';

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isLoadingDetail
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title "الاعدادات"
                          const Text(
                            'الاعدادات',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          // Close button (X circle) — far left
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  const Icon(Icons.close, size: 20, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Scrollable body ────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Task image (circular 130px) ───────────────────
                            _buildImagePicker(),
                            const SizedBox(height: 24),
                            // ── Title ──────────────────────────────────────────
                            _buildSection(
                              label: 'عنوان المهمة',
                              child: _buildInput(
                                controller: _titleCtrl,
                                hint: 'اغسل يديك',
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ── Recording section ──────────────────────────────
                            _buildSection(
                              label: 'تسجيل وصف المهمة',
                              child: _buildRecordingRow(),
                            ),
                            const SizedBox(height: 16),
                            // ── Stars ──────────────────────────────────────────
                            _buildSection(
                              label: 'عدد نجوم المهمة',
                              child: _buildStarsRow(),
                            ),
                            const SizedBox(height: 16),
                            // ── Date + Time row ───────────────────────────────
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                // Start date
                                Expanded(
                                  child: _buildSection(
                                    label: 'موعد البدء',
                                    child: _buildPillButton(
                                      icon: Icons.calendar_today_outlined,
                                      label: _dateLabel,
                                      onTap: _pickDate,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Time
                                Expanded(
                                  child: _buildSection(
                                    label: 'الوقت',
                                    child: _buildPillButton(
                                      icon: Icons.alarm_outlined,
                                      label: _timeLabel,
                                      onTap: _pickTime,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── Assigned children ──────────────────────────────
                            if (_assignedChildren.isNotEmpty)
                              _buildAssignedChildren(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        // ── Bottom buttons fixed ────────────────────────────────────────────────
        bottomNavigationBar: _isLoadingDetail
            ? const SizedBox()
            : Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Save
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'تحديث المهمة',
                                style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delete
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: _confirmDelete,
                        child: const Text(
                          'حذف المهمة',
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
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

  // ── Image picker widget ───────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    final bool hasImage =
        _newImage != null || (_existingImageUrl?.isNotEmpty == true);

    Widget imageWidget;
    if (_newImage != null) {
      imageWidget = ClipOval(
        child: Image.file(_newImage!,
            width: 130, height: 130, fit: BoxFit.cover),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageWidget = ClipOval(
        child: Image.network(
          _existingImageUrl!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    } else {
      imageWidget = _imagePlaceholder();
    }

    return Stack(
      children: [
        imageWidget,
        // Camera button — bottom-left of circle
        Positioned(
          bottom: 0,
          left: 0,
          child: GestureDetector(
            onTap: _pickImage,
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
                  size: 16, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
      );

  // ── Recording row ─────────────────────────────────────────────────────────────
  Widget _buildRecordingRow() {
    final bool hasRec = _recordingPath != null ||
        (_existingRecordingUrl?.isNotEmpty == true);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: delete + redo icons (when recording exists)
          if (hasRec)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _deleteRecording,
                  child: const Icon(Icons.delete_outline,
                      size: 24, color: Colors.red),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: const Icon(Icons.refresh, size: 24, color: Colors.black),
                ),
              ],
            )
          else
            const SizedBox(),
          // Right side: timer + mic/stop button
          Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isRecording || hasRec)
                Text(
                  _fmtDuration(_recordDuration),
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              if (_isRecording || hasRec) const SizedBox(width: 8),
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Icon(
                  _isRecording
                      ? Icons.stop_circle_outlined
                      : (hasRec
                          ? Icons.play_circle_outline
                          : Icons.mic_outlined),
                  size: 24,
                  color: _isRecording ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stars row ─────────────────────────────────────────────────────────────────
  Widget _buildStarsRow() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // Star + value pill (wide)
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border.all(color: Colors.black.withValues(alpha: 0.25)),
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
                      size: 22, color: Color(0xFFFE8401)),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_stars',
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
        ),
        const SizedBox(width: 8),
        // Minus button
        _CircleBtn(
          icon: Icons.remove,
          onTap: () {
            if (_stars >= 5) setState(() => _stars -= 5);
          },
        ),
        const SizedBox(width: 8),
        // Plus button
        _CircleBtn(
          icon: Icons.add,
          onTap: () {
            if (_stars < 300) setState(() => _stars += 5);
          },
        ),
      ],
    );
  }

  // ── Assigned children row ─────────────────────────────────────────────────────
  Widget _buildAssignedChildren() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'اختر الاطفال',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 79,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL order
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _assignedChildren.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = _assignedChildren[i];
              final isDefault = c.profileImageUrl == null ||
                  c.profileImageUrl!.isEmpty ||
                  c.profileImageUrl!.contains('/defaults/');
              final letter = c.fullName.isNotEmpty
                  ? c.fullName.substring(0, 1)
                  : '؟';
              return Stack(
                children: [
                  // Avatar
                  isDefault
                      ? Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: c.isCompleted
                                    ? const Color(0xFF01A449)
                                    : Colors.transparent,
                                width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(letter,
                              style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary)),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: c.isCompleted
                                    ? const Color(0xFF01A449)
                                    : Colors.transparent,
                                width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              c.profileImageUrl!,
                              width: 74,
                              height: 74,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 74,
                                height: 74,
                                color: _kPrimary.withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: Text(letter,
                                    style: const TextStyle(
                                        fontFamily: _kFont,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: _kPrimary)),
                              ),
                            ),
                          ),
                        ),
                  // Green check badge if completed
                  if (c.isCompleted)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                            color: Color(0xFF01A449), shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            size: 15, color: Colors.white),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _buildSection(
      {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInput(
      {required TextEditingController controller, String hint = ''}) {
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: _kFont, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: _kFont, color: Colors.black38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: _kPrimary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPillButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: _kFont, fontSize: 14),
            ),
            Opacity(
              opacity: 0.5,
              child: Icon(icon, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle +/- button ────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 24, color: Colors.black),
      ),
    );
  }
}

// ─── Delete dialog ────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.onCancel, required this.onConfirm});

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
          child: Stack(
            children: [
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
                    child: const Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
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
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'هل أنت متأكد من حذف هذه المهمة؟',
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
                        Expanded(
                          child: GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                      color: Colors.black
                                          .withValues(alpha: 0.5))),
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
    );
  }
}
