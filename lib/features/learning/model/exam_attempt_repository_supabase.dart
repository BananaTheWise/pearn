import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'exam_attempt.dart';
import 'exam_attempt_repository.dart';

/// Concrete implementation of [ExamAttemptRepository] using Supabase.
///
/// Interacts with the `exam_attempts` table.
class ExamAttemptRepositorySupabase implements ExamAttemptRepository {
  final SupabaseService _supabaseService;

  ExamAttemptRepositorySupabase(this._supabaseService);

  // ---------------------------------------------------------------------------
  // saveAttempt
  // ---------------------------------------------------------------------------
  @override
  Future<ExamAttempt> saveAttempt(ExamAttempt attempt) async {
    debugPrint('[REPOSITORY][EXAM] Saving exam attempt');
    debugPrint('[DB] Inserting EXAM_ATTEMPTS row');

    try {
      // Build insert map without the id to let Supabase generate a UUID.
      final data = {
        'user_id': attempt.userId,
        'exam_id': attempt.examId,
        'score': attempt.score,
        'passed': attempt.passed,
        'attempted_at': attempt.attemptedAt.toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('exam_attempts')
          .insert(data)
          .select()
          .single();

      debugPrint('[DB] Exam attempt saved');
      return ExamAttempt.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][EXAM] Failed to save exam attempt');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getAttemptsForUser
  // ---------------------------------------------------------------------------
  @override
  Future<List<ExamAttempt>> getAttemptsForUser(String userId) async {
    debugPrint('[REPOSITORY][EXAM] Loading user exam attempts');

    try {
      final response = await _supabaseService.client
          .from('exam_attempts')
          .select()
          .eq('user_id', userId)
          .order('attempted_at', ascending: false);

      final attempts =
          (response as List<dynamic>).map((e) => ExamAttempt.fromMap(e)).toList();

      debugPrint('[DB] Exam attempts loaded: ${attempts.length}');
      return attempts;
    } catch (e) {
      debugPrint('[ERROR][EXAM] Failed to load user exam attempts');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getAttemptsForExam
  // ---------------------------------------------------------------------------
  @override
  Future<List<ExamAttempt>> getAttemptsForExam(String userId, String examId) async {
    debugPrint('[REPOSITORY][EXAM] Loading attempts for exam $examId');

    try {
      final response = await _supabaseService.client
          .from('exam_attempts')
          .select()
          .eq('user_id', userId)
          .eq('exam_id', examId)
          .order('attempted_at', ascending: false);

      final attempts =
          (response as List<dynamic>).map((e) => ExamAttempt.fromMap(e)).toList();

      debugPrint('[DB] Exam attempts loaded: ${attempts.length}');
      return attempts;
    } catch (e) {
      debugPrint('[ERROR][EXAM] Failed to load exam attempts for exam');
      debugPrint('Reason: $e');
      rethrow;
    }
  }
}