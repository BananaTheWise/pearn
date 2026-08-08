/// Pure data model representing a user's exam attempt.
///
/// Mapped from the `exam_attempts` database table.
///
/// Database:
/// - course_id -> int4
/// - score -> int4 (0-100)
///
/// Application:
/// - courseId -> int
/// - score -> double (0.0-1.0)
class ExamAttempt {
  /// Unique identifier of the attempt.
  final String id;

  /// ID of the user who made the attempt.
  final String userId;

  /// ID of the course containing the exam.
  final int courseId;

  /// ID of the attempted exam.
  final String examId;

  /// Score represented as a ratio from 0.0 to 1.0.
  ///
  /// Examples:
  /// 0.0 = 0%
  /// 0.5 = 50%
  /// 0.75 = 75%
  /// 1.0 = 100%
  final double score;

  /// Whether the attempt passed.
  final bool passed;

  /// Time when the attempt was submitted.
  final DateTime attemptedAt;

  const ExamAttempt({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.examId,
    required this.score,
    required this.passed,
    required this.attemptedAt,
  });

  // ---------------------------------------------------------------------------
  // FROM DATABASE
  // ---------------------------------------------------------------------------

  /// Creates an [ExamAttempt] from a Supabase database row.
  ///
  /// Supabase stores:
  /// score = 0-100
  ///
  /// The application receives:
  /// score = 0.0-1.0
  factory ExamAttempt.fromMap(Map<String, dynamic> map) {
    final rawScore = map['score'];

    if (rawScore is! num) {
      throw FormatException(
        'ExamAttempt score must be numeric, got: $rawScore',
      );
    }

    final rawCourseId = map['course_id'];

    if (rawCourseId is! num) {
      throw FormatException(
        'ExamAttempt course_id must be numeric, got: $rawCourseId',
      );
    }

    final rawId = map['id'];
    final rawUserId = map['user_id'];
    final rawExamId = map['exam_id'];
    final rawPassed = map['passed'];
    final rawAttemptedAt = map['attempted_at'];

    if (rawId is! String) {
      throw FormatException(
        'ExamAttempt id must be a String, got: $rawId',
      );
    }

    if (rawUserId is! String) {
      throw FormatException(
        'ExamAttempt user_id must be a String, got: $rawUserId',
      );
    }

    if (rawExamId is! String) {
      throw FormatException(
        'ExamAttempt exam_id must be a String, got: $rawExamId',
      );
    }

    if (rawPassed is! bool) {
      throw FormatException(
        'ExamAttempt passed must be a bool, got: $rawPassed',
      );
    }

    if (rawAttemptedAt is! String) {
      throw FormatException(
        'ExamAttempt attempted_at must be a String, got: $rawAttemptedAt',
      );
    }

    return ExamAttempt(
      id: rawId,
      userId: rawUserId,
      courseId: rawCourseId.toInt(),
      examId: rawExamId,

      // Database: 0-100
      // Application: 0.0-1.0
      score: rawScore.toDouble() / 100.0,

      passed: rawPassed,
      attemptedAt: DateTime.parse(rawAttemptedAt),
    );
  }

  // ---------------------------------------------------------------------------
  // TO DATABASE
  // ---------------------------------------------------------------------------

  /// Converts this attempt into a Supabase database row.
  ///
  /// Converts the application score:
  ///
  /// 0.0 -> 0
  /// 0.5 -> 50
  /// 0.75 -> 75
  /// 1.0 -> 100
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'exam_id': examId,
      'score': (score * 100).round(),
      'passed': passed,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // EQUALITY
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExamAttempt &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            userId == other.userId &&
            courseId == other.courseId &&
            examId == other.examId &&
            score == other.score &&
            passed == other.passed &&
            attemptedAt == other.attemptedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        courseId,
        examId,
        score,
        passed,
        attemptedAt,
      );

  @override
  String toString() {
    return 'ExamAttempt('
        'id: $id, '
        'userId: $userId, '
        'courseId: $courseId, '
        'examId: $examId, '
        'score: $score, '
        'passed: $passed, '
        'attemptedAt: $attemptedAt'
        ')';
  }
}