// --- Models for Clinic & Remote Consultation API ---
// Follows same pattern as specialist_application_models.dart

import 'package:Ajial/specialist-app/application-tracking/models/specialist_application_models.dart'
    show ApiResponse;

// ============================================================
// ==================== Clinic Models =========================
// ============================================================

/// Summary card for a clinic in the doctor's list.
class ClinicCardModel {
  final String clinicId;
  final String name;
  final String status;
  final String statusAr;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final bool canEdit;
  final bool canCancel;
  final bool canSubmit;

  const ClinicCardModel({
    required this.clinicId,
    required this.name,
    required this.status,
    required this.statusAr,
    this.submittedAt,
    this.rejectionReason,
    required this.canEdit,
    required this.canCancel,
    required this.canSubmit,
  });

  factory ClinicCardModel.fromJson(Map<String, dynamic> json) {
    return ClinicCardModel(
      clinicId: _read(json, 'clinicId').toString(),
      name: _read(json, 'name').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
      canEdit: _read(json, 'canEdit') == true,
      canCancel: _read(json, 'canCancel') == true,
      canSubmit: _read(json, 'canSubmit') == true,
    );
  }
}

/// Full detail of a clinic (all 3 steps + capability flags).
class ClinicDetailModel {
  final String clinicId;
  final String status;
  final String statusAr;
  final DateTime? submittedAt;
  final String? rejectionReason;

  // Step 1 — تفاصيل العيادة
  final String? name;
  final int? governorateId;
  final String? governorateName;
  final String? districtName;
  final String? address;
  final String? phone;

  // Step 2 — اوقات العمل و التكلفة
  final String? workingHoursJson;
  final double? examinationPrice;
  final double? consultationPrice;

  // Step 3 — بيانات ترخيص العيادة
  final String? licenseImageUrl;
  final String? syndicateRegistrationImageUrl;
  final String? hazardousWasteImageUrl;
  final String? exteriorImageUrl;
  final String? interiorImageUrl;

  // Capability flags
  final bool canEdit;
  final bool canCancel;
  final bool canSubmit;

  const ClinicDetailModel({
    required this.clinicId,
    required this.status,
    required this.statusAr,
    this.submittedAt,
    this.rejectionReason,
    this.name,
    this.governorateId,
    this.governorateName,
    this.districtName,
    this.address,
    this.phone,
    this.workingHoursJson,
    this.examinationPrice,
    this.consultationPrice,
    this.licenseImageUrl,
    this.syndicateRegistrationImageUrl,
    this.hazardousWasteImageUrl,
    this.exteriorImageUrl,
    this.interiorImageUrl,
    required this.canEdit,
    required this.canCancel,
    required this.canSubmit,
  });

  factory ClinicDetailModel.fromJson(Map<String, dynamic> json) {
    return ClinicDetailModel(
      clinicId: _read(json, 'clinicId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
      name: _nullableString(_read(json, 'name')),
      governorateId: _parseInt(_read(json, 'governorateId')),
      governorateName: _nullableString(_read(json, 'governorateName')),
      districtName: _nullableString(_read(json, 'districtName')),
      address: _nullableString(_read(json, 'address')),
      phone: _nullableString(_read(json, 'phone')),
      workingHoursJson: _nullableString(_read(json, 'workingHoursJson')),
      examinationPrice: _parseDouble(_read(json, 'examinationPrice')),
      consultationPrice: _parseDouble(_read(json, 'consultationPrice')),
      licenseImageUrl: _nullableString(_read(json, 'licenseImageUrl')),
      syndicateRegistrationImageUrl:
          _nullableString(_read(json, 'syndicateRegistrationImageUrl')),
      hazardousWasteImageUrl:
          _nullableString(_read(json, 'hazardousWasteImageUrl')),
      exteriorImageUrl: _nullableString(_read(json, 'exteriorImageUrl')),
      interiorImageUrl: _nullableString(_read(json, 'interiorImageUrl')),
      canEdit: _read(json, 'canEdit') == true,
      canCancel: _read(json, 'canCancel') == true,
      canSubmit: _read(json, 'canSubmit') == true,
    );
  }
}

/// Response for status-change operations (submit, cancel, start-edit, create).
class ClinicStatusChangeModel {
  final String clinicId;
  final String status;
  final String statusAr;

  const ClinicStatusChangeModel({
    required this.clinicId,
    required this.status,
    required this.statusAr,
  });

