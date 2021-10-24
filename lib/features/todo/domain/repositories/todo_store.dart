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
    return [..._todos.values.where((t) => !t.deleted)];
  }

  Iterable<Todo> get all => _todos.values.toList();
  Iterable<Todo> get done => _todos.values.where((t) => t.done);
  Iterable<Todo> get open => _todos.values.where((t) => t.open);
  Iterable<Todo> get deleted => _todos.values.where((t) => t.deleted);

  Stream<Todo> onReceived() => _service.onReceived();

  Future<void> load() {
    _modifications = 0;
    return _service.load();
  }

  Future<void> create(Todo newTodo) async {
    await _service.create(newTodo);
    _todos[newTodo.uuid] = newTodo;
  }

  Future<void> toggle(int index) async {
    final todo = todos[index];
    final newTodo = todo.toggle();
    await _service.toggle(newTodo);
    _todos[todo.uuid] = newTodo;
  }

  Future<void> delete(int index) async {
    final todo = todos[index];
    final newTodo = todo.delete();
    _todos[todo.uuid] = newTodo;
    await _service.delete(newTodo);
  }

  Future<void> dispose() => _service.dispose();
}
