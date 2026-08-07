/// Pure data model representing synchronization state/metadata for an entity.
///
/// Used to track when specific entities were last synchronized between the
/// local device and the backend. Separate from the pending-write queue.
///
/// This model does **not** perform network calls, database operations, or
/// any external communication.
class SyncRecord {
  /// Unique identifier for this sync record.
  final String id;

  /// The ID of the user this record belongs to.
  final String userId;

  /// The type of entity being tracked (e.g., `'course'`, `'note'`).
  final String entityType;

  /// The ID of the specific entity instance.
  final String entityId;

  /// Timestamp of the last successful synchronization.
  final DateTime lastSyncedAt;

  const SyncRecord({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.lastSyncedAt,
  });

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory SyncRecord.fromMap(Map<String, dynamic> map) {
    return SyncRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      lastSyncedAt: DateTime.parse(map['last_synced_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Returns a copy with the [lastSyncedAt] updated to the current time.
  SyncRecord markSynced() {
    return copyWith(lastSyncedAt: DateTime.now());
  }

  SyncRecord copyWith({
    String? id,
    String? userId,
    String? entityType,
    String? entityId,
    DateTime? lastSyncedAt,
  }) {
    return SyncRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & debug
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SyncRecord(id: $id, userId: $userId, entityType: $entityType, '
      'entityId: $entityId, lastSyncedAt: $lastSyncedAt)';
}