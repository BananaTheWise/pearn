/// Pure data model representing an administrative audit event.
///
/// Records important admin actions (e.g., course approval, user suspension)
/// for accountability. This model is immutable and does **not** interact with
/// any backend, repository, or service.
///
/// The [metadata] map must never contain passwords, tokens, or secrets.
class AuditLog {
  /// Unique identifier of the audit entry.
  final String id;

  /// User ID of the admin who performed the action.
  final String actorId;

  /// Description of the action (e.g., `'course_approved'`).
  final String action;

  /// Identifier of the resource or entity that was acted upon.
  final String targetId;

  /// Optional unstructured metadata about the event.
  /// **Must not contain sensitive credentials.**
  final Map<String, dynamic>? metadata;

  /// Timestamp when the action occurred.
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetId,
    this.metadata,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates an [AuditLog] from a raw database map.
  ///
  /// Required fields: `id`, `actor_id`, `action`, `target_id`, `created_at`.
  /// Throws [FormatException] if any required field is missing.
  factory AuditLog.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final actorId = map['actor_id'];
    final action = map['action'];
    final targetId = map['target_id'];
    final createdAt = map['created_at'];

    if (id == null || actorId == null || action == null ||
        targetId == null || createdAt == null) {
      throw const FormatException(
        'AuditLog map must contain non-null "id", "actor_id", '
        '"action", "target_id", and "created_at".',
      );
    }

    return AuditLog(
      id: id as String,
      actorId: actorId as String,
      action: action as String,
      targetId: targetId as String,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(createdAt as String),
    );
  }

  /// Converts this [AuditLog] to a map suitable for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actor_id': actorId,
      'action': action,
      'target_id': targetId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          actorId == other.actorId &&
          action == other.action &&
          targetId == other.targetId &&
          createdAt == other.createdAt &&
          _mapsEqual(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        id,
        actorId,
        action,
        targetId,
        createdAt,
        metadata != null
            ? Object.hashAll(metadata!.entries.map((e) => Object.hash(e.key, e.value)))
            : null,
      );

  static bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Debug representation (secrets are never included because we don't log them)
  // ---------------------------------------------------------------------------

  @override
  String toString() =>
      'AuditLog(id: $id, actorId: $actorId, action: $action, '
      'targetId: $targetId, createdAt: $createdAt)';
}