import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';

abstract class TodoService {
  Future<void> create(Todo todo);

  Future<void> complete(Todo todo);

  Future<void> delete(Todo todo);

  Stream<Todo> onReceived();
}
