// lib/tasks/repositories/task_category_repository.dart
//
// Repository for Task Category API calls.
// Endpoints:
//   GET  /TaskCategory/parent/{parentId}  — list all categories
//   POST /TaskCategory                    — create a new category
//
// The parentId is decoded from the stored JWT token (NameIdentifier claim),
// consistent with the project's auth patterns.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_category_model.dart';

class TaskCategoryRepository {
  // ── Constants ─────────────────────────────────────────────────────────────
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  /// SharedPreferences key used by [AuthService] for the parent JWT token.
  static const String _parentTokenKey = 'ajial_auth_token';

  /// SharedPreferences key where [AuthService.loginParent] saves the parentId
  /// from the login response — this is the real Parent table ID.
  static const String _savedParentIdKey = 'ajial_parent_id';

  // ── Dio instance ──────────────────────────────────────────────────────────
  final Dio _dio;

  TaskCategoryRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Retrieves the stored parent JWT token.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentTokenKey);
  }

  /// Retrieves the parentId saved by [AuthService.loginParent].
  /// Returns null if not yet saved (user hasn't logged in, or using an old build).
  Future<String?> _getSavedParentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedParentIdKey);
  }

  /// Decodes a JWT token and extracts the parentId.
  ///
  /// Tries multiple claim keys in priority order and prints ALL claims
  /// to the console so we can identify the correct key during debugging.
  String? _extractParentId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64url → Base64 (pad to multiple of 4)
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64.decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      // ── Print ALL claims so we can identify the correct parentId key ──────
      print('🔑 [JWT] All claims in token:');
      claims.forEach((key, value) => print('   "$key": $value'));

      // ── Try claim keys in priority order ──────────────────────────────────
      // Custom claims the backend might use for the Parent table ID:
      const customKeys = [
        'ParentId',
        'parentId',
        'parent_id',
        'Parent_Id',
        'ParentID',
      ];

      for (final key in customKeys) {
        final value = claims[key];
        if (value != null && value.toString().isNotEmpty) {
          print('✅ [JWT] Using parentId from claim "$key": $value');
          return value.toString();
        }
      }

      // Standard .NET NameIdentifier (AspNetUsers.Id) — fallback
      const nameIdentifierKey =
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
      final id = claims[nameIdentifierKey] ?? claims['sub'];
      if (id != null) {
        print('⚠️ [JWT] Falling back to nameIdentifier/sub: $id');
        print('⚠️ [JWT] If the API returns 400, the backend uses a different claim key.');
      }
      return id?.toString();
    } catch (e) {
      print('❌ [JWT] decode error: $e');
      return null;
    }
  }


  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches all task categories for the authenticated parent.
  ///
  /// **Endpoint:** `GET /TaskCategory/parent/{parentId}`
  ///
  /// Returns a [List<TaskCategoryModel>] on success.
  /// Throws a descriptive [Exception] on any failure.
  Future<List<TaskCategoryModel>> fetchCategories() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    // ── Resolve parentId ─────────────────────────────────────────────────────
    // Priority 1: use the parentId saved at login time (real Parent table ID)
    // Priority 2: scan JWT claims for custom parentId keys
    // Priority 3: fall back to nameIdentifier (AspNetUsers.Id — may be wrong)
    String? parentId = await _getSavedParentId();

    if (parentId == null || parentId.isEmpty) {
      print('⚠️ [Categories] No saved parentId — extracting from JWT...');
      parentId = _extractParentId(token);
    } else {
      print('✅ [Categories] Using saved parentId: $parentId');
    }

    if (parentId == null || parentId.isEmpty) {
      throw Exception('تعذّر تحديد هوية الوالد. يرجى تسجيل الدخول مجددًا.');
    }

    print('📤 [Categories] Fetching for parentId: $parentId');

    try {
      final response = await _dio.get(
        '/TaskCategory/parent/$parentId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data;
      print('🔍 [Categories] HTTP ${response.statusCode} — raw data type: ${data.runtimeType}');
      print('🔍 [Categories] Raw response: $data');

      // ── Parse every possible response shape the server might return ──────
      List<dynamic> rawList = _extractCategoryList(data);

      print('🔍 [Categories] Extracted rawList length: ${rawList.length}');

      if (rawList.isEmpty) {
        print('⚠️ [Categories] rawList is empty — server returned no items or unknown format');
        return [];
      }

      final categories = rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => TaskCategoryModel.fromJson(json))
          .where((c) => c.id.isNotEmpty) // skip malformed entries
          .toList();

      print('✅ [Categories] Parsed ${categories.length} categories: ${categories.map((c) => c.name).toList()}');
      return categories;
    } on DioException catch (e) {
      print('❌ [Categories] DioException [${e.response?.statusCode}]: ${e.response?.data}');
      // 404 = no categories found for this parent — treat as empty, not an error
      if (e.response?.statusCode == 404) {
        print('⚠️ [Categories] 404 — treating as empty list (no categories yet)');
        return [];
      }
      throw _handleDioError(e);
    } catch (e) {
      print('❌ [Categories] Unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Extracts the list of category JSON objects from any server response shape.
  ///
  /// Handles all known formats:
  ///  - `{ "data": { "categories": [...] } }`   ← standard wrapped
  ///  - `{ "categories": [...] }`               ← root-level categories
  ///  - `{ "data": [...] }`                     ← wrapped array
  ///  - `[...]`                                 ← direct array
  ///  - `{ "success": false, "message": "..." }` ← error wrapper (returns [])
  List<dynamic> _extractCategoryList(dynamic data) {
    if (data == null) {
      print('⚠️ [Categories] data is null');
      return [];
    }

    // Direct array
    if (data is List) {
      print('✅ [Categories] Format: direct array');
      return data;
    }

    if (data is Map<String, dynamic>) {
      // Check for explicit failure
      if (data['success'] == false) {
        final msg = data['message']?.toString() ?? 'فشل جلب التصنيفات';
        print('⚠️ [Categories] Server returned success=false: $msg');
        return [];
      }

      // Root-level "categories" key
      if (data['categories'] is List) {
        print('✅ [Categories] Format: { "categories": [...] }');
        return data['categories'] as List;
      }

      // Wrapped "data" key
      final inner = data['data'];
      if (inner != null) {
        // { "data": { "categories": [...] } }
        if (inner is Map<String, dynamic> && inner['categories'] is List) {
          print('✅ [Categories] Format: { "data": { "categories": [...] } }');
          return inner['categories'] as List;
        }
        // { "data": [...] }
        if (inner is List) {
          print('✅ [Categories] Format: { "data": [...] }');
          return inner;
        }
      }

      // Any other list value in the top-level map
      for (final entry in data.entries) {
        if (entry.value is List) {
          final list = entry.value as List;
          // Likely a category list if items look like category objects
          if (list.isNotEmpty && list.first is Map && (list.first as Map).containsKey('id')) {
            print('✅ [Categories] Format: found list under key "${entry.key}"');
            return list;
          }
        }
      }

      print('⚠️ [Categories] Unknown Map format. Keys: ${data.keys.toList()}');
    }

    return [];
  }

  // ── Error Handling ────────────────────────────────────────────────────────

  /// Updates (renames) an existing custom category.
  ///
  /// **Endpoint:** `PUT /TaskCategory/{categoryId}`
  ///
  /// Note: System categories (`isSystem: true`) cannot be renamed — enforced
  /// on the provider level before this method is called.
  ///
  /// Throws a descriptive [Exception] on any failure.
  Future<void> updateCategory({
    required String categoryId,
    required String newName,
  }) async {
    if (newName.trim().isEmpty) {
      throw Exception('اسم التصنيف لا يمكن أن يكون فارغًا.');
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    print('📤 Updating category $categoryId → "$newName"');

    try {
      await _dio.put(
        '/TaskCategory/$categoryId',
        data: {'name': newName.trim()},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Category updated to "$newName"');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Deletes a custom category.
  ///
  /// **Endpoint:** `DELETE /TaskCategory/{categoryId}`
  ///
  /// Note: System categories (`isSystem: true`) cannot be deleted — enforced
  /// on the provider level.
  ///
  /// Throws a descriptive [Exception] on any failure.
  Future<void> deleteCategory(String categoryId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    print('📤 Deleting category $categoryId');

    try {
      await _dio.delete(
        '/TaskCategory/$categoryId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      print('✅ Category deleted successfully');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }


  /// Creates a new custom category for the authenticated parent.
  ///
  /// **Endpoint:** `POST /TaskCategory`
  ///
  /// Returns the created [TaskCategoryModel] on success.
  /// Throws a descriptive [Exception] on any failure.
  Future<TaskCategoryModel> createCategory(String name) async {
    if (name.trim().isEmpty) {
      throw Exception('اسم التصنيف لا يمكن أن يكون فارغًا.');
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('لا يوجد رمز مصادقة. يرجى تسجيل الدخول مجددًا.');
    }

    print('📤 Creating task category: "$name"');

    try {
      final response = await _dio.post(
        '/TaskCategory',
        data: {'name': name.trim()},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;

      // Unwrap { success, data: { id, name, isSystem, taskCount } }
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw Exception(
              data['message']?.toString() ?? 'فشل إنشاء التصنيف.');
        }
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          final created = TaskCategoryModel.fromJson(inner);
          print('✅ Category created: ${created.name} (${created.id})');
          return created;
        }
      }

      // If the server returned the object directly (no wrapper)
      if (data is Map<String, dynamic> && data.containsKey('id')) {
        return TaskCategoryModel.fromJson(data);
      }

      throw Exception('رد غير متوقع من السيرفر.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع: $e');
    }
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
        if (statusCode == 404) {
          return Exception('لم يتم العثور على تصنيفات للوالد.');
        }
        final msg =
            e.response?.data?['message'] ?? 'خطأ من الخادم ($statusCode)';
        return Exception(msg.toString());
      default:
        return Exception('حدث خطأ غير متوقع: ${e.message}');
    }
  }
}