  factory ClinicStatusChangeModel.fromJson(Map<String, dynamic> json) {
    return ClinicStatusChangeModel(
      clinicId: _read(json, 'clinicId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
    );
  }
}

/// Response for document upload.
class ClinicDocumentUploadModel {
  final String documentType;
  final String url;

  const ClinicDocumentUploadModel({
    required this.documentType,
    required this.url,
  });

  factory ClinicDocumentUploadModel.fromJson(Map<String, dynamic> json) {
    return ClinicDocumentUploadModel(
      documentType: _read(json, 'documentType').toString(),
      url: _read(json, 'url').toString(),
    );
  }
}

// ============================================================
// ============== Remote Consultation Models ==================
// ============================================================

/// Summary card for a remote consultation in the doctor's list.
class RemoteConsultationCardModel {
  final String consultationId;
  final String status;
  final String statusAr;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final bool canEdit;
  final bool canCancel;
  final bool canSubmit;

  const RemoteConsultationCardModel({
    required this.consultationId,
    required this.status,
    required this.statusAr,
    this.submittedAt,
    this.rejectionReason,
    required this.canEdit,
    required this.canCancel,
    required this.canSubmit,
  });

  factory RemoteConsultationCardModel.fromJson(Map<String, dynamic> json) {
    return RemoteConsultationCardModel(
      consultationId: _read(json, 'consultationId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
      canEdit: _read(json, 'canEdit') == true,
      canCancel: _read(json, 'canCancel') == true,
      canSubmit: _read(json, 'canSubmit') == true,
    );
  }
}

/// Full detail of a remote consultation.
class RemoteConsultationDetailModel {
  final String consultationId;
  final String status;
  final String statusAr;
  final DateTime? submittedAt;
  final String? rejectionReason;

  final double? sessionPrice;
  final int? sessionDurationMinutes;
  final int? waitingPeriodMinutes;
  final String? workingHoursJson;

  final bool canEdit;
  final bool canCancel;
  final bool canSubmit;

  const RemoteConsultationDetailModel({
    required this.consultationId,
    required this.status,
    required this.statusAr,
    this.submittedAt,
    this.rejectionReason,
    this.sessionPrice,
    this.sessionDurationMinutes,
    this.waitingPeriodMinutes,
    this.workingHoursJson,
    required this.canEdit,
    required this.canCancel,
    required this.canSubmit,
  });

  factory RemoteConsultationDetailModel.fromJson(Map<String, dynamic> json) {
    return RemoteConsultationDetailModel(
      consultationId: _read(json, 'consultationId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
      sessionPrice: _parseDouble(_read(json, 'sessionPrice')),
      sessionDurationMinutes: _parseInt(_read(json, 'sessionDurationMinutes')),
      waitingPeriodMinutes: _parseInt(_read(json, 'waitingPeriodMinutes')),
      workingHoursJson: _nullableString(_read(json, 'workingHoursJson')),
      canEdit: _read(json, 'canEdit') == true,
      canCancel: _read(json, 'canCancel') == true,
      canSubmit: _read(json, 'canSubmit') == true,
    );
  }
}

/// Response for remote consultation status-change operations.
class RemoteConsultationStatusChangeModel {
  final String consultationId;
  final String status;
  final String statusAr;

  const RemoteConsultationStatusChangeModel({
    required this.consultationId,
    required this.status,
    required this.statusAr,
  });

  factory RemoteConsultationStatusChangeModel.fromJson(
      Map<String, dynamic> json) {
    return RemoteConsultationStatusChangeModel(
      consultationId: _read(json, 'consultationId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
    );
  }
}

// ============================================================
// ==================== Enums =================================
// ============================================================

/// Clinic document type enum values for upload endpoint.
enum ClinicDocumentType {
  licenseImage(1),
  syndicateRegistrationImage(2),
  hazardousWasteImage(3),
  exteriorImage(4),
  interiorImage(5);

  final int value;
  const ClinicDocumentType(this.value);
}

// ============================================================
// ==================== Helpers ===============================
// ============================================================

/// Reads a key from JSON with case-insensitive fallback (camelCase / PascalCase).
dynamic _read(Map<String, dynamic> json, String key) {
  final pascal =
      key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  return json[key] ?? json[pascal] ?? '';
}

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

DateTime? _parseDate(dynamic value) {
  final text = _nullableString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  final text = _nullableString(value);
  if (text == null) return null;
  return int.tryParse(text);
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  final text = _nullableString(value);
  if (text == null) return null;
  return double.tryParse(text);
}
