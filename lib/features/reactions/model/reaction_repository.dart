import 'reaction.dart';

/// Abstract contract for course reaction persistence.
///
/// **All operations are scoped to courses only.**
/// The concrete implementation must enforce that every reaction has
/// `targetType = 'course'`.
abstract class ReactionRepository {
  /// Returns the current user's reaction to the given course, or `null` if
  /// the user has not reacted.
  Future<Reaction?> getUserCourseReaction(String userId, String courseId);

  /// Saves (inserts or updates) a course reaction.
  ///
  /// The [reaction] must have `targetType = 'course'` and `targetId` set to
  /// the course ID.  Returns the persisted [Reaction].
  Future<Reaction> saveCourseReaction(Reaction reaction);

  /// Removes the user's reaction from the course.
  ///
  /// Returns `true` if a reaction was deleted, `false` if none existed.
  Future<bool> deleteCourseReaction(String userId, String courseId);

  /// Returns the total number of reactions of the given [reactionType]
  /// (emoji) on the specified course.
  Future<int> getCourseReactionCount(String courseId, String reactionType);
}