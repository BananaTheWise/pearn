import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/audit_log.dart';
import '../../../core/models/user.dart';
import '../../../core/services/github_service.dart';
import '../../../core/services/supabase_service.dart';
import '../model/admin_repository.dart';

class AdminRepositorySupabase implements AdminRepository {
  final SupabaseService _supabaseService;
  final GithubService _githubService;

  AdminRepositorySupabase({
    required SupabaseService supabaseService,
    required GithubService githubService,
  })  : _supabaseService = supabaseService,
        _githubService = githubService;

  // ---------------------------------------------------------------------------
  // Authorization helper
  // ---------------------------------------------------------------------------
  Future<void> _ensureAdmin() async {
    final currentUserId = _supabaseService.client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Not authenticated.');

    final profile = await _supabaseService.client
        .from('profiles')
        .select('role')
        .eq('id', currentUserId)
        .single();
    if (profile['role'] != 'admin') {
      throw Exception('Access denied: admin role required.');
    }
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------
  @override
  Future<List<User>> getUsers({String? role, String? status}) async {
    await _ensureAdmin();
    debugPrint('[REPOSITORY][ADMIN][USER] Loading users');
    debugPrint('[DB][ADMIN] User query started');

    try {
      var query = _supabaseService.client.from('profiles').select();
      if (role != null) query = query.eq('role', role);
      if (status != null) query = query.eq('status', status);

      final response = await query.order('created_at', ascending: false);
      final users = (response as List<dynamic>)
          .map((e) => User.fromMap(e))
          .toList();

      debugPrint('[DB][ADMIN] User query completed');
      debugPrint('[REPOSITORY][ADMIN][USER] Users loaded: ${users.length}');
      return users;
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Failed to load users');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  @override
  Future<User?> getUser(String userId) async {
    await _ensureAdmin();
    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      return User.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Failed to get user');
      rethrow;
    }
  }

  @override
  Future<void> updateUserStatus(String userId, String newStatus) async {
    await _ensureAdmin();
    debugPrint('[REPOSITORY][ADMIN][USER] User status update started');
    try {
      await _supabaseService.client
          .from('profiles')
          .update({'status': newStatus}).eq('id', userId);
      debugPrint('[REPOSITORY][ADMIN][USER] User status update completed');
      await saveAuditLog(AuditLog(
        id: '', // auto-generated
        actorId: _supabaseService.client.auth.currentUser!.id,
        action: 'user_status_changed',
        targetId: userId,
        metadata: {'new_status': newStatus},
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] User status update failed');
      rethrow;
    }
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    await _ensureAdmin();
    debugPrint('[REPOSITORY][ADMIN][USER] User role update started');
    try {
      await _supabaseService.client
          .from('profiles')
          .update({'role': newRole}).eq('id', userId);
      debugPrint('[REPOSITORY][ADMIN][USER] User role update completed');
      await saveAuditLog(AuditLog(
        id: '',
        actorId: _supabaseService.client.auth.currentUser!.id,
        action: 'user_role_changed',
        targetId: userId,
        metadata: {'new_role': newRole},
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] User role update failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Tutors (reuse user methods)
  // ---------------------------------------------------------------------------
  @override
  Future<List<User>> getTutors() async {
    return getUsers(role: 'tutor');
  }

  @override
  Future<User?> getTutor(String tutorId) async {
    final user = await getUser(tutorId);
    if (user != null && user.role != 'tutor') return null;
    return user;
  }

  @override
  Future<void> updateTutorStatus(String tutorId, String newStatus) async {
    // Ensure it's actually a tutor
    final user = await getUser(tutorId);
    if (user == null || user.role != 'tutor') {
      throw Exception('User is not a tutor.');
    }
    return updateUserStatus(tutorId, newStatus);
  }

  // ---------------------------------------------------------------------------
  // Course Review
  // ---------------------------------------------------------------------------
  @override
  Future<List<Map<String, dynamic>>> getPendingCourses() async {
    await _ensureAdmin();
    debugPrint('[REPOSITORY][ADMIN][COURSE] Loading pending courses');
    debugPrint('[DB][ADMIN][COURSE] Pending course query started');
    try {
      final response = await _supabaseService.client
          .from('courses')
          .select()
          .eq('status', 'pending_review')
          .order('submitted_at', ascending: false);

      final courses = (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      debugPrint('[DB][ADMIN][COURSE] Pending course query completed');
      debugPrint('[REPOSITORY][ADMIN][COURSE] Pending courses loaded: ${courses.length}');
      return courses;
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN][COURSE] Failed to load pending courses');
      rethrow;
    }
  }

  @override
  Future<void> approveCourse(String courseId) async {
    await _ensureAdmin();
    debugPrint('[REPOSITORY][ADMIN][COURSE] Approval started');
    try {
      // Fetch course record to get PR URL/number
      final courseData = await _supabaseService.client
          .from('courses')
          .select('*')
          .eq('id', courseId)
          .single();

      final prUrl = courseData['pr_url'] as String?;
      if (prUrl != null) {
        // Extract PR number from URL (e.g., https://github.com/owner/repo/pull/5)
        final prNumber = _extractPrNumber(prUrl);
        if (prNumber != null) {
          await _githubService.mergePullRequest(prNumber);
        }
      }

      // Update course status
      await _supabaseService.client
          .from('courses')
          .update({'status': 'approved'})
          .eq('id', courseId);
      debugPrint('[ADMIN][COURSE] Course status updated');

      await saveAuditLog(AuditLog(
        id: '',
        actorId: _supabaseService.client.auth.currentUser!.id,
        action: 'course_approved',
        targetId: courseId,
        metadata: {'pr_url': prUrl},
        createdAt: DateTime.now(),
      ));
      debugPrint('[AUDIT] Course approval recorded');
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Course approval failed');
      rethrow;
    }
  }

  @override
  Future<void> rejectCourse(String courseId, String? reason) async {
    await _ensureAdmin();
    debugPrint('[ADMIN][COURSE] Course rejection started');
    try {
      final courseData = await _supabaseService.client
          .from('courses')
          .select('*')
          .eq('id', courseId)
          .single();

      final prUrl = courseData['pr_url'] as String?;
      if (prUrl != null) {
        final prNumber = _extractPrNumber(prUrl);
        if (prNumber != null) {
          // Close PR without merging
          await _githubService.closePullRequest(prNumber);
          if (reason != null && reason.isNotEmpty) {
            // Add a comment? We'll skip for now; GitHubService may not have that.
            // We'll just close.
          }
        }
      }

      // Update course status to 'rejected' and optionally store reason
      await _supabaseService.client
          .from('courses')
          .update({
            'status': 'rejected',
            'rejection_reason': reason ?? '',
          })
          .eq('id', courseId);
      debugPrint('[ADMIN][COURSE] Course rejected');

      await saveAuditLog(AuditLog(
        id: '',
        actorId: _supabaseService.client.auth.currentUser!.id,
        action: 'course_rejected',
        targetId: courseId,
        metadata: {'reason': reason},
        createdAt: DateTime.now(),
      ));
      debugPrint('[AUDIT] Course rejection recorded');
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Course rejection failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------
  @override
  Future<List<Map<String, dynamic>>> getReports() async {
    await _ensureAdmin();
    try {
      // If the reports table doesn't exist, this will throw, we'll catch and return [].
      final response = await _supabaseService.client
          .from('reports')
          .select()
          .eq('resolved', false)
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[WARNING][ADMIN] Reports table may not exist; returning empty list.');
      return [];
    }
  }

  @override
  Future<void> resolveReport(String reportId) async {
    await _ensureAdmin();
    try {
      await _supabaseService.client
          .from('reports')
          .update({'resolved': true})
          .eq('id', reportId);
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Failed to resolve report');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Audit Logging
  // ---------------------------------------------------------------------------
  @override
  Future<void> saveAuditLog(AuditLog entry) async {
    try {
      await _supabaseService.client.from('audit_logs').insert(entry.toMap());
    } catch (e) {
      debugPrint('[ERROR][DB][AUDIT] Failed to save audit log');
      // Do not throw to avoid breaking the main operation
    }
  }

  @override
  Future<List<AuditLog>> getAuditLogs() async {
    await _ensureAdmin();
    try {
      final response = await _supabaseService.client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((e) => AuditLog.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Failed to load audit logs');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------
  @override
  Future<Map<String, dynamic>> getSystemAnalytics() async {
    await _ensureAdmin();
    debugPrint('[REPOSITORY][ADMIN][ANALYTICS] Loading system analytics');
    try {
      // Total users
      final totalUsersResponse = await _supabaseService.client
          .from('profiles')
          .select('*', const FetchOptions(count: FetchCount.exact))
          .limit(1);
      final totalUsers = totalUsersResponse.count ?? 0;

      // Active users (status = 'active')
      final activeUsersResponse = await _supabaseService.client
          .from('profiles')
          .select('*', const FetchOptions(count: FetchCount.exact))
          .eq('status', 'active')
          .limit(1);
      final activeUsers = activeUsersResponse.count ?? 0;

      // Total courses
      final totalCoursesResponse = await _supabaseService.client
          .from('courses')
          .select('*', const FetchOptions(count: FetchCount.exact))
          .limit(1);
      final totalCourses = totalCoursesResponse.count ?? 0;

      // Total enrollments
      final totalEnrollmentsResponse = await _supabaseService.client
          .from('enrollments')
          .select('*', const FetchOptions(count: FetchCount.exact))
          .limit(1);
      final totalEnrollments = totalEnrollmentsResponse.count ?? 0;

      return {
        'total_users': totalUsers,
        'active_users': activeUsers,
        'total_courses': totalCourses,
        'total_enrollments': totalEnrollments,
      };
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Analytics query failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------
  int? _extractPrNumber(String prUrl) {
    try {
      final uri = Uri.parse(prUrl);
      // Format: https://github.com/owner/repo/pull/123
      final segments = uri.pathSegments;
      if (segments.length >= 4 && segments[segments.length - 2] == 'pull') {
        return int.tryParse(segments.last);
      }
    } catch (_) {}
    return null;
  }
}