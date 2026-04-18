// lib/tasks/repositories/child_task_repository.dart
//
// Repository for:
//   GET /api/ChildTask/parent/{parentId}/children

import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/tasks/models/child_task_model.dart';

class ChildTaskRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final AuthService _authService = AuthService();

  ChildTaskRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            ));

  Future<String?> _getToken() => _authService.getToken();
  Future<String?> _getParentId() => _authService.getSavedParentId();

  /// Returns the children list for the authenticated parent.
  Future<List<ChildTaskModel>> fetchChildren() async {
    final token = await _getToken();
    final parentId = await _getParentId();

    if (token == null || parentId == null) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    try {
      final response = await _dio.get(
        '/ChildTask/parent/$parentId/children',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data as Map<String, dynamic>;

      // Handle explicit failure
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }

      final data = body['data'] as Map<String, dynamic>?;
      final rawList = data?['children'] as List<dynamic>? ?? [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(ChildTaskModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleDioError(e);
    }
  }

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
