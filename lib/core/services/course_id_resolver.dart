import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Converts between the app's String course id and Supabase's
/// integer course_id.
///
/// GitHub:
///
///     courses/2/
///
/// Supabase:
///
///     courses.course_id = 2
class CourseIdResolver {
  final SupabaseService _supabaseService;

  final Map<int, int> _totalLessonsCache =
      <int, int>{};

  CourseIdResolver(
    this._supabaseService,
  );

  Future<int> idForSlug(
    String courseId,
  ) async {
    final id =
        int.tryParse(courseId);

    if (id == null) {
      throw FormatException(
        'Course id "$courseId" is not numeric. '
        'Supabase course_id must be an integer.',
      );
    }

    return id;
  }

  Future<String> slugForId(
    int courseId,
  ) async {
    return courseId.toString();
  }

  Future<int> totalLessonsForSlug(
    String courseId,
  ) async {
    final id =
        await idForSlug(courseId);

    final cached =
        _totalLessonsCache[id];

    if (cached != null) {
      return cached;
    }

    debugPrint(
      '[COURSE_ID_RESOLVER] '
      'Fetching total_lessons for course_id: $id',
    );

    final response =
        await _supabaseService.client
            .from('courses')
            .select('total_lessons')
            .eq('course_id', id)
            .single();

    final rawTotal =
        response['total_lessons'];

    final total =
        rawTotal is int
            ? rawTotal
            : int.tryParse(
                  rawTotal?.toString() ?? '',
                ) ??
                0;

    _totalLessonsCache[id] =
        total;

    return total;
  }

  void clearCache() {
    _totalLessonsCache.clear();
  }
}