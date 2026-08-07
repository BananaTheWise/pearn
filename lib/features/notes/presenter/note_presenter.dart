import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/models/sync_status.dart';
import '../../notes/model/note.dart';
import '../../notes/model/note_context.dart';
import '../../notes/model/note_repository.dart';
import '../../notes/view/i_note_view.dart';

/// Coordinates between the note UI and the [NoteRepository].
///
/// Manages draft notes, debounced autosave, and lifecycle.
class NotePresenter {
  final NoteRepository _noteRepository;
  final String _userId;

  INoteView? _view;

  Timer? _debounceTimer;

  Note? _draft;

  List<Note> _notes = [];

  SyncStatus _syncStatus = SyncStatus.synced;

  /// Duration to wait after the last keystroke before autosaving.
  static const Duration _autosaveDelay = Duration(seconds: 2);

  NotePresenter({
    required this._noteRepository,
    required this._userId,
  });

  /// Attaches the view that will receive UI updates.
  set view(INoteView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads all notes belonging to the current user and displays them.
  Future<void> loadNotes() async {
    debugPrint('[PRESENTER][NOTE] Loading notes');

    _view?.showLoading(true);

    try {
      _notes = await _noteRepository.findByUser(_userId);

      _view?.showNotes(_notes);

      debugPrint(
        '[PRESENTER][NOTE] Notes loaded: ${_notes.length}',
      );
    } catch (e) {
      debugPrint(
        '[PRESENTER][NOTE] Failed to load notes: $e',
      );

      _view?.showError(
        'Could not load notes. Please try again.',
      );
    } finally {
      _view?.showLoading(false);
    }
  }

  /// Creates a new draft note with the given context.
  void createNote(NoteContext context) {
    debugPrint('[PRESENTER][NOTE] Creating note draft');

    final now = DateTime.now();

    final draft = Note(
      id: '',
      userId: _userId,
      courseId: context.courseId,
      lessonId: context.lessonId,
      title: null,
      content: '',
      createdAt: now,
      updatedAt: now,
    );

    _draft = draft;

    _cancelAutosave();

    _syncStatus = SyncStatus.synced;

    _view?.showSyncStatus(_syncStatus);

    debugPrint('[PRESENTER][NOTE] Note editor requested');

    _view?.showEditor(draft);
  }

  /// Opens the editor for an existing note.
  void openEditor(Note note) {
    _draft = note;

    _cancelAutosave();

    _syncStatus = SyncStatus.synced;

    _view?.showSyncStatus(_syncStatus);

    _view?.showEditor(note);
  }

  /// Called when the user modifies the content of the draft.
  ///
  /// Never logs the actual content.
  /// Triggers a debounced autosave.
  void updateDraft(String content) {
    if (_draft == null) {
      return;
    }

    _draft = _draft!.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    debugPrint('[PRESENTER][NOTE] Note draft changed');

    _scheduleAutosave();
  }

  /// Saves the current draft immediately.
  Future<void> saveNow() async {
    if (_draft == null) {
      return;
    }

    debugPrint('[PRESENTER][NOTE] Explicit save requested');

    _cancelAutosave();

    await _autosave();

    if (_syncStatus == SyncStatus.synced) {
      _view?.closeEditor();
    }
  }

  /// Discards the current draft and closes the editor.
  void cancelEdit() {
    _cancelAutosave();

    _draft = null;

    _view?.closeEditor();
  }

  /// Deletes the note with the given [id].
  Future<void> deleteNote(String id) async {
    debugPrint('[PRESENTER][NOTE] Deleting note');

    try {
      final success = await _noteRepository.delete(id);

      if (success) {
        _notes.removeWhere((note) => note.id == id);

        _view?.showNotes(_notes);
      } else {
        _view?.showError(
          'Could not delete note.',
        );
      }
    } catch (e) {
      debugPrint(
        '[PRESENTER][NOTE] Delete failed: $e',
      );

      _view?.showError(
        'Failed to delete note.',
      );
    }
  }

  /// Cancels the autosave timer and disposes resources.
  void dispose() {
    _cancelAutosave();

    _view = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Schedules a debounced autosave after the last keystroke.
  void _scheduleAutosave() {
    _cancelAutosave();

    _debounceTimer = Timer(
      _autosaveDelay,
      _autosave,
    );
  }

  /// Cancels any pending autosave timer.
  void _cancelAutosave() {
    _debounceTimer?.cancel();

    _debounceTimer = null;
  }

  /// Performs the actual save operation.
  Future<void> _autosave() async {
    if (_draft == null) {
      return;
    }

    debugPrint('[PRESENTER][NOTE] Autosave started');

    _setSyncStatus(SyncStatus.pending);

    try {
      debugPrint('[REPOSITORY][NOTE] Saving note');

      final saved = await _noteRepository.save(_draft!);

      _draft = saved;

      // Replace existing note or add new note.
      final existingIndex = _notes.indexWhere(
        (note) => note.id == saved.id,
      );

      if (existingIndex >= 0) {
        _notes[existingIndex] = saved;
      } else {
        _notes.add(saved);
      }

      _setSyncStatus(SyncStatus.synced);

      _view?.showNotes(_notes);

      _view?.showSaved();

      debugPrint(
        '[PRESENTER][NOTE] Autosave completed',
      );
    } catch (e) {
      debugPrint(
        '[PRESENTER][NOTE] Autosave failed: $e',
      );

      _setSyncStatus(SyncStatus.error);

      // Keep the draft so the user can retry.
    }
  }

  /// Updates sync status and notifies the view.
  void _setSyncStatus(SyncStatus status) {
    _syncStatus = status;

    _view?.showSyncStatus(status);
  }
}