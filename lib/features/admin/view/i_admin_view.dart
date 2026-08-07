import '../../../core/models/user.dart';

/// Abstract interface through which admin presenters communicate with admin UI.
///
/// The view is responsible only for displaying data and returning user decisions.
/// All business logic, authorization, and backend access remains in the presenter
/// and repository layers.
abstract class IAdminView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the list of all users (or a filtered subset).
  void showUsers(List<User> users);

  /// Displays the list of tutors (users with role 'tutor').
  void showTutors(List<User> tutors);

  /// Displays pending courses awaiting review.
  void showPendingCourses(List<Map<String, dynamic>> courses);

  /// Displays unresolved reports (if the system supports them).
  void showReports(List<Map<String, dynamic>> reports);

  /// Displays system analytics data.
  void showAnalytics(Map<String, dynamic> data);

  /// Displays general system status information.
  void showSystemStatus(Map<String, dynamic> status);

  /// Asks the user to confirm an action. Returns `true` if confirmed.
  Future<bool> showConfirmation(String message);

  /// Shows an error message.
  void showError(String message);
}