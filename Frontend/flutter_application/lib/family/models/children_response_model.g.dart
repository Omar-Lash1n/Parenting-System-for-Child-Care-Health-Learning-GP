// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'children_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChildrenDataImpl _$$ChildrenDataImplFromJson(Map<String, dynamic> json) =>
    _$ChildrenDataImpl(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => ChildModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ChildrenDataImplToJson(_$ChildrenDataImpl instance) =>
    <String, dynamic>{
      'totalCount': instance.totalCount,
      'children': instance.children,
    };

_$ChildrenResponseModelImpl _$$ChildrenResponseModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ChildrenResponseModelImpl(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : ChildrenData.fromJson(json['data'] as Map<String, dynamic>),
      errors: json['errors'] as List<dynamic>? ?? const [],
    );

Map<String, dynamic> _$$ChildrenResponseModelImplToJson(
        _$ChildrenResponseModelImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'errors': instance.errors,
    };
