import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/enrollment.dart';
import '../../learning/model/course.dart';
import '../../learning/model/course_repository.dart';
import '../../learning/view/i_course_detail_view.dart';

// -----------------------------------------------------------------------------
// Lightweight abstractions to avoid creating unsupported repository files.
// Remove these once the concrete implementations are registered in DI.
// -----------------------------------------------------------------------------

/// Abstract contract for enrollment operations.
abstract class EnrollmentRepository {
  Future<Enrollment?> getEnrollment(String userId, String courseId);
  Future<void> enroll(String userId, String courseId);
}

/// Abstract contract for reaction operations (course-only).
abstract class ReactionRepository {
  /// Adds or updates a reaction. [targetType] must always be `'course'`.
  Future<void> react(
      String userId, String targetType, String targetId, String reaction);

  /// Removes the user's reaction on the given target.
  Future<void> removeReaction(
      String userId, String targetType, String targetId);

  /// Returns the current user's reaction emoji or `null`.
  Future<String?> getUserReaction(
      String userId, String targetType, String targetId);

  /// Returns the total number of reactions for the target.
  Future<int> getTotalReactions(String targetType, String targetId);
}

// -----------------------------------------------------------------------------

/// Coordinates between the course detail UI and the repositories.
class CourseDetailPresenter {
  final CourseRepository _courseRepository;
  final EnrollmentRepository? _enrollmentRepository;
  final ReactionRepository? _reactionRepository;
  final String _userId;

  ICourseDetailView? _view;
  String? _currentCourseId; // used internally for reactions/enrollment

  CourseDetailPresenter({
    required CourseRepository courseRepo,
    required String userId,
    EnrollmentRepository? enrollmentRepo,
    ReactionRepository? reactionRepo,
  })  : _courseRepository = courseRepo,
        _userId = userId,
        _enrollmentRepository = enrollmentRepo,
        _reactionRepository = reactionRepo;

  /// Attaches the view that will receive UI updates.
  set view(ICourseDetailView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // 1. Load course details
  // ---------------------------------------------------------------------------
  Future<void> loadCourse(String courseId) async {
    _currentCourseId = courseId;
    _view?.showLoading(true);

    try {
      final course = await _courseRepository.getCourse(courseId);
      if (course == null) {
        _view?.showError('Course not found.');
        return;
      }

      final chapters = await _courseRepository.getChapters(courseId);
      _view?.showCourse(course);
      _view?.showChapters(chapters);

      // Optionally load enrollment & reaction state
      await _loadEnrollment();
      await _loadReactionState();

      debugPrint('[PRESENTER][COURSE] Course details loaded: $courseId');
    } catch (e) {
      debugPrint('[PRESENTER][COURSE] Failed to load course details');
      _view?.showError('Unable to load course. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Open lesson
  // ---------------------------------------------------------------------------
  void openLesson(String lessonId) {
    if (lessonId.trim().isEmpty) {
      _view?.showError('Invalid lesson identifier.');
      return;
    }
    _view?.navigateToLesson(lessonId);
  }

  // ---------------------------------------------------------------------------
  // 3. React to course (course-only, target_type must be 'course')
  // ---------------------------------------------------------------------------
  Future<void> reactToCourse(String emoji) async {
    final courseId = _currentCourseId;
    if (courseId == null) return;

    debugPrint('[PRESENTER][REACTION] Course reaction requested');
    final targetType = 'course'; // never allow any other type

    if (_reactionRepository == null) {
      _view?.showError('Reactions are not supported.');
      return;
    }

    try {
      await _reactionRepository!.react(_userId, targetType, courseId, emoji);
      await _loadReactionState();
      debugPrint('[PRESENTER][REACTION] Course reaction completed');
    } catch (e) {
      debugPrint('[PRESENTER][REACTION] Reaction failed');
      _view?.showError('Could not save reaction. Please try again.');
    }
  }

  /// Removes the current user's reaction (called when tapping the active emoji again).
  Future<void> removeReaction() async {
    final courseId = _currentCourseId;
    if (courseId == null) return;

    debugPrint('[PRESENTER][REACTION] Removing course reaction');
    if (_reactionRepository == null) return;

    try {
      await _reactionRepository!.removeReaction(_userId, 'course', courseId);
      await _loadReactionState();
    } catch (e) {
      debugPrint('[PRESENTER][REACTION] Failed to remove reaction');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Enroll in the course (if supported)
  // ---------------------------------------------------------------------------
  Future<void> enrollInCourse() async {
    final courseId = _currentCourseId;
    if (courseId == null) return;

    if (_enrollmentRepository == null) {
      _view?.showError('Enrollment is not available.');
      return;
    }

    try {
      await _enrollmentRepository!.enroll(_userId, courseId);
      await _loadEnrollment();
    } catch (e) {
      debugPrint('[PRESENTER][ENROLL] Enrollment failed');
      _view?.showError('Could not enroll. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------
  Future<void> _loadEnrollment() async {
    if (_enrollmentRepository == null || _currentCourseId == null) {
      _view?.showEnrollmentState(null);
      return;
    }
    try {
      final enrollment = await _enrollmentRepository!.getEnrollment(
          _userId, _currentCourseId!);
      _view?.showEnrollmentState(enrollment);
    } catch (_) {
      _view?.showEnrollmentState(null);
    }
  }

  Future<void> _loadReactionState() async {
    if (_reactionRepository == null || _currentCourseId == null) {
      _view?.showReactionState(null, 0);
      return;
    }
    try {
      final userReaction = await _reactionRepository!.getUserReaction(
          _userId, 'course', _currentCourseId!);
      final total = await _reactionRepository!.getTotalReactions(
          'course', _currentCourseId!);
      _view?.showReactionState(userReaction, total);
    } catch (_) {
      _view?.showReactionState(null, 0);
    }
  }

}


/// Reusable widget that displays a set of course reaction buttons.
///
/// This widget is **only** for courses. It does not call any repository,
/// service, or backend. All state and actions are controlled via callbacks
/// from the presenter.
class CourseReactionBar extends StatelessWidget {
  /// The list of emojis available for reaction (e.g. ['👍', '❤️']).
  final List<String> reactionTypes;

  /// The emoji the current user has selected, or `null` if none.
  final String? userReaction;

  /// A map from emoji string to the number of reactions of that type.
  /// If not provided, counts are not displayed.
  final Map<String, int>? reactionCounts;

  /// Total number of reactions across all types (optional).
  final int? totalReactions;

  /// Called when the user taps a reaction emoji.
  /// The selected emoji string is passed as argument.
  final ValueChanged<String> onReactionSelected;

  const CourseReactionBar({
    super.key,
    required this.reactionTypes,
    required this.userReaction,
    this.reactionCounts,
    this.totalReactions,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Total count label (optional)
            if (totalReactions != null) ...[
              Text(
                '$totalReactions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
            ],
            // Reaction buttons
            ...reactionTypes.map((emoji) {
              final isSelected = userReaction == emoji;
              final count = reactionCounts?[emoji] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onReactionSelected(emoji),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        if (reactionCounts != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}