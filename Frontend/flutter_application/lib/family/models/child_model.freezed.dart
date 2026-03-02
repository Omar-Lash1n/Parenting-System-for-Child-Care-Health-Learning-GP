// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'child_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChildModel _$ChildModelFromJson(Map<String, dynamic> json) {
  return _ChildModel.fromJson(json);
}

/// @nodoc
mixin _$ChildModel {
  /// Unique identifier for the child.
  String get childId => throw _privateConstructorUsedError;

  /// Child's full name in Arabic.
  String get fullName => throw _privateConstructorUsedError;

  /// Remote URL to the child's profile photo. May be null.
  String? get photoUrl => throw _privateConstructorUsedError;

  /// Age in years.
  int get age => throw _privateConstructorUsedError;

  /// Whether the child currently has an active session (shows green dot).
  bool get isActive => throw _privateConstructorUsedError;

  /// Whether the child has a login account.
  bool get hasAccount => throw _privateConstructorUsedError;

  /// Total number of prizes the child has earned.
  int get prizeCount => throw _privateConstructorUsedError;

  /// Serializes this ChildModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChildModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChildModelCopyWith<ChildModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChildModelCopyWith<$Res> {
  factory $ChildModelCopyWith(
          ChildModel value, $Res Function(ChildModel) then) =
      _$ChildModelCopyWithImpl<$Res, ChildModel>;
  @useResult
  $Res call(
      {String childId,
      String fullName,
      String? photoUrl,
      int age,
      bool isActive,
      bool hasAccount,
      int prizeCount});
}

/// @nodoc
class _$ChildModelCopyWithImpl<$Res, $Val extends ChildModel>
    implements $ChildModelCopyWith<$Res> {
  _$ChildModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChildModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? childId = null,
    Object? fullName = null,
    Object? photoUrl = freezed,
    Object? age = null,
    Object? isActive = null,
    Object? hasAccount = null,
    Object? prizeCount = null,
  }) {
    return _then(_value.copyWith(
      childId: null == childId
          ? _value.childId
          : childId // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      age: null == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      hasAccount: null == hasAccount
          ? _value.hasAccount
          : hasAccount // ignore: cast_nullable_to_non_nullable
              as bool,
      prizeCount: null == prizeCount
          ? _value.prizeCount
          : prizeCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChildModelImplCopyWith<$Res>
    implements $ChildModelCopyWith<$Res> {
  factory _$$ChildModelImplCopyWith(
          _$ChildModelImpl value, $Res Function(_$ChildModelImpl) then) =
      __$$ChildModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String childId,
      String fullName,
      String? photoUrl,
      int age,
      bool isActive,
      bool hasAccount,
      int prizeCount});
}

/// @nodoc
class __$$ChildModelImplCopyWithImpl<$Res>
    extends _$ChildModelCopyWithImpl<$Res, _$ChildModelImpl>
    implements _$$ChildModelImplCopyWith<$Res> {
  __$$ChildModelImplCopyWithImpl(
      _$ChildModelImpl _value, $Res Function(_$ChildModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChildModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? childId = null,
    Object? fullName = null,
    Object? photoUrl = freezed,
    Object? age = null,
    Object? isActive = null,
    Object? hasAccount = null,
    Object? prizeCount = null,
  }) {
    return _then(_$ChildModelImpl(
      childId: null == childId
          ? _value.childId
          : childId // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      age: null == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      hasAccount: null == hasAccount
          ? _value.hasAccount
          : hasAccount // ignore: cast_nullable_to_non_nullable
              as bool,
      prizeCount: null == prizeCount
          ? _value.prizeCount
          : prizeCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChildModelImpl extends _ChildModel {
  const _$ChildModelImpl(
      {required this.childId,
      required this.fullName,
      this.photoUrl,
      required this.age,
      required this.isActive,
      required this.hasAccount,
      this.prizeCount = 0})
      : super._();

  factory _$ChildModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChildModelImplFromJson(json);

  /// Unique identifier for the child.
  @override
  final String childId;

  /// Child's full name in Arabic.
  @override
  final String fullName;

  /// Remote URL to the child's profile photo. May be null.
  @override
  final String? photoUrl;

  /// Age in years.
  @override
  final int age;

  /// Whether the child currently has an active session (shows green dot).
  @override
  final bool isActive;

  /// Whether the child has a login account.
  @override
  final bool hasAccount;

  /// Total number of prizes the child has earned.
  @override
  @JsonKey()
  final int prizeCount;

  @override
  String toString() {
    return 'ChildModel(childId: $childId, fullName: $fullName, photoUrl: $photoUrl, age: $age, isActive: $isActive, hasAccount: $hasAccount, prizeCount: $prizeCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChildModelImpl &&
            (identical(other.childId, childId) || other.childId == childId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.hasAccount, hasAccount) ||
                other.hasAccount == hasAccount) &&
            (identical(other.prizeCount, prizeCount) ||
                other.prizeCount == prizeCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, childId, fullName, photoUrl, age,
      isActive, hasAccount, prizeCount);

  /// Create a copy of ChildModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChildModelImplCopyWith<_$ChildModelImpl> get copyWith =>
      __$$ChildModelImplCopyWithImpl<_$ChildModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChildModelImplToJson(
      this,
    );
  }
}

abstract class _ChildModel extends ChildModel {
  const factory _ChildModel(
      {required final String childId,
      required final String fullName,
      final String? photoUrl,
      required final int age,
      required final bool isActive,
      required final bool hasAccount,
      final int prizeCount}) = _$ChildModelImpl;
  const _ChildModel._() : super._();

  factory _ChildModel.fromJson(Map<String, dynamic> json) =
      _$ChildModelImpl.fromJson;

  /// Unique identifier for the child.
  @override
  String get childId;

  /// Child's full name in Arabic.
  @override
  String get fullName;

  /// Remote URL to the child's profile photo. May be null.
  @override
  String? get photoUrl;

  /// Age in years.
  @override
  int get age;

  /// Whether the child currently has an active session (shows green dot).
  @override
  bool get isActive;

  /// Whether the child has a login account.
  @override
  bool get hasAccount;

  /// Total number of prizes the child has earned.
  @override
  int get prizeCount;

  /// Create a copy of ChildModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChildModelImplCopyWith<_$ChildModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
