// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoModel _$TodoModelFromJson(Map<String, dynamic> json) => TodoModel(
      json['done'] as bool,
      json['title'] as String,
      json['description'] as String,
    );

Map<String, dynamic> _$TodoModelToJson(Todo instance) => <String, dynamic>{
      'done': instance.done,
      'title': instance.title,
      'description': instance.description,
    };
