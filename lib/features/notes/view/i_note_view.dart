import '../model/note.dart';

/// Represents the current synchronization state of a note.
enum SyncStatus {
  synced,
  pending,
  error,
}

/// Abstract interface through which the [NotePresenter] communicates
/// with the note UI screens.
///
/// The view is responsible for rendering the provided data and reacting
/// to user actions. It must **not** access repositories, services, or
/// perform any persistence or autosave operations.
abstract class INoteView {
  /// Shows or hides a loading indicator.
  void showLoading(bool loading);

  /// Displays the list of notes.
  void showNotes(List<Note> notes);

  /// Opens the note editor with the given note for editing.
  /// Pass a new (unsaved) [Note] to create a new note.
  void showEditor(Note note);

  /// Indicates that the note has been saved successfully.
  void showSaved();

  /// Updates the sync status indicator for the current note.
  void showSyncStatus(SyncStatus status);

  /// Shows an error message.
  void showError(String message);

  /// Closes the note editor and returns to the note list.
  void closeEditor();
}