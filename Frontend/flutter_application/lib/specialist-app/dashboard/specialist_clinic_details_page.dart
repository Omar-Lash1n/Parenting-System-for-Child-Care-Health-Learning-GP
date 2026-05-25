import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_status_card.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinic_data_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_page.dart';

class SpecialistClinicDetailsPage extends StatelessWidget {
  const SpecialistClinicDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpecialistApplicationProvider>();
    final specialty = provider.current?.specialtyName ?? '';
    final displaySpecialty = specialty.isEmpty ? 'طبيب عام' : specialty;

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
                    Text(
                      globalDraftClinic?.name ?? 'عيادة',
                      style: const TextStyle(
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Clinic Card
                      ClinicStatusCard(
                        title: globalDraftClinic?.name ?? 'عيادة',
                        date: formatMockDate(globalDraftClinic?.submissionDate),
                        status: 'جاري المراجعة',
                        // rejectionReason: 'يبدوا ان شهادة تسجيل العيادة بالنقابة غير واضحة يمكنك ارفاق نسخة احدث والتقدم مرة اخرى',
                      ),
                      const SizedBox(height: 24),

                      // Expansions
                      _buildExpansionTile(
                        title: 'تفاصيل العيادة',
                        children: [
                          _buildMockField('اسم العيادة', globalDraftClinic?.name ?? 'عيادة الأمل لطب الأطفال'),
                          _buildMockField('التخصص', displaySpecialty),
                          _buildMockField('المحافظة', globalDraftClinic?.city ?? 'القاهرة'),
                          _buildMockField('المدينة', globalDraftClinic?.region ?? 'نصر'),
                          _buildMockField('العنوان التفصيلي', globalDraftClinic?.address ?? 'شارع الأمل تقاطع 2 بجوار محل مخبز القاهرة'),
                          _buildMockField('رقم موبايل العيادة', globalDraftClinic?.phone ?? '0102355565'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildExpansionTile(
                        title: 'اوقات العمل و التكلفة',
                        children: [
                          _buildMockField('مواعيد العمل*', globalDraftClinic?.schedule ?? 'مواعيد مخصصة', hasCalendar: true),
                          _buildMockField('سعر الكشف ج.م*', globalDraftClinic?.examinationPrice ?? '150'),
                          _buildMockField('سعر الاستشارة ج.م*', globalDraftClinic?.consultationPrice ?? '50'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildExpansionTile(
                        title: 'بيانات ترخيص العيادة',
                        children: [
                          _buildMockImageField(context, 'صورة ترخيص العيادة*', globalDraftClinic?.imagePaths['license']),
                          _buildMockImageField(context, 'صورة شهادة تسجيل العيادة بالنقابة*', globalDraftClinic?.imagePaths['syndicate']),
                          _buildMockImageField(context, 'صورة إيصال سداد رسوم النفايات الخطرة*', globalDraftClinic?.imagePaths['waste']),
                          _buildMockImageField(context, 'صورة العيادة من الخارج*', globalDraftClinic?.imagePaths['exterior']),
                          _buildMockImageField(context, 'صورة العيادة من الداخل*', globalDraftClinic?.imagePaths['interior']),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Edit Data Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cancel Request TextButton
                      TextButton(
                        onPressed: () {
                          if (globalDraftClinic != null) {
                            globalClinicsList.remove(globalDraftClinic);
                            globalDraftClinic = null;
                          }
                          Navigator.of(context).pop();
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
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: children,
        ),
      ),
    );
  }

  Widget _buildMockField(String label, String value, {bool hasDropdown = false, bool hasCalendar = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.replaceAll('*', ''),
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              children: [
                if (label.contains('*'))
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                if (hasCalendar)
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                if (hasCalendar)
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (hasDropdown)
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockPeriodField(String period) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            period,
            style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockImageField(BuildContext context, String label, String? imagePath) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.replaceAll('*', ''),
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              children: [
                if (label.contains('*'))
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Text(
                  imagePath != null ? 'تم تحميل الصورة' : 'لم يتم التحميل',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {
                      if (imagePath != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: const Text('عرض الصورة', style: TextStyle(fontFamily: specialistFont, fontSize: 16)),
                                  automaticallyImplyLeading: false,
                                  elevation: 0,
                                  backgroundColor: Colors.white,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.black),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: kIsWeb 
                                      ? Image.network(imagePath, fit: BoxFit.contain)
                                      : Image.file(File(imagePath), fit: BoxFit.contain),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الصورة غير متوفرة', style: TextStyle(fontFamily: specialistFont))),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'فتح الصورة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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
