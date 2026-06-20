import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';

// ── Theme constants ───────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kBorder = Color(0xFFD9D9D9);
const Color _kHint = Color(0xFF9E9E9E);
const String _kFont = 'IBM Plex Sans Arabic';

/// شاشة الإبلاغ عن مشكلة تخص طبيباً (نوع المشكلة + وصف اختياري).
/// تُفتح من قائمة خيارات صفحة حجز الطبيب. تعيد `true` عند نجاح الإرسال.
class ReportProblemPage extends StatefulWidget {
  final String specialistId;
  final String? bookingId;
  final String? doctorName;

  const ReportProblemPage({
    super.key,
    required this.specialistId,
    this.bookingId,
    this.doctorName,
  });

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final ParentConsultationService _api = ParentConsultationService();
  final TextEditingController _descController = TextEditingController();

  List<ProblemCategory> _categories = [];
  ProblemCategory? _selected;
  bool _dropdownOpen = false;
  bool _loadingCategories = true;
  bool _submitting = false;

  // قائمة احتياطية في حال فشل جلب الأنواع من الـ API (نفس قيم الـ enum في الباك إند)
  static final List<ProblemCategory> _fallback = [
    ProblemCategory(value: 1, key: 'unprofessional_conduct', labelAr: 'سلوك غير مهني أو غير لائق'),
    ProblemCategory(value: 2, key: 'incorrect_doctor_info', labelAr: 'معلومات الطبيب/العيادة غير صحيحة'),
    ProblemCategory(value: 3, key: 'doctor_no_show', labelAr: 'عدم حضور الطبيب في موعد الجلسة'),
    ProblemCategory(value: 4, key: 'other', labelAr: 'سبب اخر'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _api.getProblemCategories();
      if (!mounted) return;
      setState(() {
        _categories = list.isNotEmpty ? list : _fallback;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = _fallback;
        _loadingCategories = false;
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: _kFont)),
        backgroundColor: _kPrimary,
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) {
      _toast('يرجى اختيار نوع المشكلة الرئيسية');
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await _api.submitProblemReport(
        specialistId: widget.specialistId,
        category: _selected!.value,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        bookingId: widget.bookingId,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccessDialog();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBEDEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: _kPrimary, size: 34),
                ),
                const SizedBox(height: 18),
                const Text(
                  'تم ارسال الابلاغ بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'سوف يتم مراجعة الابلاغ بدقة خلال الفترة القادمة وسنسعى للرد عليكم قريبا في الاشعارات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCategoryLabel(),
                      const SizedBox(height: 10),
                      _buildCategoryField(),
                      const SizedBox(height: 28),
                      const Text(
                        'وصف المشكلة الحالية',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildDescriptionField(),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            'الابلاغ عن مشكلة',
            style: TextStyle(
              fontFamily: _kFont,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F1F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.black87, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category selector ─────────────────────────────────────────────────────────

  Widget _buildCategoryLabel() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '*',
          style: TextStyle(fontFamily: _kFont, color: _kPrimary, fontSize: 15),
        ),
        Text(
          'اختر نوع المشكلة الرئيسية',
          style: TextStyle(
            fontFamily: _kFont,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _loadingCategories
              ? null
              : () => setState(() => _dropdownOpen = !_dropdownOpen),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _dropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selected?.labelAr ?? 'اختر نوع المشكلة الرئيسية...',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      color: _selected == null ? _kHint : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_dropdownOpen) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < _categories.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                  _buildOptionRow(_categories[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionRow(ProblemCategory option) {
    final bool isSelected = _selected?.value == option.value;
    return InkWell(
      onTap: () => setState(() {
        _selected = option;
        _dropdownOpen = false;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.labelAr,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kPrimary : _kBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Description ───────────────────────────────────────────────────────────────

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _descController,
        maxLines: 5,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: _kFont, fontSize: 14, color: Colors.black),
        decoration: const InputDecoration(
          hintText: 'اكتب الشكوى هنا...',
          hintStyle: TextStyle(fontFamily: _kFont, fontSize: 14, color: _kHint),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'ارسال',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
