/// Pure data model representing a user's enrollment in a course, including
/// their progress within it.
///
/// Mapped from the `enrollments` database table. There is no separate
/// `progress` table — completion tracking (`completed_lessons`,
/// `completion_percent`, `last_accessed_at`) lives directly on this row.
///
/// [courseId] is the app's string course slug (e.g. `python-basics`). The
/// integer `course_id` primary key used by Supabase is translated at the
/// repository boundary via `CourseIdResolver` and never appears here.
class Enrollment {
  /// The ID of the enrolled user.
  final String userId;

  /// The course slug (not the Supabase integer `course_id`).
  final String courseId;

  /// Timestamp when the enrollment was created.
  final DateTime enrolledAt;

  /// Timestamp when the course was completed, if applicable.
  final DateTime? completedAt;

  /// The last time the user accessed this course.
  final DateTime? lastAccessedAt;

  /// List of lesson IDs the user has completed within the course.
  final List<String> completedLessonIds;

  /// Completion percentage (0-100).
  final double completionPercent;

  const Enrollment({
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    this.completedAt,
    this.lastAccessedAt,
    this.completedLessonIds = const [],
    this.completionPercent = 0,
  });

  // ---------------------------------------------------------------------------
  // Derived status
  // ---------------------------------------------------------------------------

  /// Derived enrollment status. `enrollments` has no `status` column, so
  /// this is computed from [completedAt]: `'completed'` once the course is
  /// finished, `'active'` otherwise (an [Enrollment] existing at all means
  /// the user is enrolled — there's no `'dropped'` state in this schema).
  String get status => completedAt != null ? 'completed' : 'active';

  /// Whether the course has been completed.
  bool get isCompleted => completedAt != null;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates an [Enrollment] from a raw database row.
  ///
  /// [courseSlug] must be resolved separately (via `CourseIdResolver`)
  /// before calling this, since the raw row only contains the integer
  /// `course_id`.
  factory Enrollment.fromMap(
    Map<String, dynamic> map, {
    required String courseSlug,
  }) {
    return Enrollment(
      userId: map['user_id'] as String,
      courseId: courseSlug,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      lastAccessedAt: map['last_accessed_at'] == null
          ? null
          : DateTime.parse(map['last_accessed_at'] as String),
      completedLessonIds: _parseList(map['completed_lessons']),
      completionPercent: (map['completion_percent'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Converts this [Enrollment] to a map for database insertion/update.
  ///
  /// [courseIdInt] is the integer `course_id` resolved from [courseId]
  /// (the slug) via `CourseIdResolver` — passed in separately since this
  /// model only knows the slug.
  Map<String, dynamic> toMap({required int courseIdInt}) {
    return {
      'user_id': userId,
      'course_id': courseIdInt,
      'enrolled_at': enrolledAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'completed_lessons': completedLessonIds,
      'completion_percent': completionPercent,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Enrollment copyWith({
    DateTime? completedAt,
    DateTime? lastAccessedAt,
    List<String>? completedLessonIds,
    double? completionPercent,
  }) {
    return Enrollment(
      userId: userId,
      courseId: courseId,
      enrolledAt: enrolledAt,
      completedAt: completedAt ?? this.completedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      completionPercent: completionPercent ?? this.completionPercent,
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
      other is Enrollment &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          courseId == other.courseId &&
          enrolledAt == other.enrolledAt &&
          completedAt == other.completedAt &&
          lastAccessedAt == other.lastAccessedAt &&
          completionPercent == other.completionPercent &&
          _listEquals(completedLessonIds, other.completedLessonIds);

  @override
  int get hashCode => Object.hash(
        userId,
        courseId,
        enrolledAt,
        completedAt,
        lastAccessedAt,
        completionPercent,
        Object.hashAll(completedLessonIds),
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
      'Enrollment(userId: $userId, courseId: $courseId, '
      'completedLessons: ${completedLessonIds.length}, '
      'completionPercent: $completionPercent, enrolledAt: $enrolledAt)';
}