import 'package:flutter/foundation.dart';

import '../../learning/model/course_repository.dart';
import '../../learning/view/i_lesson_view.dart';
import '../../progress/services/progress_service.dart';

/// Coordinates between the lesson UI and the [CourseRepository].
///
/// Uses [ProgressService] to persist lesson completion, award XP, and
/// update the user's level/streak (rather than writing to the progress
/// repository directly, which would skip all of that business logic).
///
/// Note: exercises are no longer loaded here. Exercises are shown once
/// per chapter (see [ExercisePresenter.loadChapterExercises]), not
/// embedded inside every lesson.
class LessonPresenter {
  final CourseRepository _courseRepository;
  final ProgressService? _progressService;
  final String _userId;
  ILessonView? _view;

  // The course/lesson currently being viewed. Populated by [loadLesson]
  // so that [markLessonCompleted] knows what to persist.
  String? _currentCourseId;
  String? _currentLessonId;

  LessonPresenter({
    required CourseRepository courseRepo,
    required String userId,
    ProgressService? progressService,
  })  : _courseRepository = courseRepo,
        _userId = userId,
        _progressService = progressService;

  /// Attaches the view that will receive UI updates.
  set view(ILessonView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // 1. Load lesson
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

      // Remember which lesson is open so markLessonCompleted() has
      // something to save.
      _currentCourseId = courseId;
      _currentLessonId = lessonId;

      _view?.showLesson(lesson);
      debugPrint('[PRESENTER][LESSON] Lesson loaded');
    } catch (e) {
      debugPrint('[PRESENTER][LESSON] Lesson loading failed');
      _view?.showError('Unable to load lesson. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Mark lesson completed
  // ---------------------------------------------------------------------------
  Future<void> markLessonCompleted() async {
    if (_progressService == null) {
      debugPrint('[PRESENTER][LESSON] No ProgressService — skipping persistence');
      _view?.markLessonCompleted();
      return;
    }

    if (_currentCourseId == null || _currentLessonId == null) {
      debugPrint('[PRESENTER][LESSON] No lesson loaded — cannot mark completed');
      _view?.showError('Could not save progress.');
      return;
    }

    try {
      await _progressService.completeLesson(
        _userId,
        _currentCourseId!,
        _currentLessonId!,
      );
      debugPrint('[PRESENTER][LESSON] Lesson completion persisted');
      _view?.markLessonCompleted();
    } catch (e) {
      debugPrint('[PRESENTER][LESSON] Failed to mark lesson completed');
      debugPrint('Reason: $e');
      _view?.showError('Could not save progress.');
    }
  }
}