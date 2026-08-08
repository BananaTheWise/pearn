import '../../../features/learning/model/exercise.dart';

/// Interface through which the exercise presenter communicates
/// with the exercise UI.
abstract class IExerciseView {
  /// Shows or hides the loading indicator.
  void showLoading(bool loading);

  /// Displays an exercise.
  void showExercise(Exercise exercise);

  /// Displays the result of an answer.
  void showResult(
    bool correct,
    String? explanation,
  );

  /// Displays an error.
  void showError(String message);

  /// Indicates that all exercises have been completed.
  void showCompletion();
}