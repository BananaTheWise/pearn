import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';

/// Coordinates between [AdminDashboardScreen] and [AdminRepository].
///
/// Owns every section of the admin dashboard: access verification,
/// analytics, course review/approval, user management, tutor management,
/// and reports. The presenter never talks to Supabase or GitHub directly —
/// everything flows through [AdminRepository].
class AdminDashboardPresenter {
  final AdminRepository _adminRepository;
  final String _currentUserId;

  IAdminView? view;

  AdminDashboardPresenter({
    required AdminRepository adminRepository,
    required String currentUserId,
  })  : _adminRepository = adminRepository,
        _currentUserId = currentUserId;

  // ---------------------------------------------------------------------------
  // Access verification
  // ---------------------------------------------------------------------------

  /// Confirms the current user actually holds the admin role before showing
  /// any dashboard data, then loads the first tab (Analytics).
  Future<void> verifyAdminAccess() async {
    debugPrint('[PRESENTER][ADMIN] Verifying admin access');
    view?.showLoading(true);

    try {
      if (_currentUserId.isEmpty) {
        view?.showError('You must be signed in to view this page.');
        return;
      }

      final user = await _adminRepository.getUser(_currentUserId);

      if (user == null || user.role != User.roleAdmin) {
        debugPrint('[PRESENTER][ADMIN] Access denied for $_currentUserId');
        view?.showError('You do not have permission to view this page.');
        return;
      }

      debugPrint('[PRESENTER][ADMIN] Access verified');
      await loadAnalytics();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Access check failed: $e');
      view?.showError('Could not verify admin access.');
    } finally {
      view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  Future<void> loadAnalytics() async {
    debugPrint('[PRESENTER][ADMIN] Loading analytics');
    view?.showLoading(true);

    try {
      final data = await _adminRepository.getSystemAnalytics();
      view?.showAnalytics(data);
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to load analytics: $e');
      view?.showError('Failed to load analytics.');
    } finally {
      view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Course review / approval
  // ---------------------------------------------------------------------------

  Future<void> loadPendingCourses() async {
    debugPrint('[PRESENTER][ADMIN] Loading pending courses');
    view?.showLoading(true);

    try {
      final courses = await _adminRepository.getPendingCourses();
      view?.showPendingCourses(courses);
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to load pending courses: $e');
      view?.showError('Failed to load pending courses.');
    } finally {
      view?.showLoading(false);
    }
  }

  Future<void> approveCourse(String courseId) async {
    final confirmed =
        await view?.showConfirmation('Approve and publish this course?') ??
            false;
    if (!confirmed) return;

    debugPrint('[PRESENTER][ADMIN] Approving course $courseId');
    view?.showLoading(true);

    try {
      await _adminRepository.approveCourse(courseId);
      await loadPendingCourses();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to approve course: $e');
      view?.showError('Failed to approve course.');
      view?.showLoading(false);
    }
  }

  Future<void> rejectCourse(String courseId, [String? reason]) async {
    final confirmed =
        await view?.showConfirmation('Reject this course submission?') ??
            false;
    if (!confirmed) return;

    debugPrint('[PRESENTER][ADMIN] Rejecting course $courseId');
    view?.showLoading(true);

    try {
      await _adminRepository.rejectCourse(courseId, reason);
      await loadPendingCourses();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to reject course: $e');
      view?.showError('Failed to reject course.');
      view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  Future<void> loadUsers({String? role, String? status}) async {
    debugPrint('[PRESENTER][ADMIN] Loading users');
    view?.showLoading(true);

    try {
      final users = await _adminRepository.getUsers(role: role, status: status);
      view?.showUsers(users);
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to load users: $e');
      view?.showError('Failed to load users.');
    } finally {
      view?.showLoading(false);
    }
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    final confirmed =
        await view?.showConfirmation('Set this user\'s status to "$newStatus"?') ??
            false;
    if (!confirmed) return;

    debugPrint('[PRESENTER][ADMIN] Updating status for $userId -> $newStatus');

    try {
      await _adminRepository.updateUserStatus(userId, newStatus);
      await loadUsers();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to update user status: $e');
      view?.showError('Failed to update user status.');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final confirmed =
        await view?.showConfirmation('Change this user\'s role to "$newRole"?') ??
            false;
    if (!confirmed) return;

    debugPrint('[PRESENTER][ADMIN] Updating role for $userId -> $newRole');

    try {
      await _adminRepository.updateUserRole(userId, newRole);
      await loadUsers();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to update user role: $e');
      view?.showError('Failed to update user role.');
    }
  }

  // ---------------------------------------------------------------------------
  // Tutors
  // ---------------------------------------------------------------------------

  Future<void> loadTutors() async {
    debugPrint('[PRESENTER][ADMIN] Loading tutors');
    view?.showLoading(true);

    try {
      final tutors = await _adminRepository.getTutors();
      view?.showTutors(tutors);
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to load tutors: $e');
      view?.showError('Failed to load tutors.');
    } finally {
      view?.showLoading(false);
    }
  }

  Future<void> updateTutorStatus(String tutorId, String newStatus) async {
    final confirmed =
        await view?.showConfirmation('Set this tutor\'s status to "$newStatus"?') ??
            false;
    if (!confirmed) return;

    debugPrint('[PRESENTER][ADMIN] Updating tutor status for $tutorId -> $newStatus');

    try {
      await _adminRepository.updateTutorStatus(tutorId, newStatus);
      await loadTutors();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to update tutor status: $e');
      view?.showError('Failed to update tutor status.');
    }
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Future<void> loadReports() async {
    debugPrint('[PRESENTER][ADMIN] Loading reports');
    view?.showLoading(true);

    try {
      final reports = await _adminRepository.getReports();
      view?.showReports(reports);
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to load reports: $e');
      view?.showError('Failed to load reports.');
    } finally {
      view?.showLoading(false);
    }
  }

  Future<void> resolveReport(String reportId) async {
    final confirmed =
        await view?.showConfirmation('Mark this report as resolved?') ?? false;
    if (!confirmed) return;

    debugPrint('[PRESENTER][ADMIN] Resolving report $reportId');

    try {
      await _adminRepository.resolveReport(reportId);
      await loadReports();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][ADMIN] Failed to resolve report: $e');
      view?.showError('Failed to resolve report.');
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  void dispose() {
    view = null;
  }
}