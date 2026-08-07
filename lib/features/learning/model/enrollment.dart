/// Pure data model representing a user's enrollment in a course.
///
/// Mapped from the `enrollments` database table.
/// This model does **not** perform any database operations or external calls.
class Enrollment {
  /// The ID of the enrolled user.
  final String userId;

  /// The ID of the course.
  final String courseId;

  /// Timestamp when the enrollment was created.
  final DateTime enrolledAt;

  /// Current enrollment status (e.g., `'active'`, `'completed'`, `'dropped'`).
  final String status;

  /// Timestamp when the course was completed, if applicable.
  final DateTime? completedAt;

  const Enrollment({
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    required this.status,
    this.completedAt,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates an [Enrollment] from a raw database map.
  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      userId: map['user_id'] as String,
      courseId: map['course_id'] as String,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
      status: map['status'] as String,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
    );
  }

  /// Converts this [Enrollment] to a map for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'course_id': courseId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enrollment &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          courseId == other.courseId &&
          enrolledAt == other.enrolledAt &&
          status == other.status &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
        userId,
        courseId,
        enrolledAt,
        status,
        completedAt,
      );

  @override
  String toString() =>
      'Enrollment(userId: $userId, courseId: $courseId, status: $status, '
      'enrolledAt: $enrolledAt, completedAt: $completedAt)';
}