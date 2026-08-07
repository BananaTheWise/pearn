import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';
import 'pending_write_queue.dart';

typedef WriteHandler = Future<void> Function(WriteOperation operation);

class SyncService {
  final ConnectivityService _connectivityService;
  final PendingWriteQueue _queue;
  final Map<String, WriteHandler> _handlers;

  StreamSubscription? _connectivitySub;

  SyncService({
    required ConnectivityService connectivityService,
    required PendingWriteQueue queue,
    required Map<String, WriteHandler> handlers,
  })  : _connectivityService = connectivityService,
        _queue = queue,
        _handlers = handlers;

  void initialize() {
    debugPrint('[SYNC] Sync service initializing');

    _connectivitySub?.cancel();

    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((online) {
      if (online) {
        _onConnectivityRestored();
      } else {
        debugPrint('[SYNC] Application offline');
      }
    });

    debugPrint('[SYNC] Sync service initialized');
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> _onConnectivityRestored() async {
    debugPrint('[SYNC] Connectivity restored');
    await _flushQueue();
  }

  Future<void> _flushQueue() async {
    final count = _queue.count;

    if (count == 0) {
      return;
    }

    debugPrint(
      '[SYNC] Synchronization started – $count pending operations',
    );

    final pendingOps = _queue.getAll();

    for (final op in pendingOps) {
      debugPrint(
        '[SYNC] Processing pending operation: ${op.type} '
        '(id: ${op.id})',
      );

      final handler = _handlers[op.type];

      if (handler == null) {
        debugPrint(
          '[ERROR][SYNC] No handler registered for type: ${op.type}',
        );
        continue;
      }

      try {
        await handler(op);

        await _queue.remove(op.id);

        debugPrint(
          '[SYNC] Pending operation completed: ${op.id}',
        );
      } catch (e) {
        debugPrint(
          '[ERROR][SYNC] Pending operation failed: ${op.type}',
        );

        // Leave it in the queue.
      }
    }

    debugPrint('[SYNC] Synchronization completed');
  }
}