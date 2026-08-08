import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/course_id_resolver.dart';
import 'enrollment.dart';
import 'enrollment_repository.dart';

class EnrollmentRepositorySupabase implements EnrollmentRepository {
  final SupabaseService _supabaseService;
  final CourseIdResolver _courseIdResolver;

  EnrollmentRepositorySupabase(this._supabaseService, this._courseIdResolver);

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

    final courseIdInt = await _courseIdResolver.idForSlug(courseId);

    final response = await _supabaseService.client
        .from('enrollments')
        .select()
        .eq('user_id', userId)
        .eq('course_id', courseIdInt)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Enrollment.fromMap(
      Map<String, dynamic>.from(response),
      courseSlug: courseId,
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

    final enrollments = <Enrollment>[];
    for (final row in response) {
      final map = Map<String, dynamic>.from(row);
      final slug = await _courseIdResolver.slugForId(map['course_id'] as int);
      enrollments.add(Enrollment.fromMap(map, courseSlug: slug));
    }
    return enrollments;
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

    final courseIdInt = await _courseIdResolver.idForSlug(courseId);

    await _supabaseService.client.from('enrollments').insert({
      'user_id': userId,
      'course_id': courseIdInt,
      'enrolled_at': DateTime.now().toIso8601String(),
      'completed_at': null,
      'completed_lessons': <String>[],
      'completion_percent': 0,
    });
  }
}