// lib/family/repositories/auth_repository.dart
//
// Repository for authentication-related calls needed by the Family page,
// specifically child logout. Uses `dio` and `SharedPreferences`.

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AuthRepository] — Auth-scoped API calls for the Family page.
///
/// Currently exposes child logout. Can grow to cover parent logout, token
/// refresh, etc. as the project evolves.
class AuthRepository {
  // ── Constants ────────────────────────────────────────────────────────────
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  /// Keys used by [AuthService] — must match exactly for token sharing.
  static const String _childTokenKey = 'ajial_child_token';
  static const String _childIdKey = 'ajial_child_id';
  static const String _childNameKey = 'ajial_child_name';

  // ── Dio instance ─────────────────────────────────────────────────────────
  final Dio _dio;

  AuthRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the stored child JWT token, or `null` if no child is logged in.
  Future<String?> getChildToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childTokenKey);
  }

  /// Clears all child-related data from [SharedPreferences].
  Future<void> _clearChildSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_childTokenKey);
    await prefs.remove(_childIdKey);
    await prefs.remove(_childNameKey);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Logs a child out via the API, then clears local session data.
  ///
  /// **Endpoint:** `POST /Auth/logout/child`
  ///
  /// **Headers:** `Authorization: Bearer <Child_JWT_Token>`
  ///
  /// - Returns `true` if the API call succeeded (HTTP 200 + success:true).
  /// - Local child tokens are cleared regardless of the API result to ensure
  ///   the UI never shows a stale logged-in state.
  /// - Throws an [Exception] only on network-level failures.
  Future<bool> logoutChild() async {
    final childToken = await getChildToken();

    // If there is no child token, the child is already considered logged out.
    if (childToken == null || childToken.isEmpty) {
      return true;
    }

    try {
      final response = await _dio.post(
        '/Auth/logout/child',
        options: Options(
          headers: {'Authorization': 'Bearer $childToken'},
        ),
      );

      final bool success = response.data?['success'] == true;

      // Always clear local session data after a logout attempt.
      await _clearChildSession();

      return success;
    } on DioException catch (e) {
      // Even on API failure, clear local tokens so the UI stays consistent.
      await _clearChildSession();
      throw _handleDioError(e);
    }
  }

  // ── Error Handling ────────────────────────────────────────────────────────

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
        final msg =
            e.response?.data?['message'] ?? 'خطأ من الخادم ($statusCode)';
        return Exception(msg.toString());
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
