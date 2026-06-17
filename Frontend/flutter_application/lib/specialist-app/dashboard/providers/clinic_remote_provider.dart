// --- Provider for Clinic & Remote Consultation ---
// Follows same pattern as specialist_application_provider.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/specialist-app/dashboard/models/clinic_remote_models.dart';
import 'package:Ajial/specialist-app/dashboard/services/clinic_remote_api_service.dart';

class ClinicRemoteProvider extends ChangeNotifier {
  final ClinicRemoteApiService _api;
  final ImagePicker _picker = ImagePicker();

  ClinicRemoteProvider({ClinicRemoteApiService? api})
      : _api = api ?? ClinicRemoteApiService();

  // ============================================================
  // ==================== State =================================
  // ============================================================

  // --- Clinic State ---
  List<ClinicCardModel> clinics = [];
  ClinicDetailModel? clinicDetail;
  bool loadingClinics = false;
  bool loadingClinicDetail = false;

  // --- Remote Consultation State ---
  List<RemoteConsultationCardModel> remoteConsultations = [];
  RemoteConsultationDetailModel? remoteConsultationDetail;
  bool loadingRemoteConsultations = false;
  bool loadingRemoteConsultationDetail = false;

  // --- Shared State ---
  bool submitting = false;
  String? errorMessage;
  final Set<ClinicDocumentType> uploadingDocuments = <ClinicDocumentType>{};

  /// The current clinic draft ID being edited across steps.
  String? currentClinicDraftId;

  /// The current remote consultation draft ID being edited.
  String? currentRemoteConsultationDraftId;

  // ============================================================
  // ==================== Clinic Methods ========================
  // ============================================================

  /// Load all clinics for the authenticated doctor.
  Future<void> loadClinics() async {
    loadingClinics = true;
    errorMessage = null;
    notifyListeners();
    try {
      clinics = await _api.getDoctorClinics();
    } catch (e) {
      errorMessage = _cleanError(e);
      clinics = [];
    } finally {
      loadingClinics = false;
      notifyListeners();
    }
  }

  /// Load full detail of a specific clinic.
  Future<void> loadClinicDetail(String clinicId) async {
    loadingClinicDetail = true;
    errorMessage = null;
    if (clinicDetail?.clinicId != clinicId) {
      clinicDetail = null;
    }
    notifyListeners();
    try {
      clinicDetail = await _api.getClinicDetail(clinicId);
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      loadingClinicDetail = false;
      notifyListeners();
    }
  }

