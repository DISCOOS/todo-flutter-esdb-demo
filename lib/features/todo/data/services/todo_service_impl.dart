import 'dart:async';
import 'dart:convert';

import 'package:eventstore_client/eventstore_client.dart';
import 'package:todo_flutter_esdb_demo/features/todo/data/models/todo_model.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoServiceImpl extends TodoService {
  TodoServiceImpl(this.userId, this.client);

  final String userId;
  final EventStoreStreamsClient client;
  final Map<String, StreamPosition> _positions = {};
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
      _append(_toStreamState(todo), todo, 'TodoCreated');

  @override
  Future<Todo> toggle(Todo todo) async {
    final next = todo.toggle();
    await _append(_toStreamState(next), next, 'TodoToggled');
    return next;
  }

  @override
  Future<Todo> delete(Todo todo) async {
    final next = todo.delete();
    if (next != todo) {
      await _append(_toStreamState(next), next, 'TodoDeleted');
    }
    return next;
  }

  @override
  Future<void> dispose() async {
    await _unsubscribe();
    await _controller.close();
  }

  StreamState _toStreamState(Todo todo) {
    final position = _positions[todo.uuid];
    return position == null
        ? StreamState.noStream(_toStreamId(todo))
        : StreamState.exists(
            _toStreamId(todo),
            revision: position.toRevision(),
          );
  }

  String _toStreamId(Todo todo) => '$userId-todos-${todo.uuid}';

  Future<void> _subscribe() async {
    assert(!isReady);
    final subscription = await client.subscribeToAll(
      filterOptions: SubscriptionFilterOptions(
        StreamFilter.fromPrefix('$userId-todos'),
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
        final todo = TodoModel.fromJson(json);
        _positions[todo.uuid] = event.originalEventNumber;
        _controller.add(todo);
      }
    }
  }

  Future<void> _unsubscribe() async {
    if (isReady) {
      await _subscription!.dispose();
    }
  }

  Future<void> _append(StreamState state, Todo todo, String eventType) async {
    final result = await client.append(
      state,
      Stream.fromIterable([
        EventData(
          type: eventType,
          uuid: UuidV4.newUuid().value.uuid,
          data: utf8.encode(jsonEncode(TodoModel.from(todo).toJson())),
        )
      ]),
    );
    if (result is WrongExpectedVersionResult) {
      throw WrongExpectedVersionException.fromRevisions(
        state.streamId,
        actualStreamRevision: result.nextExpectedStreamRevision,
        expectedStreamRevision: result.expected.revision ?? StreamRevision.none,
      );
    }
    _positions[todo.uuid] = result.nextExpectedStreamRevision.toPosition();
  }
}
