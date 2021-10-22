import 'dart:convert';

import 'package:eventstore_client/eventstore_client.dart';
import 'package:todo_flutter_esdb_demo/features/todo/data/models/todo_model.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoServiceImpl extends TodoService {
  TodoServiceImpl(this.client);

  final EventStoreStreamsClient client;

  Stream<ResolvedEvent>? _stream;
  EventStreamSubscription? _subscription;

  String toStreamId(Todo todo) => 'todos-${todo.uuid}';

  @override
  Stream<Todo> onReceived() async* {
    if (_subscription == null || _subscription!.isCompleted == true) {
      _subscription = await client.subscribeToAll(
        filterOptions: SubscriptionFilterOptions(
          StreamFilter.fromPrefix('todos'),
        ),
      );
      if (_subscription!.isOK) {
        _stream = _subscription!.asBroadcastStream();
      }
    }

    await for (var event in _stream!) {
      final json = jsonDecode(
        utf8.decode(event.originalEvent.data),
      );
      yield TodoModel.fromJson(json);
    }
  }

  @override
  Future<void> create(Todo todo) async {
    await client.append(
      StreamState.noStream(toStreamId(todo)),
      Stream.fromIterable([
        EventData(
          type: 'TodoCreated',
          uuid: UuidV4.newUuid().value.uuid,
          data: utf8.encode(jsonEncode(TodoModel.from(todo).toJson())),
        )
      ]),
    );
  }

  @override
  Future<void> complete(Todo todo) async {
    await client.append(
      StreamState.exists(toStreamId(todo)),
      Stream.fromIterable([
        EventData(
          type: 'TodoCompleted',
          uuid: UuidV4.newUuid().value.uuid,
          data: utf8.encode(jsonEncode(TodoModel.from(todo).toJson())),
        )
      ]),
    );
  }

  @override
  Future<void> delete(Todo todo) async {
    await client.append(
      StreamState.exists(toStreamId(todo)),
      Stream.fromIterable([
        EventData(
          type: 'TodoDeleted',
          uuid: UuidV4.newUuid().value.uuid,
          data: utf8.encode(jsonEncode(TodoModel.from(todo).toJson())),
        )
      ]),
    );
  }
}
