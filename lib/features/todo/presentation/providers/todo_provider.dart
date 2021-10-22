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

  void create(Todo newTodo) {
    _store.create(newTodo);
    notifyListeners();
  }

  void complete(int index) {
    _store.complete(index);
    notifyListeners();
  }

  void delete(int index) {
    _store.delete(index);
    notifyListeners();
  }
}
