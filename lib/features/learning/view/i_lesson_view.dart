import '../../../features/learning/model/exercise.dart';
import '../../../features/learning/model/lesson.dart';

/// Abstract interface through which the lesson presenter communicates
/// with the lesson UI screen.
///
/// The view is responsible for rendering the state; no repository,
/// database, or GitHub access is performed here.
abstract class ILessonView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the lesson content.
  void showLesson(Lesson lesson);

  /// Displays the exercises associated with the lesson.
  void showExercises(List<Exercise> exercises);

  /// Shows an error message to the user.
  void showError(String message);

  /// Indicates that the lesson has been marked as completed.
  void markLessonCompleted();

  /// Navigates to the exercise detail/attempt screen for the given exercise ID.
  void navigateToExercise(String exerciseId);
}