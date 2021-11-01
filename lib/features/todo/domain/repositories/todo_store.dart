import 'dart:async';
import 'dart:collection';

import 'package:todo_flutter_esdb_demo/core/data/connectivity_mixin.dart';
import 'package:todo_flutter_esdb_demo/core/domain/conflict.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoStore {
  TodoStore(this._service) {
    _service.onReceived().forEach((todo) {
      _todos[todo.uuid] = todo;
      _modifications++;
    });
    _service.onException().forEach((e) {
      _exceptions.add(e);
    });
    _service.onConflicts().forEach((conflicts) {
      for (var conflict in conflicts) {
        _conflicts[conflict.their.uuid] = conflict;
      }
    });
    load();
  }

  final TodoService _service;
  final List<Exception> _exceptions = [];
  final Map<String, Todo> _todos = LinkedHashMap();
  final Map<String, Conflict<Todo>> _conflicts = {};

  int get modifications => _modifications;
  int _modifications = 0;

  Iterable<Todo> get all => _todos.values.toList();
  Iterable<Todo> get done => _todos.values.where((t) => t.isDone);
  Iterable<Todo> get open => _todos.values.where((t) => t.isOpen);
  Iterable<Todo> get deleted => _todos.values.where((t) => t.isDeleted);

  Iterable<Exception> get exceptions => _exceptions.toList();
  Map<String, Conflict<Todo>> get conflicts => Map.from(_conflicts);

  ConnectivityState get state => _service.state;

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

  Stream<Exception> onException() => _service.onException();

  Stream<Iterable<Conflict<Todo>>> onConflicts() => _service.onConflicts();

  Stream<ConnectivityState> onConnectivityChanged() =>
      _service.onConnectivityChanged();

  Future<void> load() {
    _modifications = 0;
    _conflicts.clear();
    _exceptions.clear();
    return _service.load();
  }

  Future<void> create(Todo newTodo) async {
    await _service.create(newTodo);
    _todos[newTodo.uuid] = newTodo;
  }

  Future<void> toggle(String uuid) async {
    final todo = _todos[uuid]!;
    final newTodo = await _service.toggle(todo);
    _todos[todo.uuid] = newTodo;
    _conflicts.remove(todo.uuid);
  }

  Future<void> delete(String uuid) async {
    final todo = _todos[uuid]!;
    final newTodo = await _service.delete(todo);
    _todos[todo.uuid] = newTodo;
    _conflicts.remove(todo.uuid);
  }

  Future<void> reopen(String uuid) async {
    final todo = _todos[uuid]!;
    final newTodo = await _service.reopen(todo);
    _todos[todo.uuid] = newTodo;
    _conflicts.remove(todo.uuid);
  }

  void keepYours() async {
    for (var c in _conflicts.values) {
      switch (c.type) {
        case TodoService.TodoToggled:
          await _service.toggle(c.mine);
          break;
        case TodoService.TodoDeleted:
          await _service.delete(c.mine);
          break;
        default:
          break;
      }
    }
    _conflicts.clear();
  }

  void keepTheirs() {
    _conflicts.clear();
  }

  Future<void> dispose() => _service.dispose();
}
