// lib/tasks/repositories/child_task_repository.dart
//
// Repository for all ChildTask API endpoints.

import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/tasks/models/child_task_model.dart';
import 'package:Ajial/tasks/models/task_list_model.dart';

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

  Future<Options> _opts() async {
    final token = await _getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/ChildTask/parent/{parentId}/children
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<ChildTaskModel>> fetchChildren() async {
    final parentId = await _getParentId();
    if (parentId == null) throw Exception('لا يوجد معرف الوالد');
    try {
      final res = await _dio.get(
        '/ChildTask/parent/$parentId/children',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
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

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/ChildTask/parent/{parentId}/summary
  // ──────────────────────────────────────────────────────────────────────────
  Future<ParentTaskSummary?> fetchSummary() async {
    final parentId = await _getParentId();
    if (parentId == null) return null;
    try {
      final res = await _dio.get(
        '/ChildTask/parent/$parentId/summary',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) return null;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ParentTaskSummary.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      return null; // summary is optional — never throw
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/ChildTask/child/{childId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<ChildTasksResponse> fetchChildTasks(String childId) async {
    try {
      final res = await _dio.get(
        '/ChildTask/child/$childId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return ChildTasksResponse.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/ChildTask/{taskId}/child/{childId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<TaskDetail> fetchTaskDetail(String taskId, String childId) async {
    try {
      final res = await _dio.get(
        '/ChildTask/$taskId/child/$childId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return TaskDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PATCH /api/ChildTask/{taskId}/child/{childId}/complete
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> toggleTaskComplete(String taskId, String childId) async {
    try {
      final res = await _dio.patch(
        '/ChildTask/$taskId/child/$childId/complete',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE /api/ChildTask/{taskId}/child/{childId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> deleteTask(String taskId, String childId) async {
    try {
      final res = await _dio.delete(
        '/ChildTask/$taskId/child/$childId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PUT /api/ChildTask/{taskId}/child/{childId}   (multipart)
  // ──────────────────────────────────────────────────────────────────────────
  Future<TaskDetail> updateTask(
      String taskId, String childId, FormData formData) async {
    try {
      final res = await _dio.put(
        '/ChildTask/$taskId/child/$childId',
        data: formData,
        options: (await _opts()).copyWith(
          headers: {
            ...(await _opts()).headers ?? {},
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return TaskDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.');
      case DioExceptionType.connectionError:
        return Exception('تعذّر الاتصال بالخادم.');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401) {
          return Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.');
        }
        final msg = e.response?.data?['message'] ?? 'خطأ من الخادم ($status)';
        return Exception(msg.toString());
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
