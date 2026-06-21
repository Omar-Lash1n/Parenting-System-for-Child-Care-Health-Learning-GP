// --- API Service for Phase 4 Doctor-Side Remote Consultation ---
// Base path: /api/doctor/consultations
// Follows the same Dio pattern as clinic_remote_api_service.dart.

import 'package:dio/dio.dart';
import 'package:Ajial/api/specialist-services.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart'
    show ApiResponse;
import 'package:Ajial/specialist-app/dashboard/models/doctor_consultation_models.dart';

class DoctorConsultationApiService {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final SpecialistService _specialistService = SpecialistService();

  DoctorConsultationApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 90),
                headers: {'Accept': 'application/json'},
                // Treat 4xx as normal responses so the backend's Arabic
                // ApiResponse message reaches _parseResponse.
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  /// GET /api/doctor/consultations/profile
  Future<DoctorProfile> getMyProfile() async {
    final response = await _dio.get(
      '/doctor/consultations/profile',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DoctorProfile.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/doctor/consultations/slots?date=yyyy-MM-dd
  Future<DoctorSlotsResponse> getSlots(String date) async {
    final response = await _dio.get(
      '/doctor/consultations/slots',
      queryParameters: {'date': date},
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DoctorSlotsResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/doctor/consultations/calendar?month=yyyy-MM
  Future<DoctorCalendarResponse> getCalendar(String month) async {
    final response = await _dio.get(
      '/doctor/consultations/calendar',
      queryParameters: {'month': month},
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DoctorCalendarResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/doctor/consultations/bookings/{bookingId}
  Future<DoctorBookingDetail> getBookingDetail(String bookingId) async {
    final response = await _dio.get(
      '/doctor/consultations/bookings/$bookingId',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DoctorBookingDetail.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/doctor/consultations/bookings/{bookingId}/session
  Future<DoctorSessionStatus> getSessionStatus(String bookingId) async {
    final response = await _dio.get(
      '/doctor/consultations/bookings/$bookingId/session',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DoctorSessionStatus.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/consultations/bookings/{bookingId}/start-session
  Future<StartSessionResponse> startSession(String bookingId) async {
    final response = await _dio.post(
      '/doctor/consultations/bookings/$bookingId/start-session',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => StartSessionResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/consultations/bookings/{bookingId}/end-session
  Future<DoctorSessionStatus> endSession(String bookingId) async {
    final response = await _dio.post(
      '/doctor/consultations/bookings/$bookingId/end-session',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DoctorSessionStatus.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  // ============================================================
  // ============ Prescription (الروشتة الطبية) =================
  // ============================================================

  /// GET /api/doctor/consultations/bookings/{bookingId}/prescriptions
  Future<PrescriptionListResponse> getPrescription(String bookingId) async {
    final response = await _dio.get(
      '/doctor/consultations/bookings/$bookingId/prescriptions',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => PrescriptionListResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/consultations/bookings/{bookingId}/prescriptions
  Future<PrescriptionMedicine> addPrescriptionMedicine(
    String bookingId, {
    required String medicineName,
    required String quantity,
    required String timing,
  }) async {
    final response = await _dio.post(
      '/doctor/consultations/bookings/$bookingId/prescriptions',
      data: {
        'medicineName': medicineName,
        'quantity': quantity,
        'timing': timing,
      },
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => PrescriptionMedicine.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// PUT /api/doctor/consultations/bookings/{bookingId}/prescriptions/{medicineId}
  Future<PrescriptionMedicine> updatePrescriptionMedicine(
    String bookingId,
    String medicineId, {
    required String medicineName,
    required String quantity,
    required String timing,
  }) async {
    final response = await _dio.put(
      '/doctor/consultations/bookings/$bookingId/prescriptions/$medicineId',
      data: {
        'medicineName': medicineName,
        'quantity': quantity,
        'timing': timing,
      },
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => PrescriptionMedicine.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// DELETE /api/doctor/consultations/bookings/{bookingId}/prescriptions/{medicineId}
  Future<void> deletePrescriptionMedicine(
      String bookingId, String medicineId) async {
    final response = await _dio.delete(
      '/doctor/consultations/bookings/$bookingId/prescriptions/$medicineId',
      options: await _options(),
    );
    _parseResponse(response.data, (data) => data == true);
  }

  // ============================================================
  // ============ Diagnosis (التشخيص الطبي) =====================
  // ============================================================

  /// GET /api/doctor/consultations/bookings/{bookingId}/diagnosis
  Future<DiagnosisResponse> getDiagnosis(String bookingId) async {
    final response = await _dio.get(
      '/doctor/consultations/bookings/$bookingId/diagnosis',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => DiagnosisResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/consultations/bookings/{bookingId}/diagnosis
  Future<MedicalDiagnosis> addDiagnosis(
      String bookingId, String description) async {
    final response = await _dio.post(
      '/doctor/consultations/bookings/$bookingId/diagnosis',
      data: {'description': description},
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => MedicalDiagnosis.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// PUT /api/doctor/consultations/bookings/{bookingId}/diagnosis
  Future<MedicalDiagnosis> updateDiagnosis(
      String bookingId, String description) async {
    final response = await _dio.put(
      '/doctor/consultations/bookings/$bookingId/diagnosis',
      data: {'description': description},
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => MedicalDiagnosis.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// DELETE /api/doctor/consultations/bookings/{bookingId}/diagnosis
  Future<void> deleteDiagnosis(String bookingId) async {
    final response = await _dio.delete(
      '/doctor/consultations/bookings/$bookingId/diagnosis',
      options: await _options(),
    );
    _parseResponse(response.data, (data) => data == true);
  }

  // ============================================================
  // ==================== Helpers ===============================
  // ============================================================

  Future<Options> _options() async {
    final token = await _specialistService.getSpecialistToken();
    if (token == null || token.isEmpty) {
      throw Exception('يرجى تسجيل الدخول مرة أخرى');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  T _parseResponse<T>(dynamic body, T Function(dynamic data) parser) {
    if (body is! Map) {
      throw Exception('رد غير متوقع من الخادم');
    }
    final response = ApiResponse<T>.fromJson(
      Map<String, dynamic>.from(body),
      parser,
    );
    if (!response.success) {
      throw Exception(_messageFromResponse(response));
    }
    if (response.data == null) {
      throw Exception(response.message.isNotEmpty
          ? response.message
          : 'لا توجد بيانات للعرض');
    }
    return response.data as T;
  }

  String _messageFromResponse(ApiResponse<dynamic> response) {
    if (response.errors.isNotEmpty) return response.errors.first;
    if (response.message.isNotEmpty) return response.message;
    return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
  }
}
