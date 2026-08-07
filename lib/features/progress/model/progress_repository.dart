import '../../../features/progress/model/progress.dart';

/// Abstract contract for persistent learning progress storage.
///
/// The concrete implementation ([ProgressRepositorySupabase]) interacts
/// with the `progress` database table.
abstract class ProgressRepository {
  /// Retrieves the progress record for a specific user and course.
  ///
  /// Returns `null` if no progress has been tracked yet.
  Future<Progress?> getProgress(String userId, String courseId);

  /// Marks a lesson as completed for the given user and course.
  ///
  /// If no progress record exists yet, one is created.
  Future<void> markLessonCompleted(
      String userId, String courseId, String lessonId);

  /// Returns the list of completed lesson IDs for the given user and course.
  Future<List<String>> getCompletedLessons(String userId, String courseId);

  /// Fully overwrites (upserts) a progress record.
  ///
  /// Typically used for background sync or bulk updates.
  Future<void> saveProgress(Progress progress);
}