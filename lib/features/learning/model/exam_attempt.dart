/// Pure data model representing a user's exam attempt.
///
/// Mapped from the `exam_attempts` database table.
/// This model does **not** perform any database operations or external calls.
class ExamAttempt {
  /// Unique identifier of the attempt.
  final String id;

  /// The ID of the user who made the attempt.
  final String userId;

  /// The ID of the attempted exam.
  final String examId;

  /// The score achieved (e.g., number of correct answers or percentage).
  final double score;

  /// Whether the attempt reached the passing threshold.
  final bool passed;

  /// Timestamp when the attempt was submitted.
  final DateTime attemptedAt;

  const ExamAttempt({
    required this.id,
    required this.userId,
    required this.examId,
    required this.score,
    required this.passed,
    required this.attemptedAt,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates an [ExamAttempt] from a raw database map.
  factory ExamAttempt.fromMap(Map<String, dynamic> map) {
    return ExamAttempt(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      examId: map['exam_id'] as String,
      score: (map['score'] as num).toDouble(),
      passed: map['passed'] as bool,
      attemptedAt: DateTime.parse(map['attempted_at'] as String),
    );
  }

  /// Converts this [ExamAttempt] to a map for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'exam_id': examId,
      'score': score,
      'passed': passed,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAttempt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          examId == other.examId &&
          score == other.score &&
          passed == other.passed &&
          attemptedAt == other.attemptedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        examId,
        score,
        passed,
        attemptedAt,
      );

  @override
  String toString() =>
      'ExamAttempt(id: $id, userId: $userId, examId: $examId, '
      'score: $score, passed: $passed, attemptedAt: $attemptedAt)';
}