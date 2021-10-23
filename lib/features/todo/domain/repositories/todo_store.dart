import 'dart:collection';

import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoStore {
  TodoStore(this._service) {
    _service.onReceived().forEach((todo) {
      if (todo.deleted) {
        _todos.remove(todo.uuid);
      } else {
        _todos[todo.uuid] = todo;
      }
    });
  }

  final TodoService _service;
  final Map<String, Todo> _todos = LinkedHashMap();

  int get done => _todos.values.where((t) => t.done).length;
  int get open => _todos.values.where((t) => t.open).length;

  int get total => _todos.length;

  Stream<Todo> onReceived() => _service.onReceived();

  List<Todo> get todos {
    return [..._todos.values];
  }

  Future<void> load() => _service.load();

  Future<void> create(Todo newTodo) async {
    await _service.create(newTodo);
    _todos[newTodo.uuid] = newTodo;
  }

  Future<void> toggle(int index) async {
    final todo = _todos.values.toList()[index];
    final newTodo = todo.toggle();
    await _service.toggle(newTodo);
    _todos[todo.uuid] = newTodo;
  }

  Future<void> delete(int index) async {
    final todo = _todos.values.toList()[index];
    final newTodo = todo.delete();
    await _service.delete(newTodo);
  }
}
