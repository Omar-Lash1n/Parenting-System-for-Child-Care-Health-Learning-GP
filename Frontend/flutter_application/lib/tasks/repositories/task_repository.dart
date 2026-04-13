import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/tasks/models/task_model.dart';

class TaskRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final AuthService _authService = AuthService();

  TaskRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Content-Type': 'application/json'},
            ));

  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  Future<String?> _getParentId() async {
    return await _authService.getSavedParentId();
  }

  /// 2.1 Get All Active Tasks for Parent
  Future<List<TaskModel>> fetchActiveTasks() async {
    final token = await _getToken();
    final parentId = await _getParentId();

    if (token == null || parentId == null) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    try {
      final response = await _dio.get(
        '/Task/parent/$parentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return _parseTasksFromResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleDioError(e);
    }
  }

  /// 2.3 Get Completed Tasks
  Future<List<TaskModel>> fetchCompletedTasks() async {
    final token = await _getToken();
    final parentId = await _getParentId();

    if (token == null || parentId == null) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    try {
      final response = await _dio.get(
        '/Task/parent/$parentId/done',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return _parseTasksFromResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw _handleDioError(e);
    }
  }

  /// 2.2 Get Task Details by ID
  Future<TaskModel> getTaskById(String taskId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('لا يوجد رمز مصادقة.');
    }

    try {
      final response = await _dio.get(
        '/Task/$taskId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        return TaskModel.fromJson(data['data']);
      }
      if (data is Map<String, dynamic> && data.containsKey('id')) {
        return TaskModel.fromJson(data);
      }
      throw Exception('بنية استجابة غير متوقعة للمهمة');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 2.4 Create Task
  Future<TaskModel> createTask({
    required String title,
    String? categoryId,
    required String colorHex,
    DateTime? dueDate,
    required bool includeParent,
    required List<String> childIds,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('لا يوجد رمز مصادقة.');

    try {
      final payload = {
        "title": title,
        if (categoryId != null && !categoryId.startsWith('default_')) "categoryId": categoryId,
        "color": colorHex.startsWith('#') ? colorHex : '#$colorHex',
        "dueDate": dueDate?.toUtc().toIso8601String(),
        "includeParent": includeParent,
        "childIds": childIds,
      };

      final response = await _dio.post(
        '/Task',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        return TaskModel.fromJson(data['data']);
      }
      throw Exception('بنية استجابة غير متوقعة عند إنشاء المهمة');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 2.5 Update Task
  Future<TaskModel> updateTask({
    required String taskId,
    required String title,
    String? categoryId,
    required String colorHex,
    DateTime? dueDate,
    required bool includeParent,
    required List<String> childIds,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('لا يوجد رمز مصادقة.');

    try {
      final payload = {
        "title": title,
        if (categoryId != null && !categoryId.startsWith('default_')) "categoryId": categoryId,
        "color": colorHex.startsWith('#') ? colorHex : '#$colorHex',
        "dueDate": dueDate?.toUtc().toIso8601String(),
        "includeParent": includeParent,
        "childIds": childIds,
      };

      final response = await _dio.put(
        '/Task/$taskId',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        return TaskModel.fromJson(data['data']);
      }
      throw Exception('بنية استجابة غير متوقعة عند التعديل');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 2.6 Toggle Task Completion
  Future<void> toggleTaskCompletion(String taskId) async {
    final token = await _getToken();
    if (token == null) throw Exception('لا يوجد رمز مصادقة.');

    try {
      await _dio.patch(
        '/Task/$taskId/complete',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 2.7 Delete Task
  Future<void> deleteTask(String taskId) async {
    final token = await _getToken();
    if (token == null) throw Exception('لا يوجد رمز مصادقة.');

    try {
      await _dio.delete(
        '/Task/$taskId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Helper Methods ────────────────────────────────────────────────────────

  List<TaskModel> _parseTasksFromResponse(dynamic data) {
    if (data == null) return [];

    List<dynamic> rawList = [];

    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        return [];
      }
      if (data.containsKey('tasks') && data['tasks'] is List) {
        rawList = data['tasks'] as List;
      } else if (data.containsKey('data')) {
        final inner = data['data'];
        if (inner is List) {
          rawList = inner;
        } else if (inner is Map<String, dynamic> &&
            inner.containsKey('tasks') &&
            inner['tasks'] is List) {
          rawList = inner['tasks'] as List;
        }
      }
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((json) => TaskModel.fromJson(json))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      print('❌ Dio Error Response: [${e.response?.statusCode}] ${e.response?.data}');
    } else {
      print('❌ Dio Error: ${e.message}');
    }

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
        final msg = e.response?.data?['message'] ?? 'خطأ من الخادم ($statusCode)';
        return Exception(msg.toString());
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
