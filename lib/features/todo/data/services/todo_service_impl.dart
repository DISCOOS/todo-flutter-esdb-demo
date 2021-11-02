import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:eventstore_client/eventstore_client.dart';
import 'package:todo_flutter_esdb_demo/core/data/connectivity_mixin.dart';
import 'package:todo_flutter_esdb_demo/core/domain/conflict.dart';
import 'package:todo_flutter_esdb_demo/features/todo/data/models/todo_model.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/entities/todo.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/services/todo_service.dart';

class TodoServiceImpl extends TodoService {
  TodoServiceImpl(this.userId, this.settings) {
    onConnectivityChanged().forEach((state) async {
      try {
        if (state == ConnectivityState.offline) {
          await _unsubscribe();
          await _shutdown();
        } else {
          if (!isReady) {
            await _subscribe(_logPosition);
          }
        }
      } on Exception catch (e) {
        _controller.add(e);
      }
    });
  }

  final String userId;
  final EventStoreClientSettings settings;
  final Map<String, StreamPosition> _positions = {};
  final Map<Todo, String> _pending = LinkedHashMap();
  final Map<String, Map<Todo, String>> _conflicts = LinkedHashMap();
  final StreamController<Object> _controller = StreamController.broadcast();

  LogPosition? _logPosition;
  EventStoreStreamsClient? client;
  EventStreamSubscription? _subscription;

  /// Check if service is ready for consuming events
  bool get isReady => _subscription?.isCompleted == false;

  @override
  ConnectivityState get state => isOnline
      ? _pending.isEmpty
          ? ConnectivityState.idle
          : ConnectivityState.uploading
      : ConnectivityState.offline;

  @override
  Stream<Todo> onReceived() =>
      _controller.stream.where((e) => e is Todo).map((e) => e as Todo);

  @override
  Stream<Iterable<Conflict<Todo>>> onConflicts() => _controller.stream
      .where((e) => e is Iterable<Conflict<Todo>>)
      .map((e) => e as Iterable<Conflict<Todo>>);

  @override
  Stream<Exception> onException() => _controller.stream
      .where((e) => e is Exception)
      .map((e) => e as Exception);

  @override
  Future<void> load() async {
    await _unsubscribe();
    await _subscribe();
  }

  @override
  Future<void> create(Todo todo) =>
      _append(_toStreamState(todo), todo, TodoService.TodoCreated);

  @override
  Future<Todo> toggle(Todo todo) async {
    final next = todo.toggle();
    await _append(_toStreamState(next), next, TodoService.TodoToggled);
    return next;
  }

  @override
  Future<Todo> delete(Todo todo) async {
    final next = todo.delete();
    if (next != todo) {
      await _append(_toStreamState(next), next, TodoService.TodoDeleted);
    }
    return next;
  }

  @override
  Future<Todo> reopen(Todo todo) async {
    final next = todo.open();
    if (next != todo) {
      await _append(_toStreamState(next), next, TodoService.TodoReopened);
    }
    return next;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await _unsubscribe();
    await _shutdown();
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

  Future<void> _subscribe([LogPosition? position]) async {
    assert(!isReady);
    if (isOnline) {
      client ??= EventStoreStreamsClient(settings);
      final subscription = await client!.subscribeToAll(
        position: position,
        filterOptions: SubscriptionFilterOptions(
          StreamFilter.fromPrefix('$userId-todos'),
        ),
        onSubscriptionDropped: (
          EventStreamSubscription _,
          SubscriptionDroppedEvent event,
        ) async {
          if (event.reason != SubscriptionDroppedReason.disposed) {
            await _unsubscribe();
            await _subscribe(_logPosition);
          }
        },
      );
      _listen(subscription);
      _schedule();
    }
  }

  void _listen(EventStreamSubscription subscription) async {
    if (subscription.isOK) {
      _subscription = subscription;
      try {
        await for (var event in subscription.stream) {
          final json = jsonDecode(
            utf8.decode(event.originalEvent.data),
          );
          final todo = TodoModel.fromJson(json);
          _pending.remove(todo);
          _logPosition = event.originalPosition;
          _positions[todo.uuid] = event.originalEventNumber;
          _controller.add(todo);
          _notifyConflicts(todo);
        }
      } on Exception catch (e) {
        _controller.add(e);
      }
    }
  }

  void _notifyConflicts(Todo their) {
    if (_conflicts.containsKey(their.uuid)) {
      _controller.add(
        _conflicts[their.uuid]!
            .entries
            .map((e) => Conflict(e.key, their, e.value)),
      );
      _conflicts.remove(their.uuid);
    }
  }

  Future<void> _schedule() async {
    if (isReady) {
      for (var todo in _pending.entries.toList()) {
        try {
          if (_pending.containsKey(todo.key)) {
            await _append(_toStreamState(todo.key), todo.key, todo.value);
          }
        } on WrongExpectedVersionException catch (e) {
          final uuid = todo.key.uuid;
          _conflicts.update(uuid, (events) {
            events[todo.key] = todo.value;
            return events;
          }, ifAbsent: () => {todo.key: todo.value});

          if ((_positions[uuid]?.toInt() ?? 0) >= (e.actualVersion ?? 0)) {
            _notifyConflicts(todo.key);
          }
        } on Exception catch (e) {
          _controller.add(e);
        }
        _pending.remove(todo.key);
      }
    }
    updateConnectivity();
  }

  Future<void> _shutdown() {
    if (client != null) {
      final old = client;
      client = null;
      old?.shutdown();
    }
    return Future.value();
  }

  Future<void> _unsubscribe() async {
    if (isReady) {
      await _subscription!.dispose();
    }
  }

  Future<void> _append(StreamState state, Todo todo, String eventType) async {
    if (isOnline) {
      final result = await client!.append(
        state,
        Stream.fromIterable([
          EventData(
            type: eventType,
            uuid: UuidV4.newUuid().value.uuid,
            data: utf8.encode(jsonEncode(TodoModel.from(todo).toJson())),
          )
        ]),
      );
      if (result.isOK) {
        updateConnectivity();
        _positions[todo.uuid] = result.nextExpectedStreamRevision.toPosition();
      } else if (result is WrongExpectedVersionResult) {
        throw WrongExpectedVersionException.fromRevisions(
          state.streamId,
          actualStreamRevision: result.nextExpectedStreamRevision,
          expectedStreamRevision:
              result.expected.revision ?? StreamRevision.none,
        );
      } else if (result is BatchWriteErrorResult) {
        throw Exception(result.message);
      }
      throw StateError('Unknown error: ${result.toString()}');
    } else {
      _pending[todo] = eventType;
      _controller.add(todo);
    }
  }
}
