import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'enrollment.dart';
import 'enrollment_repository.dart';

class EnrollmentRepositorySupabase implements EnrollmentRepository {
  final SupabaseService _supabaseService;

  EnrollmentRepositorySupabase(this._supabaseService);

  // ---------------------------------------------------------------------------
  // Get enrollment for a specific course
  // ---------------------------------------------------------------------------

  @override
  Future<Enrollment?> getEnrollment(
    String userId,
    String courseId,
  ) async {
    debugPrint(
      '[ENROLLMENT] Loading enrollment for course: $courseId',
    );

    final response = await _supabaseService.client
        .from('enrollments')
        .select()
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Enrollment.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ---------------------------------------------------------------------------
  // Get all enrollments for a user
  // ---------------------------------------------------------------------------

  @override
  Future<List<Enrollment>> getUserEnrollments(
    String userId,
  ) async {
    debugPrint(
      '[ENROLLMENT] Loading all enrollments for user: $userId',
    );

    final response = await _supabaseService.client
        .from('enrollments')
        .select()
        .eq('user_id', userId)
        .order('enrolled_at', ascending: false);

    return response
        .map<Enrollment>(
          (row) => Enrollment.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Enroll user in course
  // ---------------------------------------------------------------------------

  @override
  Future<void> enroll(
    String userId,
    String courseId,
  ) async {
    debugPrint(
      '[ENROLLMENT] Enrolling user in course: $courseId',
    );

    await _supabaseService.client
        .from('enrollments')
        .insert({
      'user_id': userId,
      'course_id': courseId,
      'status': 'active',
      'enrolled_at': DateTime.now().toIso8601String(),
      'completed_at': null,
    });
  }
}