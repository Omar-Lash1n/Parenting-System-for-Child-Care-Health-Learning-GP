import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaccinationReminderService {
  static const String _apiBaseUrl =
      "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api";
  static const String _tokenKey = 'ajial_auth_token';
  
  static Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 1. POST /api/VaccinationReminder/device-token
  static Future<void> registerDeviceToken() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final deviceToken = await FirebaseMessaging.instance.getToken();
      if (deviceToken == null) return;
      
      print('📱 FCM Device Token: $deviceToken');

      final url = Uri.parse('$_apiBaseUrl/VaccinationReminder/device-token');
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"deviceToken": deviceToken}),
      );

      if (response.statusCode == 200) {
        print('✅ Device token registered successfully on the backend');
      } else {
        print('⚠️ Failed to register device token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering device token: $e');
    }
  }

  /// 2. GET /api/VaccinationReminder/child/{childId}/milestone/{milestoneId}
  static Future<Map<String, dynamic>?> getReminderSettings(
      String childId, int milestoneId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final url = Uri.parse(
          '$_apiBaseUrl/VaccinationReminder/child/$childId/milestone/$milestoneId');
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching reminder settings: $e');
      return null;
    }
  }

  /// 3. POST /api/VaccinationReminder/upsert
  static Future<(bool, String)> upsertReminder({
    required String childId,
    required int milestoneId,
    required String hospitalName,
    required String appointmentDate,
    required String appointmentTime,
    required bool notifyOneDayBefore,
    required bool notifyThreeHoursBefore,
    required bool customReminderEnabled,
    String? customReminderDateTime,
    required bool isAlarmEnabled,
    required bool isPushEnabled,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (false, 'غير مصرح');

      final url = Uri.parse('$_apiBaseUrl/VaccinationReminder/upsert');
      
      final Map<String, dynamic> body = {
        "childId": childId,
        "milestoneId": milestoneId,
        "healthUnit": hospitalName,
        "appointmentDate": appointmentDate,
        "appointmentTime": appointmentTime,
        "notifyOneDayBefore": notifyOneDayBefore,
        "notifyThreeHoursBefore": notifyThreeHoursBefore,
        "customReminderEnabled": customReminderEnabled,
        "customReminderDateTime": customReminderDateTime,
        "isAlarmEnabled": isAlarmEnabled,
        "isPushEnabled": isPushEnabled,
      };

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return (true, 'تم حفظ إعدادات التنبيه بنجاح');
      } else {
        return (false, (responseData['message'] ?? 'فشل في حفظ إعدادات التنبيه').toString());
      }
    } catch (e) {
      print('❌ Error upserting reminder settings: $e');
      return (false, 'تأكد من الاتصال بالإنترنت');
    }
  }
}
