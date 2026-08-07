import '../../progress/model/progress.dart';

/// Abstract interface through which the progress presenter communicates
/// with the progress UI screen.
///
/// The concrete screen is responsible for rendering the states.
/// No repositories, services, or business logic are called here.
abstract class IProgressView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the full progress for a course.
  void showProgress(Progress progress);

  /// Shows an error message to the user.
  void showError(String message);

  /// Shows updated progress after an activity (e.g., after a lesson completion).
  void showUpdatedProgress(Progress progress);

  /// Displays the current streak count.
  void showStreak(int streak);

  /// Displays the current user level.
  void showLevel(int level);
}