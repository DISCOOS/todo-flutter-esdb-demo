import 'package:json_annotation/json_annotation.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';

part 'todo_model.g.dart';

@JsonSerializable()
class TodoModel extends Todo {
  TodoModel(
    String uuid,
    bool done,
    String title,
    String description,
    bool deleted,
  ) : super(uuid, done, title, description, deleted);

  factory TodoModel.from(Todo todo) => TodoModel(
        todo.uuid,
        todo.done,
        todo.title,
        todo.description,
        todo.deleted,
      );

  factory TodoModel.fromJson(Map<String, dynamic> json) =>
      _$TodoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TodoModelToJson(this);
}
