import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';

/// نوع البطاقة الطبية: روشتة (أدوية) أو تشخيص (نص).
enum ClinicalRecordType { prescription, diagnosis }

/// ============================================================
/// بطاقة الورقة الطبية (الروشتة / التشخيص) كما تُعرض لولي الأمر.
///
/// تُرسم فوق صورة القالب (template) الرسمية. كل المواضع مُعرّفة كـ "نِسَب"
/// (0..1) من عرض/ارتفاع القالب، ثم تُضرب في أبعاد القالب الفعلية لكل نوع —
/// فمجموعة نِسَب واحدة تعمل للقالبين رغم اختلاف أبعادهما بالبكسل.
/// يتكفّل [FittedBox] بتصغير البطاقة لتناسب عرض الشاشة.
///
/// 🔧 الضبط الدقيق: عدّل ثوابت النِسَب أدناه (_fDoctorNameTop ...). القيم
/// مُعايَرة على القالبين المرفقين (prescription 1057×1488، diagnosis 1086×1448).
/// ============================================================
class ClinicalRecordPaper extends StatelessWidget {
  final ClinicalRecordType type;

  // بيانات الترويسة
  final String doctorName;
  final String specialization;
  final String patientName;
  final int? patientAge;
  final String dateText;

  // المحتوى
  final List<PrescriptionMedicine> medicines; // للروشتة
  final String? diagnosisText; // للتشخيص

  const ClinicalRecordPaper({
    super.key,
    required this.type,
    required this.doctorName,
    required this.specialization,
    required this.patientName,
    required this.patientAge,
    required this.dateText,
    this.medicines = const [],
    this.diagnosisText,
  });

  // ── أبعاد القوالب الفعلية بالبكسل ───────────────────────────────────────────
  static const double _prescW = 1057, _prescH = 1488;
  static const double _diagW = 1086, _diagH = 1448;

  static const String _prescriptionTemplate = 'images/prescription_template.png';
  static const String _diagnosisTemplate = 'images/diagnosis_template.png';

  // ── نِسَب المواضع (0..1) — مُعايَرة على القالبين ─────────────────────────────
  // اسم الطبيب وتخصصه (نص أبيض في الشريط الأحمر العلوي يمين)
  static const double _fDoctorNameTop = 0.078;
  static const double _fDoctorNameRight = 0.110;
  static const double _fDoctorSpecTop = 0.128;
  static const double _fDoctorSpecRight = 0.120;

  // قيم: اسم المريض / السن / التاريخ (على نفس سطر التسمية المطبوعة، يسار النقطتين)
  static const double _fPatientNameTop = 0.178;
  static const double _fPatientNameRight = 0.470;
  static const double _fAgeTop = 0.214;
  static const double _fAgeRight = 0.440;
  static const double _fDateTop = 0.214;
  static const double _fDateRight = 0.720;

  // منطقة المحتوى — تبدأ تحت RX/ أو التشخيص الطبي/ (الأخير أدنى قليلاً)
  static const double _fBodyTopPresc = 0.322;
  static const double _fBodyTopDiag = 0.360;
  static const double _fBodyBottom = 0.205;
  static const double _fBodySide = 0.075;

  // ارتفاع السطر (للمحاذاة مع الأسطر المنقّطة المطبوعة)
  static const double _fLineHeight = 0.0335;

  bool get _isPresc => type == ClinicalRecordType.prescription;
  double get _w => _isPresc ? _prescW : _diagW;
  double get _h => _isPresc ? _prescH : _diagH;
  String get _template => _isPresc ? _prescriptionTemplate : _diagnosisTemplate;

  @override
  Widget build(BuildContext context) {
    final w = _w, h = _h;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FittedBox(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _template,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => _FallbackFrame(type: type),
                ),
              ),

              // اسم الطبيب
              Positioned(
                top: _fDoctorNameTop * h,
                right: _fDoctorNameRight * w,
                child: Text(
                  doctorName.isEmpty ? '—' : doctorName,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.bold,
                    fontSize: w * 0.037,
                    color: Colors.white,
                  ),
                ),
              ),
              // تخصص الطبيب
              Positioned(
                top: _fDoctorSpecTop * h,
                right: _fDoctorSpecRight * w,
                child: Text(
                  specialization,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w500,
                    fontSize: w * 0.024,
                    color: Colors.white,
                  ),
                ),
              ),

              // اسم المريض
              Positioned(
                top: _fPatientNameTop * h,
                right: _fPatientNameRight * w,
                child: _valueText(patientName, w),
              ),
              // السن (يمين) و التاريخ (يسار)
              Positioned(
                top: _fAgeTop * h,
                right: _fAgeRight * w,
                child: _valueText(patientAge != null ? '$patientAge سنة' : '—', w),
              ),
              Positioned(
                top: _fDateTop * h,
                right: _fDateRight * w,
                child: _valueText(_formatArabicDate(dateText), w),
              ),

              // المحتوى
              Positioned(
                top: (_isPresc ? _fBodyTopPresc : _fBodyTopDiag) * h,
                bottom: _fBodyBottom * h,
                right: _fBodySide * w,
                left: _fBodySide * w,
                child: _isPresc ? _buildMedicines(w, h) : _buildDiagnosis(w),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueText(String text, double w) => Text(
        text,
        style: TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontWeight: FontWeight.w600,
          fontSize: w * 0.028,
          color: Colors.black87,
        ),
      );

  Widget _buildMedicines(double w, double h) {
    if (medicines.isEmpty) return const SizedBox.shrink();
    final lineH = _fLineHeight * h;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < medicines.length; i++)
          SizedBox(
            height: lineH,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: lineH * 0.18),
                child: Text(
                  _medicineLine(medicines[i], i + 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w600,
                    fontSize: w * 0.027,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _medicineLine(PrescriptionMedicine m, int index) {
    final parts = <String>[
      m.medicineName,
      if (m.quantity.isNotEmpty) m.quantity,
      if (m.timing.isNotEmpty) m.timing,
    ];
    return '$index. ${parts.join('  -  ')}';
  }

  Widget _buildDiagnosis(double w) {
    final text = (diagnosisText ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontWeight: FontWeight.w600,
          fontSize: w * 0.028,
          height: 1.6, // يقارب تباعد الأسطر المطبوعة
          color: Colors.black87,
        ),
      ),
    );
  }

  static String _formatArabicDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        const monthName = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
        return '$day ${monthName[month]} $year';
      }
    } catch (_) {}
    return dateStr;
  }
}

/// إطار احتياطي يُرسم بالكود عند غياب صورة القالب — كي لا تنكسر الصفحة.
class _FallbackFrame extends StatelessWidget {
  final ClinicalRecordType type;
  const _FallbackFrame({required this.type});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFBF092F);
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 360,
            decoration: const BoxDecoration(
              color: red,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(120)),
            ),
          ),
          const Spacer(),
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: red,
              borderRadius: BorderRadius.only(topRight: Radius.circular(120)),
            ),
          ),
        ],
      ),
    );
  }
}
