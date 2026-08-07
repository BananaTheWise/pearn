/// Abstract interface through which the [AuthPresenter] communicates
/// with authentication screens (login, signup, etc.).
///
/// Concrete screens implement this interface to render the UI without
/// knowing about presenters, repositories, or backend services.
abstract class IAuthView {
  /// Displays the login form.
  void showLoginForm();

  /// Displays the sign-up form.
  void showSignUpForm();

  /// Shows a validation error message to the user.
  void showValidationError(String message);

  /// Displays a prompt asking the user to verify their email address.
  void showVerificationPrompt();

  /// Shows or hides a loading indicator.
  void showLoading(bool isLoading);

  /// Navigates the user to the main home screen after successful authentication.
  void navigateToHome();
}