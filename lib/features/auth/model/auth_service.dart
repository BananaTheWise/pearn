import '../../../core/models/session.dart';
import '../../../core/models/user.dart';

/// Represents the current authentication state of the application.
enum AuthState {
  /// The user is authenticated and a session is active.
  authenticated,

  /// No user is signed in.
  unauthenticated,

  /// The authentication state is being determined (e.g., during app launch).
  loading,
}

/// Abstract contract for authentication operations.
///
/// All concrete authentication implementations (e.g., Supabase, Firebase)
/// must implement this interface. The contract ensures that presenters and
/// views do not depend on a specific backend.
abstract class AuthService {
  /// Creates a new account with the given [email] and [password].
  /// Returns the newly created [User] profile.
  Future<User> signUp(String email, String password);

  /// Authenticates a user with [email] and [password].
  /// Returns a [Session] containing the authentication tokens.
  Future<Session> login(String email, String password);

  /// Initiates the Google Sign-In flow and authenticates the user.
  /// Returns the [User] profile associated with the Google account.
  Future<User> signInWithGoogle();

  /// Logs out the current user and clears the session.
  Future<void> logout();

  /// Sends a password reset email to the given [email] address.
  Future<void> requestPasswordReset(String email);

  /// Resets the user's password using [newPassword].
  /// The user must already be in a valid password-reset flow
  /// (e.g., via a deep link).
  Future<void> resetPassword(String newPassword);

  /// Emits the current [AuthState] whenever it changes.
  Stream<AuthState> authStateChanges();

  
}

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}