import '../model/student_stat.dart';

/// Abstract contract for tutor-related data operations.
///
/// The concrete implementation ([TutorRepositorySupabase]) interacts with
/// the Supabase backend and GitHub for course submissions.
///
/// All operations follow the architecture: View → Presenter → Repository.
abstract class TutorRepository {
  /// Retrieves summary data for the tutor's dashboard.
  ///
  /// Returns a map containing counts and key metrics (e.g., number of students,
  /// courses under review, etc.). The exact keys are defined by the architecture.
  Future<Map<String, dynamic>> getDashboardData(String tutorId);

  /// Returns the list of students enrolled in courses managed by the tutor.
  Future<List<String>> getStudentsForTutor(String tutorId);

  /// Retrieves statistics for a specific student in a course.
  Future<StudentStat?> getStudentStat(
      String tutorId, String studentId, String courseId);

  /// Submits a course (new or updated) for admin review via GitHub pull request.
  ///
  /// [courseData] is the serialised course content (course.json + lessons, etc.).
  /// [tutorId] identifies the submitting tutor.
  ///
  /// Returns the URL of the created pull request.
  Future<String> submitCourseForReview(
      Map<String, dynamic> courseData, String tutorId);

  /// Returns a list of course IDs that are owned or managed by the tutor.
  Future<List<String>> getManagedCourseIds(String tutorId);
}