import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class ClinicStatusCard extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final String? rejectionReason;
  final Widget? actionArea;
  final Color? statusColor;

  const ClinicStatusCard({
    super.key,
    required this.title,
    required this.date,
    required this.status,
    this.rejectionReason,
    this.actionArea,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    Color effectiveStatusColor;
    Color statusBgColor;

    if (statusColor != null) {
      effectiveStatusColor = statusColor!;
      statusBgColor = statusColor!.withValues(alpha: 0.1);
    } else {
      switch (status) {
        case 'مقبول':
          effectiveStatusColor = specialistGreen;
          statusBgColor = specialistGreen.withValues(alpha: 0.1);
          break;
        case 'مرفوض':
        case 'لم يتم القبول':
          effectiveStatusColor = Colors.red;
          statusBgColor = Colors.red.withValues(alpha: 0.1);
          break;
        case 'جاري المراجعة':
        default:
          effectiveStatusColor = Colors.orange;
          statusBgColor = Colors.orange.withValues(alpha: 0.1);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon (Right side in RTL)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: specialistGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: specialistGreen,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge (Left side in RTL)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: specialistFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: effectiveStatusColor,
                  ),
                ),
              ),
            ],
          ),
          
          if (rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
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
                    rejectionReason!,
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
          ],
          
          if (actionArea != null) ...[
            const SizedBox(height: 16),
            actionArea!,
          ],
        ],
      ),
    );
  }
}
