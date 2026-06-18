import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AvailableDoctor {
  final String id;
  final String fullName;
  final String specialization;
  final String? profileImageUrl;
  final bool hasClinic;
  final bool hasRemote;
  final double? remoteSessionPrice;
  final double? clinicExaminationPrice;

  AvailableDoctor({
    required this.id,
    required this.fullName,
    required this.specialization,
    this.profileImageUrl,
    required this.hasClinic,
    required this.hasRemote,
    this.remoteSessionPrice,
    this.clinicExaminationPrice,
  });

  factory AvailableDoctor.fromJson(Map<String, dynamic> json) {
    return AvailableDoctor(
      id: json['id']?.toString() ?? '',
      fullName: json['doctorName']?.toString() ?? json['fullName']?.toString() ?? 'طبيب',
      specialization: json['specialization']?.toString() ?? '',
      profileImageUrl: json['photoUrl']?.toString() ?? json['profileImageUrl']?.toString(),
      hasClinic: json['hasClinic'] ?? false,
      hasRemote: json['hasRemote'] ?? false,
      remoteSessionPrice: (json['remoteSessionPrice'] as num?)?.toDouble(),
      clinicExaminationPrice: (json['clinicExaminationPrice'] as num?)?.toDouble(),
    );
  }
}

class SpecialtyChip {
  final String name;

  SpecialtyChip({required this.name});

  factory SpecialtyChip.fromJson(Map<String, dynamic> json) {
    return SpecialtyChip(
      name: json['name']?.toString() ?? '',
    );
  }
}

class ParentConsultationService {
  static const String _apiBaseUrl =
      "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api";

  final AuthService _authService = AuthService();

  /// Helper to build headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No auth token found. Please login first.');
    
    print('🔑 Token found: ${token.substring(0, 20)}...');
    return {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    };
  }

  /// Helper to extract data from API response (handles both wrapped and raw responses)
  List<dynamic> _extractList(String responseBody) {
    final dynamic decoded = json.decode(responseBody);
    
    if (decoded is List) {
      return decoded;
    } else if (decoded is Map<String, dynamic>) {
      // Try common wrapper keys
      if (decoded['data'] is List) return decoded['data'];
      if (decoded['result'] is List) return decoded['result'];
      if (decoded['items'] is List) return decoded['items'];
      // If it's a success wrapper but data isn't a list, return empty
      return [];
    }
    return [];
  }

  Future<List<SpecialtyChip>> getSpecialties() async {
    final headers = await _getAuthHeaders();
    final url = '$_apiBaseUrl/parent/consultations/specialties';
    
    print('📤 GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('📥 Specialties Response: ${response.statusCode}');
      print('📥 Specialties Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractList(response.body);
        return data
            .map((item) => SpecialtyChip.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ Error getting specialties: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load specialties (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getSpecialties: $e');
      rethrow;
    }
  }

  Future<List<AvailableDoctor>> getDoctors({String? search, String? specialty}) async {
    final headers = await _getAuthHeaders();
    
    // Build URL with query parameters manually to avoid issues with empty map
    String url = '$_apiBaseUrl/parent/consultations/doctors';
    final List<String> params = [];
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (specialty != null && specialty.isNotEmpty && specialty != 'الكل') {
      params.add('specialty=${Uri.encodeComponent(specialty)}');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    print('📤 GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      print('📥 Doctors Response: ${response.statusCode}');
      print('📥 Doctors Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _extractList(response.body);
        return data
            .map((item) => AvailableDoctor.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ Error getting doctors: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load doctors (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception in getDoctors: $e');
      rethrow;
    }
  }
}
