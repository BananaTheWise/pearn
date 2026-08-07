import '../../../features/learning/model/exercise.dart';

/// Abstract interface through which the exercise presenter communicates
/// with the exercise UI screen.
///
/// The view is responsible for rendering the exercise content and feedback.
/// No repository, backend, or direct data access is performed here.
abstract class IExerciseView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the given exercise content.
  void showExercise(Exercise exercise);

  /// Shows the result of the user's answer.
  ///
  /// [correct] indicates whether the answer was correct.
  /// [explanation] optionally provides additional feedback.
  void showResult(bool correct, String? explanation);

  /// Shows an error message.
  void showError(String message);

  /// Navigates to the next exercise.
  void navigateToNextExercise();

  /// Indicates that all exercises have been completed.
  void showCompletion();
}