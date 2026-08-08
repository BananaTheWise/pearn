import '../../../features/learning/model/exam_attempt.dart';

/// Abstract contract for exam attempt storage and retrieval.
abstract class ExamAttemptRepository {
  /// Saves an exam attempt.
  Future<ExamAttempt> saveAttempt(ExamAttempt attempt);

  /// Returns all attempts belonging to a user.
  Future<List<ExamAttempt>> getAttemptsForUser(
    String userId,
  );

  /// Returns all attempts for a specific user and exam.
  Future<List<ExamAttempt>> getAttemptsForExam(
    String userId,
    String examId,
  );
}