/// Pure data model representing a learning roadmap.
///
/// A roadmap consists of ordered stages that guide the user through a
/// sequence of courses or learning milestones.
///
/// This model contains no external dependencies and is immutable.
class Roadmap {
  /// Unique identifier for the roadmap.
  final String id;

  /// Display title.
  final String title;

  /// Optional description.
  final String? description;

  /// Ordered list of stages that make up the roadmap.
  final List<RoadmapStage> stages;

  const Roadmap({
    required this.id,
    required this.title,
    this.description,
    this.stages = const [],
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates a [Roadmap] from a map.
  ///
  /// Required fields: `id`, `title`.
  factory Roadmap.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id == null || title == null) {
      throw const FormatException(
        'Roadmap map must contain non-null "id" and "title".',
      );
    }
    return Roadmap(
      id: id as String,
      title: title as String,
      description: map['description'] as String?,
      stages: _parseStages(map['stages']),
    );
  }

  /// Converts this [Roadmap] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'stages': stages.map((s) => s.toMap()).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static List<RoadmapStage> _parseStages(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => RoadmapStage.fromMap(e))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Roadmap &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          _listEquals(stages, other.stages);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        Object.hashAll(stages),
      );

  static bool _listEquals(List<RoadmapStage> a, List<RoadmapStage> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Roadmap(id: $id, title: $title, stages: ${stages.length})';
}

/// Represents a single stage within a [Roadmap].
class RoadmapStage {
  /// Unique identifier for the stage.
  final String id;

  /// Display title.
  final String title;

  /// Optional description.
  final String? description;

  /// Reference to a course ID, if the stage involves a specific course.
  final String? courseId;

  /// Order within the roadmap.
  final int? order;

  const RoadmapStage({
    required this.id,
    required this.title,
    this.description,
    this.courseId,
    this.order,
  });

  /// Creates a [RoadmapStage] from a map.
  ///
  /// Required fields: `id`, `title`.
  factory RoadmapStage.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id == null || title == null) {
      throw const FormatException(
        'RoadmapStage map must contain non-null "id" and "title".',
      );
    }
    return RoadmapStage(
      id: id as String,
      title: title as String,
      description: map['description'] as String?,
      courseId: map['course_id'] as String?,
      order: map['order'] is int ? map['order'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'course_id': courseId,
      'order': order,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadmapStage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          courseId == other.courseId &&
          order == other.order;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        courseId,
        order,
      );

  @override
  String toString() => 'RoadmapStage(id: $id, title: $title, order: $order)';
}