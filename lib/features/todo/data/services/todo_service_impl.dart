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

  bool get isReady => _subscription?.isCompleted == false;

  @override
  Stream<Todo> onReceived() async* {
    if (!isReady) {
      await _subscribe();
    }
    await for (var event in _stream!) {
      final json = jsonDecode(
        utf8.decode(event.originalEvent.data),
      );
      yield TodoModel.fromJson(json);
    }
  }

  @override
  Future<void> load() async {
    if (isReady) {
      await _subscription!.dispose();
    }
    await _subscribe();
  }

  @override
  Future<void> create(Todo todo) =>
      _append(StreamState.noStream(_toStreamId(todo)), todo, 'TodoCreated');

  @override
  Future<void> toggle(Todo todo) =>
      _append(StreamState.exists(_toStreamId(todo)), todo, 'TodoToggled');

  @override
  Future<void> delete(Todo todo) =>
      _append(StreamState.exists(_toStreamId(todo)), todo, 'TodoDeleted');

  @override
  Future<void> dispose() async {
    if (isReady) {
      await _subscription!.dispose();
    }
  }

  String _toStreamId(Todo todo) => 'todos-${todo.uuid}';

  Future<void> _subscribe() async {
    assert(!isReady);
    _subscription = await client.subscribeToAll(
      filterOptions: SubscriptionFilterOptions(
        StreamFilter.fromPrefix('todos'),
      ),
    );
    if (_subscription!.isOK) {
      _stream = _subscription!.asBroadcastStream();
    }
  }

  Future<void> _append(StreamState state, Todo todo, String eventType) {
    return client.append(
      state,
      Stream.fromIterable([
        EventData(
          type: eventType,
          uuid: UuidV4.newUuid().value.uuid,
          data: utf8.encode(jsonEncode(TodoModel.from(todo).toJson())),
        )
      ]),
    );
  }
}
