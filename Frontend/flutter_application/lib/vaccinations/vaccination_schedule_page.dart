// lib/vaccinations/vaccination_schedule_page.dart
//
// Vaccination Schedule — a STATIC informational screen showing the official
// mandatory vaccination schedule for children in Egypt (جدول التطعيمات
// الإجبارية للأطفال فى مصر), plus the "in case of delay" reference table.
//
// All data is hard-coded (no API) — sourced from جمعية وقاية.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
const Color _kPrimary = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x1ABF092F);
const Color _kGreen = Color(0xFF01A449);
const Color _kGrey = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kCardGrey = Color(0xFFF8FAFC);
const String _kFont = 'IBM Plex Sans Arabic';

// ─────────────────────────────────────────────
// Data models (immutable, local to this screen)
// ─────────────────────────────────────────────

/// A single vaccine entry within an age group.
class _VaccineRow {
  final String dose; // الجرعة
  final String vaccine; // الطعم
  final String disease; // المرض
  final String amount; // كمية الطعم
  final String method; // كيفية الإعطاء

  const _VaccineRow({
    required this.dose,
    required this.vaccine,
    required this.disease,
    required this.amount,
    required this.method,
  });
}

/// An age group containing one or more vaccine rows.
class _AgeGroup {
  final String age; // العمر
  final List<_VaccineRow> rows;

  const _AgeGroup({required this.age, required this.rows});
}

/// A row in the "in case of delay" reference table.
class _DelayRow {
  final String vaccine; // التطعيم
  final String doses; // عدد الجرعات
  final List<String> intervals; // الفترات بين الجرعات
  final String? note; // ملاحظة تمتد عبر الأعمدة

  const _DelayRow({
    required this.vaccine,
    required this.doses,
    this.intervals = const [],
    this.note,
  });
}

// ─────────────────────────────────────────────
// Static data — مأخوذة من جدول جمعية وقاية
// ─────────────────────────────────────────────
const String _kPentaDisease =
    'الدفتريا والسعال الديكى والتيتانوس والالتهاب الكبدى الفيروسى بى '
    'والانفلونزا المستدمية النزفية نمط بى';

