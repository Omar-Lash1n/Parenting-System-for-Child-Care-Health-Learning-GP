// lib/family/repositories/parent_repository.dart
//
// Repository responsible for all Parent-related API calls.
// Uses `dio` for networking and `SharedPreferences` for token retrieval,
// consistent with the rest of the Ajial project's auth conventions.

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_model.dart';
import '../models/children_response_model.dart';

/// [ParentRepository] — Data layer for parent-scoped endpoints.
///
/// Instantiate once and inject via Provider or pass directly.
class ParentRepository {
  // ── Constants ───────────────────────────────────────────────────────────
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  /// SharedPreferences key used by [AuthService] for the parent JWT token.
  static const String _parentTokenKey = 'ajial_auth_token';

  // ── Dio instance ────────────────────────────────────────────────────────
  final Dio _dio;

  ParentRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Retrieves the stored parent JWT token from [SharedPreferences].
  /// Returns `null` if no token is found (not logged in).
  Future<String?> _getParentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentTokenKey);
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Fetches the list of children belonging to the authenticated parent.
  ///
  /// **Endpoint:** `GET /Parents/children`
  ///
  /// **Headers:** `Authorization: Bearer <Parent_JWT_Token>`
  ///
  /// Returns a [List<ChildModel>] on success.
  /// Throws a descriptive [Exception] on any failure (auth, network, parse).
  Future<List<ChildModel>> fetchChildren() async {
    final token = await _getParentToken();

    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    try {
      final response = await _dio.get(
        '/Parents/children',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Parse the response using [ChildrenResponseModel]
      final apiResponse = ChildrenResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message);
      }

      return apiResponse.data!.children;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Error Handling ────────────────────────────────────────────────────────

  /// Converts a [DioException] into a human-readable Arabic exception.
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.');
      case DioExceptionType.connectionError:
        return Exception('تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.');
        }
        final msg =
            e.response?.data?['message'] ?? 'خطأ من الخادم ($statusCode)';
        return Exception(msg.toString());
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
