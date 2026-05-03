import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Ajial/homepage/models/current_vaccination_model.dart';
import 'package:Ajial/homepage/models/upcoming_task_model.dart';

class ParentHomeRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';
  static const String _tokenKey = 'ajial_auth_token';

  final Dio _dio;

  ParentHomeRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  Future<List<CurrentVaccinationModel>> fetchCurrentVaccinations() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    try {
      final response = await _dio.get(
        '/parent/home/current-vaccinations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final list = _extractList(response.data, 'vaccinations');
      return list
          .whereType<Map>()
          .map((item) => CurrentVaccinationModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<UpcomingTaskModel>> fetchUpcomingTasks({int limit = 5}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    try {
      final response = await _dio.get(
        '/parent/home/upcoming-tasks',
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final list = _extractList(response.data, 'tasks');
      return list
          .whereType<Map>()
          .map((item) => UpcomingTaskModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  List<dynamic> _extractList(dynamic response, String key) {
    if (response is List) return response;
    if (response is! Map<String, dynamic>) return [];

    if (response['success'] == false) {
      throw Exception(response['message']?.toString() ?? 'فشل تحميل البيانات');
    }

    final data = response['data'];
    if (data is Map<String, dynamic> && data[key] is List) {
      return data[key] as List;
    }
    if (data is List) return data;
    if (response[key] is List) return response[key] as List;
    return [];
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
          return Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.');
        }
        final data = e.response?.data;
        final message = data is Map ? data['message'] : null;
        return Exception(message?.toString() ?? 'خطأ من الخادم ($statusCode)');
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
