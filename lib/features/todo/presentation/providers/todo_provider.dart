import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/repositories/todo_store.dart';

class TodoProvider extends ChangeNotifier {
  TodoProvider(this._store) {
    _listen();
  }

  final TodoStore _store;

  StreamSubscription? _subscription;

  int get open => _store.open;
  int get done => _store.done;
  int get total => _store.total;
  int get deleted => _store.deleted;

  List<Todo> get todos => _store.todos;

  Future<void> load() async {
    await _store.load();
    _listen();
  }

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

  void _listen() {
    _subscription?.cancel();
    _subscription = _store.onReceived().listen((e) => notifyListeners());
  }
}
