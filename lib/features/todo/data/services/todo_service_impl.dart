import 'dart:async';
import 'dart:convert';

import 'package:eventstore_client/eventstore_client.dart';
import 'package:todo_flutter_esdb_demo/features/todo/data/models/todo_model.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoServiceImpl extends TodoService {
  TodoServiceImpl(this.client);

  final EventStoreStreamsClient client;
  final StreamController<Todo> _controller = StreamController.broadcast();

  EventStreamSubscription? _subscription;

  /// Check if service is ready for consuming events
  bool get isReady => _subscription?.isCompleted == false;

  @override
  Stream<Todo> onReceived() => _controller.stream;

  @override
  Future<void> load() async {
    await _unsubscribe();
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
    await _unsubscribe();
    await _controller.close();
  }

  String _toStreamId(Todo todo) => 'todos-${todo.uuid}';

  Future<void> _subscribe() async {
    assert(!isReady);
    final subscription = await client.subscribeToAll(
      filterOptions: SubscriptionFilterOptions(
        StreamFilter.fromPrefix('todos'),
      ),
    );
    _listen(subscription);
  }

  void _listen(EventStreamSubscription subscription) async {
    if (subscription.isOK) {
      _subscription = subscription;
      await for (var event in subscription.stream) {
        final json = jsonDecode(
          utf8.decode(event.originalEvent.data),
        );
        _controller.add(TodoModel.fromJson(json));
      }
    }
  }

  Future<void> _unsubscribe() async {
    if (isReady) {
      await _subscription!.dispose();
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
