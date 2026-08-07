/// Pure data model representing a reaction on a **course**.
///
/// **Critical:** This application supports reactions **only for courses**.
/// Any attempt to create a [Reaction] with a [targetType] other than
/// `'course'` will throw an [ArgumentError].
///
/// This model contains no external dependencies and is immutable.
class Reaction {
  /// Unique identifier of the reaction.
  ///
  /// Can be null when creating a new reaction if the database generates
  /// the ID automatically.
  final String? id;

  /// ID of the user who reacted.
  final String userId;

  /// The type of the target – must be `'course'`.
  final String targetType;

  /// The ID of the target course.
  final String targetId;

  /// The reaction emoji or code (e.g. 👍, ❤️).
  final String type;

  /// Timestamp when the reaction was created.
  final DateTime createdAt;

  const Reaction._({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.type,
    required this.createdAt,
  });

  /// Creates a [Reaction] after ensuring [targetType] is exactly `'course'`.
  ///
  /// Throws [ArgumentError] if [targetType] is not `'course'`.
  factory Reaction({
    String? id,
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
      id: id,
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

  /// Creates a [Reaction] from a database map.
  ///
  /// The map must contain a `target_type` field equal to `'course'`,
  /// otherwise an [ArgumentError] is thrown.
  factory Reaction.fromMap(Map<String, dynamic> map) {
    final targetType = map['target_type'];

    if (targetType != 'course') {
      throw ArgumentError(
        'Reaction map must have target_type = "course", '
        'got "$targetType".',
      );
    }

    return Reaction(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      targetType: targetType as String,
      targetId: map['target_id'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
    );
  }

  /// Converts this [Reaction] to a map suitable for database operations.
  ///
  /// The `id` is omitted when null or empty, allowing Supabase/PostgreSQL
  /// to generate it automatically.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };

    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          targetType == other.targetType &&
          targetId == other.targetId &&
          type == other.type &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        targetType,
        targetId,
        type,
        createdAt,
      );

  @override
  String toString() =>
      'Reaction('
      'id: $id, '
      'userId: $userId, '
      'targetId: $targetId, '
      'type: $type'
      ')';
}