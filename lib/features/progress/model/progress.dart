/// Pure data model representing a user's learning progress for a single
/// course.
///
/// There is no separate `progress` table — this is backed directly by the
/// `enrollments` row for the user/course (`completed_lessons`,
/// `completion_percent`, `last_accessed_at`). [courseId] is the app's
/// string course slug, not the Supabase integer `course_id`.
class Progress {
  /// ID of the user this progress belongs to.
  final String userId;

  /// The course slug (not the Supabase integer `course_id`).
  final String courseId;

  /// List of lesson IDs that the user has completed within the course.
  final List<String> completedLessonIds;

  /// Completion percentage (0-100).
  final double completionPercent;

  /// The last time the user accessed this course.
  final DateTime? lastAccessed;

  const Progress({
    required this.userId,
    required this.courseId,
    required this.completedLessonIds,
    this.completionPercent = 0,
    this.lastAccessed,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Progress] from a raw `enrollments` row.
  ///
  /// [courseSlug] must be resolved separately (via `CourseIdResolver`)
  /// before calling this, since the raw row only contains the integer
  /// `course_id`.
  factory Progress.fromMap(
    Map<String, dynamic> map, {
    required String courseSlug,
  }) {
    return Progress(
      userId: map['user_id'] as String,
      courseId: courseSlug,
      completedLessonIds: _parseList(map['completed_lessons']),
      completionPercent: (map['completion_percent'] as num?)?.toDouble() ?? 0,
      lastAccessed: map['last_accessed_at'] == null
          ? null
          : DateTime.parse(map['last_accessed_at'] as String),
    );
  }

  /// Converts this [Progress] to a map of just the progress-related
  /// columns on `enrollments` (caller adds `user_id`/`course_id`).
  Map<String, dynamic> toMap() {
    return {
      'completed_lessons': completedLessonIds,
      'completion_percent': completionPercent,
      'last_accessed_at': lastAccessed?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Progress copyWith({
    List<String>? completedLessonIds,
    double? completionPercent,
    DateTime? lastAccessed,
  }) {
    return Progress(
      userId: userId,
      courseId: courseId,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      completionPercent: completionPercent ?? this.completionPercent,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }

  static List<String> _parseList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => e.toString()).toList();
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Progress &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          courseId == other.courseId &&
          _listEquals(completedLessonIds, other.completedLessonIds) &&
          completionPercent == other.completionPercent &&
          lastAccessed == other.lastAccessed;

  @override
  int get hashCode => Object.hash(
        userId,
        courseId,
        Object.hashAll(completedLessonIds),
        completionPercent,
        lastAccessed,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Progress(userId: $userId, courseId: $courseId, '
      'completedLessons: ${completedLessonIds.length}, '
      'completionPercent: $completionPercent)';
}