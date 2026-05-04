import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/edit_specialist_professional_page.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class EditSpecialistIdentityPage extends StatefulWidget {
  final String applicationId;

  const EditSpecialistIdentityPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<EditSpecialistIdentityPage> createState() =>
      _EditSpecialistIdentityPageState();
}

class _EditSpecialistIdentityPageState
    extends State<EditSpecialistIdentityPage> {
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
        body: SafeArea(
          child: Consumer<SpecialistApplicationProvider>(
            builder: (context, provider, _) {
              final details = provider.details;
              final identity = details?.identityData;

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
                            'تعديل بيانات الهوية',
                            style: TextStyle(
                              fontFamily: specialistFont,
                              fontSize: 28,
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
                          if (provider.loadingDetails && identity == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: CircularProgressIndicator(
                                color: specialistGreen,
                              ),
                            )
                          else ...[
                            UploadedDocumentField(
                              label: 'صورة بطاقة (الوجه الامامي)*',
                              uploaded:
                                  identity?.nationalIdFrontUploaded ?? false,
                              editable: true,
                              loading: provider.uploadingDocuments
                                  .contains('NationalIdFront'),
                              onOpen: () => openDocumentUrl(
                                context,
                                identity?.nationalIdFrontUrl,
                              ),
                              onEdit: () => provider.pickAndUploadDocument(
                                applicationId: widget.applicationId,
                                documentType: 'NationalIdFront',
                              ),
                            ),
                            const SizedBox(height: 32),
                            UploadedDocumentField(
                              label: 'صورة بطاقة (الوجه الخلفي)*',
                              uploaded: identity?.nationalIdBackUploaded ?? false,
                              editable: true,
                              loading: provider.uploadingDocuments
                                  .contains('NationalIdBack'),
                              onOpen: () => openDocumentUrl(
                                context,
                                identity?.nationalIdBackUrl,
                              ),
                              onEdit: () => provider.pickAndUploadDocument(
                                applicationId: widget.applicationId,
                                documentType: 'NationalIdBack',
                              ),
                            ),
                            const SizedBox(height: 32),
                            UploadedDocumentField(
                              label: 'صورة شخصية*',
                              uploaded: identity?.personalPhotoUploaded ?? false,
                              editable: true,
                              loading: provider.uploadingDocuments
                                  .contains('PersonalPhoto'),
                              onOpen: () => openDocumentUrl(
                                context,
                                identity?.personalPhotoUrl,
                              ),
                              onEdit: () => provider.pickAndUploadDocument(
                                applicationId: widget.applicationId,
                                documentType: 'PersonalPhoto',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: PrimaryGreenButton(
                      label: 'التالي',
                      onPressed: () => _goNext(context, provider),
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

  void _goNext(BuildContext context, SpecialistApplicationProvider provider) {
    final identity = provider.details?.identityData;
    if (identity == null ||
        !identity.nationalIdFrontUploaded ||
        !identity.nationalIdBackUploaded ||
        !identity.personalPhotoUploaded) {
      showArabicSnackBar(context, 'يرجى رفع كل صور الهوية المطلوبة');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EditSpecialistProfessionalPage(applicationId: widget.applicationId),
      ),
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
