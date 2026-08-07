/// Abstract interface through which the tutor course editor presenter communicates
/// with the course editor UI.
///
/// The view renders the editor form and submission state; it does **not** contain
/// any backend logic, HTTP calls, or database access.
abstract class ITutorCourseEditorView {
  /// Shows or hides a loading indicator (e.g., while fetching an existing course).
  void showLoading(bool loading);

  /// Displays the course data in the editor.
  ///
  /// [courseData] is a map representing the full course definition (typically
  /// from a `course.json` file). If creating a new course, this may be an empty
  /// or partially pre‑filled map.
  void showCourseEditor(Map<String, dynamic> courseData);

  /// Shows a validation error for a specific field or global.
  void showValidationError(String message);

  /// Indicates whether a submission to GitHub is in progress.
  void showSubmitting(bool submitting);

  /// Called after a successful pull request creation.
  ///
  /// [pullRequestUrl] is the URL of the created pull request on GitHub that
  /// the admin will review.
  void showSubmissionSuccess(String pullRequestUrl);

  /// Shows a generic error message.
  void showError(String message);
}