// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoModel _$TodoModelFromJson(Map<String, dynamic> json) => TodoModel(
      json['uuid'] as String,
      json['title'] as String,
      json['description'] as String,
      $enumDecode(_$TodoStateEnumMap, json['state']),
    );

Map<String, dynamic> _$TodoModelToJson(TodoModel instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'title': instance.title,
      'state': _$TodoStateEnumMap[instance.state],
      'description': instance.description,
    };

const _$TodoStateEnumMap = {
  TodoState.open: 'open',
  TodoState.done: 'done',
  TodoState.deleted: 'deleted',
};
