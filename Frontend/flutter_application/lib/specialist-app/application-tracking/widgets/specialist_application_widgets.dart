import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Ajial/specialist-app/application-tracking/providers/specialist_application_provider.dart';

const Color specialistGreen = Color(0xFF01A449);
const Color specialistRed = Color(0xFFFF1A1A);
const String specialistFont = 'IBM Plex Sans Arabic';

class PrimaryGreenButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryGreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: specialistGreen,
          disabledBackgroundColor: specialistGreen.withValues(alpha: 0.55),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class AjialOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AjialOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.black.withValues(alpha: 0.5)),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class SpecialistHeaderWidget extends StatelessWidget {
  final String name;
  final String specialtyName;
  final String? imageUrl;

  const SpecialistHeaderWidget({
    super.key,
    required this.name,
    required this.specialtyName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Row(
            children: [
              _HeaderIcon(assetPath: 'images/specialist_messages.png'),
              const SizedBox(width: 16),
              _HeaderIcon(assetPath: 'images/specialist_alarm.png'),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialtyName.isEmpty ? 'طبيب عام' : specialtyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: CircleAvatar(
              radius: 31,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF3F4F6),
                backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? NetworkImage(imageUrl!)
                    : null,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? const Icon(Icons.person,
                        color: specialistGreen, size: 30)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;

  const _HeaderIcon({this.icon, this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFF0FAF5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: assetPath != null
            ? Image.asset(assetPath!, width: 26, height: 26)
            : Icon(icon, color: specialistGreen, size: 26),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? statusAr;

  const StatusBadge({
    super.key,
    required this.status,
    this.statusAr,
  });

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'Rejected';
    final cancelled = status == 'Cancelled';
    final approved = status == 'Approved';
    final color = rejected
        ? specialistRed
        : approved
            ? specialistGreen
            : cancelled
                ? Colors.black
                : const Color(0xFFFF7A00);
    final bg = rejected
        ? const Color(0xFFFFF0F0)
        : approved
            ? const Color(0xFFEAF8F0)
            : cancelled
                ? const Color(0xFFF2F2F2)
                : const Color(0xFFFFF2E3);
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        specialistStatusLabel(status, statusAr),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: specialistFont,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class ApplicationStatusCard extends StatelessWidget {
  final String specialtyName;
  final DateTime? submittedAt;
  final String status;
  final String? statusAr;
  final String? rejectionReason;
  final bool compact;

  const ApplicationStatusCard({
    super.key,
    required this.specialtyName,
    required this.submittedAt,
    required this.status,
    this.statusAr,
    this.rejectionReason,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
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
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: specialistGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      specialtyName.isEmpty ? 'طبيب عام' : specialtyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatArabicSubmittedDate(submittedAt),
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
              StatusBadge(status: status, statusAr: statusAr),
            ],
          ),
          if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 20),
            RejectionReasonBox(reason: rejectionReason!),
          ],
        ],
      ),
    );
  }
}

class RejectionReasonBox extends StatelessWidget {
  final String reason;

  const RejectionReasonBox({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFA8A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'السبب',
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: specialistFont,
              fontSize: 15,
              height: 1.55,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class ApplicationSectionTile extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const ApplicationSectionTile({
    super.key,
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: Radius.circular(expanded ? 0 : 18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class UploadedDocumentField extends StatelessWidget {
  final String label;
  final bool uploaded;
  final bool editable;
  final bool loading;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  const UploadedDocumentField({
    super.key,
    required this.label,
    required this.uploaded,
    required this.editable,
    required this.loading,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label.replaceAll('*', '')),
              const TextSpan(
                text: '*',
                style: TextStyle(color: specialistRed),
              ),
            ],
          ),
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
              _SmallOutlinePill(label: 'فتح', onTap: onOpen),
              const SizedBox(width: 6),
              if (editable)
                _SmallGreenPill(
                  label: loading ? '...' : 'تعديل',
                  onTap: loading ? null : onEdit,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  uploaded ? 'تم تحميل الصورة' : 'اضغط تحميل الصورة',
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

class _SmallGreenPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SmallGreenPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 68),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: specialistGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SmallOutlinePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallOutlinePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: specialistFont,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class SpecialistBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SpecialistBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => onTap?.call(0),
            behavior: HitTestBehavior.opaque,
            child: _SpecialistNavItem(
              icon: Icons.person_outline_rounded,
              label: 'الملف الشخصي',
              active: currentIndex == 0,
            ),
          ),
          GestureDetector(
            onTap: () => onTap?.call(1),
            behavior: HitTestBehavior.opaque,
            child: _SpecialistNavItem(
              icon: Icons.calendar_month_rounded,
              label: 'طلب التقدم',
              active: currentIndex == 1,
            ),
          ),
          GestureDetector(
            onTap: () => onTap?.call(2),
            behavior: HitTestBehavior.opaque,
            child: _SpecialistNavItem(
              icon: Icons.home_outlined,
              label: 'الرئيسية',
              active: currentIndex == 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _SpecialistNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                active ? specialistGreen : Colors.black.withValues(alpha: 0.25),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: specialistFont,
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color:
                  active ? Colors.black : Colors.black.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 46 : 0,
            height: 5,
            decoration: BoxDecoration(
              color: specialistGreen,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showWarningConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => WarningConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}

class WarningConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const WarningConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: specialistRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: specialistRed,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: specialistFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      Expanded(
                        child: AjialOutlineButton(
                          label: cancelLabel,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: specialistRed,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Text(
                              confirmLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: specialistFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.close, color: Colors.black, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatArabicSubmittedDate(DateTime? date) {
  if (date == null) return 'منذ 24 ديسمبر 2025';
  final months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  final local = date.toLocal();
  return 'منذ ${local.day} ${months[local.month - 1]} ${local.year}';
}

void showArabicSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: specialistFont),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> openDocumentUrl(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) {
    showArabicSnackBar(context, 'لا يوجد ملف للفتح');
    return;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    showArabicSnackBar(context, 'رابط الملف غير صالح');
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    showArabicSnackBar(context, 'تعذر فتح الملف');
  }
}
