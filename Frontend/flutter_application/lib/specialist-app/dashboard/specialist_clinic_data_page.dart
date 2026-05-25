import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinic_details_page.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_status_card.dart';

class ClinicData {
  String name;
  String city;
  String region;
  String address;
  String phone;
  String schedule;
  String examinationPrice;
  String consultationPrice;
  Map<String, String?> imagePaths;
  DateTime submissionDate;

  ClinicData({
    required this.name,
    required this.city,
    required this.region,
    required this.address,
    required this.phone,
    required this.schedule,
    required this.examinationPrice,
    required this.consultationPrice,
    this.imagePaths = const {},
    required this.submissionDate,
  });
}

String formatMockDate(DateTime? date) {
  if (date == null) return '';
  final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  return 'منذ ${date.day} ${months[date.month - 1]} ${date.year}';
}

List<ClinicData> globalClinicsList = [];
ClinicData? globalDraftClinic;

class SpecialistClinicDataPage extends StatefulWidget {
  const SpecialistClinicDataPage({super.key});

  @override
  State<SpecialistClinicDataPage> createState() => _SpecialistClinicDataPageState();
}

class _SpecialistClinicDataPageState extends State<SpecialistClinicDataPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      'بيانات العيادة',
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
              if (globalClinicsList.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/specialist_box.png',
                          width: 100,
                          height: 100,
                          color: Colors.black.withValues(alpha: 0.4),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'يبدو انه لا يتوفر عيادات تم اضافتها,',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 16,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اضغط اضافة عيادة جديدة',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 16,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        ...globalClinicsList.map((clinic) => Column(
                          children: [
                            ClinicStatusCard(
                              title: clinic.name,
                              date: formatMockDate(clinic.submissionDate),
                              status: 'جاري المراجعة',
                              actionArea: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        globalDraftClinic = clinic;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const SpecialistClinicDetailsPage(),
                                          ),
                                        );
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        globalDraftClinic = clinic;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const SpecialistAddClinicPage(),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.black.withValues(alpha: 0.8)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                      ),
                                      child: const Text(
                                        'تعديل البيانات',
                                        style: TextStyle(
                                          fontFamily: specialistFont,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        globalClinicsList.remove(clinic);
                                      });
                                    },
                                    child: const Text(
                                      'الغاء طلب الاضافة',
                                      style: TextStyle(
                                        fontFamily: specialistFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )),
                      ],
                    ),
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
                      globalDraftClinic = null;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SpecialistAddClinicPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      'اضافة عيادة جديدة',
                      style: TextStyle(
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
