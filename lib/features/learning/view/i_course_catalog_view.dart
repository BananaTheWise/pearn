import '../../../features/learning/model/course.dart';

/// Abstract interface through which the course catalog presenter communicates
/// with the UI (the course catalog screen).
///
/// The concrete screen implementing this interface decides how each state
/// is rendered – no repository, GitHub, or Supabase calls are made here.
abstract class ICourseCatalogView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the list of available courses.
  void showCourses(List<Course> courses);

  /// Shows an error message to the user.
  void showError(String message);

  /// Navigates to the detail view of the specified course.
  void navigateToCourse(String courseId);

  /// Indicates that no courses are available.
  void showEmptyState();
}