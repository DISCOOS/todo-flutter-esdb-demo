import 'package:flutter/foundation.dart';
import 'package:todo_flutter_esdb_example/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_example/features/todo/domain/repositories/todo_store.dart';

class TodoProvider extends ChangeNotifier {
  final TodoStore _store;

  TodoProvider(this._store);

  int get open => _store.open;
  int get done => _store.done;
  int get total => _store.total;

  List<Todo> get todos => _store.todos;

  set todos(List<Todo> newTodos) {
    _store.todos = newTodos;
    notifyListeners();
  }

  void addTodo(Todo newTodo) {
    _store.add(newTodo);
    notifyListeners();
  }

  void completeTodo(int index) {
    _store.complete(index);
    notifyListeners();
  }

  void removeTodo(int index) {
    _store.remove(index);
    notifyListeners();
  }
}
