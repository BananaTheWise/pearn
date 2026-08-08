import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'exam_attempt.dart';
import 'exam_attempt_repository.dart';

/// Supabase implementation of [ExamAttemptRepository].
///
/// Database table:
///     exam_attempts
///
/// Database schema:
///     id           uuid
///     user_id      uuid
///     exam_id      text
///     course_id    int4
///     score        int4
///     passed       bool
///     attempted_at timestamptz
class ExamAttemptRepositorySupabase
    implements ExamAttemptRepository {
  final SupabaseService _supabaseService;

  ExamAttemptRepositorySupabase(
    this._supabaseService,
  );

  // ---------------------------------------------------------------------------
  // SAVE ATTEMPT
  // ---------------------------------------------------------------------------

  @override
  Future<ExamAttempt> saveAttempt(
    ExamAttempt attempt,
  ) async {
    debugPrint(
      '[REPOSITORY][EXAM] Saving exam attempt',
    );

    debugPrint(
      '[DB] Inserting EXAM_ATTEMPTS row',
    );

    try {
      // The Flutter application uses:
      //
      // 0.0 -> 0%
      // 0.5 -> 50%
      // 0.75 -> 75%
      // 1.0 -> 100%
      //
      // The PostgreSQL column is int4.
      //
      // Therefore we MUST convert the score to an integer.
      final int databaseScore =
          (attempt.score * 100).round();

      final Map<String, dynamic> data = {
        'user_id': attempt.userId,
        'course_id': attempt.courseId,
        'exam_id': attempt.examId,
        'score': databaseScore,
        'passed': attempt.passed,
        'attempted_at':
            attempt.attemptedAt.toIso8601String(),
      };

      debugPrint(
        '[DB] User ID: ${attempt.userId}',
      );

      debugPrint(
        '[DB] Course ID: ${attempt.courseId}',
      );

      debugPrint(
        '[DB] Exam ID: ${attempt.examId}',
      );

      debugPrint(
        '[DB] Score: ${attempt.score} -> $databaseScore',
      );

      debugPrint(
        '[DB] Passed: ${attempt.passed}',
      );

      final response = await _supabaseService.client
          .from('exam_attempts')
          .insert(data)
          .select()
          .single();

      debugPrint(
        '[DB] Exam attempt saved successfully',
      );

      return ExamAttempt.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      debugPrint(
        '[ERROR][EXAM] Failed to save exam attempt',
      );

      debugPrint(
        'Reason: $e',
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GET ATTEMPTS FOR USER
  // ---------------------------------------------------------------------------

  @override
  Future<List<ExamAttempt>> getAttemptsForUser(
    String userId,
  ) async {
    debugPrint(
      '[REPOSITORY][EXAM] Loading user exam attempts',
    );

    try {
      final response = await _supabaseService.client
          .from('exam_attempts')
          .select()
          .eq('user_id', userId)
          .order(
            'attempted_at',
            ascending: false,
          );

      final List<ExamAttempt> attempts =
          (response as List<dynamic>)
              .map(
                (item) => ExamAttempt.fromMap(
                  Map<String, dynamic>.from(
                    item as Map,
                  ),
                ),
              )
              .toList();

      debugPrint(
        '[DB] Exam attempts loaded: ${attempts.length}',
      );

      return attempts;
    } catch (e) {
      debugPrint(
        '[ERROR][EXAM] Failed to load user exam attempts',
      );

      debugPrint(
        'Reason: $e',
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GET ATTEMPTS FOR EXAM
  // ---------------------------------------------------------------------------

  @override
  Future<List<ExamAttempt>> getAttemptsForExam(
    String userId,
    String examId,
  ) async {
    debugPrint(
      '[REPOSITORY][EXAM] Loading attempts for exam $examId',
    );

    try {
      final response = await _supabaseService.client
          .from('exam_attempts')
          .select()
          .eq('user_id', userId)
          .eq('exam_id', examId)
          .order(
            'attempted_at',
            ascending: false,
          );

      final List<ExamAttempt> attempts =
          (response as List<dynamic>)
              .map(
                (item) => ExamAttempt.fromMap(
                  Map<String, dynamic>.from(
                    item as Map,
                  ),
                ),
              )
              .toList();

      debugPrint(
        '[DB] Exam attempts loaded: ${attempts.length}',
      );

      return attempts;
    } catch (e) {
      debugPrint(
        '[ERROR][EXAM] Failed to load exam attempts',
      );

      debugPrint(
        'Reason: $e',
      );

      rethrow;
    }
  }
}