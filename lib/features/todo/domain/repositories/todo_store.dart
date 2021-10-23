import 'dart:async';
import 'dart:collection';

import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoStore {
  TodoStore(this._service) {
    _listen();
  }

  final TodoService _service;
  final Map<String, Todo> _todos = LinkedHashMap();

  StreamSubscription? _subscription;

  int get done => _todos.values.where((t) => t.done).length;
  int get open => _todos.values.where((t) => t.open).length;
  int get total => _todos.values.where((t) => !t.deleted).length;
  int get deleted => _todos.values.where((t) => t.deleted).length;

  Stream<Todo> onReceived() => _service.onReceived();

  List<Todo> get todos {
    return [..._todos.values.where((t) => !t.deleted)];
  }

  Future<void> load() async {
    await _service.load();
    _listen();
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

  void _listen() {
    _subscription?.cancel();
    _subscription = _service.onReceived().listen((todo) {
      _todos[todo.uuid] = todo;
    });
  }
}
