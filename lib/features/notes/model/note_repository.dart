import 'note.dart';

/// Abstract contract for user notes persistence.
///
/// The concrete implementation ([NoteRepositorySupabase]) interacts with
/// the `notes` database table.
abstract class NoteRepository {
  /// Creates a new note or updates an existing one.
  ///
  /// Returns the saved note with any server-generated fields,
  /// such as the generated UUID.
  Future<Note> save(Note note);

  /// Returns all notes belonging to the specified [userId].
  Future<List<Note>> findByUser(String userId);

  /// Returns notes for a specific lesson within a course,
  /// filtered by the specified [userId].
  Future<List<Note>> findByLesson(
    String userId,
    String courseId,
    String lessonId,
  );

  /// Deletes a note by its [id].
  ///
  /// Returns `true` when the deletion was successful.
  Future<bool> delete(String id);
}

