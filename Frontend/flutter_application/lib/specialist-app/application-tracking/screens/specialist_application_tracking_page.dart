import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/edit_specialist_identity_page.dart';
import 'package:Ajial/specialist-app/application-tracking/screens/specialist_application_details_page.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class SpecialistApplicationTrackingPage extends StatefulWidget {
  final bool showBottomNav;

  const SpecialistApplicationTrackingPage({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<SpecialistApplicationTrackingPage> createState() =>
      _SpecialistApplicationTrackingPageState();
}

class _SpecialistApplicationTrackingPageState
    extends State<SpecialistApplicationTrackingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialistApplicationProvider>().loadCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: widget.showBottomNav
            ? const SpecialistBottomNavBar(currentIndex: 1)
            : null,
        body: SafeArea(
          bottom: false,
          child: Consumer<SpecialistApplicationProvider>(
            builder: (context, provider, _) {
              final current = provider.current;
              if (provider.loadingCurrent && current == null) {
                return const Center(
                  child: CircularProgressIndicator(color: specialistGreen),
                );
              }

              return RefreshIndicator(
                color: specialistGreen,
                onRefresh: provider.loadCurrent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 34),
                  child: Column(
                    children: [
                      SpecialistHeaderWidget(
                        name: provider.specialistName,
                        specialtyName: current?.specialtyName ?? '',
                        imageUrl: current?.personalPhotoUrl,
                      ),
                      const SizedBox(height: 72),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: current == null
                            ? _NoApplicationCard(
                                message: provider.errorMessage,
                                onRetry: provider.loadCurrent,
                              )
                            : _CurrentApplicationCard(
                                current: current,
                                provider: provider,
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CurrentApplicationCard extends StatelessWidget {
  final SpecialistCurrentApplicationModel current;
  final SpecialistApplicationProvider provider;

  const _CurrentApplicationCard({
    required this.current,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: specialistGreen,
                  size: 33,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      current.specialtyName.isEmpty
                          ? 'طبيب عام'
                          : current.specialtyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatArabicSubmittedDate(current.submittedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: current.status, statusAr: current.statusAr),
            ],
          ),
          const SizedBox(height: 42),
          PrimaryGreenButton(
            label: 'عرض طلب التقدم',
            onPressed: current.canView
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SpecialistApplicationDetailsPage(
                          applicationId: current.applicationId,
                        ),
                      ),
                    )
                : null,
          ),
          if (current.canEdit || statusAllowsEdit(current.status)) ...[
            const SizedBox(height: 12),
            AjialOutlineButton(
              label: 'تعديل البيانات',
              onPressed: () => _handleEdit(context),
            ),
          ],
          if (current.canCancel ||
              current.status == 'Pending' ||
              current.status == 'PendingReview' ||
              current.status == 'Draft') ...[
            const SizedBox(height: 22),
            TextButton(
              onPressed: () => _handleCancel(context),
              child: const Text(
                'إلغاء طلب التقدم',
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  color: specialistRed,
                ),
              ),
            ),
          ],
          if (current.canCreateNew) ...[
            const SizedBox(height: 14),
            AjialOutlineButton(
              label: 'إنشاء طلب تقدم جديد',
              onPressed: () => _handleCreateNew(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await showWarningConfirmDialog(
      context,
      title: 'إلغاء طلب التقدم؟',
      message: 'سيتم إيقاف مراجعة طلبك، ويمكنك التقديم مرة أخرى في أي وقت',
      confirmLabel: 'نعم، إلغاء',
      cancelLabel: 'لا، إبقاء',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await provider.cancelApplication(current.applicationId);
    if (!context.mounted) return;
    showArabicSnackBar(
      context,
      ok ? 'تم إلغاء طلب التقدم بنجاح' : provider.errorMessage ?? 'تعذر إلغاء الطلب',
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    if (current.status == 'Pending' || current.status == 'PendingReview') {
      final confirmed = await showWarningConfirmDialog(
        context,
        title: 'تعديل الطلب الحالي؟',
        message: 'سيتم إيقاف مراجعة طلبك، ويمكنك تعديل البيانات و التقديم مرة أخرى',
        confirmLabel: 'نعم، تعديل',
        cancelLabel: 'لا، إلغاء',
      );
      if (!confirmed || !context.mounted) return;
      final ok = await provider.startEditApplication(current.applicationId);
      if (!context.mounted) return;
      if (!ok) {
        showArabicSnackBar(
          context,
          provider.errorMessage ?? 'تعذر بدء تعديل الطلب',
        );
        return;
      }
    } else if (current.canCreateNew) {
      final newId = await provider.createNewApplication();
      if (!context.mounted) return;
      if (newId == null) {
        showArabicSnackBar(
          context,
          provider.errorMessage ?? 'تعذر إنشاء طلب جديد',
        );
        return;
      }
      Navigator.of(context).push(
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
            EditSpecialistIdentityPage(applicationId: current.applicationId),
      ),
    );
  }

  Future<void> _handleCreateNew(BuildContext context) async {
    final newId = await provider.createNewApplication();
    if (!context.mounted) return;
    if (newId == null) {
      showArabicSnackBar(
        context,
        provider.errorMessage ?? 'تعذر إنشاء طلب جديد',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditSpecialistIdentityPage(applicationId: newId),
      ),
    );
  }
}

class _NoApplicationCard extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const _NoApplicationCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, color: specialistGreen, size: 46),
          const SizedBox(height: 12),
          Text(
            message ?? 'لا يوجد طلب تقدم حالياً',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryGreenButton(label: 'إعادة المحاولة', onPressed: onRetry),
        ],
      ),
    );
  }
}
