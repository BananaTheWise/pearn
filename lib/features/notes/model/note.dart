/// Pure data model representing a user's note.
///
/// Mapped from the `notes` database table. The table has no dedicated
/// `course_id`/`lesson_id` columns — instead it uses a generic
/// `attached_to_type`/`attached_to_id` pair (so notes could in principle
/// attach to a lesson, exercise, exam, etc). Course/lesson notes use
/// `attached_to_type = 'lesson'` and encode both ids into `attached_to_id`
/// as `'<courseId>:<lessonId>'`. [courseId]/[lessonId] stay as regular
/// properties here so the rest of the app doesn't need to know about that
/// encoding.
///
/// There is also no `created_at` column on this table — only `updated_at`.
class Note {
  /// Unique identifier of the note. Empty string for an unsaved draft —
  /// [toMap] omits `id` in that case so Postgres generates it on insert.
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

  /// Free-form tags associated with the note.
  final List<String> tags;

  /// Timestamp when the note was last updated.
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.lessonId,
    this.title,
    required this.content,
    this.tags = const [],
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
    final content = map['content'];
    final updatedAt = map['updated_at'];

    if (id == null || userId == null || content == null || updatedAt == null) {
      throw const FormatException(
        'Note map must contain non-null "id", "user_id", "content", '
        'and "updated_at".',
      );
    }

    final context = _parseAttachedTo(
      map['attached_to_type'] as String?,
      map['attached_to_id'] as String?,
    );

    return Note(
      id: id as String,
      userId: userId as String,
      courseId: context.courseId,
      lessonId: context.lessonId,
      title: map['title'] as String?,
      content: content as String,
      tags: _parseList(map['tags']),
      updatedAt: DateTime.parse(updatedAt as String),
    );
  }

  /// Converts this [Note] to a map suitable for database insertion/update.
  ///
  /// Omits `id` entirely when it's empty (an unsaved draft) so Postgres
  /// generates the UUID on insert instead of receiving an invalid empty
  /// string for a `uuid` column.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'content': content,
      'attached_to_type': 'lesson',
      'attached_to_id': '$courseId:$lessonId',
      'tags': tags,
      'updated_at': updatedAt.toIso8601String(),
    };

    if (id.isNotEmpty) {
      map['id'] = id;
    }

    return map;
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
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _parseList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => e.toString()).toList();
  }

  static _AttachedContext _parseAttachedTo(String? type, String? id) {
    if (type != 'lesson' || id == null) {
      return const _AttachedContext('', '');
    }

    final separatorIndex = id.indexOf(':');
    if (separatorIndex == -1) {
      return const _AttachedContext('', '');
    }

    return _AttachedContext(
      id.substring(0, separatorIndex),
      id.substring(separatorIndex + 1),
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
          _listEquals(tags, other.tags) &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        courseId,
        lessonId,
        title,
        content,
        Object.hashAll(tags),
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
      'Note(id: $id, userId: $userId, courseId: $courseId, lessonId: $lessonId, '
      'title: $title, updatedAt: $updatedAt)';
}

class _AttachedContext {
  final String courseId;
  final String lessonId;

  const _AttachedContext(this.courseId, this.lessonId);
}