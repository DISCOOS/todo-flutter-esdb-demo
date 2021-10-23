import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';

abstract class TodoService {
  Future<void> load();

  Future<void> create(Todo todo);

  Future<void> toggle(Todo todo);

  Future<void> delete(Todo todo);

  Stream<Todo> onReceived();

  Future<void> dispose();
}
