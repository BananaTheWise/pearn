import 'package:flutter/foundation.dart';
import 'package:pearn/features/learning/model/enrollment_repository.dart';

import '../../auth/model/user_repository.dart';
import '../../progress/model/progress_repository.dart';
import '../../progress/model/progress.dart';
import '../../progress/services/streak_service.dart';
import '../../progress/view/i_progress_view.dart';

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
  }) : _progressRepository = progressRepository,
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
      // 1. Fetch all courses the user is enrolled in.
      final enrollments = await _enrollmentRepository.getUserEnrollments(
        _userId,
      );

      // 2. Load progress for each enrolled course.
      for (final enrollment in enrollments) {
        final progress = await _progressRepository.getProgress(
          _userId,
          enrollment.courseId,
        );

        if (progress != null) {
          _view?.showProgress(progress);
        }
      }

      // 3. Load streak.
      final streak = await _streakService.getCurrentStreak(_userId);
      _view?.showStreak(streak);

      // 4. Load user level.
      final user = await _userRepository.findById(_userId);

      if (user != null) {
        _view?.showLevel(user.currentLevel);
      }

      debugPrint('[PRESENTER][PROGRESS] Progress displayed');
    } catch (e) {
      debugPrint('[PRESENTER][PROGRESS] Progress loading failed');
      debugPrint('Reason: $e');

      _view?.showError('Unable to load progress. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }
}
