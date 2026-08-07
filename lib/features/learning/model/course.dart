import 'chapter.dart';
/// Pure data model representing a learning course.
///
/// Sourced from GitHub static content (e.g., `course.json`).
/// This model contains no external dependencies and is immutable.
///
/// Required fields must be present in the source map; otherwise a
/// [FormatException] is thrown during parsing.
class Course {
  final String id;
  final String title;
  final String? description;
  final String? language;
  final String? level;
  final int? order;
  final List<Chapter> chapters;

  const Course({
    required this.id,
    required this.title,
    this.description,
    this.language,
    this.level,
    this.order,
    this.chapters = const [],
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Course] from a map (e.g., parsed from `course.json`).
  ///
  /// Throws [FormatException] if required fields (`id`, `title`) are missing.
  factory Course.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];

    if (id == null || title == null) {
      throw const FormatException(
        'Course map must contain non-null "id" and "title" fields.',
      );
    }

    return Course(
      id: id as String,
      title: title as String,
      description: map['description'] as String?,
      language: map['language'] as String?,
      level: map['level'] as String?,
      order: map['order'] is int ? map['order'] as int : null,
      chapters: _parseChapters(map['chapters']),
    );
  }

  /// Converts this [Course] to a map suitable for JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'level': level,
      'order': order,
      'chapters': chapters.map((c) => c.toMap()).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<Chapter> _parseChapters(dynamic chaptersData) {
    if (chaptersData is! List) return [];
    return chaptersData
        .whereType<Map<String, dynamic>>()
        .map((e) => Chapter.fromMap(e))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          language == other.language &&
          level == other.level &&
          order == other.order &&
          _listEquals(chapters, other.chapters);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        language,
        level,
        order,
        Object.hashAll(chapters),
      );

  static bool _listEquals(List<Chapter> a, List<Chapter> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'Course(id: $id, title: $title, chapters: ${chapters.length})';
}
