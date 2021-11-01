import 'package:eventstore_client/eventstore_client.dart';

class Todo {
  const Todo(
    this.uuid,
    this.title,
    this.description,
    this.state,
  );

  final String uuid;
  final String title;
  final TodoState state;
  final String description;

  bool get isOpen => state == TodoState.open;
  bool get isDone => state == TodoState.done;
  bool get isDeleted => state == TodoState.deleted;

  factory Todo.from(String title, String description) =>
      Todo(UuidV4.newUuid().value.uuid, title, description, TodoState.open);

  Todo open() => Todo(uuid, title, description, TodoState.open);
  Todo done() => Todo(uuid, title, description, TodoState.done);
  Todo delete() => Todo(uuid, title, description, TodoState.deleted);

  Todo toggle() => isDeleted
      ? this
      : Todo(
          uuid,
          title,
          description,
          isOpen ? TodoState.done : TodoState.open,
        );
}

enum TodoState {
  open,
  done,
  deleted,
}
