// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChildModelImpl _$$ChildModelImplFromJson(Map<String, dynamic> json) =>
    _$ChildModelImpl(
      childId: json['childId'] as String,
      fullName: json['fullName'] as String,
      photoUrl: json['photoUrl'] as String?,
      age: (json['age'] as num).toInt(),
      isActive: json['isActive'] as bool,
      hasAccount: json['hasAccount'] as bool,
      prizeCount: (json['prizeCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ChildModelImplToJson(_$ChildModelImpl instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'fullName': instance.fullName,
      'photoUrl': instance.photoUrl,
      'age': instance.age,
      'isActive': instance.isActive,
      'hasAccount': instance.hasAccount,
      'prizeCount': instance.prizeCount,
    };
