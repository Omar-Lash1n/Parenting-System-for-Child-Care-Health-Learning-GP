import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/api/specialist-services.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart';

class SpecialistApplicationApiService {
  static const String _baseUrl =
      'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  final Dio _dio;
  final SpecialistService _specialistService = SpecialistService();

  SpecialistApplicationApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 90),
                headers: {'Accept': 'application/json'},
              ),
            );

  Future<SpecialistCurrentApplicationModel> getCurrentApplication() async {
    final response = await _dio.get(
      '/specialist/application/current',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => SpecialistCurrentApplicationModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<SpecialistApplicationDetailsModel> getApplicationDetails(
    String applicationId,
  ) async {
    final response = await _dio.get(
      '/specialist/application/$applicationId',
      options: await _options(),
    );
    return _parseResponse(
      response.data,
      (data) => SpecialistApplicationDetailsModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<StatusChangeResponseModel> submitApplication(
    String applicationId,
  ) async {
    final response = await _dio.post(
      '/specialist/application/$applicationId/submit',
      options: await _options(),
    );
    return _parseStatus(response.data);
  }

  Future<StatusChangeResponseModel> cancelApplication(
    String applicationId,
  ) async {
    final response = await _dio.post(
      '/specialist/application/$applicationId/cancel',
      options: await _options(),
    );
    return _parseStatus(response.data);
  }

  Future<StatusChangeResponseModel> startEditApplication(
    String applicationId,
  ) async {
    final response = await _dio.post(
      '/specialist/application/$applicationId/start-edit',
      options: await _options(),
    );
    return _parseStatus(response.data);
  }

  Future<IdentityDataModel> updateIdentityData({
    required String applicationId,
    XFile? nationalIdFront,
    XFile? nationalIdBack,
    XFile? personalPhoto,
  }) async {
    final form = FormData();
    if (nationalIdFront != null) {
      form.files.add(MapEntry(
        'NationalIdFront',
        await _multipartFile(nationalIdFront),
      ));
    }
    if (nationalIdBack != null) {
      form.files.add(MapEntry(
        'NationalIdBack',
        await _multipartFile(nationalIdBack),
      ));
    }
    if (personalPhoto != null) {
      form.files.add(MapEntry(
        'PersonalPhoto',
        await _multipartFile(personalPhoto),
      ));
    }

    final response = await _dio.put(
      '/specialist/application/$applicationId/identity',
      data: form,
      options: await _options(multipart: true),
    );
    return _parseResponse(
      response.data,
      (data) => IdentityDataModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<ProfessionalDataModel> updateProfessionalData({
    required String applicationId,
    required int? specialtyId,
    required String licenseNumber,
    XFile? specializationCertificate,
    XFile? professionalLicense,
    XFile? syndicateCard,
  }) async {
    final form = FormData.fromMap({
      if (specialtyId != null) 'SpecialtyId': specialtyId,
      'PracticeLicenseNumber': licenseNumber,
      if (specializationCertificate != null)
        'SpecializationCertificate':
            await _multipartFile(specializationCertificate),
      if (professionalLicense != null)
        'ProfessionalLicense': await _multipartFile(professionalLicense),
      if (syndicateCard != null) 'SyndicateCard': await _multipartFile(syndicateCard),
    });

    final response = await _dio.put(
      '/specialist/application/$applicationId/professional',
      data: form,
      options: await _options(multipart: true),
    );
    return _parseResponse(
      response.data,
      (data) => ProfessionalDataModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  Future<DocumentInfoModel> uploadDocument({
    required String applicationId,
    required String documentType,
    required XFile file,
  }) async {
    final form = FormData.fromMap({'File': await _multipartFile(file)});
    final response = await _dio.put(
      '/specialist/application/$applicationId/documents/$documentType',
      data: form,
      options: await _options(multipart: true),
    );
    return _parseDocument(response.data);
  }

  Future<DocumentInfoModel> getDocument({
    required String applicationId,
    required String documentType,
  }) async {
    final response = await _dio.get(
      '/specialist/application/$applicationId/documents/$documentType',
      options: await _options(),
    );
    return _parseDocument(response.data);
  }

  Future<StatusChangeResponseModel> createNewApplication() async {
    final response = await _dio.post(
      '/specialist/application/new',
      options: await _options(),
    );
    return _parseStatus(response.data);
  }

  Future<List<SpecialtyModel>> getSpecialties() async {
    final response = await _dio.get('/specialist/specialties');
    return _parseResponse<List<SpecialtyModel>>(
      response.data,
      (data) => (data as List)
          .map((item) => SpecialtyModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }

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

  StatusChangeResponseModel _parseStatus(dynamic body) {
    return _parseResponse(
      body,
      (data) => StatusChangeResponseModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  }

  DocumentInfoModel _parseDocument(dynamic body) {
    return _parseResponse(
      body,
      (data) => DocumentInfoModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
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
