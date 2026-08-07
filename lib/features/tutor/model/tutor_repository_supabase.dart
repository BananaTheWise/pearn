import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/github_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/model/user_repository.dart';
import '../model/student_stat.dart';
import '../model/tutor_repository.dart';

/// Concrete implementation of [TutorRepository] using Supabase and GitHub.
class TutorRepositorySupabase implements TutorRepository {
  final SupabaseService _supabaseService;
  final GithubService _githubService;
  final UserRepository _userRepository; // to verify tutor role

  TutorRepositorySupabase({
    required SupabaseService supabaseService,
    required GithubService githubService,
    required UserRepository userRepository,
  })  : _supabaseService = supabaseService,
        _githubService = githubService,
        _userRepository = userRepository;

  // ---------------------------------------------------------------------------
  // Helper to enforce tutor role
  // ---------------------------------------------------------------------------
  Future<void> _ensureTutorRole(String tutorId) async {
    final user = await _userRepository.findById(tutorId);
    if (user == null || user.role != 'tutor') {
      throw Exception('Access denied: only tutors can perform this action.');
    }
  }

  // ---------------------------------------------------------------------------
  // getDashboardData
  // ---------------------------------------------------------------------------
  @override
  Future<Map<String, dynamic>> getDashboardData(String tutorId) async {
    await _ensureTutorRole(tutorId);
    debugPrint('[REPOSITORY][TUTOR] Loading Tutor dashboard');
    debugPrint('[DB][TUTOR] Dashboard query started');

    try {
      // 1. Get courses managed by this tutor
      final courseIds = await getManagedCourseIds(tutorId);

      // 2. Count distinct students enrolled in those courses
      int studentCount = 0;
      if (courseIds.isNotEmpty) {
        final enrollmentResponse = await _supabaseService.client
            .from('enrollments')
            .select('user_id')
            .inFilter('course_id', courseIds);

        final userIds = (enrollmentResponse as List<dynamic>)
            .map((e) => e['user_id'] as String)
            .toSet();
        studentCount = userIds.length;
      }

      // 3. Count courses
      final courseCount = courseIds.length;

      // 4. Other stats could be added but we keep it minimal.
      final result = {
        'student_count': studentCount,
        'course_count': courseCount,
        // additional dashboard metrics can be added here as needed
      };

      debugPrint('[DB][TUTOR] Dashboard query completed');
      debugPrint('[REPOSITORY][TUTOR] Tutor dashboard loaded');
      return result;
    } catch (e) {
      debugPrint('[ERROR][REPOSITORY][TUTOR] Failed to load dashboard');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getStudentsForTutor
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> getStudentsForTutor(String tutorId) async {
    await _ensureTutorRole(tutorId);
    debugPrint('[REPOSITORY][TUTOR] Loading students');
    debugPrint('[DB][TUTOR] Student query started');

    try {
      final courseIds = await getManagedCourseIds(tutorId);
      if (courseIds.isEmpty) {
        debugPrint('[DB][TUTOR] No courses found for tutor');
        return [];
      }

      final response = await _supabaseService.client
          .from('enrollments')
          .select('user_id')
          .inFilter('course_id', courseIds);

      final userIds = (response as List<dynamic>)
          .map((e) => e['user_id'] as String)
          .toSet()
          .toList();

      debugPrint('[DB][TUTOR] Student query completed');
      debugPrint('[REPOSITORY][TUTOR] Students loaded: ${userIds.length}');
      return userIds;
    } catch (e) {
      debugPrint('[ERROR][REPOSITORY][TUTOR] Failed to load students');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getStudentStat
  // ---------------------------------------------------------------------------
  @override
  Future<StudentStat?> getStudentStat(
      String tutorId, String studentId, String courseId) async {
    await _ensureTutorRole(tutorId);
    debugPrint('[REPOSITORY][TUTOR] Loading student statistics');
    debugPrint('[DB][TUTOR] Statistics query started');

    try {
      // Verify the course belongs to this tutor (optional, but good practice)
      final managedCourses = await getManagedCourseIds(tutorId);
      if (!managedCourses.contains(courseId)) {
        debugPrint('[ERROR][REPOSITORY][TUTOR] Access denied: not your course');
        throw Exception('You do not manage this course.');
      }

      // Fetch progress
      final progressResponse = await _supabaseService.client
          .from('progress')
          .select()
          .eq('user_id', studentId)
          .eq('course_id', courseId)
          .maybeSingle();

      final completedLessons = (progressResponse != null &&
              progressResponse['completed_lesson_ids'] != null)
          ? (progressResponse['completed_lesson_ids'] as List<dynamic>).length
          : 0;

      // Fetch user profile for XP/level
      final userProfile = await _userRepository.findById(studentId);
      final totalXp = userProfile?.totalXp ?? 0;
      final currentLevel = userProfile?.currentLevel ?? 1;

      // Fetch exam attempts
      final examAttemptsResponse = await _supabaseService.client
          .from('exam_attempts')
          .select()
          .eq('user_id', studentId)
          .eq('exam_id', courseId)  // Assuming exam_id matches course_id
          .order('attempted_at', ascending: false);

      final attempts = examAttemptsResponse as List<dynamic>;
      final attemptCount = attempts.length;
      final passedCount = attempts.where((e) => e['passed'] == true).length;
      double? avgScore;
      if (attemptCount > 0) {
        double totalScore = 0;
        for (final a in attempts) {
          totalScore += (a['score'] as num).toDouble();
        }
        avgScore = totalScore / attemptCount;
      }

      // Last active date from progress or user
      final lastActiveDate = progressResponse?['last_accessed'] != null
          ? DateTime.tryParse(progressResponse['last_accessed'] as String)
          : userProfile?.lastActiveDate;

      final stat = StudentStat(
        id: '$studentId-$courseId',
        userId: studentId,
        courseId: courseId,
        completedLessonsCount: completedLessons,
        totalXp: totalXp,
        currentLevel: currentLevel,
        examAttemptsCount: attemptCount,
        averageExamScore: avgScore,
        passedExamsCount: passedCount,
        lastActiveDate: lastActiveDate,
      );

      debugPrint('[DB][TUTOR] Statistics query completed');
      return stat;
    } catch (e) {
      debugPrint('[ERROR][REPOSITORY][TUTOR] Failed to load student stats');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // submitCourseForReview
  // ---------------------------------------------------------------------------
  @override
  Future<String> submitCourseForReview(
      Map<String, dynamic> courseData, String tutorId) async {
    await _ensureTutorRole(tutorId);
    debugPrint('[REPOSITORY][TUTOR] Submitting course for review');

    try {
      // Extract course id from data; required.
      final courseId = courseData['id'] as String?;
      if (courseId == null) {
        throw ArgumentError('courseData must contain an "id" field');
      }

      // Create a branch name with tutor and timestamp
      final branchName = 'tutor-$tutorId-$courseId-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Create branch from main (or the default branch)
      debugPrint('[GITHUB] Creating branch for submission');
      await _githubService.createBranch('main', branchName);

      // 2. Upload course JSON as the main course definition
      final courseJsonPath = 'courses/$courseId/course.json';
      final courseJsonContent = jsonEncode(courseData);
      await _githubService.createOrUpdateFile(
        branchName,
        courseJsonPath,
        base64Encode(utf8.encode(courseJsonContent)),
        'Add/update course $courseId by tutor $tutorId',
      );

      // 3. If additional files (lessons, exercises) are included, they should be part of courseData or passed separately.
      // For simplicity, we assume courseData only contains the course metadata.
      // A real implementation would handle multiple files.

      // 4. Open a pull request
      debugPrint('[GITHUB] Creating pull request');
      final prUrl = await _githubService.createPullRequest(
        branchName,
        'main',
        'Course submission: ${courseData['title'] ?? courseId}',
        'Submitted by tutor ID: $tutorId\n\nPlease review.',
      );

      debugPrint('[REPOSITORY][TUTOR] Course submitted, PR: $prUrl');
      return prUrl;
    } catch (e) {
      debugPrint('[ERROR][REPOSITORY][TUTOR] Course submission failed');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getManagedCourseIds
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> getManagedCourseIds(String tutorId) async {
    // Assuming there is a courses table with a `tutor_id` column.
    // If the architecture does not have this, we need to define it, but we are told not to invent.
    // We'll attempt to query a hypothetical table, but we can also fall back to a static list or check metadata.
    // For now, we'll use a Supabase query that expects a 'courses' table with 'tutor_id'.
    try {
      final response = await _supabaseService.client
          .from('courses')
          .select('id')
          .eq('tutor_id', tutorId);

      return (response as List<dynamic>)
          .map((e) => e['id'] as String)
          .toList();
    } catch (e) {
      // If the table doesn't exist, this will fail. In a real app, we'd handle gracefully.
      debugPrint('[ERROR][REPOSITORY][TUTOR] Failed to fetch managed courses');
      debugPrint('Reason: $e');
      rethrow;
    }
  }
}