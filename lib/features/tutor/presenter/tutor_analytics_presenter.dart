import 'package:flutter/foundation.dart';

import '../../tutor/model/tutor_repository.dart';
import '../../tutor/view/i_tutor_dashboard_view.dart';

/// Coordinates between the tutor dashboard UI and the [TutorRepository].
///
/// Retrieves dashboard summary data, student lists, and student statistics.
/// Does not contain business calculations – those belong in services.
class TutorAnalyticsPresenter {
  final TutorRepository _tutorRepository;
  final String _tutorId; // current authenticated user, must be a tutor

  ITutorDashboardView? _view;

  TutorAnalyticsPresenter({
    required TutorRepository tutorRepository,
    required String tutorId,
  })  : _tutorRepository = tutorRepository,
        _tutorId = tutorId;

  /// Attaches the view that will receive UI updates.
  set view(ITutorDashboardView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // loadDashboard
  // ---------------------------------------------------------------------------
  Future<void> loadDashboard() async {
    debugPrint('[PRESENTER][TUTOR] Loading dashboard');
    _view?.showLoading(true);

    try {
      // 1. Fetch dashboard summary
      final dashboardData =
          await _tutorRepository.getDashboardData(_tutorId);
      _view?.showDashboard(dashboardData);
      debugPrint('[PRESENTER][TUTOR] Dashboard loaded');

      // 2. Load student list
      await loadStudents();
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][TUTOR] Dashboard load failed');
      _view?.showError('Unable to load dashboard. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // loadStudents
  // ---------------------------------------------------------------------------
  Future<void> loadStudents() async {
    debugPrint('[PRESENTER][TUTOR] Loading students');
    try {
      final studentIds =
          await _tutorRepository.getStudentsForTutor(_tutorId);
      _view?.showStudents(studentIds);
      debugPrint('[PRESENTER][TUTOR] Students loaded');
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][TUTOR] Failed to load students');
      _view?.showError('Unable to load student list.');
    }
  }

  // ---------------------------------------------------------------------------
  // loadStudentStats
  // ---------------------------------------------------------------------------
  Future<void> loadStudentStats(String studentId, int courseId) async {
    debugPrint('[PRESENTER][TUTOR] Loading student statistics');
    try {
      final stats = await _tutorRepository.getStudentStat(
          _tutorId, studentId, courseId);
      if (stats != null) {
        _view?.showStudentStats(stats);
      } else {
        _view?.showError('No statistics available for this student.');
      }
    } catch (e) {
      debugPrint('[ERROR][PRESENTER][TUTOR] Statistics load failed');
      _view?.showError('Unable to load student statistics.');
    }
  }

  // ---------------------------------------------------------------------------
  // openCourseEditor
  // ---------------------------------------------------------------------------
  void openCourseEditor(String? courseId) {
    _view?.openCourseEditor(courseId);
  }
}