import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthService(String baseUrl) : dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  }));

  Future<Response> registerParent(Map<String, dynamic> payload) async {
    return await dio.post('/api/Auth/register/parent', data: payload);
  }

  Future<Response> loginParent(String username, String password) async {
    return await dio.post('/api/Auth/login/parent', data: {
      'username': username,
      'password': password,
    });
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'access_token', value: token);
  }
}
