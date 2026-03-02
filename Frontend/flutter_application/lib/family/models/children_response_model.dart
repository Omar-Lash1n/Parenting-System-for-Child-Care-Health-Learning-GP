// lib/family/models/children_response_model.dart
//
// Freezed models for the full API envelope returned by GET /Parents/children.
// Run `dart run build_runner build` to generate the .freezed.dart / .g.dart files.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'child_model.dart';

part 'children_response_model.freezed.dart';
part 'children_response_model.g.dart';

/// The `data` object inside the children list response.
///
/// ```json
/// { "totalCount": 2, "children": [...] }
/// ```
@freezed
class ChildrenData with _$ChildrenData {
  const factory ChildrenData({
    /// Total number of children registered to this parent.
    @Default(0) int totalCount,

    /// The list of child objects.
    @Default([]) List<ChildModel> children,
  }) = _ChildrenData;

  factory ChildrenData.fromJson(Map<String, dynamic> json) =>
      _$ChildrenDataFromJson(json);
}

/// Full API envelope for GET /Parents/children.
///
/// ```json
/// {
///   "success": true,
///   "message": "تم جلب بيانات 2 طفل بنجاح",
///   "data":    { "totalCount": 2, "children": [...] },
///   "errors":  []
/// }
/// ```
@freezed
class ChildrenResponseModel with _$ChildrenResponseModel {
  const factory ChildrenResponseModel({
    required bool success,
    required String message,
    ChildrenData? data,
    @Default([]) List<dynamic> errors,
  }) = _ChildrenResponseModel;

  factory ChildrenResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ChildrenResponseModelFromJson(json);
}
