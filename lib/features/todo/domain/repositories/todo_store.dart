import 'dart:async';
import 'dart:collection';

import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoStore {
  TodoStore(this._service) {
    _service.onReceived().forEach((todo) {
      _todos[todo.uuid] = todo;
      _modifications++;
    });
    load();
  }

  final TodoService _service;
  final Map<String, Todo> _todos = LinkedHashMap();

  int get modifications => _modifications;
  int _modifications = 0;

  List<Todo> get todos {
    return [..._todos.values.where((t) => !t.isDeleted)];
  }

  Iterable<Todo> get all => _todos.values.toList();
  Iterable<Todo> get done => _todos.values.where((t) => t.isDone);
  Iterable<Todo> get open => _todos.values.where((t) => t.isOpen);
  Iterable<Todo> get deleted => _todos.values.where((t) => t.isDeleted);

  Iterable<Todo> where({
    bool open: true,
    bool done: false,
    bool deleted: false,
  }) {
    final matches = [
      if (open) TodoState.open,
      if (done) TodoState.done,
      if (deleted) TodoState.deleted,
    ];

    return _todos.values.where(
      (t) => matches.contains(t.state),
    );
  }

  Stream<Todo> onReceived() => _service.onReceived();

  Future<void> load() {
    _modifications = 0;
    return _service.load();
  }

  Future<void> create(Todo newTodo) async {
    await _service.create(newTodo);
    _todos[newTodo.uuid] = newTodo;
  }

  Future<void> toggle(String uuid) async {
    final todo = _todos[uuid]!;
    final newTodo = todo.toggle();
    await _service.toggle(newTodo);
    _todos[todo.uuid] = newTodo;
  }

  Future<void> delete(String uuid) async {
    final todo = _todos[uuid]!;
    final newTodo = todo.delete();
    _todos[todo.uuid] = newTodo;
    await _service.delete(newTodo);
  }

  Future<void> dispose() => _service.dispose();
}
