// lib/tasks/models/child_task_model.dart
//
// Model for the children list returned by:
//   GET /api/ChildTask/parent/{parentId}/children
//
// Possible childStatus values:
//   "eligible"       → age >= 4, has account, account is active
//   "locked_by_age"  → age < 4, tasks feature locked
//   (account checks) → age >= 4 but hasAccount == false OR isAccountActive == false

class ChildTaskModel {
  final String childId;
  final String fullName;
  final String? profileImageUrl;
  final DateTime? birthDate;
  final int ageYears;
  final int ageMonths;

  /// "eligible" | "locked_by_age" | others
  final String childStatus;

  final bool childTasksLocked;
  final String? lockedReason;

  /// Only present when status == "eligible"
  final int totalStars;
  final int pendingTasksCount;

  /// Whether the child has a login account (absent means false)
  final bool hasAccount;

  /// Whether the child account is active (absent means false)
  final bool isAccountActive;

  const ChildTaskModel({
    required this.childId,
    required this.fullName,
    this.profileImageUrl,
    this.birthDate,
    required this.ageYears,
    required this.ageMonths,
    required this.childStatus,
    required this.childTasksLocked,
    this.lockedReason,
    this.totalStars = 0,
    this.pendingTasksCount = 0,
    this.hasAccount = false,
    this.isAccountActive = false,
  });

  factory ChildTaskModel.fromJson(Map<String, dynamic> json) {
    return ChildTaskModel(
      childId: json['childId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
      ageYears: json['ageYears'] as int? ?? 0,
      ageMonths: json['ageMonths'] as int? ?? 0,
      childStatus: json['childStatus'] as String? ?? '',
      childTasksLocked: json['childTasksLocked'] as bool? ?? false,
      lockedReason: json['lockedReason'] as String?,
      totalStars: json['totalStars'] as int? ?? 0,
      pendingTasksCount: json['pendingTasksCount'] as int? ?? 0,
      hasAccount: json['hasAccount'] as bool? ?? false,
      isAccountActive: json['isAccountActive'] as bool? ?? false,
    );
  }

  /// Human-readable age in Arabic.
  String get ageText {
    if (ageYears == 0) {
      if (ageMonths == 0) return 'أقل من شهر';
      if (ageMonths == 1) return 'شهر واحد';
      return '$ageMonths أشهر';
    }
    final yearPart = ageYears == 1
        ? 'سنة واحدة'
        : ageYears == 2
            ? 'سنتان'
            : '$ageYears سنوات';
    if (ageMonths == 0) return yearPart;
    return '$yearPart , $ageMonths أشهر';
  }

  /// True when the child is old enough, has an active account, and tasks aren't locked.
  bool get isEligible => childStatus == 'eligible' && !childTasksLocked;

  /// True when the child is < 4 years old (tasks permanently locked).
  bool get isLockedByAge => childStatus == 'locked_by_age' || childTasksLocked;

  /// True when age >= 4 but no account yet.
  bool get needsAccountCreation => ageYears >= 4 && !hasAccount;

  /// True when age >= 4, has an account, but account is not activated.
  bool get needsAccountActivation => ageYears >= 4 && hasAccount && !isAccountActive;
}
