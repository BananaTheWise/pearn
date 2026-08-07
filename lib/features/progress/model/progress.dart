/// Pure data model representing a user's learning progress for a single course.
///
/// Mapped from the `progress` table (or similar). This model contains no
/// external dependencies and is immutable.
///
/// Required fields must be present in the source map; otherwise a
/// [FormatException] is thrown.
class Progress {
  /// Unique identifier of the progress record.
  final String id;

  /// ID of the user this progress belongs to.
  final String userId;

  /// ID of the course the progress is tracked for.
  final String courseId;

  /// List of lesson IDs that the user has completed within the course.
  ///
  /// Stored as a JSON array in the database.
  final List<String> completedLessonIds;

  /// The last time the user accessed this course.
  final DateTime lastAccessed;

  /// Timestamp when the progress record was created.
  final DateTime createdAt;

  /// Timestamp when the progress record was last updated.
  final DateTime updatedAt;

  const Progress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.completedLessonIds,
    required this.lastAccessed,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Progress] from a raw database map.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory Progress.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final userId = map['user_id'];
    final courseId = map['course_id'];
    final lastAccessed = map['last_accessed'];
    final createdAt = map['created_at'];
    final updatedAt = map['updated_at'];

    if (id == null || userId == null || courseId == null ||
        lastAccessed == null || createdAt == null || updatedAt == null) {
      throw const FormatException(
        'Progress map must contain non-null "id", "user_id", "course_id", '
        '"last_accessed", "created_at", and "updated_at".',
      );
    }

    return Progress(
      id: id as String,
      userId: userId as String,
      courseId: courseId as String,
      completedLessonIds: _parseList(map['completed_lesson_ids']),
      lastAccessed: DateTime.parse(lastAccessed as String),
      createdAt: DateTime.parse(createdAt as String),
      updatedAt: DateTime.parse(updatedAt as String),
    );
  }

  /// Converts this [Progress] to a map suitable for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'completed_lesson_ids': completedLessonIds,
      'last_accessed': lastAccessed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  Progress copyWith({
    String? id,
    String? userId,
    String? courseId,
    List<String>? completedLessonIds,
    DateTime? lastAccessed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Progress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
          id == other.id &&
          userId == other.userId &&
          courseId == other.courseId &&
          _listEquals(completedLessonIds, other.completedLessonIds) &&
          lastAccessed == other.lastAccessed &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        courseId,
        Object.hashAll(completedLessonIds),
        lastAccessed,
        createdAt,
        updatedAt,
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
      'Progress(id: $id, userId: $userId, courseId: $courseId, '
      'completedLessons: ${completedLessonIds.length}, lastAccessed: $lastAccessed)';
}