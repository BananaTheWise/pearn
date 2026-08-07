import '../../../features/learning/model/exam_attempt.dart';

/// Abstract contract for exam attempt storage and retrieval.
///
/// The concrete implementation ([ExamAttemptRepositorySupabase]) interacts
/// with the `exam_attempts` database table.
abstract class ExamAttemptRepository {
  /// Saves a new exam attempt and returns it with any server-generated fields.
  Future<ExamAttempt> saveAttempt(ExamAttempt attempt);

  /// Returns all attempts for a given user.
  Future<List<ExamAttempt>> getAttemptsForUser(String userId);

  /// Returns all attempts for a specific exam by a given user.
  Future<List<ExamAttempt>> getAttemptsForExam(String userId, String examId);
}