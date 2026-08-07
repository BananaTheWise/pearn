import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../learning/model/course.dart';

/// Manages local caching of static course content retrieved from GitHub.
///
/// This service uses Hive to persist courses locally so that subsequent
/// app launches can display content immediately.  GitHub remains the source
/// of truth – the cache is only a performance optimisation.
class CourseCacheService {
  static const String _boxName = 'course_cache';

  Box<Map<dynamic, dynamic>>? _box;

  /// Initialises the Hive box used for course caching.
  ///
  /// Must be called once after Hive itself has been initialised
  /// (e.g. in [setupDependencies]).
  Future<void> initialize() async {
    debugPrint('[CACHE] Initializing course cache');

    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    } else {
      _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    }

    debugPrint('[CACHE] Hive initialized');
    debugPrint('[CACHE] Course cache ready');
  }

  /// Returns a cached [Course] identified by its [id], or `null` if no
  /// valid entry exists.
  ///
  /// If the cached data is corrupt, it is silently removed and `null` is
  /// returned.  This ensures the application never crashes because of a
  /// single broken cache entry.
  Future<Course?> getCourse(String id) async {
    debugPrint('[CACHE] Reading course: $id');

    final data = _box?.get(id);
    if (data == null) {
      debugPrint('[CACHE] MISS');
      return null;
    }

    try {
      final course = Course.fromMap(Map<String, dynamic>.from(data));
      debugPrint('[CACHE] HIT');
      return course;
    } catch (e) {
      debugPrint('[CACHE] Corruption detected for course $id');
      await _box?.delete(id);
      return null;
    }
  }

  /// Persists a [Course] in the local cache.
  Future<void> saveCourse(Course course) async {
    debugPrint('[CACHE] Saving course: ${course.id}');
    await _box?.put(course.id, course.toMap());
    debugPrint('[CACHE] Course saved');
  }

  /// Removes the cached entry for the given [id].
  Future<void> removeCourse(String id) async {
    await _box?.delete(id);
  }

  /// Deletes all cached course data.
  Future<void> clear() async {
    await _box?.clear();
  }
}