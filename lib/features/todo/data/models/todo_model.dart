import 'package:json_annotation/json_annotation.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';

part 'todo_model.g.dart';

@JsonSerializable()
class TodoModel extends Todo {
  TodoModel(bool done, String title, String description) : super(done, title, description);

  factory TodoModel.fromJson(Map<String, dynamic> json) => _$TodoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TodoModelToJson(this);
}
