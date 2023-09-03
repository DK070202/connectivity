import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// A service class for managing connectivity status.
class ConnectivityService {
  ConnectivityService(this._connectivity)
      : _onConnectivityChanged = _connectivity.onConnectivityChanged
            .map(_onResult)
            .asBroadcastStream();

  // ignore: unused_field
  final Connectivity _connectivity;

  final Stream<bool> _onConnectivityChanged;

  StreamSubscription<bool>? _subscription;

  /// A stream of boolean values indicating the current connectivity status.
  ///
  /// This stream emits `true` when the device has an active connection and
  /// `false` when there's no active connection.
  Stream<bool> get onConnectivityChanged => _onConnectivityChanged;

  bool _hasConnection = false;

  /// Checks if there is an active connection.
  bool get hasActiveConnection => _hasConnection;

  /// Initializes the [ConnectivityService].
  ///
  /// This method should be called to initialize the service. It checks the
  /// initial connectivity status and sets up a listener for connectivity changes.
  Future<ConnectivityService> init() async {
    final result = await _connectivity.checkConnectivity();
    _subscription = onConnectivityChanged.listen(_onChange);
    _hasConnection = _onResult(result);
    return this;
  }

  void _onChange(bool value) {
    _hasConnection = value;
  }

  static bool _onResult(ConnectivityResult result) {
    bool hasConnection = false;

    /// TODO: Add logic to handle for case [vpn] in android and iOS.
    if (result case ConnectivityResult.mobile || ConnectivityResult.wifi) {
      hasConnection = true;
    }

    return hasConnection;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
