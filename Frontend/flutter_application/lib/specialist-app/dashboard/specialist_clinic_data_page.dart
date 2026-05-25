import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinic_details_page.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_status_card.dart';
import 'package:Ajial/specialist-app/dashboard/providers/clinic_remote_provider.dart';
import 'package:Ajial/specialist-app/dashboard/models/clinic_remote_models.dart';

String formatClinicDate(DateTime? date) {
  if (date == null) return '';
  final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  return 'منذ ${date.day} ${months[date.month - 1]} ${date.year}';
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

class SpecialistClinicDataPage extends StatefulWidget {
  const SpecialistClinicDataPage({super.key});

  @override
  State<SpecialistClinicDataPage> createState() => _SpecialistClinicDataPageState();
}

class _SpecialistClinicDataPageState extends State<SpecialistClinicDataPage> {
  @override
  void initState() {
    super.initState();
    // Load clinics from API on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicRemoteProvider>().loadClinics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicRemoteProvider>();
    final clinics = provider.clinics;
    final isLoading = provider.loadingClinics;

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
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: specialistGreen)),
                )
              else if (provider.errorMessage != null && clinics.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage!,
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadClinics(),
                          style: ElevatedButton.styleFrom(backgroundColor: specialistGreen),
                          child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: specialistFont, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (clinics.isEmpty)
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
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadClinics(),
                    color: specialistGreen,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          ...clinics.map((clinic) => Column(
                            children: [
                              ClinicStatusCard(
                                title: clinic.name.isNotEmpty ? clinic.name : 'عيادة جديدة',
                                date: formatClinicDate(clinic.submittedAt),
                                status: clinic.statusAr,
                                statusColor: _statusColor(clinic.status),
                                rejectionReason: clinic.rejectionReason,
                                actionArea: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          provider.currentClinicDraftId = clinic.clinicId;
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SpecialistClinicDetailsPage(
                                                clinicId: clinic.clinicId,
                                              ),
                                            ),
                                          ).then((_) => provider.loadClinics());
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
                                    if (clinic.canEdit) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            // If status is pending, pull back to draft first
                                            if (clinic.status.toLowerCase() == 'pending') {
                                              await provider.startEditClinic(clinic.clinicId);
                                            }
                                            provider.currentClinicDraftId = clinic.clinicId;
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => SpecialistAddClinicPage(
                                                    clinicId: clinic.clinicId,
                                                  ),
                                                ),
                                              ).then((_) => provider.loadClinics());
                                            }
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
                                    ],
                                    if (clinic.canCancel) ...[
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: provider.submitting
                                            ? null
                                            : () async {
                                                final confirmed = await _showConfirmDialog(
                                                  context,
                                                  'هل أنت متأكد من إلغاء طلب إضافة العيادة؟',
                                                );
                                                if (confirmed == true) {
                                                  await provider.cancelClinic(clinic.clinicId);
                                                }
                                              },
                                        child: provider.submitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text(
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
                ),
              
              // Bottom Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: provider.submitting
                        ? null
                        : () async {
                            final clinicId = await provider.createClinic();
                            if (clinicId != null && context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SpecialistAddClinicPage(
                                    clinicId: clinicId,
                                  ),
                                ),
                              ).then((_) => provider.loadClinics());
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: provider.submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: specialistGreen),
                          )
                        : const Text(
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

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد', style: TextStyle(fontFamily: specialistFont, fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(fontFamily: specialistFont, fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('لا', style: TextStyle(fontFamily: specialistFont, color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('نعم', style: TextStyle(fontFamily: specialistFont, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
