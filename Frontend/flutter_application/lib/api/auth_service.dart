// --- lib/api/auth_service.dart ---

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // (قد تحتاج لإضافتها في pubspec.yaml، أو اتركها للكشف التلقائي)
import 'package:mime/mime.dart';

class AuthService {
  // الرابط الأساسي للـ API
  static const String _apiBaseUrl =
      "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api";

  static const String _tokenKey = 'ajial_auth_token';
  static const String _childTokenKey = 'ajial_child_token';
  static const String _childIdKey = 'ajial_child_id';
  static const String _childNameKey = 'ajial_child_name';

  // ============================================================
  // ==================== Parent Functions ======================
  // ============================================================

  /// دالة تسجيل الوالدين (Register Parent)
  Future<String?> registerParent({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required int cityId,
    required String dateOfBirth,
    required int gender,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/register/parent';

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      "fullName": fullName,
      "username": username,
      "email": email,
      "password": password,
      "cityId": cityId,
      "dateOfBirth": dateOfBirth,
      "gender": gender,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Registration Successful: ${response.body}');
        return null;
      } else {
        print('Server Error: ${response.statusCode}');
        print('Response Body: ${response.body}');

        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['errors'] != null &&
              (errorBody['errors'] as List).isNotEmpty) {
            return (errorBody['errors'] as List).first.toString();
          } else if (errorBody['message'] != null) {
            return errorBody['message'].toString();
          }
          return 'حدث خطأ غير معروف.  رمز الحالة: ${response.statusCode}';
        } catch (e) {
          return response.body;
        }
      }
    } catch (e) {
      print('Connection Error: $e');
      return 'حدث خطأ في الاتصال.  يرجى المحاولة مرة أخرى.';
    }
  }

  /// دالة تسجيل دخول الوالدين
  Future<(String?, String?)> loginParent({
    required String username,
    required String password,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/login/parent';

    final Map<String, String> headers = {
      'accept': 'application/json',
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
        final responseBody = jsonDecode(response.body);

        if (responseBody['success'] == true &&
            responseBody['data'] != null &&
            responseBody['data']['token'] != null) {
          final String token = responseBody['data']['token'].toString();
          print('Login Successful.  Token received.');

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);

          return (token, null);
        } else {
          return (
            null,
            (responseBody['message'] ?? 'رد غير متوقع من السيرفر').toString(),
          );
        }
      } else {
        print('Server Error: ${response.statusCode}');
        print('Response Body: ${response.body}');

        try {
          final errorBody = jsonDecode(response.body);
          final String errorMessage =
              (errorBody['message'] ?? response.body).toString();
          return (null, errorMessage);
        } catch (e) {
          return (null, response.body);
        }
      }
    } catch (e) {
      print('Connection Error: $e');
      return (null, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// دالة تسجيل الخروج
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_childTokenKey);
    await prefs.remove(_childIdKey);
    await prefs.remove(_childNameKey);
    print('User logged out, all tokens removed.');
  }

  /// الحصول على توكن الوالد
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ==================== Child Functions =======================

  /// دالة إضافة طفل جديد (Add Child)
  ///
  /// تتعامل مع Multipart Request لرفع الصورة والبيانات
  Future<(bool success, String message)> addChild({
    required String fullName,
    required DateTime birthDate,
    required String gender, // "Male" or "Female"
    File? profileImage,
    String? childLoginId, // للأطفال 4-13 سنة
    List<String>? fruitPasswordCodes, // للأطفال 4-13 سنة
  }) async {
    final String apiUrl = '$_apiBaseUrl/Child/add';
    final String? token = await getToken();

    if (token == null) {
      return (false, "غير مصرح. يرجى تسجيل الدخول أولاً.");
    }

    // 1. إنشاء طلب Multipart
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // 2. إضافة الهيدرز
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'accept': 'text/plain',
      // Content-Type يضاف تلقائياً مع multipart
    });

    // 3. إضافة الحقول النصية (Fields)
    request.fields['FullName'] = fullName;
    // تحويل التاريخ لصيغة ISO 8601 (مثل: 2017-06-15T00:00:00.000Z)
    request.fields['BirthDate'] = birthDate.toUtc().toIso8601String();
    request.fields['Gender'] = gender; // "Male" or "Female"

    // 4. إضافة بيانات الحساب (إذا وجدت)
    if (childLoginId != null && childLoginId.isNotEmpty) {
      request.fields['ChildLoginId'] = childLoginId;
    }

    // إضافة أكواد الفواكه (مهم جداً: إرسال القائمة كحقول متكررة بنفس الاسم)
    if (fruitPasswordCodes != null && fruitPasswordCodes.isNotEmpty) {
      for (String code in fruitPasswordCodes) {
        // في Dart http، لإرسال مصفوفة، نكرر الحقل بنفس المفتاح
        request.files
            .add(http.MultipartFile.fromString('FruitPasswordCodes', code));
      }
    }

    // 5. إضافة ملف الصورة (إذا وجد)
    if (profileImage != null) {
      // محاولة تحديد نوع الملف (MimeType)
      final mimeTypeData = lookupMimeType(profileImage.path)?.split('/');

      request.files.add(await http.MultipartFile.fromPath(
        'ProfileImage',
        profileImage.path,
        contentType: mimeTypeData != null
            ? MediaType(mimeTypeData[0], mimeTypeData[1])
            : null,
      ));
    }

    try {
      // 6. إرسال الطلب
      print("📤 Sending Add Child Request...");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // حسب الـ PDF، النجاح يرجع 200 مع success: true
        if (responseBody['success'] == true) {
          return (
            true,
            responseBody['message']?.toString() ?? "تم إضافة الطفل بنجاح"
          );
        } else {
          return (
            false,
            responseBody['message']?.toString() ?? "فشل إضافة الطفل"
          );
        }
      } else {
        // التعامل مع الأخطاء (400, 401, etc.)
        String errorMsg = "حدث خطأ غير معروف";

        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          errorMsg = (responseBody['errors'] as List).first.toString();
        } else if (responseBody['message'] != null) {
          errorMsg = responseBody['message'].toString();
        }

        return (false, errorMsg);
      }
    } catch (e) {
      print("❌ Error adding child: $e");
      return (false, "تأكد من الاتصال بالإنترنت");
    }
  }

  /// دالة نسيت كلمة المرور
  Future<(bool, String)> forgotPassword({required String email}) async {
    final String apiUrl = '$_apiBaseUrl/Auth/forgot-password';

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {"email": email};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);
      final String message =
          (responseBody['message'] ?? 'حدث خطأ غير متوقع').toString();

      if (response.statusCode == 200) {
        print('Forgot Password Success: $message');
        return (true, message);
      } else {
        print('Forgot Password Error: $message');
        return (false, message);
      }
    } catch (e) {
      print('Connection Error: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// دالة إعادة تعيين كلمة المرور
  Future<(bool, String)> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/reset-password';

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

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

      final responseBody = jsonDecode(response.body);
      final String message =
          (responseBody['message'] ?? 'حدث خطأ غير متوقع').toString();

      if (response.statusCode == 200) {
        print('Password Reset Success: $message');
        return (true, message);
      } else {
        print('Password Reset Error: $message');

        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          return (false, (responseBody['errors'] as List).first.toString());
        }
        return (false, message);
      }
    } catch (e) {
      print('Connection Error: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// دالة التحقق من الرمز (OTP)
  Future<(bool, String)> verifyOtp({required String otpCode}) async {
    final String apiUrl = '$_apiBaseUrl/Auth/verify-otp';

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {"token": otpCode};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);
      final String message =
          (responseBody['message'] ?? 'حدث خطأ غير متوقع').toString();

      if (response.statusCode == 200 &&
          responseBody['success'] == true &&
          responseBody['data'] != null &&
          responseBody['data']['isValid'] == true) {
        print('OTP Verification Success: $message');
        return (true, message);
      } else {
        print('OTP Verification Error: $message');

        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          return (false, (responseBody['errors'] as List).first.toString());
        }
        return (false, message);
      }
    } catch (e) {
      print('Connection Error: $e');
      return (false, 'حدث خطأ في الاتصال.  يرجى المحاولة مرة أخرى.');
    }
  }

  // ============================================================
  // ==================== Child Functions =======================
  // ============================================================

  /// دالة تسجيل دخول الطفل
  ///
  /// ترجع ChildLoginResult يحتوي على جميع بيانات الطفل
  Future<ChildLoginResult> loginChild({
    required String childLoginId,
    required List<String> fruitPasswordCodes,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/login/child';

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // تحويل أكواد الفواكه للصيغة المطلوبة من الباك اند
    final Map<String, dynamic> body = {
      "childLoginId": childLoginId,
      "fruitPasswordCodes": fruitPasswordCodes,
    };

    print('📤 Sending child login request: $body');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        // --- نجاح ---
        final data = responseBody['data'];

        if (data != null && data['token'] != null) {
          final String token = data['token'].toString();
          final String childId = data['childId']?.toString() ?? '';
          final String childName = data['fullName']?.toString() ?? 'يا بطل';
          final int age = data['age'] ?? 0;
          final String gender = data['gender']?.toString() ?? '';
          final String? profileImageUrl = data['profileImageUrl'];
          final String parentId = data['parentId']?.toString() ?? '';
          final String message = data['message']?.toString() ?? 'مرحباً بك! ';

          // حفظ بيانات الطفل
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(_childTokenKey, token);
          await prefs.setString(_childIdKey, childId);
          await prefs.setString(_childNameKey, childName);

          print('✅ Child Login Successful: $childName');

          return ChildLoginResult(
            success: true,
            token: token,
            childId: childId,
            childName: childName,
            age: age,
            gender: gender,
            profileImageUrl: profileImageUrl,
            parentId: parentId,
            message: message,
            errorMessage: null,
            errorType: null,
          );
        } else {
          return ChildLoginResult(
            success: false,
            errorMessage: responseBody['message']?.toString() ??
                'رد غير متوقع من السيرفر',
            errorType: ChildLoginErrorType.unknown,
          );
        }
      } else {
        // --- خطأ ---
        print('❌ Child login failed: ${response.statusCode}');

        String errorMessage = 'حدث خطأ غير معروف';
        ChildLoginErrorType errorType = ChildLoginErrorType.unknown;

        // استخراج رسالة الخطأ
        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          errorMessage = (responseBody['errors'] as List).first.toString();
        } else if (responseBody['message'] != null) {
          errorMessage = responseBody['message'].toString();
        }

        // تحديد نوع الخطأ بناءً على الرسالة
        errorType = _determineErrorType(errorMessage);

        return ChildLoginResult(
          success: false,
          errorMessage: errorMessage,
          errorType: errorType,
        );
      }
    } catch (e) {
      print('❌ Connection Error: $e');
      return ChildLoginResult(
        success: false,
        errorMessage: 'تأكد من الاتصال بالإنترنت',
        errorType: ChildLoginErrorType.connection,
      );
    }
  }

  /// تحديد نوع الخطأ بناءً على رسالة الخطأ
  ChildLoginErrorType _determineErrorType(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();

    // خطأ في الرقم
    if (lowerMessage.contains('معرف') ||
        lowerMessage.contains('رقم') ||
        lowerMessage.contains('login id') ||
        lowerMessage.contains('not found')) {
      return ChildLoginErrorType.invalidId;
    }

    // خطأ في كلمة السر (الفواكه)
    if (lowerMessage.contains('كلمة') ||
        lowerMessage.contains('سر') ||
        lowerMessage.contains('password') ||
        lowerMessage.contains('fruit') ||
        lowerMessage.contains('فواكه')) {
      return ChildLoginErrorType.invalidPassword;
    }

    // خطأ عام في البيانات
    if (lowerMessage.contains('غير صحيح') ||
        lowerMessage.contains('invalid') ||
        lowerMessage.contains('حاول')) {
      return ChildLoginErrorType.invalidCredentials;
    }

    return ChildLoginErrorType.unknown;
  }

  /// الحصول على توكن الطفل
  Future<String?> getChildToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childTokenKey);
  }

  /// الحصول على اسم الطفل المحفوظ
  Future<String?> getChildName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childNameKey);
  }

  /// الحصول على معرف الطفل المحفوظ
  Future<String?> getChildId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childIdKey);
  }

  /// تسجيل خروج الطفل
  Future<void> logoutChild() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_childTokenKey);
    await prefs.remove(_childIdKey);
    await prefs.remove(_childNameKey);
    print('Child logged out, token removed.');
  }

  /// التحقق من وجود جلسة طفل نشطة
  Future<bool> isChildLoggedIn() async {
    final token = await getChildToken();
    return token != null && token.isNotEmpty;
  }
}

// ============================================================
// ==================== Data Models ===========================
// ============================================================

/// نوع خطأ تسجيل دخول الطفل
enum ChildLoginErrorType {
  invalidId, // الرقم غلط أو غير موجود
  invalidPassword, // الفواكه غلط
  invalidCredentials, // بيانات غير صحيحة (عام)
  connection, // مشكلة اتصال
  unknown, // خطأ غير معروف
}

/// نتيجة تسجيل دخول الطفل
class ChildLoginResult {
  final bool success;
  final String? token;
  final String? childId;
  final String? childName;
  final int? age;
  final String? gender;
  final String? profileImageUrl;
  final String? parentId;
  final String? message;
  final String? errorMessage;
  final ChildLoginErrorType? errorType;

  ChildLoginResult({
    required this.success,
    this.token,
    this.childId,
    this.childName,
    this.age,
    this.gender,
    this.profileImageUrl,
    this.parentId,
    this.message,
    this.errorMessage,
    this.errorType,
  });

  @override
  String toString() {
    if (success) {
      return 'ChildLoginResult(success: true, childName: $childName, age: $age)';
    } else {
      return 'ChildLoginResult(success: false, error: $errorMessage, type: $errorType)';
    }
  }
}
