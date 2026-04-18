// lib/family/models/child_model.dart
//
// Freezed data model for a single child returned by GET /Parents/children.
// Run `dart run build_runner build` to generate child_model.freezed.dart
// and child_model.g.dart.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'child_model.freezed.dart';
part 'child_model.g.dart';

/// Represents a single child object from the API response.
///
/// Example JSON:
/// ```json
/// {
///   "childId":    "e021500a-...",
///   "fullName":   "محمد اسلام",
///   "photoUrl":   "https://...",
///   "age":        6,
///   "isActive":   true,
///   "hasAccount": true,
///   "prizeCount": 0
/// }
/// ```
@freezed
class ChildModel with _$ChildModel {
  const ChildModel._(); // enables computed getters

  const factory ChildModel({
    /// Unique identifier for the child.
    required String childId,

    /// Child's full name in Arabic.
    required String fullName,

    /// Remote URL to the child's profile photo. May be null.
    String? photoUrl,

    /// Age in years.
    required int age,

    /// Whether the child currently has an active session (shows green dot).
    required bool isActive,

    /// Whether the child has a login account.
    required bool hasAccount,

    /// Total number of prizes the child has earned.
    @Default(0) int prizeCount,
  }) = _ChildModel;

  /// Human-readable age string in Arabic (e.g. "6 سنوات").
  String get ageText {
    if (age == 0) return 'أقل من سنة';
    if (age == 1) return 'سنة واحدة';
    if (age == 2) return 'سنتان';
    if (age == 3) return '3 سنوات';
    return '$age سنوات';
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) =>
      _$ChildModelFromJson(json);
}
