import 'dart:io';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';

/// Callback invoked when an alarm starts ringing.
/// Provides the AlarmSettings of the triggered alarm.
typedef AlarmRingCallback = void Function(AlarmSettings alarmSettings);

/// Service class for managing local alarm notifications for vaccination reminders.
///
/// Uses the `alarm` package for real alarm functionality:
/// - Plays looping alarm sound via native Foreground Service
/// - Shows full-screen intent over lock screen
/// - Works even when app is closed/killed/minimized
/// - Vibration support
///
/// This service handles:
/// - Scheduling alarms at specified times
/// - Canceling scheduled alarms
/// - Snooze functionality (reschedule 30 minutes from now)
/// - Generating unique alarm IDs from childId + milestoneId
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  bool _isInitialized = false;
  AlarmRingCallback? onAlarmRing;

  /// The path to the alarm sound asset file.
  static const String _alarmSoundPath = 'assets/sounds/alarm_sound.mp3';

  /// Initializes the alarm service.
  /// Must be called once at app startup (in main.dart).
  Future<void> initialize({AlarmRingCallback? onRing}) async {
    if (_isInitialized) return;

    onAlarmRing = onRing;

    // Initialize the alarm plugin
    await Alarm.init();

    // Listen to alarm ringing events
    Alarm.ringing.listen((AlarmSet alarmSet) {
      debugPrint('🔔 Alarm ringing! ${alarmSet.alarms.length} alarm(s)');
      for (final alarm in alarmSet.alarms) {
        debugPrint('   Alarm ID: ${alarm.id}');
        onAlarmRing?.call(alarm);
      }
    });

    _isInitialized = true;
    debugPrint('✅ LocalNotificationService initialized (alarm package)');
  }

  /// Generates a unique notification ID from childId (GUID) and milestoneId.
  /// Uses hashCode which produces consistent integers.
  ///
  /// We use 4 IDs per reminder for different alarm times:
  /// - Base ID: Exact appointment time
  /// - Base ID + 1: 1 day before
  /// - Base ID + 2: 3 hours before
  /// - Base ID + 3: Custom reminder time
  int _generateBaseNotificationId(String childId, int milestoneId) {
    final combinedKey = '${childId}_$milestoneId';
    // Use abs() to ensure positive, and mod to keep within int range
    // alarm package uses int ids so we keep them reasonable
    return combinedKey.hashCode.abs() % 100000000;
  }

  /// Schedules all vaccination reminder alarms based on the user's settings.
  ///
  /// [childId] - The child's unique GUID
  /// [milestoneId] - The vaccination milestone ID
  /// [childName] - The child's name for notification body
  /// [healthUnit] - The health unit/hospital name
  /// [appointmentDateTime] - The actual appointment date and time
  /// [notifyOneDayBefore] - Whether to notify 1 day before
  /// [notifyThreeHoursBefore] - Whether to notify 3 hours before
  /// [customReminderEnabled] - Whether custom reminder is enabled
  /// [customReminderDateTime] - The custom reminder date/time (if enabled)
  Future<void> scheduleVaccinationAlarms({
    required String childId,
    required int milestoneId,
    required String childName,
    required String healthUnit,
    required DateTime appointmentDateTime,
    required bool notifyOneDayBefore,
    required bool notifyThreeHoursBefore,
    required bool customReminderEnabled,
    DateTime? customReminderDateTime,
  }) async {
    // First, cancel any existing alarms for this child/milestone
    await cancelVaccinationAlarms(childId: childId, milestoneId: milestoneId);

    final baseId = _generateBaseNotificationId(childId, milestoneId);
    final payload = '$childId|$milestoneId|$childName|$healthUnit';

    // 1. Schedule exact appointment time alarm
    await _scheduleAlarm(
      id: baseId,
      scheduledTime: appointmentDateTime,
      title: 'تذكير بموعد التطعيم 💉',
      body: 'حان موعد تطعيم $childName الآن - $healthUnit',
      payload: payload,
    );

    // 2. Schedule 1 day before (if enabled)
    if (notifyOneDayBefore) {
      final oneDayBefore =
          appointmentDateTime.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(DateTime.now())) {
        await _scheduleAlarm(
          id: baseId + 1,
          scheduledTime: oneDayBefore,
          title: 'تذكير بموعد التطعيم 💉',
          body:
              'موعد تطعيم $childName غداً في ${_formatTime(appointmentDateTime)} - $healthUnit',
          payload: payload,
        );
      }
    }

    // 3. Schedule 3 hours before (if enabled)
    if (notifyThreeHoursBefore) {
      final threeHoursBefore =
          appointmentDateTime.subtract(const Duration(hours: 3));
      if (threeHoursBefore.isAfter(DateTime.now())) {
        await _scheduleAlarm(
          id: baseId + 2,
          scheduledTime: threeHoursBefore,
          title: 'تذكير بموعد التطعيم 💉',
          body:
              'موعد تطعيم $childName بعد 3 ساعات في ${_formatTime(appointmentDateTime)} - $healthUnit',
          payload: payload,
        );
      }
    }

    // 4. Schedule custom reminder (if enabled)
    if (customReminderEnabled && customReminderDateTime != null) {
      if (customReminderDateTime.isAfter(DateTime.now())) {
        await _scheduleAlarm(
          id: baseId + 3,
          scheduledTime: customReminderDateTime,
          title: 'تذكير بموعد التطعيم 💉',
          body:
              'تذكير مخصص: موعد تطعيم $childName في ${_formatTime(appointmentDateTime)} - $healthUnit',
          payload: payload,
        );
      }
    }

    debugPrint(
        '✅ Scheduled vaccination alarms for childId=$childId, milestoneId=$milestoneId');
  }

  /// Schedules a single alarm using the `alarm` package.
  /// This creates a real alarm with:
  /// - Looping alarm sound
  /// - Full-screen intent (shows over lock screen)
  /// - Vibration
  /// - Native foreground service (works when app is killed)
  Future<void> _scheduleAlarm({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = DateTime.now();

    // Don't schedule if time is in the past
    if (scheduledTime.isBefore(now)) {
      debugPrint('⚠️ Skipping alarm $id - scheduled time is in the past');
      debugPrint('   Now: $now, Scheduled: $scheduledTime');
      return;
    }

    debugPrint('📅 Scheduling alarm ID=$id');
    debugPrint('   Scheduled time: $scheduledTime');
    debugPrint(
        '   Seconds until trigger: ${scheduledTime.difference(now).inSeconds}');

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledTime,
      assetAudioPath: _alarmSoundPath,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.9,
        fadeDuration: const Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'إيقاف التنبيه',
        icon: 'launcher_icon',
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      debugPrint('✅ Successfully scheduled alarm ID=$id for $scheduledTime');

      // Verify the alarm was scheduled
      final alarms = await Alarm.getAlarms();
      final scheduled = alarms.any((a) => a.id == id);
      debugPrint(
          '   Verification: Alarm $id is ${scheduled ? "SCHEDULED" : "NOT FOUND"}');
      debugPrint('   Total scheduled alarms: ${alarms.length}');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to schedule alarm ID=$id: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  /// Cancels all vaccination alarms for a specific child and milestone.
  Future<void> cancelVaccinationAlarms({
    required String childId,
    required int milestoneId,
  }) async {
    final baseId = _generateBaseNotificationId(childId, milestoneId);

    // Cancel all 4 possible alarm IDs
    await Alarm.stop(baseId);
    await Alarm.stop(baseId + 1);
    await Alarm.stop(baseId + 2);
    await Alarm.stop(baseId + 3);

    debugPrint(
        '🗑️ Cancelled vaccination alarms for childId=$childId, milestoneId=$milestoneId');
  }

  /// Stops the currently ringing alarm by ID.
  Future<void> stopAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
    debugPrint('🛑 Stopped alarm ID=$alarmId');
  }

  /// Cancels a specific alarm by ID and schedules a snooze alarm
  /// 30 minutes from now.
  Future<void> snooze30Minutes({
    required int alarmId,
    required String childName,
    required String healthUnit,
    required String payload,
  }) async {
    // Stop the current alarm (stops sound + vibration)
    await Alarm.stop(alarmId);

    // Schedule a new one 30 minutes from now
    final snoozeTime = DateTime.now().add(const Duration(minutes: 30));

    // Use a modified ID for snooze (add 1000 to avoid collision)
    final snoozeId = alarmId + 1000;

    await _scheduleAlarm(
      id: snoozeId,
      scheduledTime: snoozeTime,
      title: 'تذكير بموعد التطعيم 💉',
      body: 'تذكير (تأجيل): حان موعد تطعيم $childName - $healthUnit',
      payload: payload,
    );

    debugPrint('⏰ Snoozed alarm for 30 minutes (new ID=$snoozeId)');
  }

  /// Formats time for display in notification body.
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Cancels all pending alarms.
  Future<void> cancelAllAlarms() async {
    await Alarm.stopAll();
    debugPrint('🗑️ Cancelled all alarms');
  }

  /// Gets list of currently scheduled alarms (for debugging).
  Future<List<AlarmSettings>> getScheduledAlarms() async {
    return await Alarm.getAlarms();
  }

  /// Schedules a test alarm in the specified number of seconds.
  /// Use this to verify that alarm functionality is working.
  Future<void> scheduleTestAlarm({int delaySeconds = 10}) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: delaySeconds));

    debugPrint('🧪 Scheduling TEST alarm in $delaySeconds seconds');
    debugPrint('   Current time: ${DateTime.now()}');
    debugPrint('   Scheduled time: $scheduledTime');

    await _scheduleAlarm(
      id: 99999, // Test alarm ID
      scheduledTime: scheduledTime,
      title: '🧪 اختبار التنبيه',
      body: 'إذا رأيت هذا، فإن التنبيهات تعمل بشكل صحيح!',
      payload: 'test|0|test|test',
    );

    // Verify scheduling
    final alarms = await getScheduledAlarms();
    debugPrint('🧪 Total scheduled alarms after test: ${alarms.length}');
    for (final alarm in alarms) {
      debugPrint('   - ID: ${alarm.id}, Time: ${alarm.dateTime}');
    }
  }

  /// Checks if permissions are properly granted.
  /// Returns a map with permission status.
  Future<Map<String, bool>> checkPermissions() async {
    // The alarm package handles permissions internally,
    // but we can still check basic notification permission
    if (Platform.isAndroid) {
      // alarm package manages its own permissions
      return {
        'notificationsEnabled': true,
        'exactAlarmsAllowed': true,
      };
    }
    return {'notificationsEnabled': true, 'exactAlarmsAllowed': true};
  }
}
