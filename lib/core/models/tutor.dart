/// Pure data model representing a tutor identity.
///
/// A tutor is a user with the role `'tutor'` in the `profiles` table.
/// This model exists to keep tutor-specific logic separate without inventing
/// fields that are not present in the database schema.
///
/// If future tutor-specific columns (e.g. `bio`, `specialties`) are added
/// to the schema, they should be added here – but only when the schema
/// explicitly supports them.
class Tutor {
  /// The user ID of the tutor. This matches `profiles.id`.
  final String userId;

  const Tutor({required this.userId});

  /// Creates a [Tutor] from a raw database map.
  ///
  /// Expects the map to contain at least the `'user_id'` key.
  factory Tutor.fromMap(Map<String, dynamic> map) {
    return Tutor(
      userId: map['user_id'] as String,
    );
  }

  /// Converts this [Tutor] to a map suitable for database operations.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tutor &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'Tutor(userId: $userId)';
}