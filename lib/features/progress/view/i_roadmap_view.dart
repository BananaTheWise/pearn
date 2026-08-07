import '../../progress/model/progress.dart';
import '../../progress/model/roadmap.dart';

/// Abstract interface through which the roadmap presenter communicates
/// with the roadmap UI screen.
abstract class IRoadmapView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the full roadmap.
  void showRoadmap(Roadmap roadmap);

  /// Shows an error message.
  void showError(String message);

  /// Navigates to the course detail screen for the given [courseId].
  void navigateToCourse(String courseId);

  /// Updates the displayed progress for a specific course within the roadmap.
  ///
  /// [progress] may be `null` if no progress has been recorded yet.
  void showCourseProgress(String courseId, Progress? progress);
}