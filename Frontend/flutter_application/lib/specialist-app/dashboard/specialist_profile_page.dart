import 'package:flutter/material.dart';
import 'package:Ajial/api/specialist-services.dart';
import 'package:Ajial/role_selection.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/models/doctor_consultation_models.dart';
import 'package:Ajial/specialist-app/dashboard/services/doctor_consultation_api_service.dart';

/// شاشة الملف الشخصي للطبيب — تعرض بياناته الأساسية، مستندات التوثيق،
/// الخدمات المتاحة، والإحصائيات (GET /api/doctor/consultations/profile).
/// تُعرض داخل تبويب "الملف الشخصي" في [SpecialistHomePage]، لذلك فهي عنصر
/// محتوى بدون Scaffold أو شريط تنقّل سفلي خاص بها.
class SpecialistProfilePage extends StatefulWidget {
  const SpecialistProfilePage({super.key});

  @override
  State<SpecialistProfilePage> createState() => _SpecialistProfilePageState();
}

class _SpecialistProfilePageState extends State<SpecialistProfilePage> {
  final DoctorConsultationApiService _api = DoctorConsultationApiService();
  final SpecialistService _specialistService = SpecialistService();

  bool _loading = true;
  String? _error;
  DoctorProfile? _profile;

  bool _documentsExpanded = false;
  bool _basicExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _loading = false;
      });
    }
  }

  String _cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').trim();

  Future<void> _handleLogout() async {
    final confirmed = await showWarningConfirmDialog(
      context,
      title: 'تسجيل الخروج؟',
      message: 'سيتم تسجيل خروجك من حساب الطبيب الحالي',
      confirmLabel: 'نعم، خروج',
      cancelLabel: 'لا، إبقاء',
    );
    if (!confirmed || !mounted) return;
    await _specialistService.logoutSpecialist();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: specialistGreen),
      );
    }
    if (_profile == null) {
      return _ErrorState(
        message: _error ?? 'تعذر تحميل الملف الشخصي',
        onRetry: _loadProfile,
      );
    }

    final profile = _profile!;
    return RefreshIndicator(
      color: specialistGreen,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        child: Column(
          children: [
            const _TopTitle(),
            const SizedBox(height: 24),
            _ProfileHeaderCard(profile: profile),
            if (profile.status == 'rejected' &&
                (profile.rejectionReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 18),
              RejectionReasonBox(reason: profile.rejectionReason!),
            ],
            const SizedBox(height: 22),
            _StatsRow(stats: profile.stats),
            const SizedBox(height: 22),
            ApplicationSectionTile(
              title: 'البيانات الأساسية',
              expanded: _basicExpanded,
              onTap: () => setState(() => _basicExpanded = !_basicExpanded),
              child: _BasicInfoSection(profile: profile),
            ),
            const SizedBox(height: 22),
            ApplicationSectionTile(
              title: 'مستندات التوثيق',
              expanded: _documentsExpanded,
              onTap: () =>
                  setState(() => _documentsExpanded = !_documentsExpanded),
              child: _DocumentsSection(documents: profile.documents),
            ),
            const SizedBox(height: 22),
            _ServicesCard(services: profile.services),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBF092F), width: 1.5),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.logout,
                    color: Color(0xFFBF092F), size: 20),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBF092F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTitle extends StatelessWidget {
  const _TopTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'الملف الشخصي',
        style: TextStyle(
          fontFamily: specialistFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final DoctorProfile profile;

  const _ProfileHeaderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final photo = profile.personalPhotoUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 47,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFF0FAF5),
              backgroundImage:
                  (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
              child: (photo == null || photo.isEmpty)
                  ? const Icon(Icons.person, color: specialistGreen, size: 46)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.fullName.isEmpty ? 'طبيب' : profile.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.specialization.isEmpty ? 'طبيب عام' : profile.specialization,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 14),
          StatusBadge(status: profile.statusPascal, statusAr: profile.statusAr),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DoctorProfileStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.event_available_rounded,
                value: stats.totalBookings.toString(),
                label: 'إجمالي الحجوزات',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.task_alt_rounded,
                value: stats.completedSessions.toString(),
                label: 'جلسات مكتملة',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.upcoming_rounded,
                value: stats.upcomingBookings.toString(),
                label: 'حجوزات قادمة',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                value: stats.ratingsCount == 0
                    ? '—'
                    : stats.averageRating.toStringAsFixed(1),
                label: stats.ratingsCount == 0
                    ? 'لا توجد تقييمات'
                    : 'التقييم (${stats.ratingsCount})',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FAF5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: specialistGreen, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  final DoctorProfile profile;

  const _BasicInfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(label: 'الاسم الكامل', value: profile.fullName),
        _InfoRow(label: 'اسم المستخدم', value: profile.username),
        _InfoRow(
          label: 'البريد الإلكتروني',
          value: profile.email,
          trailing: _VerifiedChip(verified: profile.isEmailVerified),
        ),
        _InfoRow(label: 'رقم الهاتف', value: profile.phone),
        _InfoRow(label: 'التخصص', value: profile.specialization),
        _InfoRow(
          label: 'رقم الترخيص المهني',
          value: profile.practiceLicenseNumber,
        ),
        _InfoRow(
          label: 'تاريخ التسجيل',
          value: formatArabicSubmittedDate(profile.createdAt)
              .replaceFirst('منذ ', ''),
          isLast: true,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: specialistFont,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  final bool verified;

  const _VerifiedChip({required this.verified});

  @override
  Widget build(BuildContext context) {
    final color = verified ? specialistGreen : const Color(0xFFFF7A00);
    final bg = verified ? const Color(0xFFEAF8F0) : const Color(0xFFFFF2E3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.error_outline_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'موثّق' : 'غير موثّق',
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  final DoctorVerificationDocuments documents;

  const _DocumentsSection({required this.documents});

  @override
  Widget build(BuildContext context) {
    final items = <_DocItem>[
      _DocItem('صورة بطاقة (الوجه الأمامي)', documents.idFrontImageUrl),
      _DocItem('صورة بطاقة (الوجه الخلفي)', documents.idBackImageUrl),
      _DocItem('صورة شهادة التخصص',
          documents.specializationCertificateImageUrl),
      _DocItem('صورة الترخيص المهني', documents.practiceLicenseImageUrl),
      _DocItem('صورة كارنيه النقابة', documents.unionCardImageUrl),
      _DocItem('صورة شخصية', documents.personalPhotoUrl),
    ];
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _ProfileDocumentField(label: items[i].label, url: items[i].url),
          if (i != items.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _DocItem {
  final String label;
  final String? url;
  const _DocItem(this.label, this.url);
}

/// صف مستند للعرض فقط (فتح الصورة في المتصفح) — بنفس شكل حقول التوثيق
/// في شاشات الطبيب، لكن بدون زر تعديل.
class _ProfileDocumentField extends StatelessWidget {
  final String label;
  final String? url;

  const _ProfileDocumentField({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final uploaded = url != null && url!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: uploaded ? () => openDocumentUrl(context, url) : null,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 64),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: uploaded
                          ? Colors.black.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'فتح',
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: uploaded
                          ? Colors.black
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  uploaded ? 'تم رفع الصورة' : 'لم يتم الرفع',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 15,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServicesCard extends StatelessWidget {
  final DoctorServicesSummary services;

  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الخدمات المتاحة',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          if (!services.hasClinic && !services.hasRemote)
            _EmptyServices()
          else ...[
            if (services.hasClinic) ...[
              _ServiceBlock(
                icon: Icons.local_hospital_rounded,
                title: 'الكشف داخل العيادة',
                rows: [
                  if (services.clinic?.name?.isNotEmpty ?? false)
                    _InfoRow(label: 'اسم العيادة', value: services.clinic!.name!),
                  if (services.clinic?.governorateName?.isNotEmpty ?? false)
                    _InfoRow(
                      label: 'المحافظة',
                      value: services.clinic!.governorateName!,
                    ),
                  if (services.clinic?.address?.isNotEmpty ?? false)
                    _InfoRow(label: 'العنوان', value: services.clinic!.address!),
                  if (services.clinic?.examinationPrice != null)
                    _InfoRow(
                      label: 'سعر الكشف',
                      value: _price(services.clinic!.examinationPrice!),
                    ),
                  if (services.clinic?.consultationPrice != null)
                    _InfoRow(
                      label: 'سعر الاستشارة',
                      value: _price(services.clinic!.consultationPrice!),
                      isLast: true,
                    ),
                ],
              ),
              if (services.hasRemote) const SizedBox(height: 18),
            ],
            if (services.hasRemote)
              _ServiceBlock(
                icon: Icons.video_camera_front_rounded,
                title: 'الكشف عن بُعد',
                rows: [
                  if (services.remote?.sessionPrice != null)
                    _InfoRow(
                      label: 'سعر الجلسة',
                      value: _price(services.remote!.sessionPrice!),
                    ),
                  if (services.remote?.sessionDurationMinutes != null)
                    _InfoRow(
                      label: 'مدة الجلسة',
                      value: '${services.remote!.sessionDurationMinutes} دقيقة',
                      isLast: true,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String _price(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return '$text ج.م';
  }
}

class _ServiceBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> rows;

  const _ServiceBlock({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: specialistGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...rows,
          ],
        ],
      ),
    );
  }
}

class _EmptyServices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.medical_services_outlined,
          color: Colors.black.withValues(alpha: 0.2),
          size: 44,
        ),
        const SizedBox(height: 10),
        Text(
          'لا توجد خدمات مفعّلة بعد',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: specialistFont,
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
