/// Base class for all application-specific errors.
class AppError implements Exception {
  final String message;
  final String? technicalDetails;

  const AppError(
    this.message, {
    this.technicalDetails,
  });

  @override
  String toString() => 'AppError: $message';
}

/// Raised when a network operation fails.
class NetworkError extends AppError {
  const NetworkError({
    String message = 'Unable to connect. Please check your network.',
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}

/// Raised when a database / backend query fails.
class DatabaseError extends AppError {
  const DatabaseError({
    String message = 'Unable to load data. Please try again.',
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}

/// Raised when authentication fails.
class AuthenticationError extends AppError {
  const AuthenticationError({
    String message = 'Authentication failed. Please sign in again.',
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}

/// Raised when the current user does not have sufficient permissions.
class AuthorizationError extends AppError {
  const AuthorizationError({
    String message = 'You do not have permission to perform this action.',
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}

/// Raised when user input or application state fails validation.
class ValidationError extends AppError {
  const ValidationError(
    String message, {
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}

/// Raised when a synchronisation operation fails.
class SyncError extends AppError {
  const SyncError({
    String message =
        'Synchronisation failed. Your changes have been saved locally.',
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}

/// Raised when a GitHub API operation fails.
class GitHubError extends AppError {
  const GitHubError({
    String message =
        'An error occurred while communicating with GitHub.',
    String? technicalDetails,
  }) : super(
          message,
          technicalDetails: technicalDetails,
        );
}