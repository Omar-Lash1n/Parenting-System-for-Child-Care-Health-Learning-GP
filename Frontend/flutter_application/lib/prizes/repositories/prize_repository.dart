// lib/prizes/repositories/prize_repository.dart
//
// Repository for all Prize API endpoints.
// Follows the same Dio + AuthService pattern as ChildTaskRepository.

import 'package:dio/dio.dart';
import 'package:Ajial/api/auth_service.dart';
import 'package:Ajial/prizes/models/child_prizes_response_model.dart';
import 'package:Ajial/prizes/models/parent_prizes_response_model.dart';
import 'package:Ajial/prizes/models/prize_detail_model.dart';

class PrizeRepository {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final AuthService _authService = AuthService();

  PrizeRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ));

  Future<String?> _getToken() => _authService.getToken();
  Future<String?> _getParentId() => _authService.getSavedParentId();

  Future<Options> _opts({Map<String, dynamic>? extraHeaders}) async {
    final token = await _getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      if (extraHeaders != null) ...extraHeaders,
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/Prize/parent/{parentId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<ParentPrizesResponse> fetchParentPrizes() async {
    final parentId = await _getParentId();
    if (parentId == null) throw Exception('لا يوجد معرف الوالد');
    try {
      final res = await _dio.get(
        '/Prize/parent/$parentId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return ParentPrizesResponse.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const ParentPrizesResponse(
            parentId: '', totalPrizes: 0, prizes: []);
      }
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/Prize/child/{childId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<ChildPrizesResponse> fetchChildPrizes(String childId) async {
    try {
      final res = await _dio.get(
        '/Prize/child/$childId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return ChildPrizesResponse.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/Prize/{prizeId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<PrizeDetail> fetchPrizeDetail(String prizeId) async {
    try {
      final res = await _dio.get(
        '/Prize/$prizeId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'خطأ من الخادم');
      }
      return PrizeDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // POST /api/Prize  (multipart/form-data)
  // ──────────────────────────────────────────────────────────────────────────
  Future<PrizeDetail> createPrize(FormData formData) async {
    try {
      final res = await _dio.post(
        '/Prize',
        data: formData,
        options: await _opts(
            extraHeaders: {'Content-Type': 'multipart/form-data'}),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(_firstError(body) ?? 'تعذّر إنشاء المكافئة');
      }
      return PrizeDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PUT /api/Prize/{prizeId}  (multipart/form-data)
  // ──────────────────────────────────────────────────────────────────────────
  Future<PrizeDetail> updatePrize(String prizeId, FormData formData) async {
    try {
      final res = await _dio.put(
        '/Prize/$prizeId',
        data: formData,
        options: await _opts(
            extraHeaders: {'Content-Type': 'multipart/form-data'}),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(_firstError(body) ?? 'تعذّر تحديث المكافئة');
      }
      return PrizeDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE /api/Prize/{prizeId}
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> deletePrize(String prizeId) async {
    try {
      final res = await _dio.delete(
        '/Prize/$prizeId',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(body['message']?.toString() ?? 'تعذّر حذف المكافئة');
      }
      return body['success'] as bool? ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PATCH /api/Prize/{prizeId}/deliver
  // ──────────────────────────────────────────────────────────────────────────
  Future<PrizeDetail> deliverPrize(String prizeId) async {
    try {
      final res = await _dio.patch(
        '/Prize/$prizeId/deliver',
        options: await _opts(),
      );
      final body = res.data as Map<String, dynamic>;
      if (body['success'] == false) {
        throw Exception(_firstError(body) ?? 'تعذّر تسليم المكافئة');
      }
      return PrizeDetail.fromJson(
          body['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  String? _firstError(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    final msg = body['message'];
    return msg?.toString();
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
          final msg = _firstError(data);
          if (msg != null && msg.isNotEmpty) return Exception(msg);
        }
        return Exception('خطأ من الخادم ($status)');
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
