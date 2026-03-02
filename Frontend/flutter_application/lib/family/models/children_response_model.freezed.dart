// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'children_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChildrenData _$ChildrenDataFromJson(Map<String, dynamic> json) {
  return _ChildrenData.fromJson(json);
}

/// @nodoc
mixin _$ChildrenData {
  /// Total number of children registered to this parent.
  int get totalCount => throw _privateConstructorUsedError;

  /// The list of child objects.
  List<ChildModel> get children => throw _privateConstructorUsedError;

  /// Serializes this ChildrenData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChildrenData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChildrenDataCopyWith<ChildrenData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChildrenDataCopyWith<$Res> {
  factory $ChildrenDataCopyWith(
          ChildrenData value, $Res Function(ChildrenData) then) =
      _$ChildrenDataCopyWithImpl<$Res, ChildrenData>;
  @useResult
  $Res call({int totalCount, List<ChildModel> children});
}

/// @nodoc
class _$ChildrenDataCopyWithImpl<$Res, $Val extends ChildrenData>
    implements $ChildrenDataCopyWith<$Res> {
  _$ChildrenDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChildrenData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCount = null,
    Object? children = null,
  }) {
    return _then(_value.copyWith(
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<ChildModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChildrenDataImplCopyWith<$Res>
    implements $ChildrenDataCopyWith<$Res> {
  factory _$$ChildrenDataImplCopyWith(
          _$ChildrenDataImpl value, $Res Function(_$ChildrenDataImpl) then) =
      __$$ChildrenDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int totalCount, List<ChildModel> children});
}

/// @nodoc
class __$$ChildrenDataImplCopyWithImpl<$Res>
    extends _$ChildrenDataCopyWithImpl<$Res, _$ChildrenDataImpl>
    implements _$$ChildrenDataImplCopyWith<$Res> {
  __$$ChildrenDataImplCopyWithImpl(
      _$ChildrenDataImpl _value, $Res Function(_$ChildrenDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChildrenData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCount = null,
    Object? children = null,
  }) {
    return _then(_$ChildrenDataImpl(
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<ChildModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChildrenDataImpl implements _ChildrenData {
  const _$ChildrenDataImpl(
      {this.totalCount = 0, final List<ChildModel> children = const []})
      : _children = children;

  factory _$ChildrenDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChildrenDataImplFromJson(json);

  /// Total number of children registered to this parent.
  @override
  @JsonKey()
  final int totalCount;

  /// The list of child objects.
  final List<ChildModel> _children;

  /// The list of child objects.
  @override
  @JsonKey()
  List<ChildModel> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  String toString() {
    return 'ChildrenData(totalCount: $totalCount, children: $children)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChildrenDataImpl &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            const DeepCollectionEquality().equals(other._children, _children));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalCount, const DeepCollectionEquality().hash(_children));

  /// Create a copy of ChildrenData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChildrenDataImplCopyWith<_$ChildrenDataImpl> get copyWith =>
      __$$ChildrenDataImplCopyWithImpl<_$ChildrenDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChildrenDataImplToJson(
      this,
    );
  }
}

abstract class _ChildrenData implements ChildrenData {
  const factory _ChildrenData(
      {final int totalCount,
      final List<ChildModel> children}) = _$ChildrenDataImpl;

  factory _ChildrenData.fromJson(Map<String, dynamic> json) =
      _$ChildrenDataImpl.fromJson;

  /// Total number of children registered to this parent.
  @override
  int get totalCount;

  /// The list of child objects.
  @override
  List<ChildModel> get children;

  /// Create a copy of ChildrenData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChildrenDataImplCopyWith<_$ChildrenDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChildrenResponseModel _$ChildrenResponseModelFromJson(
    Map<String, dynamic> json) {
  return _ChildrenResponseModel.fromJson(json);
}

/// @nodoc
mixin _$ChildrenResponseModel {
  bool get success => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  ChildrenData? get data => throw _privateConstructorUsedError;
  List<dynamic> get errors => throw _privateConstructorUsedError;

  /// Serializes this ChildrenResponseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChildrenResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChildrenResponseModelCopyWith<ChildrenResponseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChildrenResponseModelCopyWith<$Res> {
  factory $ChildrenResponseModelCopyWith(ChildrenResponseModel value,
          $Res Function(ChildrenResponseModel) then) =
      _$ChildrenResponseModelCopyWithImpl<$Res, ChildrenResponseModel>;
  @useResult
  $Res call(
      {bool success, String message, ChildrenData? data, List<dynamic> errors});

  $ChildrenDataCopyWith<$Res>? get data;
}

/// @nodoc
class _$ChildrenResponseModelCopyWithImpl<$Res,
        $Val extends ChildrenResponseModel>
    implements $ChildrenResponseModelCopyWith<$Res> {
  _$ChildrenResponseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChildrenResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? data = freezed,
    Object? errors = null,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as ChildrenData?,
      errors: null == errors
          ? _value.errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
    ) as $Val);
  }

  /// Create a copy of ChildrenResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChildrenDataCopyWith<$Res>? get data {
    if (_value.data == null) {
      return null;
    }

    return $ChildrenDataCopyWith<$Res>(_value.data!, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChildrenResponseModelImplCopyWith<$Res>
    implements $ChildrenResponseModelCopyWith<$Res> {
  factory _$$ChildrenResponseModelImplCopyWith(
          _$ChildrenResponseModelImpl value,
          $Res Function(_$ChildrenResponseModelImpl) then) =
      __$$ChildrenResponseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success, String message, ChildrenData? data, List<dynamic> errors});

  @override
  $ChildrenDataCopyWith<$Res>? get data;
}

/// @nodoc
class __$$ChildrenResponseModelImplCopyWithImpl<$Res>
    extends _$ChildrenResponseModelCopyWithImpl<$Res,
        _$ChildrenResponseModelImpl>
    implements _$$ChildrenResponseModelImplCopyWith<$Res> {
  __$$ChildrenResponseModelImplCopyWithImpl(_$ChildrenResponseModelImpl _value,
      $Res Function(_$ChildrenResponseModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChildrenResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? data = freezed,
    Object? errors = null,
  }) {
    return _then(_$ChildrenResponseModelImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as ChildrenData?,
      errors: null == errors
          ? _value._errors
          : errors // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChildrenResponseModelImpl implements _ChildrenResponseModel {
  const _$ChildrenResponseModelImpl(
      {required this.success,
      required this.message,
      this.data,
      final List<dynamic> errors = const []})
      : _errors = errors;

  factory _$ChildrenResponseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChildrenResponseModelImplFromJson(json);

  @override
  final bool success;
  @override
  final String message;
  @override
  final ChildrenData? data;
  final List<dynamic> _errors;
  @override
  @JsonKey()
  List<dynamic> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  @override
  String toString() {
    return 'ChildrenResponseModel(success: $success, message: $message, data: $data, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChildrenResponseModelImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, message, data,
      const DeepCollectionEquality().hash(_errors));

  /// Create a copy of ChildrenResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChildrenResponseModelImplCopyWith<_$ChildrenResponseModelImpl>
      get copyWith => __$$ChildrenResponseModelImplCopyWithImpl<
          _$ChildrenResponseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChildrenResponseModelImplToJson(
      this,
    );
  }
}

abstract class _ChildrenResponseModel implements ChildrenResponseModel {
  const factory _ChildrenResponseModel(
      {required final bool success,
      required final String message,
      final ChildrenData? data,
      final List<dynamic> errors}) = _$ChildrenResponseModelImpl;

  factory _ChildrenResponseModel.fromJson(Map<String, dynamic> json) =
      _$ChildrenResponseModelImpl.fromJson;

  @override
  bool get success;
  @override
  String get message;
  @override
  ChildrenData? get data;
  @override
  List<dynamic> get errors;

  /// Create a copy of ChildrenResponseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChildrenResponseModelImplCopyWith<_$ChildrenResponseModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
