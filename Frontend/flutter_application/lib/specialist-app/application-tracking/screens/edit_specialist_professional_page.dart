import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/specialist_application_submit_success_page.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class EditSpecialistProfessionalPage extends StatefulWidget {
  final String applicationId;

  const EditSpecialistProfessionalPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<EditSpecialistProfessionalPage> createState() =>
      _EditSpecialistProfessionalPageState();
}

class _EditSpecialistProfessionalPageState
    extends State<EditSpecialistProfessionalPage> {
  final TextEditingController _licenseController = TextEditingController();
  int? _selectedSpecialtyId;
  XFile? _certificateFile;
  XFile? _licenseFile;
  XFile? _syndicateFile;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SpecialistApplicationProvider>();
      await provider.loadSpecialties();
      await provider.loadDetails(widget.applicationId);
      _seedFromDetails(provider.details);
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<SpecialistApplicationProvider>(
            builder: (context, provider, _) {
              _seedFromDetails(provider.details);
              final details = provider.details;
              final professional = details?.professionalData;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      child: Column(
                        children: [
                          _EditHeader(onClose: () => _confirmExit(context)),
                          const SizedBox(height: 54),
                          const Text(
                            'تعديل بيانات مزاولة المهنة',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'نحتاج لتأكيد هويتك الشخصية لضمان أمان المنصة',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 17,
                              color: Colors.black.withValues(alpha: 0.62),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 54),
                          if ((provider.loadingDetails && professional == null) ||
                              provider.loadingSpecialties)
                            const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: CircularProgressIndicator(
                                color: specialistGreen,
                              ),
                            )
                          else ...[
                            const _RequiredLabel('التخصص*'),
                            const SizedBox(height: 8),
                            _SpecialtyDropdown(
                              value: _selectedSpecialtyId,
                              specialties: provider.specialties,
                              onChanged: (value) {
                                setState(() => _selectedSpecialtyId = value);
                              },
                            ),
                            const SizedBox(height: 32),
                            UploadedDocumentField(
                              label: 'صورة شهادة التخصص*',
                              uploaded:
                                  _certificateFile != null ||
                                      (professional
                                              ?.specializationCertificateUploaded ??
                                          false),
                              editable: true,
                              loading: false,
                              onOpen: () => openDocumentUrl(
                                context,
                                professional?.specializationCertificateUrl,
                              ),
                              onEdit: () => _pickFile((file) {
                                setState(() => _certificateFile = file);
                              }, provider),
                            ),
                            const SizedBox(height: 32),
                            const _RequiredLabel('رقم الترخيص المهني*'),
                            const SizedBox(height: 8),
                            _LicenseTextField(controller: _licenseController),
                            const SizedBox(height: 32),
                            UploadedDocumentField(
                              label: 'صورة الترخيص المهني*',
                              uploaded: _licenseFile != null ||
                                  (professional?.professionalLicenseUploaded ??
                                      false),
                              editable: true,
                              loading: false,
                              onOpen: () => openDocumentUrl(
                                context,
                                professional?.professionalLicenseUrl,
                              ),
                              onEdit: () => _pickFile((file) {
                                setState(() => _licenseFile = file);
                              }, provider),
                            ),
                            const SizedBox(height: 32),
                            UploadedDocumentField(
                              label: 'صورة كارنيه النقابة*',
                              uploaded: _syndicateFile != null ||
                                  (professional?.syndicateCardUploaded ?? false),
                              editable: true,
                              loading: false,
                              onOpen: () => openDocumentUrl(
                                context,
                                professional?.syndicateCardUrl,
                              ),
                              onEdit: () => _pickFile((file) {
                                setState(() => _syndicateFile = file);
                              }, provider),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      children: [
                        PrimaryGreenButton(
                          label: 'ارسال طلب التقدم',
                          loading: provider.submitting,
                          onPressed: () => _submit(context, provider),
                        ),
                        const SizedBox(height: 12),
                        AjialOutlineButton(
                          label: 'السابق',
                          onPressed: provider.submitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _seedFromDetails(SpecialistApplicationDetailsModel? details) {
    if (_seeded || details == null) return;
    final professional = details.professionalData;
    _licenseController.text = professional.practiceLicenseNumber;
    _selectedSpecialtyId = professional.specialtyId;
    _seeded = true;
  }

  Future<void> _pickFile(
    ValueChanged<XFile> setter,
    SpecialistApplicationProvider provider,
  ) async {
    final file = await provider.pickImage();
    if (file == null) return;
    setter(file);
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showWarningConfirmDialog(
      context,
      title: 'إلغاء تقديم الطلب؟',
      message: 'سيتم إلغاء عملية التقديم الحالي لكن ستظل المعلومات محفوظة',
      confirmLabel: 'نعم، إلغاء',
      cancelLabel: 'لا، استمرار',
    );
    if (confirmed && context.mounted) Navigator.pop(context);
  }

  Future<void> _submit(
    BuildContext context,
    SpecialistApplicationProvider provider,
  ) async {
    final professional = provider.details?.professionalData;
    final license = _licenseController.text.trim();
    if (_selectedSpecialtyId == null) {
      showArabicSnackBar(context, 'يرجى اختيار التخصص');
      return;
    }
    if (license.isEmpty) {
      showArabicSnackBar(context, 'رقم الترخيص المهني مطلوب');
      return;
    }
    if (_certificateFile == null &&
        !(professional?.specializationCertificateUploaded ?? false)) {
      showArabicSnackBar(context, 'صورة شهادة التخصص مطلوبة');
      return;
    }
    if (_licenseFile == null &&
        !(professional?.professionalLicenseUploaded ?? false)) {
      showArabicSnackBar(context, 'صورة الترخيص المهني مطلوبة');
      return;
    }
    if (_syndicateFile == null &&
        !(professional?.syndicateCardUploaded ?? false)) {
      showArabicSnackBar(context, 'صورة كارنيه النقابة مطلوبة');
      return;
    }

    final updated = await provider.updateProfessionalData(
      applicationId: widget.applicationId,
      specialtyId: _selectedSpecialtyId,
      licenseNumber: license,
      specializationCertificate: _certificateFile,
      professionalLicense: _licenseFile,
      syndicateCard: _syndicateFile,
    );
    if (!context.mounted) return;
    if (!updated) {
      showArabicSnackBar(
        context,
        provider.errorMessage ?? 'تعذر حفظ بيانات مزاولة المهنة',
      );
      return;
    }

    final submitted = await provider.submitApplication(widget.applicationId);
    if (!context.mounted) return;
    if (!submitted) {
      showArabicSnackBar(
        context,
        provider.errorMessage ?? 'تعذر إرسال الطلب، تأكد من اكتمال البيانات',
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const SpecialistApplicationSubmitSuccessPage(),
      ),
      (route) => route.isFirst,
    );
  }
}

class _EditHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _EditHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.black, size: 30),
          ),
        ),
        const SizedBox(width: 18),
        const Expanded(
          child: Text(
            'تعديل طلب التقدم',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  final String text;

  const _RequiredLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text.replaceAll('*', '')),
            const TextSpan(
              text: '*',
              style: TextStyle(color: specialistRed),
            ),
          ],
        ),
        style: const TextStyle(
          fontFamily: specialistFont,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _SpecialtyDropdown extends StatelessWidget {
  final int? value;
  final List<SpecialtyModel> specialties;
  final ValueChanged<int?> onChanged;

  const _SpecialtyDropdown({
    required this.value,
    required this.specialties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = specialties.any((item) => item.id == value);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.22)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: hasValue ? value : null,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          hint: Text(
            'متخصص تربوى/طبيب اطفال ...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 17,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          items: specialties
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      item.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LicenseTextField extends StatelessWidget {
  final TextEditingController controller;

  const _LicenseTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black.withValues(alpha: 0.22)),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontFamily: specialistFont,
          fontSize: 18,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'مثل : *****-*******-7859',
          hintStyle: TextStyle(
            fontFamily: specialistFont,
            fontSize: 17,
            color: Colors.black.withValues(alpha: 0.42),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
