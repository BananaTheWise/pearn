/// Pure data model representing an exercise from the GitHub course content.
///
/// Source: `exercises.json` inside a course folder.
/// This model stores the exercise data exactly as defined in the JSON.
///
/// It does **not** perform answer evaluation, network requests, or any
/// backend operations.
class Exercise {
  /// Unique identifier for the exercise (e.g., `'ex-1'`).
  final String id;

  /// The type of exercise (e.g., `'multiple_choice'`, `'code'`, `'text'`).
  final String type;

  /// The question or instruction text.
  final String question;

  /// Available options for multiple-choice exercises.
  final List<String>? options;

  /// The correct answer (format depends on the exercise type).
  final dynamic correctAnswer;

  /// Optional explanation or solution text.
  final String? explanation;

  /// Display order within the lesson or exam.
  final int? order;

  /// Points awarded for a correct answer.
  final int? points;

  const Exercise({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    this.correctAnswer,
    this.explanation,
    this.order,
    this.points,
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Creates an [Exercise] from a map (parsed JSON).
  ///
  /// Required fields: `id`, `type`, `question`.
  factory Exercise.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final type = map['type'];
    final question = map['question'];

    if (id == null || type == null || question == null) {
      throw const FormatException(
        'Exercise map must contain non-null "id", "type", and "question".',
      );
    }

    return Exercise(
      id: id as String,
      type: type as String,
      question: question as String,
      options: map['options'] is List
          ? (map['options'] as List).map((e) => e.toString()).toList()
          : null,
      correctAnswer: map['correct_answer'],
      explanation: map['explanation'] as String?,
      order: map['order'] is int ? map['order'] as int : null,
      points: map['points'] is int ? map['points'] as int : null,
    );
  }

  /// Converts this [Exercise] to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'order': order,
      'points': points,
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Exercise &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          question == other.question &&
          _listEquals(options, other.options) &&
          correctAnswer == other.correctAnswer &&
          explanation == other.explanation &&
          order == other.order &&
          points == other.points;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        question,
        options != null ? Object.hashAll(options!) : null,
        correctAnswer,
        explanation,
        order,
        points,
      );

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'Exercise(id: $id, type: $type, order: $order)';
}