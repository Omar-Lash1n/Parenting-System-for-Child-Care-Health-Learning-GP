import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/edit_specialist_identity_page.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class SpecialistApplicationDetailsPage extends StatefulWidget {
  final String applicationId;

  const SpecialistApplicationDetailsPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<SpecialistApplicationDetailsPage> createState() =>
      _SpecialistApplicationDetailsPageState();
}

class _SpecialistApplicationDetailsPageState
    extends State<SpecialistApplicationDetailsPage> {
  bool _identityExpanded = false;
  bool _professionalExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<SpecialistApplicationProvider>()
          .loadDetails(widget.applicationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const SpecialistBottomNavBar(currentIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Consumer<SpecialistApplicationProvider>(
            builder: (context, provider, _) {
              final details = provider.details;
              if (provider.loadingDetails && details == null) {
                return const Center(
                  child: CircularProgressIndicator(color: specialistGreen),
                );
              }
              if (details == null) {
                return _ErrorState(
                  message: provider.errorMessage ?? 'تعذر تحميل تفاصيل الطلب',
                  onRetry: () => provider.loadDetails(widget.applicationId),
                );
              }

              final editable = details.canEdit || statusAllowsEdit(details.status);
              final current = provider.current;
              final specialty = details.professionalData.specialtyName.isNotEmpty
                  ? details.professionalData.specialtyName
                  : current?.specialtyName ?? 'طبيب عام';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                child: Column(
                  children: [
                    _TopTitle(onBack: () => Navigator.pop(context)),
                    const SizedBox(height: 42),
                    ApplicationStatusCard(
                      specialtyName: specialty,
                      submittedAt: details.submittedAt,
                      status: details.status,
                      statusAr: details.statusAr,
                      rejectionReason: details.status == 'Rejected'
                          ? details.rejectionReason
                          : null,
                      compact: true,
                    ),
                    const SizedBox(height: 22),
                    ApplicationSectionTile(
                      title: 'بيانات الهوية',
                      expanded: _identityExpanded,
                      onTap: () => setState(
                        () => _identityExpanded = !_identityExpanded,
                      ),
                      child: _IdentitySection(
                        data: details.identityData,
                        editable: editable,
                        provider: provider,
                        applicationId: widget.applicationId,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ApplicationSectionTile(
                      title: 'بيانات مزاولة المهنة',
                      expanded: _professionalExpanded,
                      onTap: () => setState(
                        () => _professionalExpanded = !_professionalExpanded,
                      ),
                      child: _ProfessionalSection(
                        data: details.professionalData,
                        editable: editable,
                        provider: provider,
                        applicationId: widget.applicationId,
                      ),
                    ),
                    const SizedBox(height: 42),
                    if (editable)
                      AjialOutlineButton(
                        label: 'تعديل البيانات',
                        onPressed: () => _handleEdit(context, provider, details),
                      ),
                    if (details.canCancel ||
                        details.status == 'Pending' ||
                        details.status == 'PendingReview' ||
                        details.status == 'Draft') ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _handleCancel(context, provider),
                        child: const Text(
                          'إلغاء طلب التقدم',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: specialistRed,
                          ),
                        ),
                      ),
                    ],
                    if (current?.canCreateNew == true ||
                        details.status == 'Cancelled' ||
                        details.status == 'Rejected') ...[
                      const SizedBox(height: 20),
                      AjialOutlineButton(
                        label: 'إنشاء طلب تقدم جديد',
                        onPressed: () => _handleCreateNew(context, provider),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    SpecialistApplicationProvider provider,
  ) async {
    final confirmed = await showWarningConfirmDialog(
      context,
      title: 'إلغاء طلب التقدم؟',
      message: 'سيتم إيقاف مراجعة طلبك، ويمكنك التقديم مرة أخرى في أي وقت',
      confirmLabel: 'نعم، إلغاء',
      cancelLabel: 'لا، إبقاء',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await provider.cancelApplication(widget.applicationId);
    if (!context.mounted) return;
    showArabicSnackBar(
      context,
      ok ? 'تم إلغاء طلب التقدم بنجاح' : provider.errorMessage ?? 'تعذر إلغاء الطلب',
    );
    if (ok) Navigator.pop(context);
  }

  Future<void> _handleEdit(
    BuildContext context,
    SpecialistApplicationProvider provider,
    SpecialistApplicationDetailsModel details,
  ) async {
    if (details.status == 'Pending' || details.status == 'PendingReview') {
      final confirmed = await showWarningConfirmDialog(
        context,
        title: 'تعديل الطلب الحالي؟',
        message: 'سيتم إيقاف مراجعة طلبك، ويمكنك تعديل البيانات و التقديم مرة أخرى',
        confirmLabel: 'نعم، تعديل',
        cancelLabel: 'لا، إلغاء',
      );
      if (!confirmed || !context.mounted) return;
      final ok = await provider.startEditApplication(widget.applicationId);
      if (!context.mounted) return;
      if (!ok) {
        showArabicSnackBar(
          context,
          provider.errorMessage ?? 'تعذر بدء تعديل الطلب',
        );
        return;
      }
    } else if (details.status == 'Rejected' || details.status == 'Cancelled') {
      final newId = await provider.createNewApplication();
      if (!context.mounted) return;
      if (newId == null) {
        showArabicSnackBar(
          context,
          provider.errorMessage ?? 'تعذر إنشاء طلب جديد',
        );
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EditSpecialistIdentityPage(applicationId: newId),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EditSpecialistIdentityPage(applicationId: widget.applicationId),
      ),
    );
  }

  Future<void> _handleCreateNew(
    BuildContext context,
    SpecialistApplicationProvider provider,
  ) async {
    final newId = await provider.createNewApplication();
    if (!context.mounted) return;
    if (newId == null) {
      showArabicSnackBar(
        context,
        provider.errorMessage ?? 'تعذر إنشاء طلب جديد',
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EditSpecialistIdentityPage(applicationId: newId),
      ),
    );
  }
}

class _TopTitle extends StatelessWidget {
  final VoidCallback onBack;

  const _TopTitle({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        const Spacer(),
        const Text(
          'طلب التقدم',
          style: TextStyle(
            fontFamily: specialistFont,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: specialistGreen,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentitySection extends StatelessWidget {
  final IdentityDataModel data;
  final bool editable;
  final SpecialistApplicationProvider provider;
  final String applicationId;

  const _IdentitySection({
    required this.data,
    required this.editable,
    required this.provider,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _doc(
          context,
          label: 'صورة بطاقة (الوجه الامامي)*',
          type: 'NationalIdFront',
          url: data.nationalIdFrontUrl,
          uploaded: data.nationalIdFrontUploaded,
        ),
        const SizedBox(height: 22),
        _doc(
          context,
          label: 'صورة بطاقة (الوجه الخلفي)*',
          type: 'NationalIdBack',
          url: data.nationalIdBackUrl,
          uploaded: data.nationalIdBackUploaded,
        ),
        const SizedBox(height: 22),
        _doc(
          context,
          label: 'صورة شخصية*',
          type: 'PersonalPhoto',
          url: data.personalPhotoUrl,
          uploaded: data.personalPhotoUploaded,
        ),
      ],
    );
  }

  Widget _doc(
    BuildContext context, {
    required String label,
    required String type,
    required String? url,
    required bool uploaded,
  }) {
    return UploadedDocumentField(
      label: label,
      uploaded: uploaded,
      editable: editable,
      loading: provider.uploadingDocuments.contains(type),
      onOpen: () => openDocumentUrl(context, url),
      onEdit: () => provider.pickAndUploadDocument(
        applicationId: applicationId,
        documentType: type,
      ),
    );
  }
}

class _ProfessionalSection extends StatelessWidget {
  final ProfessionalDataModel data;
  final bool editable;
  final SpecialistApplicationProvider provider;
  final String applicationId;

  const _ProfessionalSection({
    required this.data,
    required this.editable,
    required this.provider,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _RequiredLabel('التخصص*'),
        const SizedBox(height: 8),
        _ReadonlyField(value: data.specialtyName),
        const SizedBox(height: 22),
        _doc(
          context,
          label: 'صورة شهادة التخصص*',
          type: 'SpecializationCertificate',
          url: data.specializationCertificateUrl,
          uploaded: data.specializationCertificateUploaded,
        ),
        const SizedBox(height: 22),
        const _RequiredLabel('رقم الترخيص المهني*'),
        const SizedBox(height: 8),
        _ReadonlyField(value: data.practiceLicenseNumber),
        const SizedBox(height: 22),
        _doc(
          context,
          label: 'صورة الترخيص المهني*',
          type: 'ProfessionalLicense',
          url: data.professionalLicenseUrl,
          uploaded: data.professionalLicenseUploaded,
        ),
        const SizedBox(height: 22),
        _doc(
          context,
          label: 'صورة كارنيه النقابة*',
          type: 'SyndicateCard',
          url: data.syndicateCardUrl,
          uploaded: data.syndicateCardUploaded,
        ),
      ],
    );
  }

  Widget _doc(
    BuildContext context, {
    required String label,
    required String type,
    required String? url,
    required bool uploaded,
  }) {
    return UploadedDocumentField(
      label: label,
      uploaded: uploaded,
      editable: editable,
      loading: provider.uploadingDocuments.contains(type),
      onOpen: () => openDocumentUrl(context, url),
      onEdit: () => provider.pickAndUploadDocument(
        applicationId: applicationId,
        documentType: type,
      ),
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  final String text;

  const _RequiredLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.replaceAll('*', '')),
          const TextSpan(
            text: '*',
            style: TextStyle(color: specialistRed),
          ),
        ],
      ),
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFamily: specialistFont,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String value;

  const _ReadonlyField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withValues(alpha: 0.18)),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: specialistFont,
          fontSize: 16,
          color: Colors.black.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryGreenButton(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
