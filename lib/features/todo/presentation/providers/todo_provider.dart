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

  Future<void> load() => _store.load();

  Future<void> create(Todo newTodo) async {
    await _store.create(newTodo);
    notifyListeners();
  }

  Future<void> toggle(int index) async {
    await _store.toggle(index);
    notifyListeners();
  }

  Future<void> delete(int index) async {
    await _store.delete(index);
    notifyListeners();
  }

  @override
  void dispose() async {
    super.dispose();
    await _store.dispose();
  }
}
