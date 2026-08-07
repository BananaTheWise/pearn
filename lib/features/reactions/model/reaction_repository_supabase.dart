import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'reaction.dart';
import 'reaction_repository.dart';

/// Concrete implementation of [ReactionRepository] using Supabase.
///
/// Interacts with the `reactions` table.  Every operation is strictly
/// scoped to `target_type = 'course'`.  Any attempt to save a reaction
/// with a different target type will throw an [ArgumentError].
class ReactionRepositorySupabase implements ReactionRepository {
  final SupabaseService _supabaseService;

  ReactionRepositorySupabase(this._supabaseService);

  // ---------------------------------------------------------------------------
  // getUserCourseReaction
  // ---------------------------------------------------------------------------
  @override
  Future<Reaction?> getUserCourseReaction(
    String userId,
    String courseId,
  ) async {
    debugPrint('[REPOSITORY][REACTION] Loading course reaction');
    debugPrint('[DB][REACTION] Query started');

    try {
      final response = await _supabaseService.client
          .from('reactions')
          .select()
          .eq('user_id', userId)
          .eq('target_type', 'course')
          .eq('target_id', courseId)
          .maybeSingle();

      debugPrint('[DB][REACTION] Query completed');

      if (response == null) return null;
      return Reaction.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][REACTION] Failed to load course reaction');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // saveCourseReaction
  // ---------------------------------------------------------------------------
  @override
  Future<Reaction> saveCourseReaction(Reaction reaction) async {
    // Enforce course-only semantics – reject any other target type.
    if (reaction.targetType != 'course') {
      throw ArgumentError(
        'Only course reactions are supported. '
        'Received targetType: "${reaction.targetType}".',
      );
    }

    debugPrint('[REPOSITORY][REACTION] Saving course reaction');
    debugPrint('[DB][REACTION] target_type=course');
    debugPrint('[DB][REACTION] target_id=${reaction.targetId}');

    try {
      final data = reaction.toMap();

      // Upsert based on the unique combination of (user_id, target_type, target_id).
      // This ensures a user can only have one active reaction per course.
      final response = await _supabaseService.client
          .from('reactions')
          .upsert(data, onConflict: 'user_id, target_type, target_id')
          .select()
          .single();

      debugPrint('[DB][REACTION] Course reaction saved');
      return Reaction.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][REACTION] Failed to save course reaction');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // deleteCourseReaction
  // ---------------------------------------------------------------------------
  @override
  Future<bool> deleteCourseReaction(String userId, String courseId) async {
    debugPrint('[REPOSITORY][REACTION] Removing course reaction');

    try {
      await _supabaseService.client
          .from('reactions')
          .delete()
          .eq('user_id', userId)
          .eq('target_type', 'course')
          .eq('target_id', courseId);

      debugPrint('[DB][REACTION] Course reaction removed');
      return true;
    } catch (e) {
      debugPrint('[ERROR][REACTION] Failed to remove course reaction');
      debugPrint('Reason: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // getCourseReactionCount
  // ---------------------------------------------------------------------------
  @override
  Future<int> getCourseReactionCount(
    String courseId,
    String reactionType,
  ) async {
    debugPrint('[REPOSITORY][REACTION] Loading course reaction count');

    try {
      final response = await _supabaseService.client
          .from('reactions')
          .select('id')
          .eq('target_type', 'course')
          .eq('target_id', courseId)
          .eq('type', reactionType)
          .count();

      final count = response.count;

      debugPrint('[DB][REACTION] Reaction count: $count');

      return count;
    } catch (e) {
      debugPrint('[ERROR][REACTION] Failed to load reaction count');
      debugPrint('Reason: $e');

      return 0;
    }
  }
}
