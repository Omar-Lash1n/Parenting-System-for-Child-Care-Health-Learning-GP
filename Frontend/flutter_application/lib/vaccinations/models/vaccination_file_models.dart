// lib/vaccinations/models/vaccination_file_models.dart
//
// Data models for GET /api/Vaccination/file/{childId}

/// A single vaccination card (used in both main and additional sections).
class VaccinationCardDto {
  final int milestoneId;
  final String nameAr;
  final String nameEn;
  final String vaccinesAr;
  final String vaccinesEn;

  /// Arabic badge label: "حالي" / "فائت" / "قادم" / "تم"
  final String label;

  /// English badge label for filter logic: "Current" / "Missed" / "Upcoming" / "Done"
  final String labelEn;

  final String dueDate;
  final String dueDateFormatted;

  /// Toggle switch value (true = ON)
  final bool isTaken;

  /// Toggle switch enabled state (true = locked/disabled)
  final bool isDisabled;

  /// Only non-null when labelEn == "Missed"
  final int? missedSinceDays;

  final String? completedDate;

  /// Only non-null when labelEn == "Done"
  final String? completedDateFormatted;

  const VaccinationCardDto({
    required this.milestoneId,
    required this.nameAr,
    required this.nameEn,
    required this.vaccinesAr,
    required this.vaccinesEn,
    required this.label,
    required this.labelEn,
    required this.dueDate,
    required this.dueDateFormatted,
    required this.isTaken,
    required this.isDisabled,
    this.missedSinceDays,
    this.completedDate,
    this.completedDateFormatted,
  });

  VaccinationCardDto copyWith({
    int? milestoneId,
    String? nameAr,
    String? nameEn,
    String? vaccinesAr,
    String? vaccinesEn,
    String? label,
    String? labelEn,
    String? dueDate,
    String? dueDateFormatted,
    bool? isTaken,
    bool? isDisabled,
    int? missedSinceDays,
    String? completedDate,
    String? completedDateFormatted,
  }) {
    return VaccinationCardDto(
      milestoneId: milestoneId ?? this.milestoneId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      vaccinesAr: vaccinesAr ?? this.vaccinesAr,
      vaccinesEn: vaccinesEn ?? this.vaccinesEn,
      label: label ?? this.label,
      labelEn: labelEn ?? this.labelEn,
      dueDate: dueDate ?? this.dueDate,
      dueDateFormatted: dueDateFormatted ?? this.dueDateFormatted,
      isTaken: isTaken ?? this.isTaken,
      isDisabled: isDisabled ?? this.isDisabled,
      missedSinceDays: missedSinceDays ?? this.missedSinceDays,
      completedDate: completedDate ?? this.completedDate,
      completedDateFormatted: completedDateFormatted ?? this.completedDateFormatted,
    );
  }

  factory VaccinationCardDto.fromJson(Map<String, dynamic> json) {
    return VaccinationCardDto(
      milestoneId: json['milestoneId'] as int,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      vaccinesAr: json['vaccinesAr'] as String,
      vaccinesEn: json['vaccinesEn'] as String,
      label: json['label'] as String,
      labelEn: json['labelEn'] as String,
      dueDate: json['dueDate'] as String,
      dueDateFormatted: json['dueDateFormatted'] as String,
      isTaken: json['isTaken'] as bool,
      isDisabled: json['isDisabled'] as bool,
      missedSinceDays: json['missedSinceDays'] as int?,
      completedDate: json['completedDate'] as String?,
      completedDateFormatted: json['completedDateFormatted'] as String?,
    );
  }
}

/// Main vaccinations section (0–18 months).
class MainVaccinationSectionDto {
  final int allCount;
  final int currentCount;
  final int missedCount;
  final int upcomingCount;
  final int doneCount;
  final List<VaccinationCardDto> vaccinations;

  const MainVaccinationSectionDto({
    required this.allCount,
    required this.currentCount,
    required this.missedCount,
    required this.upcomingCount,
    required this.doneCount,
    required this.vaccinations,
  });

  MainVaccinationSectionDto copyWith({
    int? allCount,
    int? currentCount,
    int? missedCount,
    int? upcomingCount,
    int? doneCount,
    List<VaccinationCardDto>? vaccinations,
  }) {
    return MainVaccinationSectionDto(
      allCount: allCount ?? this.allCount,
      currentCount: currentCount ?? this.currentCount,
      missedCount: missedCount ?? this.missedCount,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      doneCount: doneCount ?? this.doneCount,
      vaccinations: vaccinations ?? this.vaccinations,
    );
  }

