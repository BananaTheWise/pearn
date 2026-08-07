import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors device network connectivity and exposes it as a simple
/// online / offline boolean stream.
///
/// **Important:** A `true` value only means the device has a network
/// interface (Wi‑Fi, mobile data, Ethernet).  It does **not** guarantee
/// that the Supabase or GitHub backend is reachable – the [SyncService]
/// and individual repositories must handle backend failures separately.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  // ---------------------------------------------------------------------------
  // Initialisation (optional – logs only)
  // ---------------------------------------------------------------------------
  /// Logs that the service is ready.  No asynchronous work is performed.
  void initialize() {
    debugPrint('[NETWORK] Connectivity service initializing');
    debugPrint('[NETWORK] Connectivity service initialized');
  }

  // ---------------------------------------------------------------------------
  // Stream of connectivity changes
  // ---------------------------------------------------------------------------
  /// Emits `true` when the device is online and `false` when it is offline.
  ///
  /// Distinct values are emitted only when the state actually changes,
  /// preventing repeated logs.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .map((List<ConnectivityResult> results) =>
            !results.contains(ConnectivityResult.none))
        .distinct()
        .map((bool online) {
          debugPrint(
            '[NETWORK] Connectivity changed: ${online ? "ONLINE" : "OFFLINE"}',
          );
          return online;
        });
  }

  // ---------------------------------------------------------------------------
  // One‑shot check
  // ---------------------------------------------------------------------------
  /// Returns `true` if the device currently has network connectivity.
  Future<bool> isOnline() async {
    debugPrint('[NETWORK] Checking connectivity');
    try {
      final results = await _connectivity.checkConnectivity();
      final online = !results.contains(ConnectivityResult.none);
      debugPrint('[NETWORK] Connectivity result: ${online ? "ONLINE" : "OFFLINE"}');
      return online;
    } catch (e) {
      debugPrint('[ERROR][NETWORK] Connectivity check failed');
      // Assume offline on error.
      return false;
    }
  }
}