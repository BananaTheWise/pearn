import 'package:flutter/foundation.dart';

import '../../learning/model/exam.dart';
import '../../learning/model/exam_attempt.dart';
import '../../learning/model/course_repository.dart';
import '../../learning/model/exam_attempt_repository.dart';
import '../../learning/view/i_exam_view.dart';

/// Coordinates between the exam UI and repositories.
///
/// Responsible for:
/// - Loading exams
/// - Evaluating answers
/// - Calculating scores
/// - Saving attempts
/// - Preventing duplicate submissions
class ExamPresenter {
final CourseRepository _courseRepository;
final ExamAttemptRepository _examAttemptRepository;
final String _userId;

IExamView? _view;

Exam? _exam;

/// Course ID is kept separately because an exam ID is not necessarily
/// the same thing as the course ID.
String? _courseId;

bool _isSubmitting = false;
bool _attemptSaved = false;

ExamPresenter({
required CourseRepository courseRepo,
required ExamAttemptRepository examAttemptRepo,
required String userId,
})  : _courseRepository = courseRepo,
_examAttemptRepository = examAttemptRepo,
_userId = userId;

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

set view(IExamView? view) {
_view = view;
}

// ---------------------------------------------------------------------------
// Load exam
// ---------------------------------------------------------------------------

Future<void> loadExam(
String courseId,
String examId,
) async {
debugPrint(
'[PRESENTER][EXAM] Loading exam',
);


_view?.showLoading(true);

try {
  final exam =
      await _courseRepository.getExam(
    courseId,
    examId,
  );

  if (exam == null) {
    debugPrint(
      '[PRESENTER][EXAM] Exam not found',
    );

    _view?.showError(
      'Exam not found.',
    );

    return;
  }

  _exam = exam;

  // Keep the course ID for saving the attempt.
  _courseId = courseId;

  _attemptSaved = false;
  _isSubmitting = false;

  debugPrint(
    '[PRESENTER][EXAM] Exam loaded',
  );

  debugPrint(
    '[PRESENTER][EXAM] Course ID: $_courseId',
  );

  debugPrint(
    '[PRESENTER][EXAM] Exam ID: ${exam.id}',
  );

  debugPrint(
    '[PRESENTER][EXAM] Questions: '
    '${exam.questions.length}',
  );

  _view?.showExam(exam);
} catch (e, stackTrace) {
  debugPrint(
    '[PRESENTER][EXAM] Exam loading failed: $e',
  );

  debugPrint(
    '$stackTrace',
  );

  _view?.showError(
    'Unable to load exam. Please try again.',
  );
} finally {
  _view?.showLoading(false);
}


}

// ---------------------------------------------------------------------------
// Question navigation
// ---------------------------------------------------------------------------

void showQuestion(int index) {
if (_exam == null) {
return;
}


if (index < 0 ||
    index >= _exam!.questions.length) {
  return;
}

_view?.showQuestion(index);

}

// ---------------------------------------------------------------------------
// Submit exam
// ---------------------------------------------------------------------------

Future<void> submitExam(
Map<int, dynamic> answers,
) async {
if (_exam == null) {
debugPrint(
'[PRESENTER][EXAM] Cannot submit: exam is null',
);


  return;
}

if (_isSubmitting) {
  debugPrint(
    '[PRESENTER][EXAM] Submission already running',
  );

  return;
}

if (_attemptSaved) {
  debugPrint(
    '[PRESENTER][EXAM] Attempt already saved',
  );

  return;
}

if (_courseId == null) {
  debugPrint(
    '[PRESENTER][EXAM] Cannot submit: course ID is null',
  );

  _view?.showError(
    'Course information is missing.',
  );

  return;
}

debugPrint(
  '[PRESENTER][EXAM] Exam submission started',
);

_isSubmitting = true;

try {
  final result =
      _evaluateAnswers(answers);

  final double score = result.$1;
  final bool passed = result.$2;

  debugPrint(
    '[PRESENTER][EXAM] Exam result calculated',
  );

  debugPrint(
    '[PRESENTER][EXAM] Score: $score',
  );

  debugPrint(
    '[PRESENTER][EXAM] Percentage: '
    '${(score * 100).round()}%',
  );

  debugPrint(
    '[PRESENTER][EXAM] Passed: $passed',
  );

  // course_id is int4 in Supabase.
  final int courseId =
      int.parse(_courseId!);

  final attempt = ExamAttempt(
    // Supabase generates the UUID.
    id: '',

    userId: _userId,

    courseId: courseId,

    examId: _exam!.id,

    // Application representation:
    // 0.0 -> 1.0
    score: score,

    passed: passed,

    attemptedAt: DateTime.now(),
  );

  debugPrint(
    '[REPOSITORY][EXAM] Saving attempt',
  );

  debugPrint(
    '[REPOSITORY][EXAM] '
    'courseId=${attempt.courseId}',
  );

  debugPrint(
    '[REPOSITORY][EXAM] '
    'examId=${attempt.examId}',
  );

  final savedAttempt =
      await _examAttemptRepository
          .saveAttempt(attempt);

  _attemptSaved = true;

  debugPrint(
    '[PRESENTER][EXAM] '
    'Exam submission completed',
  );

  _view?.showResult(
    savedAttempt,
  );
} catch (e, stackTrace) {
  debugPrint(
    '[PRESENTER][EXAM] '
    'Exam submission failed: $e',
  );

  debugPrint(
    '$stackTrace',
  );

  _view?.showError(
    'Failed to save exam attempt. '
    'Please try again.',
  );
} finally {
  _isSubmitting = false;
}


}

// ---------------------------------------------------------------------------
// Navigation after completion
// ---------------------------------------------------------------------------

void navigateAfterExam() {
_view?.navigateAfterExam();
}

// ---------------------------------------------------------------------------
// Evaluate answers
// ---------------------------------------------------------------------------

(double, bool) _evaluateAnswers(
Map<int, dynamic> answers,
) {
final questions = _exam!.questions;


double totalPoints = 0;
double earnedPoints = 0;

debugPrint(
  '[PRESENTER][EXAM] '
  'Evaluating ${questions.length} questions',
);

for (int i = 0;
    i < questions.length;
    i++) {
  final question = questions[i];

  final double points =
      (question.points ?? 1).toDouble();

  totalPoints += points;

  final dynamic userAnswer =
      answers[i];

  final bool correct =
      _isAnswerCorrect(
    question,
    userAnswer,
  );

  debugPrint(
    '[EXAM][ANSWER] '
    'Question ${i + 1}: '
    'user="$userAnswer" '
    'correct="${question.correctAnswer}" '
    'result=$correct',
  );

  if (correct) {
    earnedPoints += points;
  }
}

final double score =
    totalPoints > 0
        ? earnedPoints / totalPoints
        : 0.0;

final double passingThreshold =
    _exam!.passingScore ?? 0.6;

final bool passed =
    score >= passingThreshold;

debugPrint(
  '[EXAM][RESULT] '
  'earned=$earnedPoints '
  'total=$totalPoints '
  'score=$score '
  'threshold=$passingThreshold '
  'passed=$passed',
);

return (score, passed);


}

// ---------------------------------------------------------------------------
// Answer comparison
// ---------------------------------------------------------------------------

bool _isAnswerCorrect(
ExamQuestion question,
dynamic userAnswer,
) {
if (userAnswer == null) {
debugPrint(
'[EXAM][ANSWER] No answer selected',
);


  return false;
}

final dynamic correctAnswer =
    question.correctAnswer;

if (correctAnswer == null) {
  debugPrint(
    '[EXAM][ANSWER] '
    'WARNING: correctAnswer is null '
    'for question ${question.id}',
  );

  return false;
}

// -------------------------------------------------------------------------
// Multiple acceptable answers
// -------------------------------------------------------------------------

if (correctAnswer is List) {
  final String user =
      _normalizeAnswer(userAnswer);

  for (final answer in correctAnswer) {
    final String correct =
        _normalizeAnswer(answer);

    if (user == correct) {
      return true;
    }
  }

  return false;
}

// -------------------------------------------------------------------------
// Normal single answer
// -------------------------------------------------------------------------

final String user =
    _normalizeAnswer(userAnswer);

final String correct =
    _normalizeAnswer(correctAnswer);

return user == correct;


}

// ---------------------------------------------------------------------------
// Normalize answers
// ---------------------------------------------------------------------------

String _normalizeAnswer(
dynamic value,
) {
return value
.toString()
.trim()
.toLowerCase()
.replaceAll(RegExp(r'\s+'), ' ');
}
}
