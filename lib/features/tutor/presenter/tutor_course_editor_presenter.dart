import 'package:flutter/foundation.dart';

import '../../tutor/model/tutor_repository.dart';
import '../../tutor/view/i_tutor_course_editor_view.dart';

/// Coordinates the course editor UI with the [TutorRepository].
///
/// Handles validation and submission of courses for admin review
/// via the GitHub pull-request workflow.
class TutorCourseEditorPresenter {
  final TutorRepository _tutorRepository;
  final String _tutorId;

  ITutorCourseEditorView? _view;
  bool _isSubmitting = false;

  TutorCourseEditorPresenter({
    required TutorRepository tutorRepository,
    required String tutorId,
  })  : _tutorRepository = tutorRepository,
        _tutorId = tutorId;

  /// Attaches the view that will receive UI updates.
  set view(ITutorCourseEditorView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // Load course
  // ---------------------------------------------------------------------------

  Future<void> loadCourse(String? courseId) async {
    debugPrint('[PRESENTER][TUTOR][EDITOR] Loading course');

    // Creating a new course.
    if (courseId == null || courseId.trim().isEmpty) {
      _view?.showCourseEditor({});
      _view?.showLoading(false);
      return;
    }

    /*
     * TutorRepository currently does not provide getCourseData().
     *
     * Therefore we cannot load an existing course here yet.
     * Add a getCourseData() method to TutorRepository when the
     * repository implementation is ready to support course editing.
     */

    debugPrint(
      '[PRESENTER][TUTOR][EDITOR] '
      'Existing course loading is not implemented.',
    );

    _view?.showError(
      'Editing existing courses is not available yet.',
    );

    _view?.showLoading(false);
  }

  // ---------------------------------------------------------------------------
  // Validate course data
  // ---------------------------------------------------------------------------

  List<String>? _validateCourseData(
    Map<String, dynamic> courseData,
  ) {
    debugPrint(
      '[PRESENTER][TUTOR][EDITOR] Validation started',
    );

    final errors = <String>[];

    final id = courseData['id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      errors.add('Course ID is required.');
    }

    final title = courseData['title']?.toString().trim() ?? '';

    if (title.isEmpty) {
      errors.add('Title is required.');
    }

    if (errors.isNotEmpty) {
      debugPrint(
        '[PRESENTER][TUTOR][EDITOR] Validation failed',
      );

      return errors;
    }

    debugPrint(
      '[PRESENTER][TUTOR][EDITOR] Validation passed',
    );

    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit course
  // ---------------------------------------------------------------------------

  Future<void> submitCourse(
    Map<String, dynamic> courseData,
  ) async {
    // Prevent double submission.
    if (_isSubmitting) {
      return;
    }

    // Validate course.
    final errors = _validateCourseData(courseData);

    if (errors != null) {
      _view?.showValidationError(
        errors.join('\n'),
      );
      return;
    }

    debugPrint(
      '[PRESENTER][TUTOR][GITHUB] Submission started',
    );

    _isSubmitting = true;
    _view?.showSubmitting(true);

    try {
      // Repository handles the GitHub branch/commit/PR workflow.
      final pullRequestUrl =
          await _tutorRepository.submitCourseForReview(
        courseData,
        _tutorId,
      );

      debugPrint(
        '[PRESENTER][TUTOR][GITHUB] Submission completed',
      );

      _view?.showSubmissionSuccess(
        pullRequestUrl,
      );
    } catch (e) {
      debugPrint(
        '[ERROR][GITHUB] Submission failed: $e',
      );

      _view?.showError(
        'Course submission failed. Please try again.',
      );
    } finally {
      _isSubmitting = false;
      _view?.showSubmitting(false);
    }
  }
}