import 'package:flutter/foundation.dart';
import 'package:todo_flutter_esdb_example/features/todo/domain/todo.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todoList = [];

  int get count => _todoList.length;

  List<Todo> get todos {
    return [..._todoList];
  }

  set todos(List<Todo> newTodos) {
    _todoList = newTodos.toList();
    notifyListeners();
  }

  void addTodo(Todo newTodo) {
    _todoList.add(newTodo);
    notifyListeners();
  }

  void completeTodo(int index) {
    _todoList.replaceRange(index, index + 1, [
      Todo(
        !_todoList[index].done,
        _todoList[index].title,
        _todoList[index].description,
      )
    ]);
    notifyListeners();
  }

  void removeTodo(int index) {
    _todoList.removeAt(index);
    notifyListeners();
  }
}
