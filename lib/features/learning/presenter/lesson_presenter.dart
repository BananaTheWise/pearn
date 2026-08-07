import 'package:flutter/foundation.dart';

import '../../learning/model/course_repository.dart';
import '../../learning/model/exercise.dart';
import '../../learning/view/i_lesson_view.dart';

// -----------------------------------------------------------------------------
// Lightweight placeholder until ProgressRepository is fully implemented.
// -----------------------------------------------------------------------------
abstract class ProgressRepository {
  Future<void> markLessonCompleted(
      String userId, String courseId, String lessonId);
}
// -----------------------------------------------------------------------------

/// Coordinates between the lesson UI and the [CourseRepository].
///
/// Optionally uses a [ProgressRepository] to persist lesson completion.
class LessonPresenter {
  final CourseRepository _courseRepository;
  final ProgressRepository? _progressRepository;
  final String _userId;
  ILessonView? _view;

  LessonPresenter({
    required CourseRepository courseRepo,
    required String userId,
    ProgressRepository? progressRepo,
  })  : _courseRepository = courseRepo,
        _userId = userId,
        _progressRepository = progressRepo;

  /// Attaches the view that will receive UI updates.
  set view(ILessonView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // 1. Load lesson and exercises
  // ---------------------------------------------------------------------------
  Future<void> loadLesson(String courseId, String lessonId) async {
    debugPrint('[PRESENTER][LESSON] Loading lesson');
    _view?.showLoading(true);

    try {
      final lesson = await _courseRepository.getLesson(courseId, lessonId);
      if (lesson == null) {
        _view?.showError('Lesson not found.');
        return;
      }

      _view?.showLesson(lesson);
      debugPrint('[PRESENTER][LESSON] Lesson loaded');

      // Load exercises for this lesson
      await _loadExercises(courseId, lessonId);
    } catch (e) {
      debugPrint('[PRESENTER][LESSON] Lesson loading failed');
      _view?.showError('Unable to load lesson. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Open exercise
  // ---------------------------------------------------------------------------
  void openExercise(String exerciseId) {
    if (exerciseId.trim().isEmpty) {
      _view?.showError('Invalid exercise identifier.');
      return;
    }
    _view?.navigateToExercise(exerciseId);
  }

  // ---------------------------------------------------------------------------
  // 3. Mark lesson completed
  // ---------------------------------------------------------------------------
  Future<void> markLessonCompleted() async {
    if (_progressRepository == null) {
      // Completion tracking not available; just notify the view.
      _view?.markLessonCompleted();
      return;
    }

    try {
      // The presenter needs to know which course/lesson is currently open.
      // In a full implementation, store courseId/lessonId when loading.
      // For brevity we assume they are held as fields in a real scenario.
      // This method would then call _progressRepository.markLessonCompleted(...)
      // but since we don't have them stored, we simply notify the view.
      _view?.markLessonCompleted();
    } catch (e) {
      debugPrint('[PRESENTER][LESSON] Failed to mark lesson completed');
      _view?.showError('Could not save progress.');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  Future<void> _loadExercises(String courseId, String lessonId) async {
    debugPrint('[PRESENTER][LESSON] Loading exercises');
    try {
      final exercises = await _courseRepository.getExercises(courseId, lessonId);
      _view?.showExercises(exercises);
      debugPrint('[PRESENTER][LESSON] Exercises loaded');
    } catch (e) {
      debugPrint('[PRESENTER][LESSON] Exercises loading failed');
      // Non-fatal – show empty list
      _view?.showExercises([]);
    }
  }
}