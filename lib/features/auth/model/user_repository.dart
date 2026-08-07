import '../../../core/models/user.dart';

/// Abstract contract for user/profile persistence.
///
/// This interface defines the required repository operations without any
/// database-specific implementation. The concrete implementation is provided
/// by `UserRepositorySupabase`.
abstract class UserRepository {
  /// Finds a user profile by its unique ID.
  Future<User?> findById(String id);

  /// Finds a user profile by email address.
  Future<User?> findByEmail(String email);

  /// Creates or updates a user profile.
  Future<User> save(User user);

  /// Deletes a user profile by ID.
  /// Returns `true` if the deletion was successful.
  Future<bool> delete(String id);

  /// Searches for users matching the given [query].
  /// The implementation defines which fields are searched.
  Future<List<User>> search(String query);
}