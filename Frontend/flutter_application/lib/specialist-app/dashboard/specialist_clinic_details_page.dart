import 'dart:convert';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart'
    show SpecialistApplicationProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_status_card.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_page.dart';
import 'package:Ajial/specialist-app/dashboard/providers/clinic_remote_provider.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinic_data_page.dart';

class SpecialistClinicDetailsPage extends StatefulWidget {
  final String clinicId;

  const SpecialistClinicDetailsPage({super.key, required this.clinicId});

  @override
  State<SpecialistClinicDetailsPage> createState() =>
      _SpecialistClinicDetailsPageState();
}

class _SpecialistClinicDetailsPageState
    extends State<SpecialistClinicDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicRemoteProvider>().loadClinicDetail(widget.clinicId);
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.blueGrey;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return specialistGreen;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicProvider = context.watch<ClinicRemoteProvider>();
    final appProvider = context.watch<SpecialistApplicationProvider>();
    final detail = clinicProvider.clinicDetail;
    final specialty = appProvider.current?.specialtyName ?? '';
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
                    Text(
                      detail?.name ?? 'عيادة',
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
              if (clinicProvider.loadingClinicDetail)
                const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: specialistGreen)),
                )
              else if (detail == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60, color: Colors.red.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          clinicProvider.errorMessage ?? 'لا توجد بيانات',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              clinicProvider.loadClinicDetail(widget.clinicId),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: specialistGreen),
                          child: const Text('إعادة المحاولة',
                              style: TextStyle(
                                  fontFamily: specialistFont,
                                  color: Colors.white)),
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
                        // Clinic Card
                        ClinicStatusCard(
                          title: detail.name ?? 'عيادة',
                          date: formatClinicDate(detail.submittedAt),
                          status: detail.statusAr,
                          statusColor: _statusColor(detail.status),
                          rejectionReason: detail.rejectionReason,
                        ),
                        const SizedBox(height: 24),

                        // Expansions
                        _buildExpansionTile(
                          title: 'تفاصيل العيادة',
                          children: [
                            _buildMockField('اسم العيادة', detail.name ?? ''),
                            _buildMockField('التخصص', displaySpecialty),
                            _buildMockField(
                                'المحافظة', detail.governorateName ?? ''),
                            _buildMockField(
                                'المدينة', detail.districtName ?? ''),
                            _buildMockField(
                                'العنوان التفصيلي', detail.address ?? ''),
                            _buildMockField(
                                'رقم موبايل العيادة', detail.phone ?? ''),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExpansionTile(
                          title: 'اوقات العمل و التكلفة',
                          children: [
                            _buildWorkingHoursSection(detail.workingHoursJson),
                            _buildMockField(
                                'سعر الكشف ج.م*',
                                detail.examinationPrice?.toStringAsFixed(0) ??
                                    ''),
                            _buildMockField(
                                'سعر الاستشارة ج.م*',
                                detail.consultationPrice?.toStringAsFixed(0) ??
                                    ''),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExpansionTile(
                          title: 'بيانات ترخيص العيادة',
                          children: [
                            _buildNetworkImageField(context,
                                'صورة ترخيص العيادة*', detail.licenseImageUrl),
                            _buildNetworkImageField(
                                context,
                                'صورة شهادة تسجيل العيادة بالنقابة*',
                                detail.syndicateRegistrationImageUrl),
                            _buildNetworkImageField(
                                context,
                                'صورة إيصال سداد رسوم النفايات الخطرة*',
                                detail.hazardousWasteImageUrl),
                            _buildNetworkImageField(
                                context,
                                'صورة العيادة من الخارج*',
                                detail.exteriorImageUrl),
                            _buildNetworkImageField(
                                context,
                                'صورة العيادة من الداخل*',
                                detail.interiorImageUrl),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Edit Data Button (only if canEdit)
                        if (detail.canEdit)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: clinicProvider.submitting
                                  ? null
                                  : () async {
                                      // If pending, pull back to draft first
                                      if (detail.status.toLowerCase() ==
                                          'pending') {
                                        await clinicProvider
                                            .startEditClinic(widget.clinicId);
                                      }
                                      if (context.mounted) {
                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    SpecialistAddClinicPage(
                                                  clinicId: widget.clinicId,
                                                ),
                                              ),
                                            )
                                            .then((_) =>
                                                clinicProvider.loadClinicDetail(
                                                    widget.clinicId));
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.8)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: clinicProvider.submitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text(
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

                        if (detail.canCancel) ...[
                          const SizedBox(height: 16),
                          // Cancel Request TextButton
                          TextButton(
                            onPressed: clinicProvider.submitting
                                ? null
                                : () async {
                                    final confirmed = await _showConfirmDialog(
                                      context,
                                      'هل أنت متأكد من إلغاء طلب إضافة العيادة؟',
                                    );
                                    if (confirmed == true) {
                                      final success = await clinicProvider
                                          .cancelClinic(widget.clinicId);
                                      if (success && context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    }
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

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد',
              style: TextStyle(
                  fontFamily: specialistFont, fontWeight: FontWeight.bold)),
          content: Text(message,
              style: const TextStyle(fontFamily: specialistFont, fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('لا',
                  style: TextStyle(
                      fontFamily: specialistFont, color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('نعم',
                  style: TextStyle(
                      fontFamily: specialistFont,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile(
      {required String title, required List<Widget> children}) {
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
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: children,
        ),
      ),
    );
  }

  Widget _buildMockField(String label, String value,
      {bool hasDropdown = false, bool hasCalendar = false}) {
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
                  const Icon(Icons.calendar_today_outlined,
                      color: Colors.grey, size: 20),
                if (hasCalendar) const SizedBox(width: 8),
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
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursSection(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return _buildMockField('مواعيد العمل*', '', hasCalendar: true);
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        if (decoded['type'] == 'fixed') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMockField('مواعيد العمل*', 'مواعيد ثابتة', hasCalendar: true),
              _buildScheduleBlock('يومياً من ${decoded['from']} الى ${decoded['to']}'),
              const SizedBox(height: 8),
            ],
          );
        } else if (decoded['type'] == 'specific') {
          final periods = decoded['periods'] as List? ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMockField('مواعيد العمل*', 'مواعيد مخصصة', hasCalendar: true),
              for (var p in periods)
                _buildScheduleBlock('${p['day']} من ${p['from']} الى ${p['to']}'),
              const SizedBox(height: 8),
            ],
          );
        }
      }
    } catch (_) {
      // Fallback
    }

    return _buildMockField('مواعيد العمل*', jsonString, hasCalendar: true);
  }

  Widget _buildScheduleBlock(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 14,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNetworkImageField(
      BuildContext context, String label, String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
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
                  hasImage ? 'تم تحميل الصورة' : 'لم يتم التحميل',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 14,
                    color: hasImage
                        ? specialistGreen
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const Spacer(),
                if (hasImage)
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: const Text('عرض الصورة',
                                      style: TextStyle(
                                          fontFamily: specialistFont,
                                          fontSize: 16)),
                                  automaticallyImplyLeading: false,
                                  elevation: 0,
                                  backgroundColor: Colors.white,
                                  actions: [
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.black),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Image.network(imageUrl,
                                      fit: BoxFit.contain),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.4)),
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
