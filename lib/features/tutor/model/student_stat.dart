/// Pure data model representing a student's statistics for a specific course,
/// as viewed by a tutor.
///
/// This model does **not** perform any backend calls or data aggregation.
/// It is assembled by the repository layer from existing `progress` and
/// `exam_attempts` data and passed to the presenter.
///
/// Only fields that can be derived from the current database schema are
/// included – no new columns are invented.
class StudentStat {
  /// Unique identifier for this statistics snapshot.
  /// Typically a composite of userId and courseId.
  final String id;

  /// ID of the student (user).
  final String userId;

  /// ID of the course (matches courses.course_id, an integer identity column).
  final int courseId;

  /// Number of lessons completed by the student in this course.
  final int completedLessonsCount;

  /// Total XP of the student (from their user profile, not per-course).
  final int totalXp;

  /// Current level of the student.
  final int currentLevel;

  /// Number of exam attempts made by the student for this course.
  final int examAttemptsCount;

  /// Average score across all exam attempts (0.0 to 1.0). `null` if no attempts.
  final double? averageExamScore;

  /// Number of exam attempts that passed.
  final int passedExamsCount;

  /// Last time the student was active in this course. `null` if never.
  final DateTime? lastActiveDate;

  const StudentStat({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.completedLessonsCount,
    required this.totalXp,
    required this.currentLevel,
    required this.examAttemptsCount,
    this.averageExamScore,
    required this.passedExamsCount,
    this.lastActiveDate,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [StudentStat] from a map (e.g. from an aggregated query).
  ///
  /// Required fields: `id`, `user_id`, `course_id`, `completed_lessons_count`,
  /// `total_xp`, `current_level`, `exam_attempts_count`, `passed_exams_count`.
  factory StudentStat.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final userId = map['user_id'];
    final courseId = map['course_id'];
    final completed = map['completed_lessons_count'];
    final totalXp = map['total_xp'];
    final currentLevel = map['current_level'];
    final attemptsCount = map['exam_attempts_count'];
    final passedCount = map['passed_exams_count'];

    if (id == null || userId == null || courseId == null ||
        completed == null || totalXp == null || currentLevel == null ||
        attemptsCount == null || passedCount == null) {
      throw const FormatException(
        'StudentStat map must contain non-null "id", "user_id", "course_id", '
        '"completed_lessons_count", "total_xp", "current_level", '
        '"exam_attempts_count", "passed_exams_count".',
      );
    }

    return StudentStat(
      id: id as String,
      userId: userId as String,
      courseId: (courseId as num).toInt(),
      completedLessonsCount: (completed as num).toInt(),
      totalXp: (totalXp as num).toInt(),
      currentLevel: (currentLevel as num).toInt(),
      examAttemptsCount: (attemptsCount as num).toInt(),
      averageExamScore: map['average_exam_score'] != null
          ? (map['average_exam_score'] as num).toDouble()
          : null,
      passedExamsCount: (passedCount as num).toInt(),
      lastActiveDate: map['last_active_date'] != null
          ? DateTime.tryParse(map['last_active_date'].toString())
          : null,
    );
  }

  /// Converts this [StudentStat] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'completed_lessons_count': completedLessonsCount,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'exam_attempts_count': examAttemptsCount,
      'average_exam_score': averageExamScore,
      'passed_exams_count': passedExamsCount,
      'last_active_date': lastActiveDate?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentStat &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StudentStat(id: $id, userId: $userId, courseId: $courseId, '
      'completed: $completedLessonsCount, xp: $totalXp, level: $currentLevel)';
}