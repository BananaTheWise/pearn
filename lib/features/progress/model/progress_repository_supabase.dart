import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/course_id_resolver.dart';
import 'progress.dart';
import 'progress_repository.dart';

/// Concrete implementation of [ProgressRepository] using Supabase.
///
/// There is no separate `progress` table — progress is stored directly on
/// the `enrollments` row for the user/course (`completed_lessons`,
/// `completion_percent`, `last_accessed_at`). [CourseIdResolver] bridges
/// between the app's string course slug and the integer `course_id` used
/// as the primary key in Supabase.
class ProgressRepositorySupabase implements ProgressRepository {
  final SupabaseService _supabaseService;
  final CourseIdResolver _courseIdResolver;

  ProgressRepositorySupabase(this._supabaseService, this._courseIdResolver);

  // ---------------------------------------------------------------------------
  // getProgress
  // ---------------------------------------------------------------------------
  @override
  Future<Progress?> getProgress(String userId, String courseId) async {
    debugPrint('[REPOSITORY][PROGRESS] Loading user progress');
    debugPrint('[DB] Progress query started');

    try {
      final courseIdInt = await _courseIdResolver.idForSlug(courseId);

      final response = await _supabaseService.client
          .from('enrollments')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseIdInt)
          .maybeSingle();

      debugPrint('[DB] Progress query completed');

      if (response == null) {
        debugPrint('[REPOSITORY][PROGRESS] No progress found');
        return null;
      }

      debugPrint('[REPOSITORY][PROGRESS] Progress loaded');
      return Progress.fromMap(
        Map<String, dynamic>.from(response),
        courseSlug: courseId,
      );
    } catch (e) {
      debugPrint('[ERROR][PROGRESS] Failed to load progress');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // markLessonCompleted
  // ---------------------------------------------------------------------------
  @override
  Future<void> markLessonCompleted(
      String userId, String courseId, String lessonId) async {
    debugPrint('[REPOSITORY][PROGRESS] Marking lesson completed');
    debugPrint('[DB] Progress write started');

    try {
      final courseIdInt = await _courseIdResolver.idForSlug(courseId);

      // 1. Fetch existing enrollment row (if any)
      final existing = await _supabaseService.client
          .from('enrollments')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseIdInt)
          .maybeSingle();

      final now = DateTime.now().toIso8601String();
      List<String> completed = [];

      if (existing != null) {
        completed = (existing['completed_lessons'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      }

      // Only add if not already present
      if (!completed.contains(lessonId)) {
        completed.add(lessonId);
      }

      final totalLessons =
          await _courseIdResolver.totalLessonsForSlug(courseId);
      final percent = totalLessons > 0
          ? (completed.length / totalLessons * 100).clamp(0, 100).toDouble()
          : 0.0;

      final data = {
        'completed_lessons': completed,
        'completion_percent': percent,
        'last_accessed_at': now,
      };

      if (existing != null) {
        // Update the existing enrollment row
        await _supabaseService.client
            .from('enrollments')
            .update(data)
            .eq('user_id', userId)
            .eq('course_id', courseIdInt);
      } else {
        // No enrollment row yet (shouldn't normally happen — the user
        // should be enrolled before completing lessons) — create one.
        await _supabaseService.client.from('enrollments').insert({
          'user_id': userId,
          'course_id': courseIdInt,
          'enrolled_at': now,
          ...data,
        });
      }

      debugPrint('[DB] Progress write completed');
    } catch (e) {
      debugPrint('[ERROR][PROGRESS] Failed to mark lesson completed');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getCompletedLessons
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> getCompletedLessons(
      String userId, String courseId) async {
    final progress = await getProgress(userId, courseId);
    return progress?.completedLessonIds ?? [];
  }

  // ---------------------------------------------------------------------------
  // saveProgress
  // ---------------------------------------------------------------------------
  @override
  Future<void> saveProgress(Progress progress) async {
    debugPrint('[REPOSITORY][PROGRESS] Saving progress');
    debugPrint('[DB] Progress write started');

    try {
      final courseIdInt =
          await _courseIdResolver.idForSlug(progress.courseId);

      final data = {
        'user_id': progress.userId,
        'course_id': courseIdInt,
        ...progress.toMap(),
      };

      // Upsert based on the (user_id, course_id) composite key.
      await _supabaseService.client
          .from('enrollments')
          .upsert(data, onConflict: 'user_id,course_id');

      debugPrint('[DB] Progress write completed');
    } catch (e) {
      debugPrint('[ERROR][PROGRESS] Failed to save progress');
      debugPrint('Reason: $e');
      rethrow;
    }
  }
}