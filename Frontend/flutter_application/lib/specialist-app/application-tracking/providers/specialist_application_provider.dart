import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/api/specialist-services.dart';
import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart';
import 'package:Ajial/specialist-app/application-tracking/services/specialist_application_api_service.dart';

class SpecialistApplicationProvider extends ChangeNotifier {
  final SpecialistApplicationApiService _api;
  final SpecialistService _specialistService;
  final ImagePicker _picker = ImagePicker();

  SpecialistApplicationProvider({
    SpecialistApplicationApiService? api,
    SpecialistService? specialistService,
  })  : _api = api ?? SpecialistApplicationApiService(),
        _specialistService = specialistService ?? SpecialistService();

  SpecialistCurrentApplicationModel? current;
  SpecialistApplicationDetailsModel? details;
  List<SpecialtyModel> specialties = const [];
  String specialistName = 'متخصص';

  bool loadingCurrent = false;
  bool loadingDetails = false;
  bool loadingSpecialties = false;
  bool submitting = false;
  bool creatingNew = false;
  String? errorMessage;
  final Set<String> uploadingDocuments = <String>{};

  bool get hasApplication => current != null;

  Future<void> loadCurrent() async {
    loadingCurrent = true;
    errorMessage = null;
    notifyListeners();
    try {
      specialistName = await _specialistService.getSpecialistName() ?? 'متخصص';
      current = await _api.getCurrentApplication();
    } catch (e) {
      errorMessage = _cleanError(e);
      current = null;
    } finally {
      loadingCurrent = false;
      notifyListeners();
    }
  }

  Future<void> loadDetails(String applicationId) async {
    loadingDetails = true;
    errorMessage = null;
    if (details?.applicationId != applicationId) {
      details = null;
    }
    notifyListeners();
    try {
      details = await _api.getApplicationDetails(applicationId);
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      loadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> loadSpecialties() async {
    if (specialties.isNotEmpty || loadingSpecialties) return;
    loadingSpecialties = true;
    notifyListeners();
    try {
      specialties = await _api.getSpecialties();
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      loadingSpecialties = false;
      notifyListeners();
    }
  }

  Future<bool> cancelApplication(String applicationId) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.cancelApplication(applicationId);
      await loadCurrent();
      details = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<bool> startEditApplication(String applicationId) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.startEditApplication(applicationId);
      await loadCurrent();
      await loadDetails(applicationId);
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<String?> createNewApplication() async {
    creatingNew = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.createNewApplication();
      await loadCurrent();
      await loadDetails(response.applicationId);
      return response.applicationId;
    } catch (e) {
      errorMessage = _cleanError(e);
      return null;
    } finally {
      creatingNew = false;
      notifyListeners();
    }
  }

  Future<XFile?> pickImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
  }

  Future<bool> pickAndUploadDocument({
    required String applicationId,
    required String documentType,
  }) async {
    final file = await pickImage();
    if (file == null) return false;
    return uploadDocument(
      applicationId: applicationId,
      documentType: documentType,
      file: file,
    );
  }

  Future<bool> uploadDocument({
    required String applicationId,
    required String documentType,
    required XFile file,
  }) async {
    uploadingDocuments.add(documentType);
    errorMessage = null;
    notifyListeners();
    try {
      await _api.uploadDocument(
        applicationId: applicationId,
        documentType: documentType,
        file: file,
      );
      await loadDetails(applicationId);
      await loadCurrent();
      return true;
    } catch (e) {
      errorMessage = 'فشل رفع الصورة، حاول مرة أخرى';
      return false;
    } finally {
      uploadingDocuments.remove(documentType);
      notifyListeners();
    }
  }

  Future<bool> updateProfessionalData({
    required String applicationId,
    required int? specialtyId,
    required String licenseNumber,
    XFile? specializationCertificate,
    XFile? professionalLicense,
    XFile? syndicateCard,
  }) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.updateProfessionalData(
        applicationId: applicationId,
        specialtyId: specialtyId,
        licenseNumber: licenseNumber,
        specializationCertificate: specializationCertificate,
        professionalLicense: professionalLicense,
        syndicateCard: syndicateCard,
      );
      await loadDetails(applicationId);
      await loadCurrent();
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<bool> submitApplication(String applicationId) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.submitApplication(applicationId);
      await loadCurrent();
      details = null;
      return true;
    } catch (e) {
      errorMessage = 'تعذر إرسال الطلب، تأكد من اكتمال البيانات';
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('SocketException') ||
        text.contains('connection') ||
        text.contains('Connection') ||
        text.contains('DioException')) {
      return 'تعذر الاتصال بالخادم، حاول مرة أخرى';
    }
    return text.isEmpty ? 'تعذر الاتصال بالخادم، حاول مرة أخرى' : text;
  }
}

String specialistStatusLabel(String status, [String? fallback]) {
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  switch (status) {
    case 'Draft':
      return 'مسودة';
    case 'Pending':
    case 'PendingReview':
      return 'جاري المراجعة';
    case 'Approved':
      return 'تم القبول';
    case 'Rejected':
      return 'لم يتم القبول';
    case 'Cancelled':
      return 'تم الغاء الطلب';
    default:
      return status;
  }
}

bool statusAllowsEdit(String status) {
  return status == 'Pending' ||
      status == 'PendingReview' ||
      status == 'Rejected' ||
      status == 'Draft';
}
