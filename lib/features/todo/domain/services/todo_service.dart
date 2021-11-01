import 'package:todo_flutter_esdb_demo/core/data/connectivity_mixin.dart';
import 'package:todo_flutter_esdb_demo/core/domain/conflict.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';

abstract class TodoService with ConnectivityMixin {
  static const TodoCreated = 'TodoCreated';
  static const TodoToggled = 'TodoToggled';
  static const TodoDeleted = 'TodoDeleted';
  static const TodoReopened = 'TodoReopened';

  Future<void> load();

  Future<void> create(Todo todo);

  Future<Todo> toggle(Todo todo);

  Future<Todo> delete(Todo todo);

  Future<Todo> reopen(Todo todo);

  Stream<Todo> onReceived();

  Stream<Exception> onException();

  Stream<Iterable<Conflict<Todo>>> onConflicts();

  Future<void> dispose();
}
