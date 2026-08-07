import '../../../features/learning/model/exam.dart';
import '../../../features/learning/model/exam_attempt.dart';

/// Abstract interface through which the exam presenter communicates
/// with the exam UI screen.
///
/// The view is responsible for displaying the exam, its questions, results,
/// and navigation. The presenter handles all business logic, including
/// submission of attempts.
abstract class IExamView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the exam overview (title, description, time limit, etc.).
  void showExam(Exam exam);

  /// Shows a specific question identified by its index in the exam.
  void showQuestion(int index);

  /// Displays the result after the exam attempt has been submitted and evaluated.
  void showResult(ExamAttempt attempt);

  /// Shows an error message to the user.
  void showError(String message);

  /// Navigates to the appropriate screen after the exam is completed or
  /// if the user chooses to exit.
  void navigateAfterExam();
}