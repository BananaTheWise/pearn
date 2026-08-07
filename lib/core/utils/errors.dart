/// Base class for all application-specific errors.
///
/// Each error holds a user‑safe [message] and optional [technicalDetails]
/// that should **never** be shown to the user.  The technical details are
/// only for logging / debugging.
class AppError implements Exception {
  /// Human-readable message suitable for display in the UI.
  final String message;

  /// Technical information for developers (e.g. exception type, status code).
  /// May be logged but never exposed to the user.
  final String? technicalDetails;

  const AppError(this.message, {this.technicalDetails});

  @override
  String toString() => 'AppError: $message';
}

/// Raised when a network operation fails (timeout, no connectivity, etc.).
class NetworkError extends AppError {
  const NetworkError([String message = 'Unable to connect. Please check your network.']
      , {super.technicalDetails})
      : super(message);
}

/// Raised when a database / backend query fails.
class DatabaseError extends AppError {
  const DatabaseError([String message = 'Unable to load data. Please try again.'
      , {super.technicalDetails}])
      : super(message);
}

/// Raised when authentication fails (invalid credentials, expired session, etc.).
class AuthenticationError extends AppError {
  const AuthenticationError([String message = 'Authentication failed. Please sign in again.'
      , {super.technicalDetails}])
      : super(message);
}

/// Raised when the current user does not have sufficient permissions.
class AuthorizationError extends AppError {
  const AuthorizationError([String message = 'You do not have permission to perform this action.'
      , {super.technicalDetails}])
      : super(message);
}

/// Raised when user input or application state fails validation.
class ValidationError extends AppError {
  const ValidationError(String message, {super.technicalDetails}) : super(message);
}

/// Raised when a synchronisation operation fails.
class SyncError extends AppError {
  const SyncError([String message = 'Synchronisation failed. Your changes have been saved locally.'
      , {super.technicalDetails}])
      : super(message);
}

/// Raised when a GitHub API operation fails.
class GitHubError extends AppError {
  const GitHubError([String message = 'An error occurred while communicating with GitHub.'
      , {super.technicalDetails}])
      : super(message);
}