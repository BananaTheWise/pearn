import '../../../core/models/audit_log.dart';
import '../../../core/models/user.dart';

/// Abstract contract for all administrative operations.
///
/// The concrete implementation ([AdminRepositorySupabase]) uses Supabase
/// and GitHub to execute these operations.  All methods are assumed to be
/// called in a context where the current user is verified as an admin.
abstract class AdminRepository {
  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  /// Returns a list of all users, optionally filtered by role and/or status.
  Future<List<User>> getUsers({String? role, String? status});

  /// Returns a single user by ID.
  Future<User?> getUser(String userId);

  /// Updates the status (active/suspended/banned) of a user.
  Future<void> updateUserStatus(String userId, String newStatus);

  /// Updates the role (student/tutor/admin) of a user.
  Future<void> updateUserRole(String userId, String newRole);

  // ---------------------------------------------------------------------------
  // Tutors
  // ---------------------------------------------------------------------------

  /// Returns all users with role = 'tutor'.
  Future<List<User>> getTutors();

  /// Returns a single tutor by ID.
  Future<User?> getTutor(String tutorId);

  /// Updates a tutor's status (typically active/suspended).
  Future<void> updateTutorStatus(String tutorId, String newStatus);

  // ---------------------------------------------------------------------------
  // Course Review / Approval
  // ---------------------------------------------------------------------------

  /// Returns a list of course submissions pending admin review.
  ///
  /// Each entry is a map containing at least 'course_id', 'title',
  /// 'tutor_id', 'pull_request_url', and 'submitted_at'.
  Future<List<Map<String, dynamic>>> getPendingCourses();

  /// Approves a course submission, merging the associated pull request and
  /// making the course publicly available.
  Future<void> approveCourse(String courseId);

  /// Rejects a course submission, closing the pull request without merging.
  /// [reason] is an optional explanation for the tutor.
  Future<void> rejectCourse(String courseId, String? reason);

  // ---------------------------------------------------------------------------
  // Reports (if the reports table still exists in the final schema)
  // ---------------------------------------------------------------------------

  /// Returns a list of unresolved reports.  Returns an empty list if the
  /// reports table has been removed from the schema.
  Future<List<Map<String, dynamic>>> getReports();

  /// Marks a report as resolved.
  Future<void> resolveReport(String reportId);

  // ---------------------------------------------------------------------------
  // Audit Logging
  // ---------------------------------------------------------------------------

  /// Persists a new audit log entry.
  Future<void> saveAuditLog(AuditLog entry);

  /// Returns all audit log entries, ordered by creation time descending.
  Future<List<AuditLog>> getAuditLogs();

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  /// Returns system‑wide analytics as a map.
  ///
  /// The map may contain keys such as 'total_users', 'active_users',
  /// 'total_courses', 'total_enrollments', etc.  Only metrics that can
  /// be derived from the current database schema are included.
  Future<Map<String, dynamic>> getSystemAnalytics();
}