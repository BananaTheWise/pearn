import 'package:flutter/material.dart';

import '../../learning/model/course_repository.dart';
import '../../learning/view/i_course_detail_view.dart';
import '../../reactions/model/reaction.dart';
import '../../reactions/model/reaction_repository.dart';
import '../model/enrollment_repository.dart';

/// Coordinates between the course detail UI and the repositories.
///
/// Course reactions are strictly scoped to courses.
class CourseDetailPresenter {
  final CourseRepository _courseRepository;
  final EnrollmentRepository? _enrollmentRepository;
  final ReactionRepository? _reactionRepository;
  final String _userId;

  ICourseDetailView? _view;
  String? _currentCourseId;

  CourseDetailPresenter({
    required CourseRepository courseRepo,
    required String userId,
    EnrollmentRepository? enrollmentRepo,
    ReactionRepository? reactionRepo,
  }) : _courseRepository = courseRepo,
       _userId = userId,
       _enrollmentRepository = enrollmentRepo,
       _reactionRepository = reactionRepo;

  // ---------------------------------------------------------------------------
  // View
  // ---------------------------------------------------------------------------

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

      await _loadEnrollment();
      await _loadReactionState();

      debugPrint('[PRESENTER][COURSE] Course details loaded: $courseId');
    } catch (e) {
      debugPrint('[PRESENTER][COURSE] Failed to load course details: $e');

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
  // 3. React to course
  // ---------------------------------------------------------------------------

  Future<void> reactToCourse(String emoji) async {
    final courseId = _currentCourseId;

    if (courseId == null) {
      return;
    }

    if (emoji.trim().isEmpty) {
      _view?.showError('Invalid reaction.');
      return;
    }

    final repository = _reactionRepository;

    if (repository == null) {
      _view?.showError('Reactions are not supported.');
      return;
    }

    debugPrint('[PRESENTER][REACTION] Course reaction requested');

    try {
      final reaction = Reaction(
        userId: _userId,
        targetType: 'course',
        targetId: courseId,
        type: emoji,
        createdAt: DateTime.now(),
      );

      await repository.saveCourseReaction(reaction);

      await _loadReactionState();

      debugPrint('[PRESENTER][REACTION] Course reaction completed');
    } catch (e) {
      debugPrint('[PRESENTER][REACTION] Reaction failed: $e');

      _view?.showError('Could not save reaction. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Remove current user's course reaction
  // ---------------------------------------------------------------------------

  Future<void> removeReaction() async {
    final courseId = _currentCourseId;

    if (courseId == null) {
      return;
    }

    final repository = _reactionRepository;

    if (repository == null) {
      return;
    }

    debugPrint('[PRESENTER][REACTION] Removing course reaction');

    try {
      await repository.deleteCourseReaction(_userId, courseId);

      await _loadReactionState();
    } catch (e) {
      debugPrint('[PRESENTER][REACTION] Failed to remove reaction: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 5. Enroll in course
  // ---------------------------------------------------------------------------

  Future<void> enrollInCourse() async {
    final courseId = _currentCourseId;

    if (courseId == null) {
      return;
    }

    final repository = _enrollmentRepository;

    if (repository == null) {
      _view?.showError('Enrollment is not available.');
      return;
    }

    try {
      await repository.enroll(_userId, courseId);

      await _loadEnrollment();
    } catch (e) {
      debugPrint('[PRESENTER][ENROLL] Enrollment failed: $e');

      _view?.showError('Could not enroll. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Private: enrollment
  // ---------------------------------------------------------------------------

  Future<void> _loadEnrollment() async {
    final repository = _enrollmentRepository;
    final courseId = _currentCourseId;

    if (repository == null || courseId == null) {
      _view?.showEnrollmentState(null);
      return;
    }

    try {
      final enrollment = await repository.getEnrollment(_userId, courseId);

      _view?.showEnrollmentState(enrollment);
    } catch (e) {
      debugPrint('[PRESENTER][ENROLLMENT] Failed to load enrollment: $e');

      _view?.showEnrollmentState(null);
    }
  }

  // ---------------------------------------------------------------------------
  // Private: reactions
  // ---------------------------------------------------------------------------

  Future<void> _loadReactionState() async {
    final repository = _reactionRepository;
    final courseId = _currentCourseId;

    if (repository == null || courseId == null) {
      _view?.showReactionState(null, 0);
      return;
    }

    try {
      // Current user's reaction.
      final userReaction = await repository.getUserCourseReaction(
        _userId,
        courseId,
      );

      // Total number of reactions.
      //
      // Your repository requires a reaction type to count.
      // Therefore we calculate the total from the supported emojis.
      const reactionTypes = ['👍', '❤️', '😂', '😮', '😢', '😡'];

      int total = 0;

      for (final reactionType in reactionTypes) {
        total += await repository.getCourseReactionCount(
          courseId,
          reactionType,
        );
      }

      _view?.showReactionState(userReaction?.type, total);
    } catch (e) {
      debugPrint('[PRESENTER][REACTION] Failed to load reaction state: $e');

      _view?.showReactionState(null, 0);
    }
  }
}

// =============================================================================
// COURSE REACTION BAR
// =============================================================================

/// Reusable widget that displays course reaction buttons.
///
/// This widget does not communicate with repositories or Supabase.
/// All state and actions are supplied through callbacks.
class CourseReactionBar extends StatelessWidget {
  final List<String> reactionTypes;

  final String? userReaction;

  final Map<String, int>? reactionCounts;

  final int? totalReactions;

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
            if (totalReactions != null) ...[
              Text(
                '$totalReactions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],

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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        if (reactionCounts != null) ...[
                          const SizedBox(width: 4),
                          Text('$count', style: const TextStyle(fontSize: 14)),
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
