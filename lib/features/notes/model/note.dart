/// Pure data model representing a user's note.
///
/// Notes are associated with a specific course and lesson context.
/// This model contains no external dependencies and is immutable.
///
/// Mapped from the `notes` database table.
class Note {
  /// Unique identifier of the note.
  final String id;

  /// ID of the user who owns the note.
  final String userId;

  /// ID of the course this note belongs to.
  final String courseId;

  /// ID of the lesson this note belongs to.
  final String lessonId;

  /// Optional title of the note. Can be `null`.
  final String? title;

  /// The note's content. Must not be empty.
  final String content;

  /// Timestamp when the note was created.
  final DateTime createdAt;

  /// Timestamp when the note was last updated.
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.lessonId,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Note] from a raw database map.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory Note.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final userId = map['user_id'];
    final courseId = map['course_id'];
    final lessonId = map['lesson_id'];
    final content = map['content'];
    final createdAt = map['created_at'];
    final updatedAt = map['updated_at'];

    if (id == null || userId == null || courseId == null || lessonId == null ||
        content == null || createdAt == null || updatedAt == null) {
      throw const FormatException(
        'Note map must contain non-null "id", "user_id", "course_id", '
        '"lesson_id", "content", "created_at", and "updated_at".',
      );
    }

    return Note(
      id: id as String,
      userId: userId as String,
      courseId: courseId as String,
      lessonId: lessonId as String,
      title: map['title'] as String?,
      content: content as String,
      createdAt: DateTime.parse(createdAt as String),
      updatedAt: DateTime.parse(updatedAt as String),
    );
  }

  /// Converts this [Note] to a map suitable for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'lesson_id': lessonId,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields updated.
  Note copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? lessonId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          courseId == other.courseId &&
          lessonId == other.lessonId &&
          title == other.title &&
          content == other.content &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        courseId,
        lessonId,
        title,
        content,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'Note(id: $id, userId: $userId, courseId: $courseId, lessonId: $lessonId, '
      'title: $title, updatedAt: $updatedAt)';
}