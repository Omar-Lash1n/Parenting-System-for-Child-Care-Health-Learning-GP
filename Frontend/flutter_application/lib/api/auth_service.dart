// --- lib/api/auth_service.dart ---

import 'package:http/http.dart' as http;
import 'dart:convert'; // (لعمل jsonEncode و jsonDecode)
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 1. الرابط الأساسي للـ API (من ملف الـ PDF)
  static const String _apiBaseUrl =
      "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api";

  static const String _tokenKey = 'ajial_auth_token';

  /// دالة تسجيل الوالدين (Register Parent)
  ///
  /// تأخذ جميع البيانات المطلوبة كـ parameters.
  /// ترجع `null` في حالة النجاح.
  /// ترجع `String` (رسالة الخطأ) في حالة الفشل.
  Future<String?> registerParent({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required int cityId,
    required String dateOfBirth, // (String in ISO 8601 format)
    required int gender,
  }) async {
    // 2. تجميع الرابط الكامل (من ملف الـ PDF صفحة 4) [cite: 10]
    final String apiUrl = '$_apiBaseUrl/Auth/register/parent';

    // 3. تجهيز الـ Headers (من ملف الـ PDF صفحة 4) [cite: 16, 17]
    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // 4. تجهيز الـ Body (من ملف الـ PDF صفحة 4) [cite: 19-32]
    final Map<String, dynamic> body = {
      "fullName": fullName,
      "username": username,
      "email": email,
      "password": password,
      "cityId": cityId,
      "dateOfBirth": dateOfBirth, // (الـ API يتوقع صيغة "YYYY-MM-DD")
      "gender": gender,
    };

    try {
      // 5. إرسال الطلب (Request)
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body), // (تحويل الـ Map إلى JSON String)
      );

      // 6. التعامل مع الرد (Response)

      // في حالة النجاح (201 Created) [cite: 67]
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Registration Successful: ${response.body}');
        return null; // (null) يعني "لا يوجد خطأ"
      }
      // في حالة الفشل (400 Bad Request) [cite: 91]
      else {
        print('Server Error: ${response.statusCode}');
        print('Response Body: ${response.body}');

        // محاولة استخراج رسائل الخطأ من الـ JSON [cite: 97-100]
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['errors'] != null &&
              (errorBody['errors'] as List).isNotEmpty) {
            // إرجاع أول رسالة خطأ
            return (errorBody['errors'] as List).first.toString();
          } else if (errorBody['message'] != null) {
            return errorBody['message'].toString();
          }
          return 'حدث خطأ غير معروف. رمز الحالة: ${response.statusCode}';
        } catch (e) {
          return response.body; // (إذا فشل تحليل JSON، أعد النص كما هو)
        }
      }
    } catch (e) {
      // --- خطأ في الاتصال (مثل عدم وجود انترنت) ---
      print('Connection Error: $e');
      return 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.';
    }
  }

  // --- *** بداية التعديل المطلوب *** ---
  // --- 3. دالة تسجيل الدخول (Login) ---

  /// ترجع (Token, null) في حالة النجاح.
  /// ترجع (null, ErrorMessage) في حالة الفشل.
  Future<(String?, String?)> loginParent({
    required String username,
    required String password,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/login/parent';

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      "username": username,
      "password": password,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // --- نجاح ---
        final responseBody = jsonDecode(response.body);

        // 1. التحقق من الـ JSON الجديد
        if (responseBody['success'] == true &&
            responseBody['data'] != null &&
            responseBody['data']['token'] != null) {
          // 2. استخراج التوكن
          final String token = responseBody['data']['token'].toString();
          print('Login Successful. Token received.');

          // 3. حفظ التوكن (الـ Session) في ذاكرة الهاتف
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);

          return (token, null); // (نجاح: أعد التوكن)
        } else {
          // (إذا الرد 200 ولكن success = false أو لا يوجد توكن)
          return (
            null,
            (responseBody['message'] ?? 'رد غير متوقع من السيرفر').toString(),
          );
        }
      } else {
        // --- خطأ من السيرفر (مثل: 400 Bad Request) ---
        print('Server Error: ${response.statusCode}');
        print('Response Body: ${response.body}');

        // (الـ JSON للخطأ والفشل متطابق في Swagger، سنفترض أن رسالة الخطأ موجودة في "message")
        try {
          final errorBody = jsonDecode(response.body);
          final String errorMessage = (errorBody['message'] ?? response.body)
              .toString();
          return (null, errorMessage);
        } catch (e) {
          return (null, response.body); // (فشل: أعد رسالة الخطأ)
        }
      }
    } catch (e) {
      // --- خطأ في الاتصال ---
      print('Connection Error: $e');
      return (null, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  // --- 4. دالة تسجيل الخروج (Logout) ---
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // (ببساطة قم بمسح التوكن المحفوظ)
    await prefs.remove(_tokenKey);
    print('User logged out, token removed.');
  }

  // --- (دالة إضافية للتحقق من الـ Token عند فتح التطبيق) ---
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  // --- *** نهاية التعديل المطلوب *** ---

  /// دالة طلب "نسيت كلمة المرور"
  ///
  /// تأخذ الإيميل.
  /// ترجع (true, SuccessMessage) في حالة النجاح.
  /// ترجع (false, ErrorMessage) في حالة الفشل.
  Future<(bool, String)> forgotPassword({required String email}) async {
    // 1. الرابط (من المعلومات التي أرسلتها)
    final String apiUrl = '$_apiBaseUrl/Auth/forgot-password';

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
    };

    // 2. الجسم (Body) (من المعلومات التي أرسلتها)
    final Map<String, dynamic> body = {"email": email};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      // 3. تحليل الرد
      final responseBody = jsonDecode(response.body);

      // (استخراج الرسالة، سواء كانت نجاحاً أو فشلاً)
      // (نفترض أن "message" موجود دائماً بناءً على الردود التي أرسلتها)
      final String message = (responseBody['message'] ?? 'حدث خطأ غير متوقع')
          .toString();

      if (response.statusCode == 200) {
        // --- نجاح ---
        print('Forgot Password Success: $message');
        return (true, message); // (نجاح: أعد الرسالة)
      } else {
        // --- خطأ (مثل 400 أو 404) ---
        print('Forgot Password Error: $message');
        return (false, message); // (فشل: أعد رسالة الخطأ)
      }
    } catch (e) {
      // --- خطأ في الاتصال ---
      print('Connection Error: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  // --- (أضف هذا الكود داخل كلاس AuthService في lib/api/auth_service.dart) ---

  /// دالة إعادة تعيين كلمة المرور
  ///
  /// تأخذ الرمز (OTP)، وكلمة المرور الجديدة، وتأكيدها.
  /// ترجع (true, SuccessMessage) في حالة النجاح.
  /// ترجع (false, ErrorMessage) في حالة الفشل.
  Future<(bool, String)> resetPassword({
    required String token, // هذا هو الـ OTP/Code من الإيميل
    required String newPassword,
    required String confirmPassword,
  }) async {
    // 1. الرابط (من المعلومات التي أرسلتها)
    final String apiUrl = '$_apiBaseUrl/Auth/reset-password';

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
    };

    // 2. الجسم (Body) (من المعلومات التي أرسلتها)
    final Map<String, dynamic> body = {
      "token": token,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      // 3. تحليل الرد
      final responseBody = jsonDecode(response.body);
      final String message = (responseBody['message'] ?? 'حدث خطأ غير متوقع')
          .toString();

      if (response.statusCode == 200) {
        // --- نجاح ---
        print('Password Reset Success: $message');
        return (true, message); // (نجاح: أعد الرسالة)
      } else {
        // --- خطأ (مثل 400 - الرمز غلط أو الباسورد ضعيف) ---
        print('Password Reset Error: $message');

        // (محاولة استخراج رسائل خطأ مفصلة إن وجدت)
        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          return (false, (responseBody['errors'] as List).first.toString());
        }
        return (false, message); // (فشل: أعد رسالة الخطأ)
      }
    } catch (e) {
      // --- خطأ في الاتصال ---
      print('Connection Error: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  // --- (أضف هذا الكود داخل كلاس AuthService في lib/api/auth_service.dart) ---

  /// دالة التحقق من الرمز (OTP)
  ///
  /// تأخذ الرمز الذي أدخله المستخدم.
  /// ترجع (true, SuccessMessage) في حالة النجاح.
  /// ترجع (false, ErrorMessage) في حالة الفشل.
  Future<(bool, String)> verifyOtp({
    required String otpCode, // هذا هو الرمز من الإيميل
  }) async {
    // 1. الرابط (من المعلومات التي أرسلتها)
    final String apiUrl = '$_apiBaseUrl/Auth/verify-otp';

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
    };

    // 2. الجسم (Body) (فقط الـ token كما طلبت)
    final Map<String, dynamic> body = {"token": otpCode};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      // 3. تحليل الرد
      final responseBody = jsonDecode(response.body);
      final String message = (responseBody['message'] ?? 'حدث خطأ غير متوقع')
          .toString();

      // 4. التحقق من النجاح (StatusCode و success و isValid)
      if (response.statusCode == 200 &&
          responseBody['success'] == true &&
          responseBody['data'] != null &&
          responseBody['data']['isValid'] == true) {
        // --- نجاح ---
        print('OTP Verification Success: $message');
        return (true, message);
      } else {
        // --- خطأ (مثل 400 - الرمز غلط) ---
        print('OTP Verification Error: $message');

        // (محاولة استخراج رسائل خطأ مفصلة إن وجدت)
        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          return (false, (responseBody['errors'] as List).first.toString());
        }
        // (إرجاع الرسالة الرئيسية من السيرفر)
        return (false, message);
      }
    } catch (e) {
      // --- خطأ في الاتصال ---
      print('Connection Error: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }
}