  factory MainVaccinationSectionDto.fromJson(Map<String, dynamic> json) {
    final list = (json['vaccinations'] as List<dynamic>? ?? [])
        .map((e) => VaccinationCardDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return MainVaccinationSectionDto(
      allCount: json['allCount'] as int,
      currentCount: json['currentCount'] as int,
      missedCount: json['missedCount'] as int,
      upcomingCount: json['upcomingCount'] as int,
      doneCount: json['doneCount'] as int,
      vaccinations: list,
    );
  }
}

/// Additional vaccinations section (4–15 years).
class AdditionalVaccinationSectionDto {
  /// If false, hide the entire additional tab from the UI.
  final bool isAvailable;
  final int allCount;
  final int upcomingCount;
  final int doneCount;
  final List<VaccinationCardDto> vaccinations;

  const AdditionalVaccinationSectionDto({
    required this.isAvailable,
    required this.allCount,
    required this.upcomingCount,
    required this.doneCount,
    required this.vaccinations,
  });

  AdditionalVaccinationSectionDto copyWith({
    bool? isAvailable,
    int? allCount,
    int? upcomingCount,
    int? doneCount,
    List<VaccinationCardDto>? vaccinations,
  }) {
    return AdditionalVaccinationSectionDto(
      isAvailable: isAvailable ?? this.isAvailable,
      allCount: allCount ?? this.allCount,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      doneCount: doneCount ?? this.doneCount,
      vaccinations: vaccinations ?? this.vaccinations,
    );
  }

  factory AdditionalVaccinationSectionDto.fromJson(Map<String, dynamic> json) {
    final list = (json['vaccinations'] as List<dynamic>? ?? [])
        .map((e) => VaccinationCardDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdditionalVaccinationSectionDto(
      isAvailable: json['isAvailable'] as bool,
      allCount: json['allCount'] as int? ?? 0,
      upcomingCount: json['upcomingCount'] as int? ?? 0,
      doneCount: json['doneCount'] as int? ?? 0,
      vaccinations: list,
    );
  }
}

/// Top-level response DTO for GET /api/Vaccination/file/{childId}.
class GetVaccinationFileResponseDto {
  final String childId;
  final String childName;
  final String? childImageUrl;
  final int ageMonths;
  final int ageDays;
  final String ageFormatted;
  final MainVaccinationSectionDto mainVaccinations;
  final AdditionalVaccinationSectionDto additionalVaccinations;

  const GetVaccinationFileResponseDto({
    required this.childId,
    required this.childName,
    this.childImageUrl,
    required this.ageMonths,
    required this.ageDays,
    required this.ageFormatted,
    required this.mainVaccinations,
    required this.additionalVaccinations,
  });

  GetVaccinationFileResponseDto copyWith({
    String? childId,
    String? childName,
    String? childImageUrl,
    int? ageMonths,
    int? ageDays,
    String? ageFormatted,
    MainVaccinationSectionDto? mainVaccinations,
    AdditionalVaccinationSectionDto? additionalVaccinations,
  }) {
    return GetVaccinationFileResponseDto(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      childImageUrl: childImageUrl ?? this.childImageUrl,
      ageMonths: ageMonths ?? this.ageMonths,
      ageDays: ageDays ?? this.ageDays,
      ageFormatted: ageFormatted ?? this.ageFormatted,
      mainVaccinations: mainVaccinations ?? this.mainVaccinations,
      additionalVaccinations: additionalVaccinations ?? this.additionalVaccinations,
    );
  }

  factory GetVaccinationFileResponseDto.fromJson(Map<String, dynamic> json) {
    return GetVaccinationFileResponseDto(
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      childImageUrl: json['childImageUrl'] as String?,
      ageMonths: json['ageMonths'] as int,
      ageDays: json['ageDays'] as int,
      ageFormatted: json['ageFormatted'] as String,
      mainVaccinations: MainVaccinationSectionDto.fromJson(
          json['mainVaccinations'] as Map<String, dynamic>),
      additionalVaccinations: AdditionalVaccinationSectionDto.fromJson(
          json['additionalVaccinations'] as Map<String, dynamic>),
    );
  }
}

class ToggleVaccinationRequestDto {
  final String childId;
  final int milestoneId;
  final bool isTaken;

  const ToggleVaccinationRequestDto({
    required this.childId,
    required this.milestoneId,
    required this.isTaken,
  });

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'milestoneId': milestoneId,
      'isTaken': isTaken,
    };
  }
}
