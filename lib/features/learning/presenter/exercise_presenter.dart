import 'package:flutter/foundation.dart';

import '../../learning/model/exercise.dart';
import '../../learning/model/course_repository.dart';
import '../../learning/view/i_exercise_view.dart';

/// Coordinates between the exercise UI and the [CourseRepository].
///
/// Handles exercise loading, answer evaluation, and navigation between
/// exercises.
///
/// Exercises can be:
/// - scoped to a single lesson
/// - flattened across multiple lessons in a chapter
class ExercisePresenter {
  final CourseRepository _courseRepository;

  IExerciseView? _view;

  /// Exercises currently loaded for this exercise session.
  List<Exercise> _exercises = [];

  /// Index of the currently displayed exercise.
  int _currentIndex = 0;

  /// Whether the current exercise has already been answered.
  bool _hasAnsweredCurrentExercise = false;

  /// Current course.
  String? _courseId;

  /// Current exercise ID.
  String? _currentExerciseId;

  ExercisePresenter({required CourseRepository courseRepo})
    : _courseRepository = courseRepo;

  /// Attaches the view.
  set view(IExerciseView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // 1. Load a specific exercise
  // ---------------------------------------------------------------------------

  Future<void> loadExercise(
    String courseId,
    String lessonId,
    String exerciseId,
  ) async {
    debugPrint('[PRESENTER][EXERCISE] Loading exercise $exerciseId');

    _view?.showLoading(true);

    try {
      final exercises = await _courseRepository.getExercises(
        courseId,
        lessonId,
      );

      _exercises = exercises;

      if (_exercises.isEmpty) {
        _view?.showError('No exercises available for this lesson.');
        return;
      }

      final index = _exercises.indexWhere(
        (exercise) => exercise.id == exerciseId,
      );

      if (index == -1) {
        _view?.showError('Exercise not found.');
        return;
      }

      _courseId = courseId;
      _currentIndex = index;
      _currentExerciseId = _exercises[index].id;
      _hasAnsweredCurrentExercise = false;

      _view?.showExercise(_exercises[_currentIndex]);

      debugPrint(
        '[PRESENTER][EXERCISE] '
        'Loaded ${_currentExerciseId} '
        '(${_currentIndex + 1}/${_exercises.length})',
      );
    } catch (e) {
      debugPrint('[PRESENTER][EXERCISE] Failed to load exercise: $e');

      _view?.showError('Unable to load exercise. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 1b. Load chapter exercises
  // ---------------------------------------------------------------------------

 Future<void> loadChapterExercises(
  String courseId,
  List lessonIds, {
  String? startExerciseId,
}) async {
  debugPrint('[PRESENTER][EXERCISE] Loading chapter exercises');

  _view?.showLoading(true);

  try {
    final allExercises = <Exercise>[];

    // -------------------------------------------------------
    // Find which chapters these lessons belong to.
    // -------------------------------------------------------

    final chapters = await _courseRepository.getChapters(courseId);

    final chapterIds = <String>{};

    for (final lessonId in lessonIds) {
      for (final chapter in chapters) {
        final containsLesson =
            chapter.lessons.any((lesson) => lesson.id == lessonId);

        if (containsLesson) {
          chapterIds.add(chapter.id);

          debugPrint(
            '[PRESENTER][EXERCISE] '
            'Lesson "$lessonId" belongs to chapter "${chapter.id}"',
          );

          break;
        }
      }
    }

    debugPrint(
      '[PRESENTER][EXERCISE] '
      'Unique chapters: $chapterIds',
    );

    // -------------------------------------------------------
    // Load exercises ONCE per chapter.
    // -------------------------------------------------------

    for (final chapterId in chapterIds) {
      final chapter = chapters.firstWhere(
        (chapter) => chapter.id == chapterId,
      );

      // Use the first lesson in this chapter to resolve the
      // chapter's exercises.json through the repository.
      if (chapter.lessons.isEmpty) {
        continue;
      }

      final firstLessonId = chapter.lessons.first.id;

      final chapterExercises =
          await _courseRepository.getExercises(
        courseId,
        firstLessonId,
      );

      debugPrint(
        '[PRESENTER][EXERCISE] '
        'Chapter "$chapterId" exercises: '
        '${chapterExercises.length}',
      );

      allExercises.addAll(chapterExercises);
    }

    // -------------------------------------------------------
    // Remove duplicate exercise IDs as a safety measure.
    // -------------------------------------------------------

    final uniqueExercises = <String, Exercise>{};

    for (final exercise in allExercises) {
      uniqueExercises[exercise.id] = exercise;
    }

    _exercises = uniqueExercises.values.toList();

    // Sort by exercise order.
    _exercises.sort(
      (a, b) => a.order!.compareTo(b.order as num),
    );

    _courseId = courseId;

    // -------------------------------------------------------
    // Nothing found.
    // -------------------------------------------------------

    if (_exercises.isEmpty) {
      _view?.showError(
        'No exercises available for this chapter.',
      );
      return;
    }

    // -------------------------------------------------------
    // Find starting exercise.
    // -------------------------------------------------------

    int index = 0;

    if (startExerciseId != null &&
        startExerciseId.isNotEmpty) {
      final foundIndex = _exercises.indexWhere(
        (exercise) => exercise.id == startExerciseId,
      );

      if (foundIndex != -1) {
        index = foundIndex;
      }
    }

    _currentIndex = index;
    _currentExerciseId = _exercises[index].id;
    _hasAnsweredCurrentExercise = false;

    // -------------------------------------------------------
    // Display first exercise.
    // -------------------------------------------------------

    _view?.showExercise(
      _exercises[_currentIndex],
    );

    debugPrint(
      '[PRESENTER][EXERCISE] '
      'Chapter loaded: ${_exercises.length} exercises',
    );

    debugPrint(
      '[PRESENTER][EXERCISE] '
      'Starting at $_currentExerciseId',
    );
  } catch (e) {
    debugPrint(
      '[PRESENTER][EXERCISE] '
      'Failed to load chapter exercises: $e',
    );

    _view?.showError(
      'Unable to load exercises. Please try again.',
    );
  } finally {
    _view?.showLoading(false);
  }
}

  // ---------------------------------------------------------------------------
  // 2. Submit answer
  // ---------------------------------------------------------------------------

  Future<void> submitAnswer(dynamic answer) async {
    if (_exercises.isEmpty) {
      return;
    }

    if (_currentIndex < 0 || _currentIndex >= _exercises.length) {
      return;
    }

    // Prevent submitting the same exercise repeatedly.
    if (_hasAnsweredCurrentExercise) {
      return;
    }

    final exercise = _exercises[_currentIndex];

    debugPrint(
      '[PRESENTER][EXERCISE] '
      'Answer submitted for ${exercise.id}',
    );

    try {
      final correct = _evaluateAnswer(exercise, answer);

      _hasAnsweredCurrentExercise = true;

      debugPrint(
        '[PRESENTER][EXERCISE] '
        'Exercise ${exercise.id}: '
        '${correct ? "CORRECT" : "INCORRECT"}',
      );

      _view?.showResult(correct, exercise.explanation);
    } catch (e) {
      debugPrint(
        '[PRESENTER][EXERCISE] '
        'Failed to evaluate answer: $e',
      );

      _view?.showError('Could not evaluate answer. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Next exercise
  // ---------------------------------------------------------------------------

  void nextExercise() {
    debugPrint('========== NEXT EXERCISE ==========');
    debugPrint('Current index: $_currentIndex');
    debugPrint('Total exercises: ${_exercises.length}');

    if (_exercises.isEmpty) {
      debugPrint('[EXERCISE] Exercise list is EMPTY');
      return;
    }

    if (_currentIndex < 0 || _currentIndex >= _exercises.length) {
      debugPrint('[EXERCISE] Invalid current index: $_currentIndex');
      return;
    }

    debugPrint(
      '[EXERCISE] Current exercise: '
      '${_exercises[_currentIndex].id}',
    );

    if (!_hasAnsweredCurrentExercise) {
      debugPrint('[EXERCISE] Cannot advance - answer not submitted');
      return;
    }

    final nextIndex = _currentIndex + 1;

    debugPrint('[EXERCISE] Calculated next index: $nextIndex');

    // -------------------------------------------------------
    // NEXT EXERCISE
    // -------------------------------------------------------

    if (nextIndex < _exercises.length) {
      final nextExercise = _exercises[nextIndex];

      debugPrint('[EXERCISE] NEXT exercise: ${nextExercise.id}');

      _currentIndex = nextIndex;
      _currentExerciseId = nextExercise.id;
      _hasAnsweredCurrentExercise = false;

      _view?.showExercise(nextExercise);

      debugPrint('[EXERCISE] Now displaying index $_currentIndex');

      return;
    }

    // -------------------------------------------------------
    // FINISHED
    // -------------------------------------------------------

    debugPrint('[EXERCISE] ===== ALL EXERCISES COMPLETED =====');

    _view?.showCompletion();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _evaluateAnswer(Exercise exercise, dynamic userAnswer) {
    final correctAnswer = exercise.correctAnswer;

    final userStr = userAnswer?.toString().trim().toLowerCase() ?? '';

    final correctStr = correctAnswer?.toString().trim().toLowerCase() ?? '';

    if (correctAnswer is List) {
      return correctAnswer.any(
        (item) => item.toString().trim().toLowerCase() == userStr,
      );
    }

    return userStr == correctStr;
  }
}
