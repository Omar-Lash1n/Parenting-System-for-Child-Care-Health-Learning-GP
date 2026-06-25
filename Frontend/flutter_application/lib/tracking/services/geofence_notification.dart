import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Fires a single local notification when the child exits the safe zone.
class GeofenceNotification {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  static Future<void> showBreach() async {
    await _init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'geofence_breach',
        'تنبيهات سور الحماية',
        channelDescription: 'إشعارات خروج الطفل من منطقة سور الامان',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      1001,
      'تحذير!! خرج الطفل من منطقة سور الامان',
      'اتصل الان بالطفل او اكد اعلامك بذلك',
      details,
    );
  }
}
