import 'package:todo_flutter_esdb_example/features/todo/domain/entities/todo.dart';

class TodoStore {
  List<Todo> _todoList = [];

  int get done => _todoList.where((t) => t.done).length;
  int get open => _todoList.where((t) => !t.done).length;
  int get total => _todoList.length;

  List<Todo> get todos {
    return [..._todoList];
  }

  set todos(List<Todo> newTodos) {
    _todoList = newTodos.toList();
  }

  void add(Todo newTodo) {
    _todoList.add(newTodo);
  }

  void complete(int index) {
    _todoList.replaceRange(index, index + 1, [
      Todo(
        !_todoList[index].done,
        _todoList[index].title,
        _todoList[index].description,
      )
    ]);
  }

  void remove(int index) {
    _todoList.removeAt(index);
  }
}
