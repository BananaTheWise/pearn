import 'package:flutter/foundation.dart';

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
  // Authorization
  // ---------------------------------------------------------------------------

  Future<void> _ensureAdmin() async {
    final currentUserId =
        _supabaseService.client.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('Not authenticated.');
    }

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
  Future<List<User>> getUsers({
    String? role,
    String? status,
  }) async {
    await _ensureAdmin();

    debugPrint('[REPOSITORY][ADMIN][USER] Loading users');

    try {
      var query = _supabaseService.client
          .from('profiles')
          .select();

      if (role != null) {
        query = query.eq('role', role);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      return (response as List<dynamic>)
          .map(
            (e) => User.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Failed to load users');
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

      if (response == null) {
        return null;
      }

      return User.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      debugPrint('[ERROR][DB][ADMIN] Failed to get user');
      rethrow;
    }
  }

  @override
  Future<void> updateUserStatus(
    String userId,
    String newStatus,
  ) async {
    await _ensureAdmin();

    try {
      await _supabaseService.client
          .from('profiles')
          .update({
            'status': newStatus,
          })
          .eq('id', userId);

      await saveAuditLog(
        AuditLog(
          id: '',
          actorId:
              _supabaseService.client.auth.currentUser!.id,
          action: 'user_status_changed',
          targetId: userId,
          metadata: {
            'new_status': newStatus,
          },
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] User status update failed',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserRole(
    String userId,
    String newRole,
  ) async {
    await _ensureAdmin();

    try {
      await _supabaseService.client
          .from('profiles')
          .update({
            'role': newRole,
          })
          .eq('id', userId);

      await saveAuditLog(
        AuditLog(
          id: '',
          actorId:
              _supabaseService.client.auth.currentUser!.id,
          action: 'user_role_changed',
          targetId: userId,
          metadata: {
            'new_role': newRole,
          },
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] User role update failed',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Tutors
  // ---------------------------------------------------------------------------

  @override
  Future<List<User>> getTutors() async {
    return getUsers(role: 'tutor');
  }

  @override
  Future<User?> getTutor(String tutorId) async {
    final user = await getUser(tutorId);

    if (user == null || user.role != 'tutor') {
      return null;
    }

    return user;
  }

  @override
  Future<void> updateTutorStatus(
    String tutorId,
    String newStatus,
  ) async {
    final user = await getUser(tutorId);

    if (user == null || user.role != 'tutor') {
      throw Exception('User is not a tutor.');
    }

    await updateUserStatus(tutorId, newStatus);
  }

  // ---------------------------------------------------------------------------
  // Course Review
  // ---------------------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getPendingCourses() async {
    await _ensureAdmin();

    try {
      final response = await _supabaseService.client
          .from('courses')
          .select()
          .eq('status', 'pending_review')
          .order(
            'submitted_at',
            ascending: false,
          );

      return (response as List<dynamic>)
          .map(
            (e) => Map<String, dynamic>.from(
              e as Map,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN][COURSE] '
        'Failed to load pending courses',
      );
      rethrow;
    }
  }

  @override
  Future<void> approveCourse(String courseId) async {
    await _ensureAdmin();

    try {
      final courseData = await _supabaseService.client
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();

      final prUrl = courseData['pr_url'] as String?;

      if (prUrl != null) {
        final prNumber = _extractPrNumber(prUrl);

        if (prNumber != null) {
          await _githubService.mergePullRequest(prNumber);
        }
      }

      await _supabaseService.client
          .from('courses')
          .update({
            'status': 'approved',
          })
          .eq('id', courseId);

      await saveAuditLog(
        AuditLog(
          id: '',
          actorId:
              _supabaseService.client.auth.currentUser!.id,
          action: 'course_approved',
          targetId: courseId,
          metadata: {
            'pr_url': prUrl,
          },
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] Course approval failed',
      );
      rethrow;
    }
  }

  @override
  Future<void> rejectCourse(
    String courseId,
    String? reason,
  ) async {
    await _ensureAdmin();

    try {
      final courseData = await _supabaseService.client
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();

      final prUrl = courseData['pr_url'] as String?;

      if (prUrl != null) {
        final prNumber = _extractPrNumber(prUrl);

        if (prNumber != null) {
          await _githubService.closePullRequest(prNumber);
        }
      }

      await _supabaseService.client
          .from('courses')
          .update({
            'status': 'rejected',
            'rejection_reason': reason ?? '',
          })
          .eq('id', courseId);

      await saveAuditLog(
        AuditLog(
          id: '',
          actorId:
              _supabaseService.client.auth.currentUser!.id,
          action: 'course_rejected',
          targetId: courseId,
          metadata: {
            'reason': reason,
          },
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] Course rejection failed',
      );
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
      final response = await _supabaseService.client
          .from('reports')
          .select()
          .eq('resolved', false)
          .order(
            'created_at',
            ascending: false,
          );

      return (response as List<dynamic>)
          .map(
            (e) => Map<String, dynamic>.from(
              e as Map,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] Failed to load reports',
      );
      rethrow;
    }
  }

  @override
  Future<void> resolveReport(String reportId) async {
    await _ensureAdmin();

    try {
      await _supabaseService.client
          .from('reports')
          .update({
            'resolved': true,
          })
          .eq('id', reportId);
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] Failed to resolve report',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Audit Logging
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAuditLog(AuditLog entry) async {
    try {
      await _supabaseService.client
          .from('audit_logs')
          .insert(entry.toMap());
    } catch (e) {
      debugPrint(
        '[ERROR][DB][AUDIT] Failed to save audit log',
      );

      // Deliberately don't rethrow.
    }
  }

  @override
  Future<List<AuditLog>> getAuditLogs() async {
    await _ensureAdmin();

    try {
      final response = await _supabaseService.client
          .from('audit_logs')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      return (response as List<dynamic>)
          .map(
            (e) => AuditLog.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] Failed to load audit logs',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getSystemAnalytics() async {
    await _ensureAdmin();

    debugPrint(
      '[REPOSITORY][ADMIN][ANALYTICS] '
      'Loading system analytics',
    );

    try {
      final profiles = await _supabaseService.client
          .from('profiles')
          .select('id');

      final activeProfiles = await _supabaseService.client
          .from('profiles')
          .select('id')
          .eq('status', 'active');

      final courses = await _supabaseService.client
          .from('courses')
          .select('id');

      final enrollments = await _supabaseService.client
          .from('enrollments')
          .select('user_id, course_id');

      return {
        'total_users': (profiles as List).length,
        'active_users': (activeProfiles as List).length,
        'total_courses': (courses as List).length,
        'total_enrollments': (enrollments as List).length,
      };
    } catch (e) {
      debugPrint(
        '[ERROR][DB][ADMIN] Analytics query failed',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int? _extractPrNumber(String prUrl) {
    try {
      final uri = Uri.parse(prUrl);
      final segments = uri.pathSegments;

      if (segments.length >= 4 &&
          segments[segments.length - 2] == 'pull') {
        return int.tryParse(segments.last);
      }
    } catch (e) {
      debugPrint(
        '[ERROR][GITHUB] Invalid PR URL',
      );
    }

    return null;
  }
}