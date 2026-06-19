// --- API Service for Clinic & Remote Consultation ---
// Follows same pattern as specialist_application_api_service.dart (Dio-based)

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/api/specialist-services.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart'
    show ApiResponse;
import 'package:Ajial/specialist-app/dashboard/models/clinic_remote_models.dart';

class ClinicRemoteApiService {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final SpecialistService _specialistService = SpecialistService();

  ClinicRemoteApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 90),
                headers: {'Accept': 'application/json'},
                // Treat 4xx (400/403/404/409) as normal responses so the backend's
                // Arabic ApiResponse message reaches _parseResponse instead of being
                // collapsed into a generic "تعذر الاتصال بالخادم" DioException.
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  // ============================================================
  // ==================== Doctor — Clinic =======================
  // ============================================================

  /// POST /api/doctor/clinics — Create a new clinic draft.
  Future<ClinicStatusChangeModel> createClinicDraft() async {
    final response = await _dio.post(
      '/doctor/clinics',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/doctor/clinics — List all clinics for authenticated doctor.
  Future<List<ClinicCardModel>> getDoctorClinics() async {
    final response = await _dio.get(
      '/doctor/clinics',
      options: await _options(),
    );
    return _parseResponse<List<ClinicCardModel>>(
      response.data,
      (data) => (data as List)
          .map((item) => ClinicCardModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }

  /// GET /api/doctor/clinics/{clinicId} — Get full detail of a clinic.
  Future<ClinicDetailModel> getClinicDetail(String clinicId) async {
    final response = await _dio.get(
      '/doctor/clinics/$clinicId',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/Cities — Fetch all cities from backend
  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await _dio.get(
      '/Cities',
      options: await _options(),
    );
    return _parseResponse<List<Map<String, dynamic>>>(
      response.data,
      (data) => (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  /// PUT /api/doctor/clinics/{clinicId}/details — Update Step 1 fields.
  Future<ClinicDetailModel> updateClinicDetails(
    String clinicId, {
    String? name,
    int? governorateId,
    String? districtName,
    String? address,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (governorateId != null) body['governorateId'] = governorateId;
    if (districtName != null) body['districtName'] = districtName;
    if (address != null) body['address'] = address;
    if (phone != null) body['phone'] = phone;

    final response = await _dio.put(
      '/doctor/clinics/$clinicId/details',
      data: body,
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// PUT /api/doctor/clinics/{clinicId}/hours — Update Step 2 fields.
  Future<ClinicDetailModel> updateClinicHours(
    String clinicId, {
    String? workingHoursJson,
    double? examinationPrice,
    double? consultationPrice,
  }) async {
    final body = <String, dynamic>{};
    if (workingHoursJson != null) body['workingHoursJson'] = workingHoursJson;
    if (examinationPrice != null) body['examinationPrice'] = examinationPrice;
    if (consultationPrice != null) body['consultationPrice'] = consultationPrice;

    final response = await _dio.put(
      '/doctor/clinics/$clinicId/hours',
      data: body,
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// PUT /api/doctor/clinics/{clinicId}/documents/{documentType}
  /// Upload or replace a single certification image (Step 3).
  Future<ClinicDocumentUploadModel> uploadClinicDocument(
    String clinicId,
    ClinicDocumentType documentType,
    XFile file,
  ) async {
    final form = FormData.fromMap({
      'file': await _multipartFile(file),
    });
    final response = await _dio.put(
      '/doctor/clinics/$clinicId/documents/${documentType.value}',
      data: form,
      options: await _options(multipart: true),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicDocumentUploadModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/clinics/{clinicId}/submit — Submit for review.
  Future<ClinicStatusChangeModel> submitClinic(String clinicId) async {
    final response = await _dio.post(
      '/doctor/clinics/$clinicId/submit',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/clinics/{clinicId}/cancel — Cancel request.
  Future<ClinicStatusChangeModel> cancelClinic(String clinicId) async {
    final response = await _dio.post(
      '/doctor/clinics/$clinicId/cancel',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/clinics/{clinicId}/start-edit — Pull back to Draft.
  Future<ClinicStatusChangeModel> startEditClinic(String clinicId) async {
    final response = await _dio.post(
      '/doctor/clinics/$clinicId/start-edit',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => ClinicStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  // ============================================================
  // ============ Doctor — Remote Consultation ==================
  // ============================================================

  /// POST /api/doctor/remote-consultations — Create draft.
  Future<RemoteConsultationStatusChangeModel>
      createRemoteConsultationDraft() async {
    final response = await _dio.post(
      '/doctor/remote-consultations',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => RemoteConsultationStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// GET /api/doctor/remote-consultations — List all for doctor.
  Future<List<RemoteConsultationCardModel>>
      getDoctorRemoteConsultations() async {
    final response = await _dio.get(
      '/doctor/remote-consultations',
      options: await _options(),
    );
    return _parseResponse<List<RemoteConsultationCardModel>>(
      response.data,
      (data) => (data as List)
          .map((item) => RemoteConsultationCardModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }

  /// GET /api/doctor/remote-consultations/{id} — Get full detail.
  Future<RemoteConsultationDetailModel> getRemoteConsultationDetail(
    String id,
  ) async {
    final response = await _dio.get(
      '/doctor/remote-consultations/$id',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => RemoteConsultationDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// PUT /api/doctor/remote-consultations/{id} — Update fields.
  Future<RemoteConsultationDetailModel> updateRemoteConsultation(
    String id, {
    double? sessionPrice,
    int? sessionDurationMinutes,
    int? waitingPeriodMinutes,
    String? workingHoursJson,
  }) async {
    final body = <String, dynamic>{};
    if (sessionPrice != null) body['sessionPrice'] = sessionPrice;
    if (sessionDurationMinutes != null) {
      body['sessionDurationMinutes'] = sessionDurationMinutes;
    }
    if (waitingPeriodMinutes != null) {
      body['waitingPeriodMinutes'] = waitingPeriodMinutes;
    }
    if (workingHoursJson != null) body['workingHoursJson'] = workingHoursJson;

    final response = await _dio.put(
      '/doctor/remote-consultations/$id',
      data: body,
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => RemoteConsultationDetailModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/remote-consultations/{id}/submit — Submit for review.
  Future<RemoteConsultationStatusChangeModel> submitRemoteConsultation(
    String id,
  ) async {
    final response = await _dio.post(
      '/doctor/remote-consultations/$id/submit',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => RemoteConsultationStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/remote-consultations/{id}/cancel — Cancel request.
  Future<RemoteConsultationStatusChangeModel> cancelRemoteConsultation(
    String id,
  ) async {
    final response = await _dio.post(
      '/doctor/remote-consultations/$id/cancel',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => RemoteConsultationStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  /// POST /api/doctor/remote-consultations/{id}/start-edit — Pull back to Draft.
  Future<RemoteConsultationStatusChangeModel> startEditRemoteConsultation(
    String id,
  ) async {
    final response = await _dio.post(
      '/doctor/remote-consultations/$id/start-edit',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => RemoteConsultationStatusChangeModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  // ============================================================
  // ==================== Helpers ===============================
  // ============================================================

  Future<Options> _options({bool multipart = false}) async {
    final token = await _specialistService.getSpecialistToken();
    if (token == null || token.isEmpty) {
      throw Exception('يرجى تسجيل الدخول مرة أخرى');
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        if (multipart) 'Content-Type': 'multipart/form-data',
      },
    );
  }

  Future<MultipartFile> _multipartFile(XFile file) async {
    return MultipartFile.fromBytes(
      await file.readAsBytes(),
      filename: file.name.isNotEmpty ? file.name : 'document.jpg',
    );
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
