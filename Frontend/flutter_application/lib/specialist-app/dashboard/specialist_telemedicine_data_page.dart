import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_telemedicine_page.dart';

class TelemedicineData {
  String sessionPrice;
  String sessionDuration;
  String waitPeriod;
  String schedule;
  List<Map<String, String>> confirmedPeriods;
  DateTime submissionDate;

  TelemedicineData({
    required this.sessionPrice,
    required this.sessionDuration,
    required this.waitPeriod,
    required this.schedule,
    this.confirmedPeriods = const [],
    required this.submissionDate,
  });
}

List<TelemedicineData> globalTelemedicineList = [];
TelemedicineData? globalDraftTelemedicine;

String formatTelemedicineDate(DateTime? date) {
  if (date == null) return '';
  final months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  return 'منذ ${date.day} ${months[date.month - 1]} ${date.year}';
}

class SpecialistTelemedicineDataPage extends StatefulWidget {
  const SpecialistTelemedicineDataPage({super.key});

  @override
  State<SpecialistTelemedicineDataPage> createState() =>
      _SpecialistTelemedicineDataPageState();
}

class _SpecialistTelemedicineDataPageState
    extends State<SpecialistTelemedicineDataPage> {
  @override
  void initState() {
    super.initState();
    globalDraftTelemedicine = null;
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool hasData = globalTelemedicineList.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FAF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: specialistGreen,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'بيانات الكشف عن بعد',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: !hasData
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/specialist_box.png',
                              width: 80,
                              height: 80,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'يبدو انه لا يتوفر الكشوفات عن بعد تم\nاضافتها, اضغط اضافة كشف عن بعد جديد',
                              style: TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: globalTelemedicineList.length,
                        itemBuilder: (context, index) {
                          final data = globalTelemedicineList[index];
                          return TelemedicineRequestCard(
                            data: data,
                            onEdit: () {
                              globalDraftTelemedicine = data;
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SpecialistAddTelemedicinePage(),
                                ),
                              )
                                  .then((_) {
                                _refresh();
                              });
                            },
                            onDelete: () {
                              setState(() {
                                globalTelemedicineList.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
              ),

              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      globalDraftTelemedicine = null; // New request
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (_) => const SpecialistAddTelemedicinePage(),
                        ),
                      )
                          .then((_) {
                        _refresh();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      hasData ? 'اضافة كشف جديد' : 'اضافة خدمة كشف عن بعد',
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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

class TelemedicineRequestCard extends StatefulWidget {
  final TelemedicineData data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TelemedicineRequestCard({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TelemedicineRequestCard> createState() =>
      _TelemedicineRequestCardState();
}

class _TelemedicineRequestCardState extends State<TelemedicineRequestCard> {
  bool _isExpanded = false;

  Widget _buildDisabledField(String label, String value,
      {bool hasCalendar = false, bool hasDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Text(
              '*',
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.isEmpty ? 'غير محدد' : value,
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              if (hasCalendar)
                const Icon(Icons.calendar_month_outlined,
                    color: Colors.grey, size: 20),
              if (hasDropdown)
                const Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpecialistApplicationProvider>();
    final specialty = provider.current?.specialtyName ?? 'تخصص';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Always visible)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon (Right side in RTL)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: specialistGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Image.asset(
                      'images/notes.png',
                      color: specialistGreen,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTelemedicineDate(widget.data.submissionDate),
                        style: TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'جاري المراجعة',
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expanded Content Area
          if (_isExpanded) ...[
            Divider(color: Colors.black.withValues(alpha: 0.1), height: 1),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تفاصيل الكشف عن بعد',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.black.withValues(alpha: 0.1), height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDisabledField('سعر الجلسة ج.م', widget.data.sessionPrice),
                  _buildDisabledField('مدة الجلسة', widget.data.sessionDuration,
                      hasDropdown: true),
                  _buildDisabledField(
                      'فترة الانتظار بين كل جلسة', widget.data.waitPeriod,
                      hasDropdown: true),
                  if (widget.data.schedule == 'مواعيد مخصصة' && widget.data.confirmedPeriods.isNotEmpty) ...[
                    const Row(
                      children: [
                        Text(
                          'مواعيد العمل',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '*',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'مواعيد مخصصة',
                                style: TextStyle(
                                  fontFamily: specialistFont,
                                  fontSize: 14,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                              const Icon(Icons.calendar_month_outlined,
                                  color: Colors.grey, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...widget.data.confirmedPeriods.map((p) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${p['day']} من ${p['from']} الى ${p['to']}',
                                  style: TextStyle(
                                    fontFamily: specialistFont,
                                    fontSize: 13,
                                    color: Colors.black.withValues(alpha: 0.6),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildDisabledField('مواعيد العمل', widget.data.schedule,
                        hasCalendar: true),
                  ],
                ],
              ),
            ),
          ],

          // Action Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!_isExpanded) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: specialistGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'عرض طلب الاضافة',
                        style: TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onEdit,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'تعديل البيانات',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: widget.onDelete,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'الغاء طلب الاضافة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
