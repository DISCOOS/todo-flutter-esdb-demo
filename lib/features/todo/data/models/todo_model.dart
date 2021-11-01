import 'package:json_annotation/json_annotation.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';

part 'todo_model.g.dart';

@JsonSerializable()
class TodoModel extends Todo {
  TodoModel(
    String uuid,
    String title,
    String description,
    TodoState state,
  ) : super(uuid, title, description, state);

  factory TodoModel.from(Todo todo) => TodoModel(
        todo.uuid,
        todo.title,
        todo.description,
        todo.state,
      );

  factory TodoModel.fromJson(Map<String, dynamic> json) =>
      _$TodoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TodoModelToJson(this);
}
