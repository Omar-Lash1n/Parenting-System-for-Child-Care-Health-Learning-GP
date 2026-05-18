// lib/child-app/tasks/child_home_task_repository.dart
//
// Repository for the Child Home task endpoints.
// Uses the child's own auth token (not the parent token).
//
//   GET   /api/ChildHome/tasks              → all tasks for the logged-in child
//   GET   /api/ChildHome/tasks/{taskId}     → single task detail
//   PATCH /api/ChildHome/tasks/{taskId}/complete → mark task completed

import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';

// ─── Response models ─────────────────────────────────────────────────────────

class ChildHomeTasksResponse {
  final ChildHomeChildInfo child;
  final int totalStars;
  final List<ChildHomeTaskItem> pendingTasks;
  final List<ChildHomeTaskItem> completedTasks;

  const ChildHomeTasksResponse({
    required this.child,
    required this.totalStars,
    required this.pendingTasks,
    required this.completedTasks,
  });

  factory ChildHomeTasksResponse.fromJson(Map<String, dynamic> j) =>
      ChildHomeTasksResponse(
        child: ChildHomeChildInfo.fromJson(
            j['child'] as Map<String, dynamic>? ?? {}),
        totalStars: j['totalStars'] as int? ?? 0,
        pendingTasks: (j['pendingTasks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChildHomeTaskItem.fromJson)
            .toList(),
        completedTasks: (j['completedTasks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChildHomeTaskItem.fromJson)
            .toList(),
      );

  /// All tasks (pending + completed) in a single list.
  List<ChildHomeTaskItem> get allTasks => [...pendingTasks, ...completedTasks];
}

class ChildHomeChildInfo {
  final String childId;
  final String fullName;
  final String? profileImageUrl;
  final bool isCompleted;
  final DateTime? completedAt;

  const ChildHomeChildInfo({
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
    this.isCompleted = false,
    this.completedAt,
  });

  factory ChildHomeChildInfo.fromJson(Map<String, dynamic> j) =>
      ChildHomeChildInfo(
        childId: j['childId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        profileImageUrl: j['profileImageUrl'] as String?,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
      );
}

class ChildHomeTaskItem {
  final String taskId;
  final String title;
  final String? taskImageUrl;
  final int stars;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final String? recurrenceSummary;
  final List<ChildHomeAssignedChild> assignedChildren;

  const ChildHomeTaskItem({
    required this.taskId,
    required this.title,
    this.taskImageUrl,
    required this.stars,
    required this.isCompleted,
    this.completedAt,
    this.dueDate,
    this.recurrenceSummary,
    required this.assignedChildren,
  });

  factory ChildHomeTaskItem.fromJson(Map<String, dynamic> j) =>
      ChildHomeTaskItem(
        taskId: j['taskId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        taskImageUrl: j['taskImageUrl'] as String?,
        stars: j['stars'] as int? ?? 0,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
        dueDate: j['dueDate'] != null
            ? DateTime.tryParse(j['dueDate'] as String)
            : null,
        recurrenceSummary: j['recurrenceSummary'] as String?,
        assignedChildren: (j['assignedChildren'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChildHomeAssignedChild.fromJson)
            .toList(),
      );
}

class ChildHomeAssignedChild {
  final String childId;
  final String fullName;
  final String? profileImageUrl;
  final bool isCompleted;
  final DateTime? completedAt;

  const ChildHomeAssignedChild({
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
    required this.isCompleted,
    this.completedAt,
  });

  factory ChildHomeAssignedChild.fromJson(Map<String, dynamic> j) =>
      ChildHomeAssignedChild(
        childId: j['childId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        profileImageUrl: j['profileImageUrl'] as String?,
        isCompleted: j['isCompleted'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.tryParse(j['completedAt'] as String)
            : null,
      );
}

// ─── Task detail model ───────────────────────────────────────────────────────

class ChildHomeTaskDetail {
  final String taskId;
  final String title;
  final String? taskImageUrl;
  final String? recordingUrl;
  final int stars;
  final DateTime? startDate;
  final DateTime? dueDate;
  final ChildHomeRecurrence? recurrence;
  final List<ChildHomeAssignedChild> assignedChildren;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChildHomeTaskDetail({
    required this.taskId,
    required this.title,
    this.taskImageUrl,
    this.recordingUrl,
    required this.stars,
    this.startDate,
    this.dueDate,
    this.recurrence,
    required this.assignedChildren,
    this.createdAt,
    this.updatedAt,
  });

  factory ChildHomeTaskDetail.fromJson(Map<String, dynamic> j) =>
      ChildHomeTaskDetail(
        taskId: j['taskId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        taskImageUrl: j['taskImageUrl'] as String?,
        recordingUrl: j['recordingUrl'] as String?,
        stars: j['stars'] as int? ?? 0,
        startDate: j['startDate'] != null
            ? DateTime.tryParse(j['startDate'] as String)
            : null,
        dueDate: j['dueDate'] != null
            ? DateTime.tryParse(j['dueDate'] as String)
            : null,
        recurrence: j['recurrence'] != null
            ? ChildHomeRecurrence.fromJson(
                j['recurrence'] as Map<String, dynamic>)
            : null,
        assignedChildren: (j['assignedChildren'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChildHomeAssignedChild.fromJson)
            .toList(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String)
            : null,
      );
}

class ChildHomeRecurrence {
  final bool isRecurring;
  final List<String> repeatDays;
  final String? repeatTime;

  const ChildHomeRecurrence({
    required this.isRecurring,
    required this.repeatDays,
    this.repeatTime,
  });

  factory ChildHomeRecurrence.fromJson(Map<String, dynamic> j) =>
      ChildHomeRecurrence(
        isRecurring: j['isRecurring'] as bool? ?? false,
        repeatDays: (j['repeatDays'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        repeatTime: j['repeatTime'] as String?,
      );
}

// ─── Repository ──────────────────────────────────────────────────────────────

class ChildHomeTaskRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final AuthService _authService = AuthService();

  ChildHomeTaskRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            ));

  /// Get child token for authorization
  Future<Options> _opts() async {
    final token = await _authService.getChildToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/ChildHome/tasks
  // ──────────────────────────────────────────────────────────────────────────
  Future<ChildHomeTasksResponse> fetchTasks() async {
    try {
      final res = await _dio.get(
        '/ChildHome/tasks',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return ChildHomeTasksResponse.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/ChildHome/tasks/{taskId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<ChildHomeTaskDetail> fetchTaskDetail(String taskId) async {
    try {
      final res = await _dio.get(
        '/ChildHome/tasks/$taskId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return ChildHomeTaskDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PATCH /api/ChildHome/tasks/{taskId}/complete
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> completeTask(String taskId) async {
    try {
      final res = await _dio.patch(
        '/ChildHome/tasks/$taskId/complete',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
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
