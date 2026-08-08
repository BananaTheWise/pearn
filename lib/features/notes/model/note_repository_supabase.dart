import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'note.dart';
import 'note_repository.dart';

/// Concrete implementation of [NoteRepository] using Supabase.
///
/// Interacts with the `notes` table.  The repository is bound to a specific
/// user to enforce ownership checks for deletes.
class NoteRepositorySupabase implements NoteRepository {
  final SupabaseService _supabaseService;
  final String _userId; // owner of notes manipulated by this instance

  NoteRepositorySupabase({
    required SupabaseService supabaseService,
    required String userId,
  })  : _supabaseService = supabaseService,
        _userId = userId;

  // ---------------------------------------------------------------------------
  // save
  // ---------------------------------------------------------------------------
  @override
  Future<Note> save(Note note) async {
    debugPrint('[REPOSITORY][NOTE] Saving note');
    debugPrint('[DB][NOTE] Upsert started');

    try {
      // Ensure the note belongs to this repository's user.
      final data = note.toMap();
      if (data['user_id'] != _userId) {
        throw Exception('Cannot save a note that belongs to another user.');
      }

      // Note.toMap() already omits 'id' for a new (unsaved) note, so this
      // inserts and lets Postgres generate the UUID; when 'id' is present
      // it updates the matching row instead.
      final response = await _supabaseService.client
          .from('notes')
          .upsert(data)
          .select()
          .single();

      debugPrint('[DB][NOTE] Upsert completed');
      debugPrint('[REPOSITORY][NOTE] Note saved');
      return Note.fromMap(response);
    } catch (e) {
      debugPrint('[ERROR][DB][NOTE] Failed to save note');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // findByUser
  // ---------------------------------------------------------------------------
  @override
  Future<List<Note>> findByUser(String userId) async {
    debugPrint('[REPOSITORY][NOTE] Loading user notes');
    debugPrint('[DB][NOTE] Query started');

    try {
      final response = await _supabaseService.client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final notes = (response as List<dynamic>)
          .map((e) => Note.fromMap(e as Map<String, dynamic>))
          .toList();

      debugPrint('[DB][NOTE] Notes loaded: ${notes.length}');
      return notes;
    } catch (e) {
      debugPrint('[ERROR][DB][NOTE] Failed to load notes');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // findByLesson
  // ---------------------------------------------------------------------------
  @override
  Future<List<Note>> findByLesson(
      String userId, String courseId, String lessonId) async {
    debugPrint('[REPOSITORY][NOTE] Loading lesson notes');
    debugPrint('[DB][NOTE] Lesson note query started');

    try {
      // There are no course_id/lesson_id columns — lesson-scoped notes
      // are stored as attached_to_type='lesson' with attached_to_id
      // encoding '<courseId>:<lessonId>' (see Note.toMap).
      final attachedToId = '$courseId:$lessonId';

      final response = await _supabaseService.client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .eq('attached_to_type', 'lesson')
          .eq('attached_to_id', attachedToId)
          .order('updated_at', ascending: false);

      final notes = (response as List<dynamic>)
          .map((e) => Note.fromMap(e as Map<String, dynamic>))
          .toList();

      debugPrint('[DB][NOTE] Lesson notes loaded: ${notes.length}');
      return notes;
    } catch (e) {
      debugPrint('[ERROR][DB][NOTE] Failed to load lesson notes');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // delete
  // ---------------------------------------------------------------------------
  @override
  Future<bool> delete(String id) async {
    debugPrint('[REPOSITORY][NOTE] Deleting note');

    try {
      // Delete only if the note belongs to the current user.
      await _supabaseService.client
          .from('notes')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);

      // A successful delete returns status 200 with an empty body or 204.
      // If no rows were deleted, the response will be empty but still success.
      debugPrint('[DB][NOTE] Delete completed');
      return true;
    } catch (e) {
      debugPrint('[ERROR][DB][NOTE] Failed to delete note');
      debugPrint('Reason: $e');
      return false;
    }
  }
}