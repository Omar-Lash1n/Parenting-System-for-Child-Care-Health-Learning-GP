import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ajial/lessons/models/lesson_models.dart';

class LessonRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';
  static const String _tokenKey = 'ajial_auth_token';

  final Dio _dio;

  LessonRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  Future<List<LessonCategoryModel>> fetchCategories() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }
    try {
      final response = await _dio.get(
        '/parent/lessons/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = _extractBody(response.data);
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) =>
                LessonCategoryModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<LessonCardModel>> fetchLessons({
    String? categoryId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get(
        '/parent/lessons',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = _extractBody(response.data);
      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) =>
                LessonCardModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonDetailModel> fetchLessonDetail(String lessonId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }
    try {
      final response = await _dio.get(
        '/parent/lessons/$lessonId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = _extractBody(response.data);
      final data = body['data'];
      if (data is Map) {
        return LessonDetailModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('بيانات الدرس غير صحيحة');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MarkLessonReadResult> markLessonRead(String lessonId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }
    try {
      final response = await _dio.post(
        '/parent/lessons/$lessonId/mark-read',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = _extractBody(response.data);
      final data = body['data'];
      if (data is Map) {
        return MarkLessonReadResult.fromJson(Map<String, dynamic>.from(data));
      }
      return const MarkLessonReadResult(isRead: true, questions: []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LessonAnswerResult> submitAnswer({
    required String lessonId,
    required String questionId,
    required String selectedOptionId,
  }) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }
    try {
      final response = await _dio.post(
        '/parent/lessons/$lessonId/questions/$questionId/answer',
        data: {'selectedOptionId': selectedOptionId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = _extractBody(response.data);
      final data = body['data'];
      if (data is Map) {
        return LessonAnswerResult.fromJson(
          Map<String, dynamic>.from(data),
          message: body['message']?.toString() ?? '',
        );
      }
      throw Exception(body['message']?.toString() ?? 'تعذر إرسال الإجابة');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Map<String, dynamic> _extractBody(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw Exception('استجابة غير صحيحة من الخادم');
    }
    if (response['success'] == false) {
      throw Exception(
          response['message']?.toString() ?? 'فشل تحميل البيانات');
    }
    return response;
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.');
      case DioExceptionType.connectionError:
        return Exception('تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return Exception(
              'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.');
        }
        final data = e.response?.data;
        final message = data is Map ? data['message'] : null;
        return Exception(
            message?.toString() ?? 'خطأ من الخادم ($statusCode)');
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