  /// Create a new clinic draft. Returns the clinicId.
  Future<String?> createClinic() async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _api.createClinicDraft();
      currentClinicDraftId = result.clinicId;
      return result.clinicId;
    } catch (e) {
      errorMessage = _cleanError(e);
      return null;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Helper method to safely normalize Arabic text for comparison
  String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .trim();
  }

  /// Look up governorate ID by its name from backend API
  Future<int?> getGovernorateIdByName(String name) async {
    errorMessage = null;
    try {
      final cities = await _api.getCities();
      final normalizedInput = _normalizeArabic(name);

      for (var city in cities) {
        final cityNameAr = _normalizeArabic(city['nameAr']?.toString() ?? '');
        if (cityNameAr.isNotEmpty && cityNameAr == normalizedInput) {
          return city['id'] as int?;
        }
      }
      errorMessage = 'عذراً، لم يتم العثور على تطابق للمحافظة المختارة في قاعدة بيانات الخادم';
      return null;
    } catch (e) {
      errorMessage = _cleanError(e);
      return null;
    }
  }

  /// Update Step 1 details. Returns true on success.
  Future<bool> updateClinicDetails(
    String clinicId, {
    String? name,
    int? governorateId,
    String? districtName,
    String? address,
    String? phone,
  }) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      clinicDetail = await _api.updateClinicDetails(
        clinicId,
        name: name,
        governorateId: governorateId,
        districtName: districtName,
        address: address,
        phone: phone,
      );
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Update Step 2 hours & pricing. Returns true on success.
  Future<bool> updateClinicHours(
    String clinicId, {
    String? workingHoursJson,
    double? examinationPrice,
    double? consultationPrice,
  }) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      clinicDetail = await _api.updateClinicHours(
        clinicId,
        workingHoursJson: workingHoursJson,
        examinationPrice: examinationPrice,
        consultationPrice: consultationPrice,
      );
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Upload a clinic document (Step 3). Returns true on success.
  Future<bool> uploadClinicDocument(
    String clinicId,
    ClinicDocumentType documentType,
    XFile file,
  ) async {
    uploadingDocuments.add(documentType);
    errorMessage = null;
    notifyListeners();
    try {
      await _api.uploadClinicDocument(clinicId, documentType, file);
      // Refresh detail to get updated URLs
      await loadClinicDetail(clinicId);
      return true;
    } catch (e) {
      errorMessage = 'فشل رفع الصورة، حاول مرة أخرى';
      return false;
    } finally {
      uploadingDocuments.remove(documentType);
      notifyListeners();
    }
  }

  /// Pick and upload a clinic document image.
  Future<bool> pickAndUploadClinicDocument(
    String clinicId,
    ClinicDocumentType documentType,
  ) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return false;
    return uploadClinicDocument(clinicId, documentType, file);
  }

  /// Submit clinic for admin review.
  Future<bool> submitClinic(String clinicId) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.submitClinic(clinicId);
      await loadClinics();
      clinicDetail = null;
      currentClinicDraftId = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Cancel a clinic request.
  Future<bool> cancelClinic(String clinicId) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.cancelClinic(clinicId);
      await loadClinics();
      clinicDetail = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Pull a pending clinic back to Draft for editing.
  Future<bool> startEditClinic(String clinicId) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.startEditClinic(clinicId);
      await loadClinicDetail(clinicId);
      await loadClinics();
      currentClinicDraftId = clinicId;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ============ Remote Consultation Methods ===================
  // ============================================================

  /// Load all remote consultations for the authenticated doctor.
  Future<void> loadRemoteConsultations() async {
    loadingRemoteConsultations = true;
    errorMessage = null;
    notifyListeners();
    try {
      remoteConsultations = await _api.getDoctorRemoteConsultations();
    } catch (e) {
      errorMessage = _cleanError(e);
      remoteConsultations = [];
    } finally {
      loadingRemoteConsultations = false;
      notifyListeners();
    }
  }

  /// Load full detail of a specific remote consultation.
  Future<void> loadRemoteConsultationDetail(String id) async {
    loadingRemoteConsultationDetail = true;
    errorMessage = null;
    if (remoteConsultationDetail?.consultationId != id) {
      remoteConsultationDetail = null;
    }
    notifyListeners();
    try {
      remoteConsultationDetail = await _api.getRemoteConsultationDetail(id);
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      loadingRemoteConsultationDetail = false;
      notifyListeners();
    }
  }

  /// Create a new remote consultation draft. Returns the consultationId.
  Future<String?> createRemoteConsultation() async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _api.createRemoteConsultationDraft();
      currentRemoteConsultationDraftId = result.consultationId;
      return result.consultationId;
    } catch (e) {
      errorMessage = _cleanError(e);
      return null;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Update remote consultation fields.
  Future<bool> updateRemoteConsultation(
    String id, {
    double? sessionPrice,
    int? sessionDurationMinutes,
    int? waitingPeriodMinutes,
    String? workingHoursJson,
  }) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      remoteConsultationDetail = await _api.updateRemoteConsultation(
        id,
        sessionPrice: sessionPrice,
        sessionDurationMinutes: sessionDurationMinutes,
        waitingPeriodMinutes: waitingPeriodMinutes,
        workingHoursJson: workingHoursJson,
      );
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Submit remote consultation for admin review.
  Future<bool> submitRemoteConsultation(String id) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.submitRemoteConsultation(id);
      await loadRemoteConsultations();
      remoteConsultationDetail = null;
      currentRemoteConsultationDraftId = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Cancel a remote consultation request.
  Future<bool> cancelRemoteConsultation(String id) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.cancelRemoteConsultation(id);
      await loadRemoteConsultations();
      remoteConsultationDetail = null;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  /// Pull a pending remote consultation back to Draft.
  Future<bool> startEditRemoteConsultation(String id) async {
    submitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.startEditRemoteConsultation(id);
      await loadRemoteConsultationDetail(id);
      await loadRemoteConsultations();
      currentRemoteConsultationDraftId = id;
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ==================== Helpers ===============================
  // ============================================================

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
