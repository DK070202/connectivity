import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';
import 'no_connection_state_widget.dart';

/// An abstract interface class for managing restartable states.
///
/// Classes implementing this interface are responsible for managing the state
/// that can be loaded, reloaded, and checked for the need of reloading.

abstract interface class RestartableStateInterface {
  /// Loads the state asynchronously.
  ///
  /// Subclasses should implement this method to perform the necessary
  /// operations for loading the state.
  Future<void> loadState();

  /// Reloads the state by calling [loadState] again.
  ///
  /// This method triggers the reloading of the state by invoking the [loadState]
  /// method. Subclasses should implement the [loadState] method to handle the
  /// reloading process.
  Future<void> reloadState();

  /// Checks if the state needs to be reloaded.
  ///
  /// Subclasses should implement this method to provide a logic that determines
  /// whether the state should be reloaded.
  ///
  /// Returns `true` if the state should be reloaded, otherwise `false`.
  bool shouldReload();
}

/// A mixin that provides connection-aware functionality to a [State] of a
/// [StatefulWidget].
///
/// This mixin extends the capabilities of a stateful widget by adding
/// connection-aware behavior. It manages connectivity changes and allows
/// reloading the state when the connection is restored,
/// based on the [shouldReload] logic.
///
/// The mixin requires the stateful widget it is mixed into to implement the
/// [RestartableStateInterface] interface.
mixin ConnectionAwareMixin<T extends StatefulWidget> on State<T> {
  /// Tracks the current connection status.
  bool hasConnection = false;

  bool get initialConnectionState;

  Stream<bool> get onConnectivityChanged;

  /// Subscription for listening to connection changes.
  StreamSubscription<bool>? _subscription;

  /// Notifies the consumers when there is a change in connectivity state.
  ///
  /// The implementing state should override this method to respond to changes
  /// in connection status.
  void onConnectionStateChange();

  @override
  void initState() {
    super.initState();
    hasConnection = initialConnectionState;
    _subscription = onConnectivityChanged.listen(_onChangeConnection);
  }

  /// Listens for changes in connectivity from [ConnectivityService] and notifies
  /// the current state.
  ///
  /// If [ConnectivityService.onConnectivityChanged] emits the same state as
  /// [ConnectivityService.hasActiveConnection], no state update is triggered.
  /// Otherwise, the state is updated and notifies the client with via
  /// [onConnectionStateChange].
  void _onChangeConnection(bool result) {
    hasConnection = result;
    onConnectionStateChange();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

/// A mixin that provides the provides default UI and behavior for connection
/// changes.
///
/// This mixin is designed to be used in conjunction with the [ConnectionAwareMixin]
/// and enhances its functionality by providing a default implementation for the
/// [build] method. It handles rendering the user interface based on the connection
/// status. If there is an active connection, it uses the [buildPage] method to render
/// the content; otherwise, it displays a default no-connection state.
mixin DefaultConnectionAwareStateMixin<T extends StatefulWidget>
    on ConnectionAwareMixin<T> implements RestartableStateInterface {
  /// Inject this both via di or any other proffered way.
  @override
  Stream<bool> get onConnectivityChanged =>
      connectionService.onConnectivityChanged;

  @override
  bool get initialConnectionState => connectionService.hasActiveConnection;

  @override
  void initState() {
    super.initState();
    reloadState();
  }

  /// Reloads the state of a widget in response to connection status changes.
  ///
  /// This method triggers a reload of the widget's state when called.
  /// It is often used to refresh the UI in response to changes in the
  /// connection status or any other relevant data.
  @override
  Future<void> reloadState() async {
    await loadState();
  }

  /// Loads the state of a widget in response to connection status changes.
  ///
  /// This method is responsible for updating the widget's state. It is
  /// often overridden to fetch data from a data source or perform any other
  /// necessary operations when the connection status changes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// FutureOr<void> loadState() async {
  ///   final newData = await fetchData(); // Fetch data from a data source
  ///   setState(() {
  ///     data = newData; // Update the state with the new data
  ///   });
  /// }
  /// ```
  @override
  Future<void> loadState() async {
    setState(() {});
  }

  /// Determines whether the widget should be reloaded based on connection changes.
  ///
  /// This method provides a way to control whether the widget's state should be
  /// reloaded when the connection is restored. Returning `true` indicates that
  /// the widget's state should be reloaded; returning `false` means that no
  /// reloading will occur.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// bool shouldReload() {
  ///   return data.isEmpty; // Reload only if data is empty
  /// }
  /// ```
  @override
  bool shouldReload() => true;

  /// Default implementation for handling changes in connection status within
  /// a [ConnectionAwareMixin] mixin.
  ///
  /// This method is automatically called when the connection status changes.
  /// It provides a default behavior for responding to changes in connection state.
  /// If [hasConnection] is `true` and the [shouldReload] method returns `true`,
  /// the [reloadState] method is called to reload the state. If either condition
  /// is not met, a call to [setState] is made to update the UI based on the
  /// current connection status.
  @override
  void onConnectionStateChange() {
    if (hasConnection && shouldReload()) {
      reloadState();
    } else {
      setState(() {});
    }
  }

  /// Describes the part of the user interface represented by this widget where
  /// there is an active connection.
  ///
  /// The implementing state should provide the content to be displayed when there
  /// is an active connection.
  Widget buildPage(BuildContext context);

  /// Default implementation of [State.build] when the state is mixed with
  /// [ConnectionAwareMixin].
  ///
  /// If there is an active connection available, it will render the user interface
  /// provided by [buildPage]. Otherwise, it will provide a default [NoConnectionStateWidget]
  /// as a fallback.
  ///
  /// Additionally wraps the [NoConnectionStateWidget] with [WillPopScope] to handle
  /// system navigation pop. If there is absence of connection, in that case
  /// pops current flutter activity.
  @protected
  @override
  Widget build(BuildContext context) {
    if (hasConnection) {
      return buildPage(context);
    } else {
      return WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop(animated: true);
          return false;
        },
        child: NoConnectionStateWidget(
          onRetry: reloadState,
        ),
      );
    }
  }
}
