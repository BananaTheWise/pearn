import 'package:flutter/foundation.dart';

import '../../learning/model/course_repository.dart';
import '../../learning/view/i_course_catalog_view.dart';

/// Coordinates between the course catalog UI and the [CourseRepository].
class CourseCatalogPresenter {
  final CourseRepository _courseRepository;
  ICourseCatalogView? _view;

  CourseCatalogPresenter({required CourseRepository courseRepo})
      : _courseRepository = courseRepo;

  /// Attaches the view that will receive UI updates.
  set view(ICourseCatalogView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // 1. loadCourses
  // ---------------------------------------------------------------------------
  Future<void> loadCourses() async {
    debugPrint('[PRESENTER][COURSE] Loading courses');
    _view?.showLoading(true);

    try {
      final courses = await _courseRepository.listCourses();
      if (courses.isEmpty) {
        _view?.showEmptyState();
      } else {
        _view?.showCourses(courses);
      }
      debugPrint('[PRESENTER][COURSE] Courses loaded: ${courses.length}');
    } catch (e) {
      debugPrint('[PRESENTER][COURSE] Course loading failed');
      _view?.showError(_mapErrorToMessage(e));
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. openCourse
  // ---------------------------------------------------------------------------
  void openCourse(String courseId) {
    if (courseId.trim().isEmpty) {
      _view?.showError('Invalid course identifier.');
      return;
    }
    _view?.navigateToCourse(courseId);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  String _mapErrorToMessage(Object e) {
    // Map known repository errors to user-friendly messages.
    // Keep the message generic to avoid exposing internal details.
    return 'Unable to load courses. Please check your connection and try again.';
  }
}