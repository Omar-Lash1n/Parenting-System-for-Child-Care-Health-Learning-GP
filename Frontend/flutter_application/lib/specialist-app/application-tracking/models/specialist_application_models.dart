class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic value) parser,
  ) {
    final rawErrors = json['errors'] ?? json['Errors'];
    return ApiResponse<T>(
      success: (json['success'] ?? json['Success']) == true,
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      data: json['data'] == null && json['Data'] == null
          ? null
          : parser(json['data'] ?? json['Data']),
      errors: rawErrors is List
          ? rawErrors.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}

class SpecialistCurrentApplicationModel {
  final String applicationId;
  final String specialistId;
  final String specialtyName;
  final DateTime? submittedAt;
  final String status;
  final String statusAr;
  final String? rejectionReason;
  final bool canView;
  final bool canEdit;
  final bool canCancel;
  final bool canCreateNew;
  final String? personalPhotoUrl;

  const SpecialistCurrentApplicationModel({
    required this.applicationId,
    required this.specialistId,
    required this.specialtyName,
    required this.submittedAt,
    required this.status,
    required this.statusAr,
    required this.rejectionReason,
    required this.canView,
    required this.canEdit,
    required this.canCancel,
    required this.canCreateNew,
    required this.personalPhotoUrl,
  });

  factory SpecialistCurrentApplicationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SpecialistCurrentApplicationModel(
      applicationId: _read(json, 'applicationId').toString(),
      specialistId: _read(json, 'specialistId').toString(),
      specialtyName: _read(json, 'specialtyName').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
      canView: _read(json, 'canView') == true,
      canEdit: _read(json, 'canEdit') == true,
      canCancel: _read(json, 'canCancel') == true,
      canCreateNew: _read(json, 'canCreateNew') == true,
      personalPhotoUrl: _nullableString(_read(json, 'personalPhotoUrl')),
    );
  }
}

class SpecialistApplicationDetailsModel {
  final String applicationId;
  final String status;
  final String statusAr;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final IdentityDataModel identityData;
  final ProfessionalDataModel professionalData;
  final bool canEdit;
  final bool canCancel;

  const SpecialistApplicationDetailsModel({
    required this.applicationId,
    required this.status,
    required this.statusAr,
    required this.submittedAt,
    required this.rejectionReason,
    required this.identityData,
    required this.professionalData,
    required this.canEdit,
    required this.canCancel,
  });

  factory SpecialistApplicationDetailsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SpecialistApplicationDetailsModel(
      applicationId: _read(json, 'applicationId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
      identityData: IdentityDataModel.fromJson(
        Map<String, dynamic>.from(_read(json, 'identityData') as Map? ?? {}),
      ),
      professionalData: ProfessionalDataModel.fromJson(
        Map<String, dynamic>.from(
          _read(json, 'professionalData') as Map? ?? {},
        ),
      ),
      canEdit: _read(json, 'canEdit') == true,
      canCancel: _read(json, 'canCancel') == true,
    );
  }
}

class IdentityDataModel {
  final String? nationalIdFrontUrl;
  final bool nationalIdFrontUploaded;
  final String? nationalIdBackUrl;
  final bool nationalIdBackUploaded;
  final String? personalPhotoUrl;
  final bool personalPhotoUploaded;

  const IdentityDataModel({
    this.nationalIdFrontUrl,
    this.nationalIdFrontUploaded = false,
    this.nationalIdBackUrl,
    this.nationalIdBackUploaded = false,
    this.personalPhotoUrl,
    this.personalPhotoUploaded = false,
  });

  factory IdentityDataModel.fromJson(Map<String, dynamic> json) {
    return IdentityDataModel(
      nationalIdFrontUrl: _nullableString(_read(json, 'nationalIdFrontUrl')),
      nationalIdFrontUploaded: _read(json, 'nationalIdFrontUploaded') == true,
      nationalIdBackUrl: _nullableString(_read(json, 'nationalIdBackUrl')),
      nationalIdBackUploaded: _read(json, 'nationalIdBackUploaded') == true,
      personalPhotoUrl: _nullableString(_read(json, 'personalPhotoUrl')),
      personalPhotoUploaded: _read(json, 'personalPhotoUploaded') == true,
    );
  }
}

class ProfessionalDataModel {
  final String specialtyName;
  final int? specialtyId;
  final String? specializationCertificateUrl;
  final bool specializationCertificateUploaded;
  final String practiceLicenseNumber;
  final String? professionalLicenseUrl;
  final bool professionalLicenseUploaded;
  final String? syndicateCardUrl;
  final bool syndicateCardUploaded;

  const ProfessionalDataModel({
    required this.specialtyName,
    required this.specialtyId,
    this.specializationCertificateUrl,
    required this.specializationCertificateUploaded,
    required this.practiceLicenseNumber,
    this.professionalLicenseUrl,
    required this.professionalLicenseUploaded,
    this.syndicateCardUrl,
    required this.syndicateCardUploaded,
  });

  factory ProfessionalDataModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalDataModel(
      specialtyName: _read(json, 'specialtyName').toString(),
      specialtyId: int.tryParse(_read(json, 'specialtyId').toString()),
      specializationCertificateUrl:
          _nullableString(_read(json, 'specializationCertificateUrl')),
      specializationCertificateUploaded:
          _read(json, 'specializationCertificateUploaded') == true,
      practiceLicenseNumber: _read(json, 'practiceLicenseNumber').toString(),
      professionalLicenseUrl:
          _nullableString(_read(json, 'professionalLicenseUrl')),
      professionalLicenseUploaded:
          _read(json, 'professionalLicenseUploaded') == true,
      syndicateCardUrl: _nullableString(_read(json, 'syndicateCardUrl')),
      syndicateCardUploaded: _read(json, 'syndicateCardUploaded') == true,
    );
  }
}

class DocumentInfoModel {
  final String documentType;
  final String? documentUrl;
  final bool uploaded;

  const DocumentInfoModel({
    required this.documentType,
    required this.documentUrl,
    required this.uploaded,
  });

  factory DocumentInfoModel.fromJson(Map<String, dynamic> json) {
    return DocumentInfoModel(
      documentType: _read(json, 'documentType').toString(),
      documentUrl: _nullableString(_read(json, 'documentUrl')),
      uploaded: _read(json, 'uploaded') == true,
    );
  }
}

class SpecialtyModel {
  final int id;
  final String nameAr;
  final String nameEn;

  const SpecialtyModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: int.tryParse(_read(json, 'id').toString()) ?? 0,
      nameAr: _read(json, 'nameAr').toString(),
      nameEn: _read(json, 'nameEn').toString(),
    );
  }
}

class StatusChangeResponseModel {
  final String applicationId;
  final String status;
  final String statusAr;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const StatusChangeResponseModel({
    required this.applicationId,
    required this.status,
    required this.statusAr,
    required this.submittedAt,
    required this.reviewedAt,
    required this.rejectionReason,
  });

  factory StatusChangeResponseModel.fromJson(Map<String, dynamic> json) {
    return StatusChangeResponseModel(
      applicationId: _read(json, 'applicationId').toString(),
      status: _read(json, 'status').toString(),
      statusAr: _read(json, 'statusAr').toString(),
      submittedAt: _parseDate(_read(json, 'submittedAt')),
      reviewedAt: _parseDate(_read(json, 'reviewedAt')),
      rejectionReason: _nullableString(_read(json, 'rejectionReason')),
    );
  }
}

dynamic _read(Map<String, dynamic> json, String key) {
  final pascal = key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
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
