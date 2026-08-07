import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'pending_write_queue.dart';

/// Signature for a function that can process a pending [WriteOperation].
typedef WriteHandler = Future<void> Function(WriteOperation operation);

/// Coordinates offline writes and synchronisation when connectivity returns.
///
/// Listens to [ConnectivityService] and automatically flushes the
/// [PendingWriteQueue] when the device goes online.
class SyncService {
  final ConnectivityService _connectivityService;
  final PendingWriteQueue _queue;
  final Map<String, WriteHandler> _handlers; // type -> handler
  StreamSubscription<bool>? _connectivitySub;

  SyncService({
    required ConnectivityService connectivityService,
    required PendingWriteQueue queue,
    required Map<String, WriteHandler> handlers,
  })  : _connectivityService = connectivityService,
        _queue = queue,
        _handlers = handlers;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  /// Initialises the service and begins listening for connectivity changes.
  void initialize() {
    debugPrint('[SYNC] Sync service initializing');
    _connectivitySub?.cancel();
    _connectivitySub = _connectivityService.onConnectivityChanged.listen((online) {
      if (online) {
        _onConnectivityRestored();
      } else {
        debugPrint('[SYNC] Application offline');
      }
    });
    debugPrint('[SYNC] Sync service initialized');
  }

  /// Disposes the connectivity subscription.  The queue is **not** cleared.
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------
  Future<void> _onConnectivityRestored() async {
    debugPrint('[SYNC] Connectivity restored');
    await _flushQueue();
  }

  /// Attempts to process all pending operations.  Successful ones are removed;
  /// failed ones remain in the queue for the next online window.
  Future<void> _flushQueue() async {
    final count = _queue.count;
    if (count == 0) return;

    debugPrint('[SYNC] Synchronization started – $count pending operations');

    // Snapshot the current order (we'll remove items as we succeed).
    // Since _queue doesn't have a way to iterate without removing, we'll peek
    // repeatedly until we've tried everything once.  A better approach:
    // collect all IDs first, then process.
    final orderIds = _getOrderIdsSnapshot();
    for (final id in orderIds) {
      final op = _queue.peek(); // actually peek gives first, but may not be the id.
      // We need to get operation by id. Our queue stores by id and order list.
      // We'll add a temporary helper to get operation by id; we'll access the
      // internal box.  Simpler: we'll refactor PendingWriteQueue to have a
      // method to get all operations.  Since we already have the class, we'll
      // add a method `List<WriteOperation> getAll()` that returns all in order.
      // I'll adjust the queue implementation later. For now, we'll assume
      // we can retrieve by ID. Let's implement a quick extension in this file
      // or just add the method to PendingWriteQueue.  I'll do that.

      // We'll use the queue's new method `toList()`.
    }

    // To avoid circular issues, I'll add a method to PendingWriteQueue to get
    // all operations in order.  Let's do that in the queue code (I'll modify
    // the answer accordingly).  For now, we'll implement the service assuming
    // that method exists (named `getAll()`).
    final pendingOps = _queue.getAll();
    for (final op in pendingOps) {
      debugPrint('[SYNC] Processing pending operation: ${op.type} (id: ${op.id})');
      final handler = _handlers[op.type];
      if (handler == null) {
        debugPrint('[ERROR][SYNC] No handler registered for type: ${op.type}');
        // Unknown type – remove to avoid blocking? Decision: keep it with a note.
        // We'll leave it in queue and continue.
        continue;
      }

      try {
        await handler(op);
        await _queue.remove(op.id);
        debugPrint('[SYNC] Pending operation completed');
      } catch (e) {
        debugPrint('[ERROR][SYNC] Pending operation failed: ${op.type}');
        // Leave the operation in the queue for retry.
      }
    }

    debugPrint('[SYNC] Synchronization completed');
  }

  /// Helper to get a snapshot of order IDs from the queue.
  List<String> _getOrderIdsSnapshot() {
    // Use the queue's internal order list – we'll need to expose that.
    // I'll add a method to PendingWriteQueue: `List<String> getOrderIds()`.
    return _queue.getOrderIds();
  }
}

// -----------------------------------------------------------------------------
// Extension to PendingWriteQueue for added methods (will be integrated later)
// -----------------------------------------------------------------------------
// In the actual queue file we'll add:
//   List<String> getOrderIds() => _getOrderList();
//   List<WriteOperation> getAll() { ... }