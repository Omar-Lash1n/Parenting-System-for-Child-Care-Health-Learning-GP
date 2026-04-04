import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:alarm/alarm.dart';
import 'local_notification_service.dart';

const Color _kPrimaryColor = Color(0xFFBF092F);
const Color _kTextPrimary = Color(0xFF1E293B);
const Color _kTextSecondary = Color(0xFF64748B);
const String _kFontFamily = 'IBM Plex Sans Arabic';

/// Screen displayed when a vaccination alarm is triggered.
/// Shows the child's image, vaccination title, time, and action buttons.
///
/// When this screen is shown, the alarm is actively ringing (sound + vibration).
/// All action buttons stop the alarm before performing their action.
class VaccinationAlarmScreen extends StatelessWidget {
  /// The child's name
  final String childName;

  /// URL or asset path to the child's profile image
  final String? childImageUrl;

  /// Vaccination title (e.g., "تطعيم 4 شهور")
  final String vaccinationTitle;

  /// The scheduled appointment time
  final DateTime appointmentTime;

  /// Health unit / hospital name
  final String healthUnit;

  /// Child ID for API calls and notification management
  final String childId;

  /// Milestone ID for API calls and notification management
  final int milestoneId;

  /// The alarm ID that triggered this screen (used to stop+ the alarm)
  final int alarmId;

  /// Callback when "تم التطعيم" (Vaccination Completed) is tapped
  final VoidCallback? onVaccinationCompleted;

  /// Callback when "ضبط موعد اخر" (Set another time) is tapped
  final VoidCallback? onSetAnotherTime;

  VaccinationAlarmScreen({
    super.key,
    required this.childName,
    this.childImageUrl,
    required this.vaccinationTitle,
    required this.appointmentTime,
    required this.healthUnit,
    required this.childId,
    required this.milestoneId,
    required this.alarmId,
    this.onVaccinationCompleted,
    this.onSetAnotherTime,
  });

  /// Creates an instance from notification payload string.
  /// Payload format: "childId|milestoneId|childName|healthUnit"
  factory VaccinationAlarmScreen.fromPayload({
    required String payload,
    required String vaccinationTitle,
    required DateTime appointmentTime,
    required int alarmId,
    String? childImageUrl,
    VoidCallback? onVaccinationCompleted,
    VoidCallback? onSetAnotherTime,
  }) {
    final parts = payload.split('|');
    return VaccinationAlarmScreen(
      childId: parts.isNotEmpty ? parts[0] : '',
      milestoneId: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      childName: parts.length > 2 ? parts[2] : '',
      healthUnit: parts.length > 3 ? parts[3] : '',
      vaccinationTitle: vaccinationTitle,
      appointmentTime: appointmentTime,
      alarmId: alarmId,
      childImageUrl: childImageUrl,
      onVaccinationCompleted: onVaccinationCompleted,
      onSetAnotherTime: onSetAnotherTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        // Prevent back button from dismissing without stopping alarm
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _stopAlarmAndPop(context);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Child's circular image
                  _ChildProfileImage(imageUrl: childImageUrl),

                  const SizedBox(height: 32),

                  // Bell icon and vaccination title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: _kTextSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vaccinationTitle,
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Large time display
                  Text(
                    _formatTimeArabic(appointmentTime),
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      height: 1.1,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Action buttons
                  _ActionButtons(
                    onVaccinationCompleted: () =>
                        _handleCompleted(context),
                    onSnooze30Minutes: () => _handleSnooze(context),
                    onSetAnotherTime: () =>
                        _handleSetAnotherTime(context),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Stops the alarm sound and pops the screen.
  Future<void> _stopAlarmAndPop(BuildContext context) async {
    await Alarm.stop(alarmId);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Handles "تم التطعيم" (Vaccination Completed) button.
  Future<void> _handleCompleted(BuildContext context) async {
    // Stop the alarm sound first
    await Alarm.stop(alarmId);
    onVaccinationCompleted?.call();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Handles the snooze button tap - stops current alarm and schedules
  /// a new alarm 30 minutes from now.
  Future<void> _handleSnooze(BuildContext context) async {
    final notificationService = LocalNotificationService();
    final payload = '$childId|$milestoneId|$childName|$healthUnit';

    await notificationService.snooze30Minutes(
      alarmId: alarmId,
      childName: childName,
      healthUnit: healthUnit,
      payload: payload,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سيتم تذكيرك بعد 30 دقيقة',
            style: TextStyle(fontFamily: _kFontFamily),
          ),
          backgroundColor: _kPrimaryColor,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  /// Handles "ضبط موعد اخر" (Set Another Time) button.
  Future<void> _handleSetAnotherTime(BuildContext context) async {
    // Stop the alarm sound first
    await Alarm.stop(alarmId);
    onSetAnotherTime?.call();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Formats time in Arabic format (e.g., "10:00 ص")
  String _formatTimeArabic(DateTime dateTime) {
    return DateFormat('h:mm a', 'ar').format(dateTime);
  }
}

/// Circular child profile image with decorative border.
class _ChildProfileImage extends StatelessWidget {
  final String? imageUrl;

  const _ChildProfileImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFEE2E2), // Light red/pink border
          width: 8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? _buildNetworkImage()
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildNetworkImage() {
    if (imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: 124,
        height: 124,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    } else {
      return Image.asset(
        imageUrl!,
        width: 124,
        height: 124,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 124,
      height: 124,
      color: const Color(0xFFFEF2F2),
      child: const Icon(
        Icons.child_care,
        size: 48,
        color: _kPrimaryColor,
      ),
    );
  }
}

/// Action buttons section with three buttons.
class _ActionButtons extends StatelessWidget {
  final VoidCallback onVaccinationCompleted;
  final VoidCallback onSnooze30Minutes;
  final VoidCallback onSetAnotherTime;

  const _ActionButtons({
    required this.onVaccinationCompleted,
    required this.onSnooze30Minutes,
    required this.onSetAnotherTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary button - "تم التطعيم"
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onVaccinationCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'تم التطعيم',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Secondary button - "تذكير بعد 30 دقيقة"
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: onSnooze30Minutes,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextPrimary,
              side: BorderSide(
                color: Colors.black.withOpacity(0.2),
                width: 1.5,
              ),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'تذكير بعد 30 دقيقة',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Text button - "ضبط موعد اخر"
        TextButton(
          onPressed: onSetAnotherTime,
          style: TextButton.styleFrom(
            foregroundColor: _kTextSecondary,
          ),
          child: const Text(
            'ضبط موعد اخر',
            style: TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
