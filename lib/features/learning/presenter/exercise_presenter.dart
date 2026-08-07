import 'package:flutter/foundation.dart';
import 'package:pearn/features/learning/view/i_lesson_view.dart';

import '../../learning/model/exercise.dart';
import '../../learning/model/course_repository.dart';
import '../../learning/view/i_exercise_view.dart';

/// Coordinates between the exercise UI and the [CourseRepository].
///
/// Handles exercise loading, answer evaluation, and navigation between
/// exercises within the same lesson.
class ExercisePresenter {
  final CourseRepository _courseRepository;
  ILessonView? _view; // Actually we need IExerciseView

  // The presenter manages a list of exercises for the current context.
  List<Exercise> _exercises = [];
  int _currentIndex = 0;

  // Track the currently loaded context.
  String? _courseId;
  String? _lessonId;
  String? _currentExerciseId;

  ExercisePresenter({
    required CourseRepository courseRepo,
  }) : _courseRepository = courseRepo;

  /// Attaches the view that will receive UI updates.
  set view(IExerciseView? view) {
    _view = view as ILessonView?;
  }

  // ---------------------------------------------------------------------------
  // 1. Load a specific exercise
  // ---------------------------------------------------------------------------
  Future<void> loadExercise(
      String courseId, String lessonId, String exerciseId) async {
    debugPrint('[PRESENTER][EXERCISE] Loading exercise $exerciseId');
    _view?.showLoading(true);

    try {
      // Retrieve all exercises for this lesson.
      final exercises =
          await _courseRepository.getExercises(courseId, lessonId);
      _exercises = exercises;

      // Find the requested exercise.
      final index = _exercises.indexWhere((e) => e.id == exerciseId);
      if (index == -1) {
        _view?.showError('Exercise not found.');
        return;
      }

      _courseId = courseId;
      _lessonId = lessonId;
      _currentExerciseId = exerciseId;
      _currentIndex = index;

      _view?.showExercises(_exercises[_currentIndex] as List<Exercise>);
      debugPrint('[PRESENTER][EXERCISE] Exercise loaded');
    } catch (e) {
      debugPrint('[PRESENTER][EXERCISE] Failed to load exercise');
      _view?.showError('Unable to load exercise. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Submit answer
  // ---------------------------------------------------------------------------
  Future<void> submitAnswer(dynamic answer) async {
    if (_currentIndex >= _exercises.length) return;

    final exercise = _exercises[_currentIndex];
    debugPrint('[PRESENTER][EXERCISE] Answer submitted');

    try {
      final correct = _evaluateAnswer(exercise, answer);
      debugPrint('[PRESENTER][EXERCISE] Exercise evaluated');
      _view?.showResult(correct, exercise.explanation);
    } catch (e) {
      _view?.showError('Could not evaluate answer. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Next exercise
  // ---------------------------------------------------------------------------
  void nextExercise() {
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _exercises.length) {
      // Show the next exercise in the same screen.
      _currentIndex = nextIndex;
      _currentExerciseId = _exercises[nextIndex].id;
      _view?.showExercises(_exercises[nextIndex] as List<Exercise>);
    } else {
      // No more exercises – mark as completed and then go back.
      _view?.showCompletion();
      _view?.navigateToNextExercise();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  bool _evaluateAnswer(Exercise exercise, dynamic userAnswer) {
    final correctAnswer = exercise.correctAnswer;

    // Convert both to strings for simple comparison.
    final userStr = userAnswer?.toString().trim().toLowerCase() ?? '';
    final correctStr = correctAnswer?.toString().trim().toLowerCase() ?? '';

    // If the correct answer is a list (e.g., multiple valid answers), check
    // if the user answer is among them.
    if (correctAnswer is List) {
      return correctAnswer.any((item) =>
          item.toString().trim().toLowerCase() == userStr);
    }

    return userStr == correctStr;
  }
}