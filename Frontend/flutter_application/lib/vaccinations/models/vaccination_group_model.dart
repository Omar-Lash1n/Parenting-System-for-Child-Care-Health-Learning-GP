// --- lib/vaccinations/models/vaccination_group_model.dart ---

/// Represents one vaccination age-group (milestone) shown in the survey screen.
///
/// Each group maps to a row in the scrollable checklist. Can be constructed
/// from the API response via [VaccinationGroupModel.fromJson] or using the
/// hardcoded [defaultGroups] / [additionalGroups] fallbacks.
class VaccinationGroupModel {
  /// Unique identifier — milestoneId from the API (e.g., `"1"`, `"3"`).
  final String id;

  /// Arabic heading displayed in bold (e.g., `"تطعيم الولادة"`).
  final String title;

  /// Arabic description listing the vaccines in this group.
  final String subtitle;

  /// Age threshold in months (0 = birth, 4, 6, etc.).
  final int ageInMonths;

  /// Whether the API says this milestone is disabled (future milestone).
  final bool isDisabled;

  /// Whether the API says this milestone should be auto-selected (past milestone).
  final bool isAutoSelected;

  /// Whether the child has already taken this vaccination.
  final bool isTaken;

  /// Status string from API: "Past", "Current", or "Future".
  final String status;

  const VaccinationGroupModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ageInMonths,
    this.isDisabled = false,
    this.isAutoSelected = false,
    this.isTaken = false,
    this.status = '',
  });

  /// Creates a [VaccinationGroupModel] from an API milestone JSON object.
  factory VaccinationGroupModel.fromJson(Map<String, dynamic> json) {
    // Support both ageInMonths (basic survey) and ageInYears (additional survey).
    int age = json['ageInMonths'] ?? 0;
    if (age == 0 && json['ageInYears'] != null) {
      age = (json['ageInYears'] as int) * 12;
    }

    return VaccinationGroupModel(
      id: json['milestoneId']?.toString() ?? '',
      title: json['nameAr']?.toString() ?? '',
      subtitle: json['vaccinesAr']?.toString() ?? '',
      ageInMonths: age,
      isDisabled: json['isDisabled'] ?? false,
      isAutoSelected: json['isAutoSelected'] ?? false,
      isTaken: json['isTaken'] ?? false,
      status: json['status']?.toString() ?? '',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Static Hardcoded Data — Main (Basic) Vaccinations
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the full ordered list of **basic** vaccination groups.
  ///
  /// Ordered by [ageInMonths] ascending so that the sequential-selection
  /// logic enforced by the provider works correctly.
  ///
  /// Used as fallback when the API is not available.
  static List<VaccinationGroupModel> defaultGroups() {
    return const [
      VaccinationGroupModel(
        id: 'birth',
        title: 'تطعيم الولادة',
        ageInMonths: 0,
        subtitle: 'كبدى ب رضع شلل أطفال فموى، طعم ب ج ب',
      ),
      VaccinationGroupModel(
        id: '2months',
        title: 'تطعيم شهرين',
        ageInMonths: 2,
        subtitle: 'شلل أطفال (فموى)، الطعم الخماسي',
      ),
      VaccinationGroupModel(
        id: '4months',
        title: 'تطعيم 4 شهور',
        ageInMonths: 4,
        subtitle: 'شلل أطفال (فموى)، الطعم الخماسي، شلل أطفال (حقن)',
      ),
      VaccinationGroupModel(
        id: '6months',
        title: 'تطعيم 6 شهور',
        ageInMonths: 6,
        subtitle: 'شلل أطفال (فموى)، الطعم الخماسي، شلل أطفال (حقن)',
      ),
      VaccinationGroupModel(
        id: '9months',
        title: 'تطعيم 9 شهر',
        ageInMonths: 9,
        subtitle: 'شلل',
      ),
      VaccinationGroupModel(
        id: '12months',
        title: 'تطعيم 12 شهر',
        ageInMonths: 12,
        subtitle: 'شلل أطفال (فموى)، اللقاح الثلاثي',
      ),
      VaccinationGroupModel(
        id: '18months',
        title: 'تطعيم 18 شهر',
        ageInMonths: 18,
        subtitle: 'الثلاثي (التنشيطي)',
      ),
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Static Hardcoded Data — Additional (School-Age) Vaccinations
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the ordered list of **additional** school-age vaccination groups.
  ///
  /// Used as fallback when the API is not available.
  static List<VaccinationGroupModel> additionalGroups() {
    return const [
      VaccinationGroupModel(
        id: 'nursery_4y',
        title: 'تطعيم أولى حضانة (4 سنوات)',
        ageInMonths: 48,
        subtitle: 'المكورات السحائية الثلاثي',
      ),
      VaccinationGroupModel(
        id: 'primary_6y',
        title: 'تطعيم أولى ابتدائى (6 سنوات)',
        ageInMonths: 72,
        subtitle: 'المكورات السحائية الثلاثي',
      ),
      VaccinationGroupModel(
        id: 'primary2_7y',
        title: 'تطعيم ثانية ابتدائى (7 سنوات)',
        ageInMonths: 84,
        subtitle: 'الثلاثي البكتيري',
      ),
      VaccinationGroupModel(
        id: 'primary4_10y',
        title: 'تطعيم رابعة ابتدائى (10 سنوات)',
        ageInMonths: 120,
        subtitle: 'الثلاثي البكتيري',
      ),
      VaccinationGroupModel(
        id: 'prep_12y',
        title: 'تطعيم أولى إعدادى (12 سنة)',
        ageInMonths: 144,
        subtitle: 'المكورات السحائية الثلاثي',
      ),
      VaccinationGroupModel(
        id: 'sec_15y',
        title: 'تطعيم أولى ثانوى (15 سنة)',
        ageInMonths: 180,
        subtitle: 'المكورات السحائية الثلاثي',
      ),
    ];
  }
}
