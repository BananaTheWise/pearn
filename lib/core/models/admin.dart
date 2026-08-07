/// Pure data model representing an administrator identity.
///
/// An administrator is a user with the role `'admin'` in the `profiles` table.
/// This model exists to encapsulate admin-specific logic without introducing
/// fields that are not part of the database schema.
///
/// Authorization decisions are handled by presenters, repositories, and
/// backend RLS – not by this model.
class Admin {
  /// The user ID of the administrator, corresponding to `profiles.id`.
  final String userId;

  const Admin({required this.userId});

  /// Creates an [Admin] from a raw database map.
  ///
  /// The map must contain a `'user_id'` key.
  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      userId: map['user_id'] as String,
    );
  }

  /// Converts this [Admin] to a map suitable for database operations.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Admin &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'Admin(userId: $userId)';
}