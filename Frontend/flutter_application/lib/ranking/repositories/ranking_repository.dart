import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/ranking/models/ranking_models.dart';

class RankingRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final AuthService _authService = AuthService();

  RankingRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ));

  Future<String?> _getToken() => _authService.getToken();

  Future<Options> _opts() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<PagedRanking> fetchPublishedRanking({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _dio.get(
        '/ranking',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      final data = body['data'];
      if (data == null) throw Exception('لا يوجد ترتيب منشور حالياً');
      return PagedRanking.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('لم يتم نشر أي ترتيب بعد');
      }
      throw _handleDioError(e);
    }
  }

  Future<List<ParentBadge>> fetchMyBadges() async {
    try {
      final res = await _dio.get('/ranking/my-badges', options: await _opts());
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => ParentBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.');
      }
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
        return Exception('تعذّر الاتصال بالخادم.');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401) {
          return Exception('انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.');
        }
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final msg = data['message']?.toString();
          if (msg != null && msg.isNotEmpty) return Exception(msg);
        }
        return Exception('خطأ من الخادم ($status)');
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
