import 'enrollment.dart';

/// Abstract contract for enrollment persistence operations.
///
/// The concrete implementation will interact with the `enrollments` table.
abstract class EnrollmentRepository {
  /// Returns the enrollment record for the given user and course,
  /// or `null` if the user is not enrolled.
  Future<Enrollment?> getEnrollment(String userId, String courseId);

  /// Returns all enrollments for a specific user.
  Future<List<Enrollment>> getUserEnrollments(String userId);

  /// Enrolls the user in the specified course.
  /// If an enrollment already exists, this is a no‑op (or updates the status
  /// according to the concrete implementation).
  Future<void> enroll(String userId, String courseId);
}