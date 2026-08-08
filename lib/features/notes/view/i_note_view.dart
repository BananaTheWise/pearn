import '../../../core/models/sync_status.dart';
import '../model/note.dart';

/// Interface between NotePresenter and note UI.
///
/// The view only displays state. Persistence and business logic
/// remain inside the presenter/repository.
abstract class INoteView {
  void showLoading(bool loading);

  void showNotes(List<Note> notes);

  void showEditor(Note note);

  void showSaved();

  void showSyncStatus(SyncStatus status);

  void showError(String message);

  void closeEditor();
}