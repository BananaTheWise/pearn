/// Pure data model representing a single learning lesson.
///
/// Content is sourced from Markdown files in the GitHub course repository.
/// This model stores the lesson metadata and the raw Markdown content.
///
/// The model does **not** interpret or execute Markdown – content is preserved
/// exactly as retrieved.
class Lesson {
  /// Unique identifier (often the file slug, e.g. `'01-introduction'`).
  final String id;

  /// Display title.
  final String title;

  /// The ID of the chapter this lesson belongs to.
  final String chapterId;

  /// The raw Markdown content.
  final String content;

  /// Display order within the chapter.
  final int? order;

  /// Optional additional metadata (e.g. estimated reading time, difficulty).
  final Map<String, dynamic>? metadata;

  const Lesson({
    required this.id,
    required this.title,
    required this.chapterId,
    required this.content,
    this.order,
    this.metadata,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Lesson] from a map.
  ///
  /// Required fields: `id`, `title`, `chapter_id`, `content`.
  factory Lesson.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    final chapterId = map['chapter_id'];
    final content = map['content'];

    if (id == null || title == null || chapterId == null || content == null) {
      throw const FormatException(
        'Lesson map must contain non-null "id", "title", "chapter_id", and "content".',
      );
    }

    return Lesson(
      id: id as String,
      title: title as String,
      chapterId: chapterId as String,
      content: content as String,
      order: map['order'] is int ? map['order'] as int : null,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  /// Converts this [Lesson] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'chapter_id': chapterId,
      'content': content,
      'order': order,
      'metadata': metadata,
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          chapterId == other.chapterId &&
          content == other.content &&
          order == other.order &&
          _mapsEqual(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        chapterId,
        content,
        order,
        metadata != null ? Object.hashAll(metadata!.entries.map((e) => Object.hash(e.key, e.value))) : null,
      );

  static bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() => 'Lesson(id: $id, title: $title, chapterId: $chapterId, order: $order)';
}