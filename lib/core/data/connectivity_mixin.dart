import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectivityState {
  offline,
  uploading,
  idle,
}

mixin ConnectivityMixin {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityState> _stateController =
      StreamController.broadcast();

  Timer? _connectionCheckTimer;
  ConnectivityResult? _connectivityResult;
  StreamSubscription<ConnectivityState>? _callbackSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityState get state;
  void updateConnectivity() {
    _isOnline = state != ConnectivityState.offline;
    _stateController.add(state);
  }

  bool get isOnline => _isOnline;
  bool _isOnline = false;

  Stream<ConnectivityState> onConnectivityChanged() {
    _init();
    return _stateController.stream;
  }

  void _init() {
    _connectionCheckTimer ??=
        Timer.periodic(const Duration(seconds: 3), _checkConnection);

    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen(
      (result) => _setState(result, _isOnline),
    );
  }

  @mustCallSuper
  Future<void> dispose() async {
    _connectionCheckTimer?.cancel();
    await _stateController.close();
    await _callbackSubscription?.cancel();
    await _connectivitySubscription?.cancel();
  }

  void _checkConnection(Timer timer) async {
    const addresses = [
      '1.1.1.1', // CloudFlare
      '8.8.8.8', // Google
      '208.67.220.220', // OpenDNS
    ];
    final requests = addresses.map(_isHostReachable);
    final isOnline = await Stream.fromFutures(requests).any((result) => result);
    _setState(
      _connectivityResult ?? ConnectivityResult.none,
      isOnline,
    );
  }

  Future<bool> _isHostReachable(String address) async {
    Socket? sock;
    try {
      sock = await Socket.connect(address, 53,
          timeout: const Duration(seconds: 1));
      sock.destroy();
      return true;
    } catch (e) {
      sock?.destroy();
      return false;
    }
  }

  bool _setState(ConnectivityResult result, bool isOnline) {
    final changed = _connectivityResult != result || _isOnline != isOnline;
    if (changed) {
      _isOnline = isOnline;
      _connectivityResult = result;
      _stateController.add(state);
    }
    return changed;
  }
}
