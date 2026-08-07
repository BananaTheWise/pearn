import 'package:flutter/foundation.dart';

import '../../../core/models/enrollment.dart';
import '../../auth/model/user_repository.dart';
import '../../progress/model/progress_repository.dart';
import '../../progress/model/progress.dart';
import '../../progress/services/streak_service.dart';
import '../../progress/view/i_progress_view.dart';

// -----------------------------------------------------------------------------
// Placeholder until the EnrollmentRepository is registered in DI.
// -----------------------------------------------------------------------------
abstract class EnrollmentRepository {
  /// Returns all enrollments for a specific user.
  Future<List<Enrollment>> getUserEnrollments(String userId);
}
// -----------------------------------------------------------------------------

/// Coordinates between the progress UI and the data layer.
///
/// Fetches course progress, streak, and user level information.
class ProgressPresenter {
  final ProgressRepository _progressRepository;
  final StreakService _streakService;
  final UserRepository _userRepository;
  final EnrollmentRepository _enrollmentRepository;
  final String _userId;

  IProgressView? _view;

  ProgressPresenter({
    required ProgressRepository progressRepository,
    required StreakService streakService,
    required UserRepository userRepository,
    required EnrollmentRepository enrollmentRepository,
    required String userId,
  })  : _progressRepository = progressRepository,
        _streakService = streakService,
        _userRepository = userRepository,
        _enrollmentRepository = enrollmentRepository,
        _userId = userId;

  /// Attaches the view that will receive UI updates.
  set view(IProgressView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // loadProgress
  // ---------------------------------------------------------------------------
  Future<void> loadProgress() async {
    debugPrint('[PRESENTER][PROGRESS] Loading progress');
    _view?.showLoading(true);

    try {
      // 1. Fetch enrolled courses
      final enrollments = await _enrollmentRepository.getUserEnrollments(_userId);
      final courseIds = enrollments.map((e) => e.courseId).toList();

      // 2. Load progress for each course
      for (final courseId in courseIds) {
        final progress =
            await _progressRepository.getProgress(_userId, courseId);
        if (progress != null) {
          _view?.showProgress(progress);
        }
        // If no progress record, the view can show an empty state for that course.
      }

      // 3. Load streak
      final streak = await _streakService.getCurrentStreak(_userId);
      _view?.showStreak(streak);
      debugPrint('[PRESENTER][PROGRESS] Streak loaded');

      // 4. Load user level
      final user = await _userRepository.findById(_userId);
      if (user != null) {
        _view?.showLevel(user.currentLevel);
      }

      debugPrint('[PRESENTER][PROGRESS] Progress displayed');
    } catch (e) {
      debugPrint('[PRESENTER][PROGRESS] Progress loading failed');
      _view?.showError('Unable to load progress. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }
}