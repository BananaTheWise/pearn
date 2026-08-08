/// Pure data model representing a reaction on a course.
///
/// Pearn currently supports reactions only for courses.
///
/// A reaction is uniquely identified by the combination:
///   user_id + target_type + target_id
///
/// This matches the Supabase primary key:
///   PRIMARY KEY (user_id, target_type, target_id)
///
/// The model contains no database-specific ID because the database
/// does not have a separate `id` column for reactions.
///
/// This model is immutable.
class Reaction {
  /// ID of the user who reacted.
  final String userId;

  /// Type of the target.
  ///
  /// Pearn currently supports only:
  ///   'course'
  final String targetType;

  /// ID of the target course.
  ///
  /// This corresponds to the Supabase `target_id` column.
  final String targetId;

  /// Reaction type/code.
  ///
  /// Examples:
  ///   'like'
  ///   'love'
  ///   'fire'
  ///   'bookmark'
  final String type;

  /// Timestamp when the reaction was created.
  final DateTime createdAt;

  const Reaction._({
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.type,
    required this.createdAt,
  });

  /// Creates a [Reaction].
  ///
  /// Only course reactions are currently supported.
  ///
  /// Throws [ArgumentError] when [targetType] is not `'course'`.
  factory Reaction({
    required String userId,
    required String targetType,
    required String targetId,
    required String type,
    required DateTime createdAt,
  }) {
    if (targetType != 'course') {
      throw ArgumentError(
        'Reactions are only allowed on courses. '
        'Received targetType: "$targetType".',
      );
    }

    return Reaction._(
      userId: userId,
      targetType: targetType,
      targetId: targetId,
      type: type,
      createdAt: createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Reaction] from a Supabase database row.
  ///
  /// Expected database columns:
  ///
  ///   user_id
  ///   target_type
  ///   target_id
  ///   type
  ///   created_at
  ///
  /// There is intentionally no `id` field because the Supabase
  /// `reactions` table does not contain one.
  factory Reaction.fromMap(Map<String, dynamic> map) {
    final targetType = map['target_type'];

    if (targetType != 'course') {
      throw ArgumentError(
        'Reaction map must have target_type = "course", '
        'got "$targetType".',
      );
    }

    final userId = map['user_id'];
    final targetId = map['target_id'];
    final type = map['type'];
    final createdAt = map['created_at'];

    if (userId == null) {
      throw ArgumentError(
        'Reaction map is missing required field: user_id',
      );
    }

    if (targetId == null) {
      throw ArgumentError(
        'Reaction map is missing required field: target_id',
      );
    }

    if (type == null) {
      throw ArgumentError(
        'Reaction map is missing required field: type',
      );
    }

    if (createdAt == null) {
      throw ArgumentError(
        'Reaction map is missing required field: created_at',
      );
    }

    return Reaction(
      userId: userId as String,
      targetType: targetType as String,
      targetId: targetId as String,
      type: type as String,
      createdAt: DateTime.parse(createdAt as String),
    );
  }

  /// Converts this [Reaction] into a map suitable for Supabase.
  ///
  /// Matches the exact database columns:
  ///
  ///   user_id
  ///   target_type
  ///   target_id
  ///   type
  ///   created_at
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Reaction &&
            runtimeType == other.runtimeType &&
            userId == other.userId &&
            targetType == other.targetType &&
            targetId == other.targetId &&
            type == other.type &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      targetType,
      targetId,
      type,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Reaction('
        'userId: $userId, '
        'targetType: $targetType, '
        'targetId: $targetId, '
        'type: $type, '
        'createdAt: $createdAt'
        ')';
  }
}