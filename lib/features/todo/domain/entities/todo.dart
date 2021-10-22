import 'package:eventstore_client/eventstore_client.dart';

class Todo {
  const Todo(
    this.uuid,
    this.done,
    this.title,
    this.description,
    this.deleted,
  );

  final bool done;
  final String uuid;
  final String title;
  final bool deleted;
  final String description;

  bool get open => !(done || deleted);

  factory Todo.from(String title, String description) =>
      Todo(UuidV4.newUuid().value.uuid, false, title, description, false);

  Todo delete() => Todo(uuid, done, title, description, true);
  Todo toggle() => Todo(uuid, !done, title, description, deleted);
}
