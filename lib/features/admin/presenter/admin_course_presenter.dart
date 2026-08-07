import 'package:flutter/foundation.dart';

import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';

/// Coordinates course review actions between the admin UI and the [AdminRepository].
///
/// Handles pending course list, approval (with GitHub merge or status update),
/// and rejection with audit logging.
class AdminCoursePresenter {
  final AdminRepository _adminRepository;

  IAdminView? _view;
  bool _isProcessing = false;

  AdminCoursePresenter({required AdminRepository adminRepo})
      : _adminRepository = adminRepo;

  set view(IAdminView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // loadPendingCourses
  // ---------------------------------------------------------------------------
  Future<void> loadPendingCourses() async {
    debugPrint('[PRESENTER][ADMIN][COURSE] Loading pending courses');
    _view?.showLoading(true);
    try {
      final courses = await _adminRepository.getPendingCourses();
      _view?.showPendingCourses(courses);
      debugPrint('[PRESENTER][ADMIN][COURSE] Pending courses loaded');
    } catch (e) {
      debugPrint('[ERROR][ADMIN][COURSE] Failed to load pending courses');
      _view?.showError('Unable to load pending courses.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // approveCourse
  // ---------------------------------------------------------------------------
  Future<void> approveCourse(String courseId) async {
    if (_isProcessing) return;
    debugPrint('[ADMIN][COURSE] Approval requested');

    // Confirm with admin
    final confirmed = await _view?.showConfirmation('Approve this course?');
    if (confirmed != true) return;

    debugPrint('[ADMIN][COURSE] Approval authorized');
    _isProcessing = true;
    _view?.showLoading(true);

    try {
      debugPrint('[GITHUB][COURSE] Merge/status update started');
      await _adminRepository.approveCourse(courseId);
      debugPrint('[GITHUB][COURSE] Merge/status update completed');
      debugPrint('[AUDIT] Approval logged');
      debugPrint('[ADMIN][COURSE] Approval completed');

      // Refresh the pending course list
      await loadPendingCourses();
    } catch (e) {
      debugPrint('[ERROR][ADMIN][COURSE] Course approval failed');
      _view?.showError('Approval failed. Please try again.');
    } finally {
      _isProcessing = false;
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // rejectCourse
  // ---------------------------------------------------------------------------
  Future<void> rejectCourse(String courseId, {String? reason}) async {
    if (_isProcessing) return;
    debugPrint('[ADMIN][COURSE] Rejection requested');

    // Confirm
    final confirmed = await _view?.showConfirmation('Reject this course?');
    if (confirmed != true) return;

    // Optionally ask for reason
    if (reason == null) {
      // We could show a dialog to enter reason but IAdminView does not have that method.
      // For simplicity we'll just proceed with empty reason.
    }

    _isProcessing = true;
    _view?.showLoading(true);

    try {
      await _adminRepository.rejectCourse(courseId, reason);
      debugPrint('[ADMIN][COURSE] Rejection completed');

      await loadPendingCourses();
    } catch (e) {
      debugPrint('[ERROR][ADMIN][COURSE] Course rejection failed');
      _view?.showError('Rejection failed. Please try again.');
    } finally {
      _isProcessing = false;
      _view?.showLoading(false);
    }
  }
}