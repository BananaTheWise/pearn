import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../../../core/services/supabase_service.dart';
import 'user_repository.dart';

/// Concrete Supabase implementation of [UserRepository].
///
/// Uses [SupabaseService] to interact with the `profiles` table.
class UserRepositorySupabase implements UserRepository {
  final SupabaseService _supabaseService;

  UserRepositorySupabase(this._supabaseService);

  // ---------------------------------------------------------------------------
  // findById
  // ---------------------------------------------------------------------------
  @override
  Future<User?> findById(String id) async {
    debugPrint('[REPOSITORY][USER] findById: $id');
    debugPrint('[DB] Selecting profile');

    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      debugPrint('[DB] Profile query completed');
      debugPrint('[REPOSITORY][USER] findById completed');

      return User.fromMap(response);
    } on PostgrestException catch (e) {
      // When .single() finds no row, PostgrestException with code PGRST116 is thrown.
      if (e.code == 'PGRST116') {
        debugPrint('[DB] No profile found for id: $id');
        return null;
      }
      debugPrint('[ERROR][DB][USER] Failed to find profile by ID');
      debugPrint('Reason: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ERROR][DB][USER] Failed to find profile by ID');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // findByEmail
  // ---------------------------------------------------------------------------
  @override
  Future<User?> findByEmail(String email) async {
    debugPrint('[REPOSITORY][USER] findByEmail started');
    debugPrint('[DB] Searching profile by email');

    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      debugPrint('[DB] Profile lookup completed');

      if (response == null) {
        return null;
      }

      return User.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][DB][USER] Failed to find profile by email');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // save
  // ---------------------------------------------------------------------------
  @override
  Future<User> save(User user) async {
    debugPrint('[REPOSITORY][USER] Saving profile');
    debugPrint('[DB] Upserting profile');

    try {
      final data = user.toMap();

      // Safety guard: a normal signup should not be able to create an admin.
      // If the role is 'admin', it must be set by an authorised process.
      // Here we rely on RLS and caller validation. If needed, uncomment below.
      // if (data['role'] == User.roleAdmin) {
      //   throw UnauthorizedException('Cannot create an admin account.');
      // }

      final response = await _supabaseService.client
          .from('profiles')
          .upsert(data)
          .select()
          .single();

      debugPrint('[DB] Profile saved successfully');

      return User.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][DB][USER] Failed to save profile');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // delete
  // ---------------------------------------------------------------------------
  @override
  Future<bool> delete(String id) async {
    debugPrint('[REPOSITORY][USER] Deleting profile');
    debugPrint('[DB] Deleting profile');

    try {
      await _supabaseService.client
          .from('profiles')
          .delete()
          .eq('id', id);

      debugPrint('[DB] Profile deleted');
      return true;
    } catch (e) {
      debugPrint('[ERROR][DB][USER] Failed to delete profile');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // search
  // ---------------------------------------------------------------------------
  @override
  Future<List<User>> search(String query) async {
    debugPrint('[REPOSITORY][USER] Searching users');

    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,email.ilike.%$query%');

      final users =
          (response as List<dynamic>).map((e) => User.fromMap(e)).toList();

      debugPrint('[DB] User search completed');
      debugPrint('[REPOSITORY][USER] Users found: ${users.length}');

      return users;
    } catch (e) {
      debugPrint('[ERROR][DB][USER] Failed to search users');
      debugPrint('Reason: $e');
      rethrow;
    }
  }
}