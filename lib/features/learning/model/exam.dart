/// Pure data model representing an exam.
///
/// Sourced from `exam.json` in the GitHub course content.
/// This model stores exam metadata and its questions.
///
/// It does **not** access GitHub, repositories, or any external service.
class Exam {
/// Unique identifier for the exam.
final String id;

/// Display title.
final String title;

/// Optional description.
final String? description;

/// Minimum score required to pass.
///
/// Example: `0.7` means 70%.
final double? passingScore;

/// Time limit in minutes, if applicable.
final int? timeLimitMinutes;

/// Questions that form the exam.
final List<ExamQuestion> questions;

const Exam({
required this.id,
required this.title,
this.description,
this.passingScore,
this.timeLimitMinutes,
this.questions = const [],
});

// ---------------------------------------------------------------------------
// Serialization
// ---------------------------------------------------------------------------

/// Creates an [Exam] from a parsed JSON map.
///
/// JSON format:
///
/// `json
  /// {
  ///   "id": "introduction",
  ///   "title": "Introduction — Chapter Exam",
  ///   "description": "...",
  ///   "passingScore": 0.7,
  ///   "questions": []
  /// }
  /// `
factory Exam.fromMap(Map<String, dynamic> map) {
final id = map['id'];
final title = map['title'];


if (id == null || title == null) {
  throw const FormatException(
    'Exam map must contain non-null "id" and "title".',
  );
}

return Exam(
  id: id.toString(),
  title: title.toString(),
  description: map['description']?.toString(),

  // IMPORTANT:
  // GitHub JSON uses "passingScore", not "passing_score".
  passingScore: (map['passingScore'] as num?)?.toDouble(),

  // Support both camelCase and snake_case just in case
  // older course files use the old format.
  timeLimitMinutes:
      (map['timeLimitMinutes'] ?? map['time_limit_minutes']) is num
          ? ((map['timeLimitMinutes'] ??
                      map['time_limit_minutes']) as num)
                  .toInt()
          : null,

  questions: _parseQuestions(map['questions']),
);

}

/// Converts this [Exam] to a map using the GitHub JSON format.
Map<String, dynamic> toMap() {
return {
'id': id,
'title': title,
'description': description,
'passingScore': passingScore,
'timeLimitMinutes': timeLimitMinutes,
'questions': questions.map((q) => q.toMap()).toList(),
};
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static List<ExamQuestion> _parseQuestions(
dynamic questionsData,
) {
if (questionsData is! List) {
return [];
}


return questionsData
    .whereType<Map>()
    .map(
      (e) => ExamQuestion.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
    .toList();

}

// ---------------------------------------------------------------------------
// Equality & hashCode
// ---------------------------------------------------------------------------

@override
bool operator ==(Object other) =>
identical(this, other) ||
other is Exam &&
runtimeType == other.runtimeType &&
id == other.id &&
title == other.title &&
description == other.description &&
passingScore == other.passingScore &&
timeLimitMinutes == other.timeLimitMinutes &&
_listEquals(questions, other.questions);

@override
int get hashCode => Object.hash(
id,
title,
description,
passingScore,
timeLimitMinutes,
Object.hashAll(questions),
);

static bool _listEquals(
List a,
List b,
) {
if (a.length != b.length) {
return false;
}


for (int i = 0; i < a.length; i++) {
  if (a[i] != b[i]) {
    return false;
  }
}

return true;

}

@override
String toString() {
return 'Exam('
'id: $id, '
'title: $title, '
'questions: ${questions.length}'
')';
}
}

/// Represents a single question within an [Exam].
class ExamQuestion {
/// Unique identifier for the question.
final String id;

/// The type of question.
///
/// Examples:
/// - `multiple_choice`
/// - `code`
/// - `text`
final String type;

/// The question text.
final String question;

/// Available options for multiple-choice questions.
final List<String>? options;

/// The correct answer.
final dynamic correctAnswer;

/// Optional explanation shown after answering.
final String? explanation;

/// Points awarded for a correct answer.
final int? points;

const ExamQuestion({
required this.id,
required this.type,
required this.question,
this.options,
this.correctAnswer,
this.explanation,
this.points,
});

// ---------------------------------------------------------------------------
// Serialization
// ---------------------------------------------------------------------------

/// Creates an [ExamQuestion] from a parsed JSON map.
factory ExamQuestion.fromMap(
Map<String, dynamic> map,
) {
final id = map['id'];
final type = map['type'];
final question = map['question'];


if (id == null ||
    type == null ||
    question == null) {
  throw const FormatException(
    'Exam question map must contain non-null '
    '"id", "type", and "question".',
  );
}

return ExamQuestion(
  id: id.toString(),
  type: type.toString(),
  question: question.toString(),

  options: map['options'] is List
      ? (map['options'] as List)
          .map((e) => e.toString())
          .toList()
      : null,

  // IMPORTANT:
  // Your JSON uses "correctAnswer".
  //
  // The old code incorrectly used:
  // map['correct_answer']
  //
  // which caused correctAnswer to always be null.
  correctAnswer:
      map.containsKey('correctAnswer')
          ? map['correctAnswer']
          : map['correct_answer'],

  explanation:
      map['explanation']?.toString(),

  points:
      (map['points'] as num?)?.toInt(),
);


}

/// Converts this question to the GitHub JSON format.
Map<String, dynamic> toMap() {
return {
'id': id,
'type': type,
'question': question,
'options': options,
'correctAnswer': correctAnswer,
'explanation': explanation,
'points': points,
};
}

// ---------------------------------------------------------------------------
// Equality & hashCode
// ---------------------------------------------------------------------------

@override
bool operator ==(Object other) =>
identical(this, other) ||
other is ExamQuestion &&
runtimeType == other.runtimeType &&
id == other.id &&
type == other.type &&
question == other.question &&
_listEquals(options, other.options) &&
correctAnswer == other.correctAnswer &&
explanation == other.explanation &&
points == other.points;

@override
int get hashCode => Object.hash(
id,
type,
question,
options != null
? Object.hashAll(options!)
: null,
correctAnswer,
explanation,
points,
);

static bool _listEquals(
List<String>? a,
List<String>? b,
) {
if (a == null && b == null) {
return true;
}


if (a == null || b == null) {
  return false;
}

if (a.length != b.length) {
  return false;
}

for (int i = 0; i < a.length; i++) {
  if (a[i] != b[i]) {
    return false;
  }
}

return true;


}

@override
String toString() {
return 'ExamQuestion('
'id: $id, '
'type: $type'
')';
}
}
