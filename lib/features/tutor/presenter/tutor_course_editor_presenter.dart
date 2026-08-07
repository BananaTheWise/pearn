import 'package:flutter/foundation.dart';

import '../../tutor/model/tutor_repository.dart';
import '../../tutor/view/i_tutor_course_editor_view.dart';

/// Coordinates the course editor UI with the [TutorRepository].
///
/// Handles validation and submission of courses for admin review
/// via the GitHub pull‑request workflow.
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
  // Load course (for editing)
  // ---------------------------------------------------------------------------
  Future<void> loadCourse(String? courseId) async {
    debugPrint('[PRESENTER][TUTOR][EDITOR] Loading course');

    if (courseId == null) {
      // New course – show empty editor
      _view?.showCourseEditor({});
      _view?.showLoading(false);
      return;
    }

    _view?.showLoading(true);
    try {
      // Retrieve the course data from the repository.
      // We assume the repository provides a method to get course data by id.
      // If not yet available, we can skip and show an error.
      final courseData = await _tutorRepository.getCourseData?.(courseId);
      if (courseData != null) {
        _view?.showCourseEditor(courseData);
      } else {
        _view?.showError('Course not found.');
        return;
      }
      debugPrint('[PRESENTER][TUTOR][EDITOR] Course loaded');
    } catch (e) {
      debugPrint('[PRESENTER][TUTOR][EDITOR] Failed to load course');
      _view?.showError('Unable to load course data.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Validate course data
  // ---------------------------------------------------------------------------
  List<String>? _validateCourseData(Map<String, dynamic> courseData) {
    debugPrint('[PRESENTER][TUTOR][EDITOR] Validation started');
    final errors = <String>[];

    final id = courseData['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      errors.add('Course ID is required.');
    }

    final title = courseData['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      errors.add('Title is required.');
    }

    // Additional checks could be added here (e.g., valid characters, length)

    if (errors.isNotEmpty) {
      debugPrint('[PRESENTER][TUTOR][EDITOR] Validation failed');
      return errors;
    }

    debugPrint('[PRESENTER][TUTOR][EDITOR] Validation passed');
    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit course
  // ---------------------------------------------------------------------------
  Future<void> submitCourse(Map<String, dynamic> courseData) async {
    // Prevent double submission
    if (_isSubmitting) return;

    // Validate
    final errors = _validateCourseData(courseData);
    if (errors != null) {
      _view?.showValidationError(errors.join('\n'));
      return;
    }

    debugPrint('[PRESENTER][TUTOR][GITHUB] Submission started');
    _isSubmitting = true;
    _view?.showSubmitting(true);

    try {
      // Call the repository to handle GitHub branch, commit, PR creation
      final pullRequestUrl =
          await _tutorRepository.submitCourseForReview(courseData, _tutorId);

      debugPrint('[PRESENTER][TUTOR][GITHUB] Submission completed');
      _view?.showSubmissionSuccess(pullRequestUrl);
    } catch (e) {
      debugPrint('[ERROR][GITHUB] Submission failed');
      _view?.showError('Course submission failed. Please try again.');
    } finally {
      _isSubmitting = false;
      _view?.showSubmitting(false);
    }
  }
}