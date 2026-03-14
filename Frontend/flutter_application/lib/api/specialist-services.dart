// --- lib/api/specialist-services.dart ---

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class SpecialistService {
  static const String _apiBaseUrl =
      "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api";

  static const String _specialistTokenKey = 'ajial_specialist_token';
  static const String _specialistIdKey = 'ajial_specialist_id';
  static const String _specialistNameKey = 'ajial_specialist_name';
  static const String _specialistStatusKey = 'ajial_specialist_status';

  // ============================================================
  // ==================== Registration ==========================
  // ============================================================

  /// Registers a new specialist with multipart/form-data.
  /// Uses XFile (from image_picker) for cross-platform web + mobile support.
  /// Returns (success, message).
  Future<(bool, String)> registerSpecialist({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String specialization,
    required String practiceLicenseNumber,
    required XFile idFrontImage,
    required XFile idBackImage,
    required XFile specializationCertificateImage,
    required XFile practiceLicenseImage,
    required XFile unionCardImage,
    required XFile personalPhoto,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/register/specialist';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.headers.addAll({
      'accept': 'text/plain',
    });

    // Text fields
    request.fields['FullName'] = fullName;
    request.fields['Username'] = username;
    request.fields['Email'] = email;
    request.fields['Phone'] = phone;
    request.fields['Password'] = password;
    request.fields['Specialization'] = specialization;
    request.fields['PracticeLicenseNumber'] = practiceLicenseNumber;

    // File fields — using XFile.readAsBytes() for web + mobile compatibility
    request.files.add(await _createMultipartFile('IdFrontImage', idFrontImage));
    request.files.add(await _createMultipartFile('IdBackImage', idBackImage));
    request.files.add(await _createMultipartFile(
        'SpecializationCertificateImage', specializationCertificateImage));
    request.files.add(
        await _createMultipartFile('PracticeLicenseImage', practiceLicenseImage));
    request.files
        .add(await _createMultipartFile('UnionCardImage', unionCardImage));
    request.files
        .add(await _createMultipartFile('PersonalPhoto', personalPhoto));

    try {
      print("📤 Sending Specialist Registration...");
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return (true, 'تم إنشاء الحساب بنجاح! حسابك قيد المراجعة.');
      } else {
        try {
          final responseBody = jsonDecode(response.body);

          if (responseBody['errors'] != null &&
              (responseBody['errors'] as List).isNotEmpty) {
            return (false, (responseBody['errors'] as List).first.toString());
          } else if (responseBody['message'] != null) {
            return (false, responseBody['message'].toString());
          }
          return (
            false,
            'حدث خطأ غير معروف. رمز الحالة: ${response.statusCode}'
          );
        } catch (e) {
          return (false, response.body);
        }
      }
    } catch (e) {
      print("❌ Error registering specialist: $e");
      if (e.toString().contains('TimeoutException')) {
        return (false, 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');
      }
      return (false, 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.');
    }
  }

  /// Helper to create a multipart file from XFile (works on web + mobile).
  Future<http.MultipartFile> _createMultipartFile(
      String fieldName, XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final mimeTypeData = lookupMimeType(xfile.name)?.split('/');
    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: xfile.name,
      contentType: mimeTypeData != null
          ? MediaType(mimeTypeData[0], mimeTypeData[1])
          : null,
    );
  }

  // ============================================================
  // ==================== Login =================================
  // ============================================================

  /// Logs in a specialist and returns a result object.
  Future<SpecialistLoginResult> loginSpecialist({
    required String username,
    required String password,
  }) async {
    final String apiUrl = '$_apiBaseUrl/Auth/login/specialist';

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      "username": username,
      "password": password,
    };

    try {
      print("📤 Sending Specialist Login...");
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print("📥 Response Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];

        if (data != null && data['token'] != null) {
          final String token = data['token'].toString();
          final String specialistId = data['specialistId']?.toString() ?? '';
          final String fullName = data['fullName']?.toString() ?? '';
          final String status = data['status']?.toString() ?? 'Pending';

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_specialistTokenKey, token);
          await prefs.setString(_specialistIdKey, specialistId);
          await prefs.setString(_specialistNameKey, fullName);
          await prefs.setString(_specialistStatusKey, status);

          print('✅ Specialist Login Successful: $fullName ($status)');

          return SpecialistLoginResult(
            success: true,
            token: token,
            specialistId: specialistId,
            fullName: fullName,
            status: status,
            errorMessage: null,
          );
        } else {
          return SpecialistLoginResult(
            success: false,
            errorMessage:
                responseBody['message']?.toString() ?? 'رد غير متوقع من السيرفر',
          );
        }
      } else {
        String errorMessage = 'حدث خطأ غير معروف';

        if (responseBody['errors'] != null &&
            (responseBody['errors'] as List).isNotEmpty) {
          errorMessage = (responseBody['errors'] as List).first.toString();
        } else if (responseBody['message'] != null) {
          errorMessage = responseBody['message'].toString();
        }

        return SpecialistLoginResult(
          success: false,
          errorMessage: errorMessage,
        );
      }
    } catch (e) {
      print("❌ Connection Error: $e");
      if (e.toString().contains('TimeoutException')) {
        return SpecialistLoginResult(
          success: false,
          errorMessage: 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
        );
      }
      return SpecialistLoginResult(
        success: false,
        errorMessage: 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.',
      );
    }
  }

  // ============================================================
  // ==================== Token Helpers =========================
  // ============================================================

  Future<String?> getSpecialistToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_specialistTokenKey);
  }

  Future<String?> getSpecialistName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_specialistNameKey);
  }

  Future<String?> getSpecialistStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_specialistStatusKey);
  }

  Future<void> logoutSpecialist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_specialistTokenKey);
    await prefs.remove(_specialistIdKey);
    await prefs.remove(_specialistNameKey);
    await prefs.remove(_specialistStatusKey);
    print('Specialist logged out, all tokens removed.');
  }
}

/// Result class for specialist login
class SpecialistLoginResult {
  final bool success;
  final String? token;
  final String? specialistId;
  final String? fullName;
  final String? status; // "Pending", "Approved", "Rejected"
  final String? errorMessage;

  SpecialistLoginResult({
    required this.success,
    this.token,
    this.specialistId,
    this.fullName,
    this.status,
    this.errorMessage,
  });
}
