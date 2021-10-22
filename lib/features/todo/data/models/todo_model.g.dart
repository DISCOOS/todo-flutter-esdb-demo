// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoModel _$TodoModelFromJson(Map<String, dynamic> json) => TodoModel(
      json['uuid'] as String,
      json['done'] as bool,
      json['title'] as String,
      json['description'] as String,
      json['deleted'] as bool,
    );

Map<String, dynamic> _$TodoModelToJson(TodoModel instance) => <String, dynamic>{
      'done': instance.done,
      'uuid': instance.uuid,
      'title': instance.title,
      'deleted': instance.deleted,
      'description': instance.description,
    };