const List<_AgeGroup> _kSchedule = [
  _AgeGroup(
    age: 'عند الميلاد',
    rows: [
      _VaccineRow(
        dose: 'جرعة الميلاد',
        vaccine: 'كبدى بى رضع',
        disease: 'الالتهاب الكبدى الفيروسى بى',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالفخذ اليمنى',
      ),
      _VaccineRow(
        dose: 'الجرعة الصفرية',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'جرعة الدرن',
        vaccine: 'بى سى جى',
        disease: 'الدرن',
        amount: '٠.٠٥ سم',
        method: 'حقنا داخل الجلد بالكتف الأيسر',
      ),
    ],
  ),
  _AgeGroup(
    age: 'شهرين',
    rows: [
      _VaccineRow(
        dose: 'الجرعة الأولى',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'الجرعة الأولى',
        vaccine: 'طعم الخماسى',
        disease: _kPentaDisease,
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالفخذ اليمنى',
      ),
    ],
  ),
  _AgeGroup(
    age: '٤ شهور',
    rows: [
      _VaccineRow(
        dose: 'الجرعة الثانية',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'الجرعة الثانية',
        vaccine: 'طعم الخماسى',
        disease: _kPentaDisease,
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالفخذ اليمنى',
      ),
      _VaccineRow(
        dose: 'الجرعة الثانية',
        vaccine: 'سولك',
        disease: 'طعم شلل الأطفال المعطل بالحقن',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالفخذ اليسرى',
      ),
    ],
  ),
  _AgeGroup(
    age: '٦ شهور',
    rows: [
      _VaccineRow(
        dose: 'الجرعة الثالثة',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'الجرعة الثالثة',
        vaccine: 'طعم الخماسى',
        disease: _kPentaDisease,
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالفخذ اليمنى',
      ),
    ],
  ),
  _AgeGroup(
    age: '٩ شهور',
    rows: [
      _VaccineRow(
        dose: 'الجرعة الرابعة',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'الجرعة الرابعة',
        vaccine: 'فيتامين أ',
        disease: 'فيتامين أ',
        amount: 'كبسولة',
        method: 'بالفم',
      ),
    ],
  ),
  _AgeGroup(
    age: '١٢ شهر',
    rows: [
      _VaccineRow(
        dose: 'الجرعة الخامسة',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'الجرعة الخامسة',
        vaccine: 'ام ام آر الفيروسى',
        disease: 'الحصبة والنكاف والحصبة الألمانى',
        amount: '٠.٥ سم',
        method: 'حقنا تحت الجلد بالذراع اليمنى',
      ),
    ],
  ),
  _AgeGroup(
    age: '١٨ شهر',
    rows: [
      _VaccineRow(
        dose: 'الجرعة المنشطة',
        vaccine: 'سابين',
        disease: 'شلل الأطفال',
        amount: 'نقطتان',
        method: 'بالفم',
      ),
      _VaccineRow(
        dose: 'الجرعة المنشطة',
        vaccine: 'ام ام آر الفيروسى',
        disease: 'الحصبة والنكاف والحصبة الألمانى',
        amount: '٠.٥ سم',
        method: 'حقنا تحت الجلد بالذراع اليمنى',
      ),
      _VaccineRow(
        dose: 'الجرعة المنشطة',
        vaccine: 'الثلاثى البكتيرى',
        disease: 'الدفتريا والتيتانوس والسعال الديكى',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالفخذ اليسرى',
      ),
      _VaccineRow(
        dose: 'الجرعة المنشطة',
        vaccine: 'فيتامين أ',
        disease: 'فيتامين أ',
        amount: '٢ كبسولة',
        method: 'بالفم',
      ),
    ],
  ),
  _AgeGroup(
    age: 'أولى حضانة — ٤ سنوات',
    rows: [
      _VaccineRow(
        dose: '٤ سنوات',
        vaccine: 'المكورات السحائية الثنائى',
        disease: 'الالتهاب السحائى البكتيرى',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالذراع اليسرى',
      ),
    ],
  ),
  _AgeGroup(
    age: 'أولى ابتدائى — ٦ سنوات',
    rows: [
      _VaccineRow(
        dose: '٦ سنوات',
        vaccine: 'المكورات السحائية الثنائى',
        disease: 'الالتهاب السحائى البكتيرى',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالذراع اليسرى',
      ),
    ],
  ),
  _AgeGroup(
    age: 'ثانية ابتدائى — ٧ سنوات',
    rows: [
      _VaccineRow(
        dose: '٧ سنوات',
        vaccine: 'الثنائى البكتيرى',
        disease: 'الدفتريا والتيتانوس',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالذراع اليسرى',
      ),
    ],
  ),
  _AgeGroup(
    age: 'رابعة ابتدائى — ١٠ سنوات',
    rows: [
      _VaccineRow(
        dose: '١٠ سنوات',
        vaccine: 'الثنائى البكتيرى',
        disease: 'الدفتريا والتيتانوس',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالذراع اليسرى',
      ),
    ],
  ),
  _AgeGroup(
    age: 'أولى إعدادى — ١٢ سنة',
    rows: [
      _VaccineRow(
        dose: '١٢ سنة',
        vaccine: 'المكورات السحائية الثنائى',
        disease: 'الالتهاب السحائى البكتيرى',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالذراع اليسرى',
      ),
    ],
  ),
  _AgeGroup(
    age: 'أولى ثانوى — ١٥ سنة',
    rows: [
      _VaccineRow(
        dose: '١٥ سنة',
        vaccine: 'المكورات السحائية الثنائى',
        disease: 'الالتهاب السحائى البكتيرى',
        amount: '٠.٥ سم',
        method: 'حقنا بالعضل بالذراع اليسرى',
      ),
    ],
  ),
];

const List<_DelayRow> _kDelayTable = [
  _DelayRow(
    vaccine: 'شلل الأطفال',
    doses: '٧',
    intervals: ['شهر', 'شهر', 'شهر', 'شهر', 'شهر', 'شهر'],
  ),
  _DelayRow(
    vaccine: 'فيروس بى',
    doses: '٣',
    intervals: ['شهر', 'شهرين'],
  ),
  _DelayRow(
    vaccine: 'الثلاثى',
    doses: '٤',
    intervals: ['شهر', 'شهرين', '٣ شهور'],
    note: 'يتم إعطاء الثنائى بدل الثلاثى للأطفال بعد سن عامين',
  ),
  _DelayRow(
    vaccine: 'الإنفلونزا البكتيرية',
    doses: '٣',
    intervals: ['شهر', 'شهرين'],
  ),
  _DelayRow(
    vaccine: 'ام ام آر الفيروسى',
    doses: '٢',
    intervals: ['٦ شهور'],
  ),
  _DelayRow(
    vaccine: 'الدرن',
    doses: '١',
    note: 'يتم إعطاء التطعيم فى أى وقت، ولكن اذا بلغ عمر الطفل أكثر من عام يجب '
        'عمل اختبار الدرن (تيوبركولين) أولا والتأكد من سلبية الاختبار قبل التطعيم',
  ),
  _DelayRow(
    vaccine: 'فيتامين أ',
    doses: '٢',
    intervals: ['٤ شهور'],
  ),
];

