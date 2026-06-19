import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_telemedicine_page.dart';
import 'package:Ajial/specialist-app/dashboard/providers/clinic_remote_provider.dart';
import 'package:Ajial/specialist-app/dashboard/models/clinic_remote_models.dart';
import 'package:Ajial/specialist-app/dashboard/services/clinic_remote_api_service.dart';

String formatTelemedicineDate(DateTime? date) {
  if (date == null) return '';
  final months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  return 'منذ ${date.day} ${months[date.month - 1]} ${date.year}';
}

Color _rcStatusColor(String status) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicRemoteProvider>().loadRemoteConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicRemoteProvider>();
    final consultations = provider.remoteConsultations
        .where((c) => !(c.status.toLowerCase() == 'draft' && c.submittedAt == null))
        .toList();
    final isLoading = provider.loadingRemoteConsultations;
    final hasApproved = consultations.any((c) => c.status.toLowerCase() == 'approved');

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
              if (isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: specialistGreen)),
                )
              else if (provider.errorMessage != null && consultations.isEmpty)
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
                          onPressed: () => provider.loadRemoteConsultations(),
                          style: ElevatedButton.styleFrom(backgroundColor: specialistGreen),
                          child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: specialistFont, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (consultations.isEmpty)
                Expanded(
                  child: Center(
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
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadRemoteConsultations(),
                    color: specialistGreen,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: consultations.length,
                      itemBuilder: (context, index) {
                        final rc = consultations[index];
                        return TelemedicineRequestCard(
                          data: rc,
                          onEdit: () async {
                            if (rc.status.toLowerCase() == 'pending') {
                              await provider.startEditRemoteConsultation(rc.consultationId);
                            }
                            provider.currentRemoteConsultationDraftId = rc.consultationId;
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SpecialistAddTelemedicinePage(
                                    consultationId: rc.consultationId,
                                  ),
                                ),
                              ).then((_) => provider.loadRemoteConsultations());
                            }
                          },
                          onDelete: () async {
                            final confirmed = await _showConfirmDialog(
                              context,
                              'هل أنت متأكد من إلغاء طلب الكشف عن بعد؟',
                            );
                            if (confirmed == true) {
                              await provider.cancelRemoteConsultation(rc.consultationId);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),

              // Bottom Button
              if (!hasApproved)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                    onPressed: provider.submitting
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SpecialistAddTelemedicinePage(
                                  consultationId: '',
                                ),
                              ),
                            ).then((_) => provider.loadRemoteConsultations());
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.8)),
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
                        : Text(
                            consultations.isNotEmpty ? 'اضافة كشف جديد' : 'اضافة خدمة كشف عن بعد',
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

class TelemedicineRequestCard extends StatefulWidget {
  final RemoteConsultationCardModel data;
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
  bool _isLoadingDetails = false;
  RemoteConsultationDetailModel? _details;

  Future<void> _fetchDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final api = ClinicRemoteApiService();
      _details = await api.getRemoteConsultationDetail(widget.data.consultationId);
    } catch (e) {
      // Handle error silently or log
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _toggleExpand() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded && _details == null) {
      _fetchDetails();
    }
  }

  @override
  void didUpdateWidget(covariant TelemedicineRequestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent rebuilds this widget with new data (e.g. after refresh),
    // clear the cached details and refetch if currently expanded.
    if (oldWidget.data != widget.data) {
      _details = null;
      if (_isExpanded) {
        _fetchDetails();
      }
    }
  }

  Widget _buildDetailsContent() {
    String scheduleText = 'مواعيد مخصصة';
    List<dynamic> workingPeriods = [];
    
    if (_details!.workingHoursJson != null && _details!.workingHoursJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(_details!.workingHoursJson!);
        if (decoded is Map) {
          if (decoded['type'] == 'fixed') {
            scheduleText = 'يوميا من ${decoded['from']} الى ${decoded['to']}';
          } else if (decoded['type'] == 'specific') {
            workingPeriods = decoded['periods'] as List? ?? [];
          }
        } else if (decoded is List) {
          workingPeriods = decoded;
        }
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('سعر الجلسة ج.م*'),
        _buildReadOnlyField(_details!.sessionPrice?.toStringAsFixed(0) ?? ''),
        const SizedBox(height: 12),
        
        _buildLabel('مدة الجلسة*'),
        _buildReadOnlyField('${_details!.sessionDurationMinutes ?? ''} دق', isDropdown: true),
        const SizedBox(height: 12),
        
        _buildLabel('فترة الانتظار بين كل جلسة*'),
        _buildReadOnlyField('${_details!.waitingPeriodMinutes ?? ''} دق', isDropdown: true),
        const SizedBox(height: 12),
        
        _buildLabel('مواعيد العمل*'),
        _buildReadOnlyField(scheduleText, icon: Icons.calendar_today_outlined),
        if (workingPeriods.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...workingPeriods.map((period) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    '${period['day']} من ${period['from']} الى ${period['to']}',
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String text, {bool isDropdown = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.black.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (isDropdown)
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<SpecialistApplicationProvider>();
    final specialty = appProvider.current?.specialtyName ?? 'تخصص';
    final statusColor = _rcStatusColor(widget.data.status);

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
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                        formatTelemedicineDate(widget.data.submittedAt),
                        style: TextStyle(
                          fontFamily: specialistFont,
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.data.statusAr,
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rejection reason
          if (widget.data.rejectionReason != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'السبب',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.rejectionReason!,
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 14,
                        color: Colors.black,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Expanded Details
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoadingDetails
                  ? const Center(child: CircularProgressIndicator(color: specialistGreen))
                  : _details == null
                      ? const Center(child: Text('فشل في تحميل التفاصيل', style: TextStyle(fontFamily: specialistFont)))
                      : _buildDetailsContent(),
            ),
          ],

          // Action Area (Buttons)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Show Add Request Button (Green)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _toggleExpand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: specialistGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isExpanded ? 'إخفاء بيانات الطلب' : 'عرض طلب الاضافة',
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Edit Data Button (Outlined)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onEdit,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
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

                // 3. Cancel Request Button (Text)
                if (widget.data.canCancel)
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
