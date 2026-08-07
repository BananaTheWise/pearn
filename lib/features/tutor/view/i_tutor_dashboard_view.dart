import '../../tutor/model/student_stat.dart';

/// Abstract interface through which the tutor presenter communicates
/// with the tutor dashboard UI.
///
/// The view is responsible for rendering the data; all business logic and
/// backend access is handled by the presenter and repositories.
abstract class ITutorDashboardView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays dashboard summary data (e.g., student count, course count).
  void showDashboard(Map<String, dynamic> data);

  /// Shows the list of student IDs enrolled in the tutor's courses.
  /// The actual student names can be resolved later.
  void showStudents(List<String> studentIds);

  /// Displays detailed statistics for a specific student in a course.
  void showStudentStats(StudentStat stats);

  /// Shows an error message.
  void showError(String message);

  /// Navigates to the course editor screen.
  /// If [courseId] is non‑null, the editor opens an existing course for editing;
  /// otherwise it creates a new course.
  void openCourseEditor(String? courseId);
}