// ─────────────────────────────────────────────
// VaccinationSchedulePage
// ─────────────────────────────────────────────
class VaccinationSchedulePage extends StatelessWidget {
  const VaccinationSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _buildIntroBanner(),
                    const SizedBox(height: 20),

                    // ── Main schedule (grouped by age) ──────────
                    const _SectionTitle('جدول التطعيمات الإجبارية'),
                    const SizedBox(height: 12),
                    ..._kSchedule.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _AgeGroupCard(group: g),
                        )),

                    const SizedBox(height: 12),

                    // ── Delay table ─────────────────────────────
                    const _SectionTitle('التطعيمات فى حالة التأخير'),
                    const SizedBox(height: 12),
                    ..._kDelayTable.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DelayCard(row: r),
                        )),

                    const SizedBox(height: 16),
                    _buildFooterNote(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(Icons.arrow_forward_rounded,
                    color: _kPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'جدول التطعيمات',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Intro banner ────────────────────────────
  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, Color(0xFF8E0623)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33BF092F), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.vaccines_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'جدول التطعيمات الإجبارية للأطفال فى مصر',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'دليل استرشادى بالمواعيد والجرعات وكيفية إعطاء كل تطعيم منذ الميلاد '
            'وحتى المرحلة الثانوية.',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer disclaimer ───────────────────────
  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE2C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'هذا الجدول للاسترشاد فقط. يُرجى دائمًا الرجوع إلى الطبيب أو مكتب '
              'الصحة لتحديد المواعيد المناسبة لطفلك.',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 12,
                color: const Color(0xFF92610A),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _SectionTitle
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _AgeGroupCard — one age with its vaccines
// ─────────────────────────────────────────────
class _AgeGroupCard extends StatelessWidget {
  final _AgeGroup group;
  const _AgeGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Age header
          Container(
            color: _kPrimaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: _kPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.age,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${group.rows.length} تطعيم',
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Vaccine rows
          for (int i = 0; i < group.rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _kBorder),
            _VaccineTile(row: group.rows[i]),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _VaccineTile — one vaccine row inside a group
// ─────────────────────────────────────────────
class _VaccineTile extends StatelessWidget {
  final _VaccineRow row;
  const _VaccineTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vaccine name + dose chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_liquid_rounded,
                    color: _kGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.vaccine,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.dose,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Disease
          _InfoLine(
            icon: Icons.coronavirus_rounded,
            label: 'المرض',
            value: row.disease,
          ),
          const SizedBox(height: 8),

          // Amount + method
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoLine(
                  icon: Icons.opacity_rounded,
                  label: 'كمية الطعم',
                  value: row.amount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _InfoLine(
                  icon: Icons.healing_rounded,
                  label: 'كيفية الإعطاء',
                  value: row.method,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _InfoLine — labelled value with icon
// ─────────────────────────────────────────────
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _kGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 10.5,
                  color: _kGrey,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// _DelayCard — one row of the "in case of delay" table
// ─────────────────────────────────────────────
class _DelayCard extends StatelessWidget {
  final _DelayRow row;
  const _DelayCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.vaccine,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimaryLight,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  'عدد الجرعات: ${row.doses}',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (row.intervals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'الفترات بين الجرعات',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 11,
                color: _kGrey,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < row.intervals.length; i++)
                  _IntervalChip(
                    label: 'من ${_ordinal(i + 1)} لـ${_ordinal(i + 2)}',
                    value: row.intervals[i],
                  ),
              ],
            ),
          ],
          if (row.note != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: _kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.note!,
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _ordinal(int n) {
    const names = [
      '',
      'الأولى',
      'الثانية',
      'الثالثة',
      'الرابعة',
      'الخامسة',
      'السادسة',
      'السابعة',
    ];
    return n < names.length ? names[n] : '$n';
  }
}

// ─────────────────────────────────────────────
// _IntervalChip
// ─────────────────────────────────────────────
class _IntervalChip extends StatelessWidget {
  final String label;
  final String value;
  const _IntervalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 10,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kGreen,
            ),
          ),
        ],
      ),
    );
  }
}
