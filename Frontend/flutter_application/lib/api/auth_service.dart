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
  static const String _parentIdKey = 'ajial_parent_id'; // ← added
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

  /// جلب قائمة المدن من السيرفر
  /// GET /api/Cities
  Future<List<Map<String, dynamic>>> fetchCities() async {
    final String apiUrl = '$_apiBaseUrl/Cities';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return List<Map<String, dynamic>>.from(responseBody['data']);
        }
      }
      print('Fetch Cities Error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Connection Error in fetchCities: $e');
      return [];
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

          // Save parentId from login response so fetchCategories() can use it
          // without needing to decode the JWT claim.
          final rawId = responseBody['data']['parentId']
              ?? responseBody['data']['ParentId']
              ?? responseBody['data']['id']
              ?? responseBody['data']['userId'];
          if (rawId != null) {
            await prefs.setString(_parentIdKey, rawId.toString());
            print('Login: parentId saved: $rawId');
          } else {
            print('Login: no parentId field found in response data — will derive from JWT.');
          }

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
    await prefs.remove(_parentIdKey); // ← also clear parentId
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

  /// الحصول على معرف الوالد المحفوظ من استجابة تسجيل الدخول.
  Future<String?> getSavedParentId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentIdKey);
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

  /// دالة إنشاء حساب لطفل موجود (Create Account for existing child)
  ///
  /// POST /api/Child/{childId}/create-account
  Future<(bool success, String message)> createChildAccount({
    required String childId,
    required String childLoginId,
    required List<String> fruitPasswordCodes,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Child/$childId/create-account';
    final String? token = await getToken();

    if (token == null) {
      return (false, "غير مصرح. يرجى تسجيل الدخول أولاً.");
    }

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      "childLoginId": childLoginId,
      "fruitPasswordCodes": fruitPasswordCodes,
    };

    try {
      print("📤 Sending Create Child Account Request to $apiUrl...");
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print("📥 Clean Response Code: ${response.statusCode}");
      print("📥 Clean Response Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['message'] ?? "تم إنشاء حساب الطفل بنجاح").toString()
        );
      } else {
        // Handle errors
        String errorMsg = "فشل إنشاء الحساب";
        final errors = responseBody['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          errorMsg = errors.first.toString();
        } else if (responseBody['message'] != null) {
          errorMsg = responseBody['message'].toString();
        }
        return (false, errorMsg);
      }
    } catch (e) {
      print("❌ Error creating child account: $e");
      return (false, "تأكد من الاتصال بالإنترنت. يرجى المحاولة مرة أخرى.");
    }
  }

  /// دالة تغيير رقم كود تسجيل الدخول للطفل
  ///
  /// PUT /api/Parents/child/{childId}/account/login-id
  Future<(bool success, String message)> updateChildLoginId({
    required String childId,
    required String newChildLoginId,
  }) async {
    final String apiUrl =
        '$_apiBaseUrl/Parents/child/$childId/account/login-id';
    return _sendChildAccountUpdate(
      apiUrl: apiUrl,
      body: {"newChildLoginId": newChildLoginId},
      successDefaultMsg: "تم تغيير كود الطفل بنجاح",
    );
  }

  /// دالة تغيير كلمة مرور الفواكه للطفل
  ///
  /// PUT /api/Parents/child/{childId}/account/password
  Future<(bool success, String message)> updateChildPassword({
    required String childId,
    required List<String> oldFruitPasswordCodes,
    required List<String> newFruitPasswordCodes,
    required List<String> confirmFruitPasswordCodes,
  }) async {
    final String apiUrl =
        '$_apiBaseUrl/Parents/child/$childId/account/password';
    return _sendChildAccountUpdate(
      apiUrl: apiUrl,
      body: {
        "oldFruitPasswordCodes": oldFruitPasswordCodes,
        "newFruitPasswordCodes": newFruitPasswordCodes,
        "confirmFruitPasswordCodes": confirmFruitPasswordCodes,
      },
      successDefaultMsg: "تم تغيير كلمة المرور بنجاح",
    );
  }

  /// دالة تفعيل/إيقاف حساب الطفل
  ///
  /// PUT /api/Parents/child/{childId}/account/toggle
  Future<(bool success, String message)> toggleChildAccount({
    required String childId,
    required bool isActive,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Parents/child/$childId/account/toggle';
    return _sendChildAccountUpdate(
      apiUrl: apiUrl,
      body: {"isActive": isActive},
      successDefaultMsg:
          isActive ? "تم تفعيل الحساب بنجاح" : "تم إيقاف الحساب بنجاح",
    );
  }

  /// Helper function for PUT account update requests
  Future<(bool success, String message)> _sendChildAccountUpdate({
    required String apiUrl,
    required Map<String, dynamic> body,
    required String successDefaultMsg,
  }) async {
    final String? token = await getToken();

    if (token == null) {
      return (false, "غير مصرح. يرجى تسجيل الدخول أولاً.");
    }

    final Map<String, String> headers = {
      'accept': 'text/plain',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print("📤 Sending PUT Request to $apiUrl...");
      final response = await http
          .put(
            Uri.parse(apiUrl),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print("📥 Clean Response Code: ${response.statusCode}");
      print("📥 Clean Response Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['message'] ?? successDefaultMsg).toString()
        );
      } else {
        // Handle errors
        String errorMsg = "فشل التحديث";
        final errors = responseBody['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          errorMsg = errors.first.toString();
        } else if (responseBody['message'] != null) {
          errorMsg = responseBody['message'].toString();
        }
        return (false, errorMsg);
      }
    } catch (e) {
      print("❌ Error in _sendChildAccountUpdate: $e");
      return (false, "تأكد من الاتصال بالإنترنت. يرجى المحاولة مرة أخرى.");
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

  // ============================================================
  // ==================== Parent Profile API ====================
  // ============================================================

  /// جلب بيانات الملف الشخصي للوالد
  /// GET /Parents/profile
  Future<Map<String, dynamic>?> getParentProfile() async {
    final String apiUrl = '$_apiBaseUrl/Parents/profile';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }
      print('Get Profile Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in getParentProfile: $e');
      return null;
    }
  }

  /// تحديث بيانات الملف الشخصي
  /// PUT /Parents/profile
  Future<(bool, String)> updateParentProfile({
    String? fullName,
    String? username,
    String? email,
    int? cityId,
    String? dateOfBirth,
    int? role,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Parents/profile';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.');
    }

    final Map<String, dynamic> body = {};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (cityId != null) body['cityId'] = cityId;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (role != null) body['role'] = role;

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['message'] ?? 'تم التحديث بنجاح').toString()
        );
      } else {
        final errorMsg = responseBody['message'] ??
            (responseBody['errors'] as List?)?.first ??
            'حدث خطأ في التحديث';
        return (false, errorMsg.toString());
      }
    } catch (e) {
      print('Connection Error in updateParentProfile: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// تغيير كلمة المرور
  /// PUT /Parents/change-password
  Future<(bool, String)> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Parents/change-password';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.');
    }

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['data']?['message'] ?? 'تم تغيير كلمة المرور بنجاح')
              .toString()
        );
      } else {
        final errorMsg = responseBody['message'] ??
            (responseBody['errors'] as List?)?.first ??
            'حدث خطأ في تغيير كلمة المرور';
        return (false, errorMsg.toString());
      }
    } catch (e) {
      print('Connection Error in changePassword: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// رفع صورة الملف الشخصي
  /// POST /Parents/profile/image
  /// Works on both Web and Mobile platforms
  Future<(bool, String, String?)> uploadProfileImage(
    List<int> imageBytes,
    String fileName,
  ) async {
    final String apiUrl = '$_apiBaseUrl/Parents/profile/image';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.', null);
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': 'text/plain',
      });

      // Determine MIME type from file extension
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');

      // Use fromBytes instead of fromPath for web compatibility
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final imageUrl = responseBody['data']?['profileImageUrl']?.toString();
        return (true, 'تم رفع الصورة بنجاح', imageUrl);
      } else {
        final errorMsg = responseBody['message'] ?? 'حدث خطأ في رفع الصورة';
        return (false, errorMsg.toString(), null);
      }
    } catch (e) {
      print('Connection Error in uploadProfileImage: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.', null);
    }
  }

  /// رفع صورة الطفل
  /// POST /Parents/child/{childId}/profile-image
  Future<(bool, String, String?)> uploadChildProfileImage(
    String childId,
    List<int> imageBytes,
    String fileName,
  ) async {
    final String apiUrl = '$_apiBaseUrl/Parents/child/$childId/profile-image';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.', null);
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'accept': 'text/plain',
      });

      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final imageUrl = responseBody['data']?['profileImageUrl']?.toString();
        return (true, 'تم رفع صورة الطفل بنجاح', imageUrl);
      } else {
        final errorMsg = responseBody['message'] ?? 'حدث خطأ في رفع الصورة';
        return (false, errorMsg.toString(), null);
      }
    } catch (e) {
      print('Connection Error in uploadChildProfileImage: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.', null);
    }
  }

  /// إرسال إيميل التحقق
  /// POST /Parents/send-verification-email
  Future<(bool, String)> sendVerificationEmail() async {
    final String apiUrl = '$_apiBaseUrl/Parents/send-verification-email';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.');
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'text/plain',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['data']?['message'] ?? 'تم إرسال رابط التحقق بنجاح')
              .toString()
        );
      } else {
        final errorMsg =
            responseBody['message'] ?? 'حدث خطأ في إرسال رابط التحقق';
        return (false, errorMsg.toString());
      }
    } catch (e) {
      print('Connection Error in sendVerificationEmail: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  // ============================================================
  // ==================== Cities API ============================
  // ============================================================

  /// جلب قائمة المدن
  /// GET /Cities
  Future<List<City>> getCities() async {
    final String apiUrl = '$_apiBaseUrl/Cities';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          final List<dynamic> citiesData = responseBody['data'];
          return citiesData.map((json) => City.fromJson(json)).toList();
        }
      }
      print('Get Cities Error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Connection Error in getCities: $e');
      return [];
    }
  }

  /// Delete parent account with confirmation text
  Future<(bool, String)> deleteAccount(String confirmationText) async {
    final String apiUrl = '$_apiBaseUrl/Parents/account';
    final token = await getToken();

    if (token == null) {
      return (false, 'يرجى تسجيل الدخول أولاً');
    }

    try {
      final request = http.Request('DELETE', Uri.parse(apiUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'accept': 'application/json',
      });
      request.body = jsonEncode({'confirmationText': confirmationText});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          // Clear stored token after successful deletion
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          return (
            true,
            (responseBody['message'] ?? 'تم حذف الحساب بنجاح').toString()
          );
        }
        return (
          false,
          (responseBody['message'] ?? 'فشل حذف الحساب').toString()
        );
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        return (
          false,
          (responseBody['message'] ?? 'نص التأكيد غير صحيح').toString()
        );
      } else if (response.statusCode == 401) {
        return (false, 'جلسة منتهية، يرجى تسجيل الدخول مرة أخرى');
      }
      return (false, 'حدث خطأ، يرجى المحاولة لاحقاً');
    } catch (e) {
      print('Delete Account Error: $e');
      return (false, 'خطأ في الاتصال');
    }
  }

  // ============================================================
  // ==================== Voice Notes API =======================
  // ============================================================

  /// رفع تسجيل صوتي للطفل (باستخدام File - للموبايل فقط)
  /// POST /api/Child/voice-note
  /// Requires child JWT token
  Future<UploadVoiceNoteResult> uploadVoiceNote({
    required File audioFile,
    String? title,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Child/voice-note';
    final String? childToken = await getChildToken();

    if (childToken == null) {
      return UploadVoiceNoteResult(
        success: false,
        message: 'يجب تسجيل الدخول أولاً',
      );
    }

    try {
      // إنشاء طلب Multipart
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // إضافة الهيدرز
      request.headers.addAll({
        'Authorization': 'Bearer $childToken',
        'accept': 'application/json',
      });

      // إضافة ملف الصوت
      final mimeTypeData = lookupMimeType(audioFile.path)?.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'VoiceNote',
        audioFile.path,
        contentType: mimeTypeData != null
            ? MediaType(mimeTypeData[0], mimeTypeData[1])
            : MediaType('audio', 'm4a'),
      ));

      // إضافة العنوان (اختياري)
      if (title != null && title.isNotEmpty && title.length <= 100) {
        request.fields['Title'] = title;
      }

      print('📤 Uploading voice note...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        return UploadVoiceNoteResult(
          success: true,
          message: responseBody['message'] ?? 'تم رفع الملاحظة الصوتية بنجاح',
          voiceNote: data != null ? VoiceNote.fromJson(data) : null,
        );
      } else {
        // التعامل مع الأخطاء
        String errorMessage = 'حدث خطأ غير معروف';

        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          errorMessage = (responseBody['errors'] as List).first.toString();
        } else if (responseBody['message'] != null) {
          errorMessage = responseBody['message'].toString();
        }

        return UploadVoiceNoteResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      print('❌ Error uploading voice note: $e');
      return UploadVoiceNoteResult(
        success: false,
        message: 'تأكد من الاتصال بالإنترنت',
      );
    }
  }

  /// رفع تسجيل صوتي باستخدام Bytes (يعمل على Web و Mobile)
  /// POST /api/Child/voice-note
  /// Requires child JWT token
  Future<UploadVoiceNoteResult> uploadVoiceNoteFromBytes({
    required List<int> audioBytes,
    required String fileName,
    String? title,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Child/voice-note';
    final String? childToken = await getChildToken();

    if (childToken == null) {
      return UploadVoiceNoteResult(
        success: false,
        message: 'يجب تسجيل الدخول أولاً',
      );
    }

    try {
      // إنشاء طلب Multipart
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // إضافة الهيدرز
      request.headers.addAll({
        'Authorization': 'Bearer $childToken',
        'accept': 'application/json',
      });

      // تحديد نوع الملف
      final mimeType = lookupMimeType(fileName) ?? 'audio/m4a';
      final mimeSplit = mimeType.split('/');

      // إضافة ملف الصوت من Bytes
      request.files.add(http.MultipartFile.fromBytes(
        'VoiceNote',
        audioBytes,
        filename: fileName,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));

      // إضافة العنوان (اختياري)
      if (title != null && title.isNotEmpty && title.length <= 100) {
        request.fields['Title'] = title;
      }

      print(
          '📤 Uploading voice note from bytes (${audioBytes.length} bytes)...');

      print(
          '📤 Uploading voice note from bytes (${audioBytes.length} bytes)...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        return UploadVoiceNoteResult(
          success: true,
          message: responseBody['message'] ?? 'تم رفع الملاحظة الصوتية بنجاح',
          voiceNote: data != null ? VoiceNote.fromJson(data) : null,
        );
      } else {
        // التعامل مع الأخطاء
        String errorMessage = 'حدث خطأ غير معروف';

        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          errorMessage = (responseBody['errors'] as List).first.toString();
        } else if (responseBody['message'] != null) {
          errorMessage = responseBody['message'].toString();
        }

        return UploadVoiceNoteResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      print('❌ Error uploading voice note from bytes: $e');
      return UploadVoiceNoteResult(
        success: false,
        message: 'تأكد من الاتصال بالإنترنت',
      );
    }
  }

  /// جلب جميع التسجيلات الصوتية للطفل
  /// GET /api/Child/voice-notes
  /// Requires child JWT token
  Future<(bool success, String message, List<VoiceNote> voiceNotes)>
      getVoiceNotes() async {
    final String apiUrl = '$_apiBaseUrl/Child/voice-notes';
    final String? childToken = await getChildToken();

    if (childToken == null) {
      return (false, 'يجب تسجيل الدخول أولاً', <VoiceNote>[]);
    }

    try {
      print('📤 Fetching voice notes...');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $childToken',
          'accept': 'application/json',
        },
      );

      print('📥 Get Voice Notes Response: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'] ?? [];
        final List<VoiceNote> voiceNotes =
            data.map((e) => VoiceNote.fromJson(e)).toList();

        final String successMessage =
            (responseBody['message'] ?? 'تم جلب الملاحظات الصوتية بنجاح')
                .toString();
        return (
          true,
          successMessage,
          voiceNotes,
        );
      } else {
        String errorMessage =
            responseBody['message'] ?? 'حدث خطأ في جلب التسجيلات';
        return (false, errorMessage, <VoiceNote>[]);
      }
    } catch (e) {
      print('❌ Error fetching voice notes: $e');
      return (false, 'تأكد من الاتصال بالإنترنت', <VoiceNote>[]);
    }
  }

  // ============================================================
  // ==================== Vaccination API =======================
  // ============================================================

  /// جلب بيانات صفحة ترحيب التطعيمات للطفل
  /// GET /api/Vaccination/welcome/{childId}
  /// Requires parent JWT token
  Future<Map<String, dynamic>?> getVaccinationWelcome(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/welcome/$childId';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }
      print(
          'Get Vaccination Welcome Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in getVaccinationWelcome: $e');
      return null;
    }
  }

  /// جلب ملف التطعيمات الكامل للطفل
  /// GET /api/Vaccination/file/{childId}
  /// Requires parent JWT token.
  ///
  /// Returns a record: (data, statusCode, errorMessage)
  /// - data != null  → success
  /// - statusCode == 400 → survey not completed, redirect to survey
  /// - statusCode == 401 → unauthorized
  /// - statusCode == 404 → child not found
  Future<(Map<String, dynamic>? data, int statusCode, String? errorMessage)>
      getVaccinationFile(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/file/$childId';
    final String? token = await getToken();

    if (token == null) {
      return (null, 401, 'غير مصرح. يرجى تسجيل الدخول أولاً.');
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return (
            responseBody['data'] as Map<String, dynamic>,
            200,
            null,
          );
        }
        final msg =
            responseBody['message']?.toString() ?? 'حدث خطأ غير معروف';
        return (null, 200, msg);
      }

      // Parse error message from body if available
      String? errorMsg;
      try {
        final body = jsonDecode(response.body);
        errorMsg = body['message']?.toString();
      } catch (_) {}

      print(
          'getVaccinationFile Error: ${response.statusCode} - ${response.body}');
      return (null, response.statusCode, errorMsg);
    } catch (e) {
      print('Connection Error in getVaccinationFile: $e');
      return (null, 0, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// تغيير حالة التطعيم (تم / لم يتم)
  /// POST /api/Vaccination/file/toggle
  /// Requires parent JWT token.
  Future<(bool success, String message)> toggleVaccination({
    required String childId,
    required int milestoneId,
    required bool isTaken,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/file/toggle';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.');
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'childId': childId,
          'milestoneId': milestoneId,
          'isTaken': isTaken,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['message'] ?? "تم تحديث حالة التطعيم بنجاح").toString()
        );
      } else {
        String errorMsg = "فشل تحديث حالة التطعيم";
        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          errorMsg = (responseBody['errors'] as List).first.toString();
        } else if (responseBody['message'] != null) {
          errorMsg = responseBody['message'].toString();
        }
        return (false, errorMsg);
      }
    } catch (e) {
      print('Connection Error in toggleVaccination: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// جلب بيانات استبيان التطعيمات للطفل
  /// GET /api/Vaccination/survey/{childId}
  /// Requires parent JWT token
  Future<Map<String, dynamic>?> getVaccinationSurvey(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/survey/$childId';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }
      print(
          'Get Vaccination Survey Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in getVaccinationSurvey: $e');
      return null;
    }
  }

  /// إرسال اختيارات استبيان التطعيمات
  /// POST /api/Vaccination/survey
  /// Requires parent JWT token
  ///
  /// [childId] — the child's UUID
  /// [selections] — list of {milestoneId: int, isTaken: bool}
  Future<Map<String, dynamic>?> submitVaccinationSurvey({
    required String childId,
    required List<Map<String, dynamic>> selections,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/survey';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final body = jsonEncode({
        'childId': childId,
        'selections': selections,
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print('Vaccination Survey submitted successfully');
          return responseBody['data'] as Map<String, dynamic>?;
        }
      }
      print(
          'Submit Vaccination Survey Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in submitVaccinationSurvey: $e');
      return null;
    }
  }

  /// جلب بيانات استبيان التطعيمات الإضافية للطفل
  /// GET /api/Vaccination/additional-survey/{childId}
  /// Requires parent JWT token
  Future<Map<String, dynamic>?> getAdditionalSurvey(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/additional-survey/$childId';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }
      print(
          'Get Additional Survey Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in getAdditionalSurvey: $e');
      return null;
    }
  }

  /// إرسال اختيارات استبيان التطعيمات الإضافية
  /// POST /api/Vaccination/additional-survey
  /// Requires parent JWT token
  Future<Map<String, dynamic>?> submitAdditionalSurvey({
    required String childId,
    required List<Map<String, dynamic>> selections,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Vaccination/additional-survey';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final body = jsonEncode({
        'childId': childId,
        'selections': selections,
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          print('Additional Survey submitted successfully');
          return responseBody['data'] as Map<String, dynamic>?;
        }
      }
      print(
          'Submit Additional Survey Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in submitAdditionalSurvey: $e');
      return null;
    }
  }

  // ============================================================
  // ============== Medical File API =============================
  // ============================================================

  /// GET /api/Child/{childId}/medical-file
  /// Generates the child's unified medical file (PDF) and returns the download URL.
  Future<(bool success, String urlOrError)> getMedicalFileUrl(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Child/$childId/medical-file';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.');
    }

    try {
      print('📤 Fetching medical file for child $childId...');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 Medical File Response Code: ${response.statusCode}');
      print('📥 Medical File Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        final String? fileUrl = data?['fileUrl']?.toString();

        if (fileUrl != null && fileUrl.isNotEmpty) {
          return (true, fileUrl);
        }
        return (false, 'لم يتم إنشاء الملف الطبي بعد');
      }

      // Parse error message
      String errorMsg = 'فشل في توليد الملف الطبي';
      final errors = responseBody['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        errorMsg = errors.first.toString();
      } else if (responseBody['message'] != null) {
        errorMsg = responseBody['message'].toString();
      }
      return (false, errorMsg);
    } catch (e) {
      print('❌ Error fetching medical file: $e');
      return (false, 'تأكد من الاتصال بالإنترنت. يرجى المحاولة مرة أخرى.');
    }
  }

  // ============================================================
  // ============== Child Profile API Methods ====================
  // ============================================================

  /// GET /api/Parents/child/{childId}/profile-summary
  /// Returns the child's basic profile data for the summary screen.
  Future<Map<String, dynamic>?> getChildProfileSummary(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Parents/child/$childId/profile-summary';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }

      // Parse error
      try {
        final responseBody = jsonDecode(response.body);
        final errors = responseBody['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          print('getChildProfileSummary Error: ${errors.first}');
        }
      } catch (_) {}

      print(
          'getChildProfileSummary Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in getChildProfileSummary: $e');
      return null;
    }
  }

  /// GET /api/Parents/child/{childId}/file-data
  /// Returns the child's detailed file data (medical, personal info).
  Future<Map<String, dynamic>?> getChildFileData(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Parents/child/$childId/file-data';
    final String? token = await getToken();

    if (token == null) {
      print('Error: No token found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }

      try {
        final responseBody = jsonDecode(response.body);
        final errors = responseBody['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          print('getChildFileData Error: ${errors.first}');
        }
      } catch (_) {}

      print(
          'getChildFileData Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Connection Error in getChildFileData: $e');
      return null;
    }
  }

  /// PUT /api/Parents/child/{childId}/medical-data
  /// Updates the child's medical/personal data. Send only changed fields.
  /// Returns (success, message, responseData).
  Future<(bool, String, Map<String, dynamic>?)> updateChildMedicalData(
      String childId, Map<String, dynamic> body) async {
    final String apiUrl = '$_apiBaseUrl/Parents/child/$childId/medical-data';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'غير مصرح. يرجى تسجيل الدخول أولاً.', null);
    }

    if (body.isEmpty) {
      return (false, 'لا توجد بيانات للتحديث', null);
    }

    try {
      final response = await http
          .put(
            Uri.parse(apiUrl),
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['message'] ?? 'تم تحديث البيانات بنجاح').toString(),
          responseBody['data'] as Map<String, dynamic>?,
        );
      } else {
        // Extract error message
        String errorMsg;
        final errors = responseBody['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          errorMsg = errors.first.toString();
        } else {
          errorMsg =
              (responseBody['message'] ?? 'حدث خطأ في التحديث').toString();
        }
        return (false, errorMsg, null);
      }
    } catch (e) {
      print('Connection Error in updateChildMedicalData: $e');
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.', null);
    }
  }

  /// DELETE /api/Parents/child/{childId}
  /// Permanently deletes the child and all related data.
  Future<(bool, String)> deleteChild(String childId) async {
    final String apiUrl = '$_apiBaseUrl/Parents/child/$childId';
    final String? token = await getToken();

    if (token == null) {
      return (false, 'يرجى تسجيل الدخول أولاً');
    }

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return (
          true,
          (responseBody['message'] ?? 'تم حذف ملف الطفل بنجاح').toString(),
        );
      } else if (response.statusCode == 401) {
        return (false, 'جلسة منتهية، يرجى تسجيل الدخول مرة أخرى');
      } else {
        final errors = responseBody['errors'] as List?;
        final errorMsg = (errors != null && errors.isNotEmpty)
            ? errors.first.toString()
            : (responseBody['message'] ?? 'فشل حذف ملف الطفل').toString();
        return (false, errorMsg);
      }
    } catch (e) {
      print('Delete Child Error: $e');
      return (false, 'خطأ في الاتصال');
    }
  }

  // ============================================================
  // ==================== Health Unit API =======================
  // ============================================================

  /// البحث عن الوحدات الصحية
  /// GET /api/HealthUnit/search
  Future<Map<String, dynamic>?> searchHealthUnits({
    double? latitude,
    double? longitude,
    String? keyword,
    String? type,
    int? cityId,
    double radiusKm = 50,
    int page = 1,
    int pageSize = 20,
  }) async {
    final String? token = await getToken();
    if (token == null) {
      print('❌ No token found for searchHealthUnits');
      return null;
    }

    final Map<String, String> queryParams = {
      'radiusKm': radiusKm.toString(),
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (cityId != null) queryParams['cityId'] = cityId.toString();

    final uri = Uri.parse('$_apiBaseUrl/HealthUnit/search')
        .replace(queryParameters: queryParams);

    print('📤 searchHealthUnits: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 searchHealthUnits status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true) {
          return responseBody;
        }
      }

      print('❌ searchHealthUnits error: ${response.body}');
      return null;
    } catch (e) {
      print('❌ searchHealthUnits exception: $e');
      return null;
    }
  }

  /// جلب تفاصيل وحدة صحية
  /// GET /api/HealthUnit/{id}
  Future<Map<String, dynamic>?> getHealthUnitDetail(
    int id, {
    double? latitude,
    double? longitude,
  }) async {
    final String? token = await getToken();
    if (token == null) {
      print('❌ No token found for getHealthUnitDetail');
      return null;
    }

    final Map<String, String> queryParams = {};
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();

    final uri = Uri.parse('$_apiBaseUrl/HealthUnit/$id')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    print('📤 getHealthUnitDetail: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 getHealthUnitDetail status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'] as Map<String, dynamic>;
        }
      }

      print('❌ getHealthUnitDetail error: ${response.body}');
      return null;
    } catch (e) {
      print('❌ getHealthUnitDetail exception: $e');
      return null;
    }
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

