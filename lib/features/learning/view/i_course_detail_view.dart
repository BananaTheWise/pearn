import '../../../features/learning/model/enrollment.dart';
import '../../learning/model/chapter.dart';
import '../../learning/model/course.dart';

/// Abstract interface through which the course detail presenter communicates
/// with the UI.
///
/// Reactions are **course-only**. There is no reaction system for lessons,
/// exercises, exams, or any other entity.
abstract class ICourseDetailView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the course information.
  void showCourse(Course course);

  /// Shows the list of chapters.
  void showChapters(List<Chapter> chapters);

  /// Displays the user's enrollment state for this course.
  void showEnrollmentState(Enrollment? enrollment);

  /// Shows an error message.
  void showError(String message);

  /// Navigates to the lesson detail screen.
  void navigateToLesson(String lessonId);

  /// Updates the reaction state for the course.
  ///
  /// [userReaction] is the emoji/code of the current user's reaction,
  /// or `null` if they haven't reacted.
  /// [totalReactions] is the total count of all reactions.
  void showReactionState(String? userReaction, int totalReactions);
}