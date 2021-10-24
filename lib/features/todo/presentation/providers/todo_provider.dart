import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/repositories/todo_store.dart';

class TodoProvider extends ChangeNotifier {
  TodoProvider(this._store) {
    _store.onReceived().forEach((e) {
      if (_store.modifications > _seen) {
        _seen = _store.modifications;
        notifyListeners();
      }
    });
  }

  final TodoStore _store;

  Iterable<Todo> get all => _store.all;
  Iterable<Todo> get open => _store.open;
  Iterable<Todo> get done => _store.done;
  Iterable<Todo> get deleted => _store.deleted;

  List<Todo> get todos => _store.todos;

  int get modifications => _store.modifications;
  int _seen = 0;

  Iterable<Todo> where({
    bool open: true,
    bool done: false,
    bool deleted: false,
  }) =>
      _store.where(open: open, done: done, deleted: deleted);

  Future<void> load() => _store.load();

  Future<void> create(Todo newTodo) async {
    await _store.create(newTodo);
    notifyListeners();
  }

  Future<void> toggle(String uuid) async {
    await _store.toggle(uuid);
    notifyListeners();
  }

  Future<void> delete(String uuid) async {
    await _store.delete(uuid);
    notifyListeners();
  }

  @override
  void dispose() async {
    super.dispose();
    await _store.dispose();
  }
}
