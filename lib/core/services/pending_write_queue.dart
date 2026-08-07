import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

/// Represents a single pending write operation.
///
/// [idempotencyKey] is optional; when provided, the queue will not enqueue
/// a new operation if another pending operation already has the same key.
/// This prevents duplicate mutations (e.g., multiple autosaves of the same note).
class WriteOperation {
  final String id;
  final String type;           // e.g. 'note_save', 'note_delete'
  final Map<String, dynamic> data; // serialised payload (NO tokens/passwords)
  final String? idempotencyKey;    // optional deduplication key
  final DateTime createdAt;

  WriteOperation({
    required this.type,
    required this.data,
    this.idempotencyKey,
    String? id,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
}

/// A persistent FIFO queue of write operations that could not be
/// immediately synchronised because the backend was unreachable.
///
/// Uses Hive for lightweight persistence – it is **not** a full database.
class PendingWriteQueue {
  static const String _boxName = 'pending_write_queue';
  Box<Map>? _box;

  /// Initializes the Hive box. Must be called once before any other method.
  Future<void> initialize() async {
    debugPrint('[SYNC][QUEUE] Initializing write queue');
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<Map>(_boxName);
    } else {
      _box = await Hive.openBox<Map>(_boxName);
    }
    debugPrint('[SYNC][QUEUE] Write queue ready');
  }

  /// Adds a [WriteOperation] to the queue.
  ///
  /// If [operation.idempotencyKey] is not `null` and an existing pending
  /// operation has the same key, the operation is **not** enqueued again.
  Future<void> enqueue(WriteOperation operation) async {
    if (_box == null) throw StateError('PendingWriteQueue not initialised.');

    // Deduplication check
    if (operation.idempotencyKey != null) {
      final duplicates = _box!.values.where((map) =>
          map['idempotencyKey'] == operation.idempotencyKey);
      if (duplicates.isNotEmpty) {
        debugPrint('[SYNC][QUEUE] Duplicate write skipped (idempotencyKey: ${operation.idempotencyKey})');
        return;
      }
    }

    // Build entry map (no secrets allowed in data)
    final entry = <String, dynamic>{
      'id': operation.id,
      'type': operation.type,
      'data': operation.data,
      'idempotencyKey': operation.idempotencyKey,
      'createdAt': operation.createdAt.toIso8601String(),
    };

    await _box!.put(operation.id, entry);

    // Maintain order
    final order = _getOrderList();
    order.add(operation.id);
    await _setOrderList(order);

    debugPrint('[SYNC][QUEUE] Write queued');
    debugPrint('[SYNC][QUEUE] Pending writes: ${order.length}');
  }

  /// Returns the next [WriteOperation] (oldest) without removing it, or `null`.
  WriteOperation? peek() {
    if (_box == null) throw StateError('PendingWriteQueue not initialised.');
    final order = _getOrderList();
    if (order.isEmpty) return null;
    final id = order.first;
    final map = _box!.get(id);
    if (map == null) return null;
    return _mapToOperation(map);
  }

  /// Removes the operation with the given [id] from the queue.
  Future<void> remove(String id) async {
    if (_box == null) throw StateError('PendingWriteQueue not initialised.');
    await _box!.delete(id);
    final order = _getOrderList();
    order.remove(id);
    await _setOrderList(order);
  }

  /// Number of pending writes.
  int get count {
    if (_box == null) return 0;
    return _getOrderList().length;
  }

  /// Removes all pending writes.
  Future<void> clear() async {
    if (_box == null) throw StateError('PendingWriteQueue not initialised.');
    await _box!.clear();
    await _setOrderList([]);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the current order list (mutable).
  List<String> _getOrderList() {
    final raw = _box!.get('__queue_order__');
    if (raw == null) return [];
    return List<String>.from(raw['ids'] as List ?? []);
  }

  /// Persists the order list.
  Future<void> _setOrderList(List<String> order) async {
    await _box!.put('__queue_order__', {'ids': order});
  }

  WriteOperation _mapToOperation(Map map) {
    return WriteOperation(
      id: map['id'] as String,
      type: map['type'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      idempotencyKey: map['idempotencyKey'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}