/// نموذج المدينة
class City {
  final int id;
  final String name;
  final String nameAr;

  City({
    required this.id,
    required this.name,
    required this.nameAr,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
    );
  }

  @override
  String toString() => 'City(id: $id, name: $name, nameAr: $nameAr)';
}

/// نموذج الملاحظة الصوتية
class VoiceNote {
  final String voiceNoteId;
  final String title;
  final String blobUrl;
  final int? fileSizeBytes;
  final DateTime createdAt;

  VoiceNote({
    required this.voiceNoteId,
    required this.title,
    required this.blobUrl,
    this.fileSizeBytes,
    required this.createdAt,
  });

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      voiceNoteId: json['voiceNoteId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'تسجيل صوتي',
      blobUrl: json['blobUrl']?.toString() ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voiceNoteId': voiceNoteId,
      'title': title,
      'blobUrl': blobUrl,
      'fileSizeBytes': fileSizeBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'VoiceNote(id: $voiceNoteId, title: $title)';
}

/// نتيجة رفع الملاحظة الصوتية
class UploadVoiceNoteResult {
  final bool success;
  final String message;
  final VoiceNote? voiceNote;

  UploadVoiceNoteResult({
    required this.success,
    required this.message,
    this.voiceNote,
  });

  @override
  String toString() =>
      'UploadVoiceNoteResult(success: $success, message: $message)';
}
