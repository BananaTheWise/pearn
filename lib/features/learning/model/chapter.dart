/// Pure data model representing a course chapter.
///
/// Sourced from GitHub static content (e.g., `course.json`).
/// A chapter contains lessons and associated metadata.
///
/// This model has no external dependencies and is immutable.
class Chapter {
  /// Unique identifier for the chapter (often a folder name).
  final String id;

  /// Display title.
  final String title;

  /// Optional description.
  final String? description;

  /// Order within the course.
  final int? order;

  /// Lessons that belong to this chapter.
  final List<ChapterLesson> lessons;

  const Chapter({
    required this.id,
    required this.title,
    this.description,
    this.order,
    this.lessons = const [],
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Chapter] from a map.
  ///
  /// Throws [FormatException] if required fields (`id`, `title`) are missing.
  factory Chapter.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id == null || title == null) {
      throw const FormatException(
        'Chapter map must contain non-null "id" and "title" fields.',
      );
    }
    return Chapter(
      id: id as String,
      title: title as String,
      description: map['description'] as String?,
      order: map['order'] is int ? map['order'] as int : null,
      lessons: _parseLessons(map['lessons']),
    );
  }

  /// Converts this [Chapter] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'lessons': lessons.map((l) => l.toMap()).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<ChapterLesson> _parseLessons(dynamic lessonsData) {
    if (lessonsData is! List) return [];
    return lessonsData
        .whereType<Map<String, dynamic>>()
        .map((e) => ChapterLesson.fromMap(e))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          order == other.order &&
          _listEquals(lessons, other.lessons);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        order,
        Object.hashAll(lessons),
      );

  static bool _listEquals(List<ChapterLesson> a, List<ChapterLesson> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Chapter(id: $id, title: $title, lessons: ${lessons.length})';
}

/// Represents a lesson reference within a [Chapter].
///
/// Does not contain full lesson content, only identification metadata.
class ChapterLesson {
  /// Unique identifier (often the filename without extension).
  final String id;

  /// Display title of the lesson.
  final String title;

  /// Order within the chapter.
  final int? order;

  const ChapterLesson({
    required this.id,
    required this.title,
    this.order,
  });

  /// Creates a [ChapterLesson] from a map.
  factory ChapterLesson.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id == null || title == null) {
      throw const FormatException(
        'Lesson map must contain non-null "id" and "title" fields.',
      );
    }
    return ChapterLesson(
      id: id as String,
      title: title as String,
      order: map['order'] is int ? map['order'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'order': order,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterLesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          order == other.order;

  @override
  int get hashCode => Object.hash(id, title, order);

  @override
  String toString() => 'ChapterLesson(id: $id, title: $title)';
}