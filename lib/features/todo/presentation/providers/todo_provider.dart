import 'package:flutter/foundation.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/repositories/todo_store.dart';

class TodoProvider extends ChangeNotifier {
  final TodoStore _store;

  TodoProvider(this._store) {
    _store.onReceived().forEach((e) => notifyListeners());
  }

  int get open => _store.open;

  int get done => _store.done;

  int get total => _store.total;

  List<Todo> get todos => _store.todos;

  Future<void> load() => _store.load();

  Future<void> create(Todo newTodo) async {
    _store.create(newTodo);
    notifyListeners();
  }

  Future<void> toggle(int index) async {
    _store.toggle(index);
    notifyListeners();
  }

  Future<void> delete(int index) async {
    _store.delete(index);
    notifyListeners();
  }
}
