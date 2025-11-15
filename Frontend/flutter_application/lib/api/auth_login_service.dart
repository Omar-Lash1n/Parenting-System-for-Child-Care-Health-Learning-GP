// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginAuthService {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  LoginAuthService({required String baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  /// تسجيل الدخول للأب/الوالد
  Future<Response> loginParent(String username, String password) async {
    final payload = {
      'username': username,
      'password': password,
    };
    return await dio.post('/api/Auth/login/parent', data: payload);
  }

  /// تسهيلات لحفظ التوكن (لو موجود)
  Future<void> saveAccessToken(String token) async {
    await storage.write(key: 'access_token', value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await storage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getAccessToken() => storage.read(key: 'access_token');
  Future<void> clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}
