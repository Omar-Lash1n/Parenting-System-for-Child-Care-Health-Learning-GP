import 'package:flutter/material.dart';
import 'package:Ajial/api/parent_consultation_service.dart';

/// نوع البطاقة الطبية: روشتة (أدوية) أو تشخيص (نص).
enum ClinicalRecordType { prescription, diagnosis }

/// ============================================================
/// بطاقة الورقة الطبية (الروشتة / التشخيص) كما تُعرض لولي الأمر.
///
/// تُرسم فوق صورة القالب (template) الرسمية للعيادة. كل الإحداثيات معرّفة
/// في "مساحة تصميم" ثابتة بأبعاد القالب الأصلية (بكسل)، ويتكفّل [FittedBox]
/// بتصغيرها لتناسب عرض الشاشة — لذا يكفي ضبط الإحداثيات مرة واحدة لتطابق
/// صورة القالب بدقة.
///
/// 🔧 للضبط بعد إضافة صورة القالب الحقيقية: عدّل [_designWidth] / [_designHeight]
/// لتساوي أبعاد ملف الـ PNG بالبكسل، ثم اضبط ثوابت المواضع أدناه.
/// ============================================================
class ClinicalRecordPaper extends StatelessWidget {
  final ClinicalRecordType type;

  // بيانات الترويسة (تُرسم فوق المنطقة الفارغة من القالب)
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

  // ── أبعاد مساحة التصميم (أبعاد صورة القالب بالبكسل) ──────────────────────────
  static const double _designWidth = 1000;
  static const double _designHeight = 1450;

  // ── مسارات صور القوالب (ضعها في مجلد images/) ───────────────────────────────
  static const String _prescriptionTemplate = 'images/prescription_template.png';
  static const String _diagnosisTemplate = 'images/diagnosis_template.png';

  // ── مواضع الترويسة (left/top/right بإحداثيات مساحة التصميم) ──────────────────
  // اسم الطبيب وتخصصه (نص أبيض أعلى يمين القالب فوق منطقة الاسم الفارغة)
  static const double _doctorNameTop = 150;
  static const double _doctorNameRight = 110;
  static const double _doctorSpecTop = 225;
  static const double _doctorSpecRight = 130;

  // قيم: اسم المريض / السن / التاريخ (نص أسود)
  static const double _patientNameTop = 430;
  static const double _patientNameRight = 430;
  static const double _ageTop = 500;
  static const double _ageRight = 600;
  static const double _dateTop = 500;
  static const double _dateRight = 250;

  // منطقة المحتوى (تحت RX/ أو التشخيص الطبي/)
  static const double _bodyTop = 600;
  static const double _bodyBottom = 230;
  static const double _bodySide = 90;

  String get _template =>
      type == ClinicalRecordType.prescription ? _prescriptionTemplate : _diagnosisTemplate;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FittedBox(
        child: SizedBox(
          width: _designWidth,
          height: _designHeight,
          child: Stack(
            children: [
              // خلفية القالب (مع احتياطي يُرسم بالكود إذا غابت الصورة)
              Positioned.fill(
                child: Image.asset(
                  _template,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => _FallbackFrame(type: type),
                ),
              ),

              // اسم الطبيب
              Positioned(
                top: _doctorNameTop,
                right: _doctorNameRight,
                child: Text(
                  doctorName.isEmpty ? '—' : doctorName,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.bold,
                    fontSize: 46,
                    color: Colors.white,
                  ),
                ),
              ),
              // تخصص الطبيب
              Positioned(
                top: _doctorSpecTop,
                right: _doctorSpecRight,
                child: Text(
                  specialization,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w500,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
              ),

              // اسم المريض
              Positioned(
                top: _patientNameTop,
                right: _patientNameRight,
                child: _valueText(patientName),
              ),
              // السن
              Positioned(
                top: _ageTop,
                right: _ageRight,
                child: _valueText(patientAge != null ? '$patientAge سنة' : '—'),
              ),
              // التاريخ
              Positioned(
                top: _dateTop,
                right: _dateRight,
                child: _valueText(_formatArabicDate(dateText)),
              ),

              // المحتوى (الأدوية أو التشخيص)
              Positioned(
                top: _bodyTop,
                bottom: _bodyBottom,
                right: _bodySide,
                left: _bodySide,
                child: type == ClinicalRecordType.prescription
                    ? _buildMedicines()
                    : _buildDiagnosis(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueText(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontWeight: FontWeight.w600,
          fontSize: 30,
          color: Colors.black87,
        ),
      );

  Widget _buildMedicines() {
    if (medicines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < medicines.length; i++) _medicineRow(medicines[i], i + 1),
      ],
    );
  }

  Widget _medicineRow(PrescriptionMedicine m, int index) {
    final parts = <String>[
      m.medicineName,
      if (m.quantity.isNotEmpty) m.quantity,
      if (m.timing.isNotEmpty) m.timing,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(
        '$index. ${parts.join('  -  ')}',
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontWeight: FontWeight.w600,
          fontSize: 34,
          height: 1.4,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDiagnosis() {
    final text = (diagnosisText ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontWeight: FontWeight.w600,
          fontSize: 34,
          height: 1.6,
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(120),
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: red,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(120),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
