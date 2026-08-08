import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/sync_status.dart';
import '../../notes/model/note.dart';
import '../../notes/model/note_context.dart';
import '../../notes/model/note_repository.dart';
import '../../notes/view/i_note_view.dart';

/// Coordinates between the note UI and the [NoteRepository].
///
/// Handles:
/// - Loading notes
/// - Creating drafts
/// - Editing existing notes
/// - Debounced autosave
/// - Explicit saving
/// - Deleting notes
/// - Sync status
class NotePresenter {
  final NoteRepository _noteRepository;
  final String _userId;

  INoteView? _view;

  Timer? _debounceTimer;

  Note? _draft;

  List<Note> _notes = <Note>[];

  SyncStatus _syncStatus = SyncStatus.synced;

  /// Duration to wait after the last keystroke before autosaving.
  static const Duration _autosaveDelay = Duration(seconds: 2);

  NotePresenter({
    required NoteRepository noteRepository,
    required String userId,
  })  : _noteRepository = noteRepository,
        _userId = userId;

  /// Attaches the view that receives UI updates.
  set view(INoteView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads all notes belonging to the current user.
  Future<void> loadNotes() async {
    debugPrint('[PRESENTER][NOTE] Loading notes');

    _view?.showLoading(true);

    try {
      final notes = await _noteRepository.findByUser(_userId);

      _notes = List<Note>.from(notes);

      _view?.showNotes(List<Note>.unmodifiable(_notes));

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

  /// Loads notes attached to a specific lesson.
  ///
  /// This is useful when the UI is displaying notes for one lesson rather
  /// than all notes belonging to the user.
  Future<void> loadLessonNotes(NoteContext context) async {
    debugPrint(
      '[PRESENTER][NOTE] Loading notes for lesson '
      '${context.courseId}:${context.lessonId}',
    );

    _view?.showLoading(true);

    try {
      final notes = await _noteRepository.findByLesson(
        _userId,
        context.courseId,
        context.lessonId,
      );

      _notes = List<Note>.from(notes);

      _view?.showNotes(List<Note>.unmodifiable(_notes));

      debugPrint(
        '[PRESENTER][NOTE] Lesson notes loaded: ${_notes.length}',
      );
    } catch (e) {
      debugPrint(
        '[PRESENTER][NOTE] Failed to load lesson notes: $e',
      );

      _view?.showError(
        'Could not load lesson notes. Please try again.',
      );
    } finally {
      _view?.showLoading(false);
    }
  }

  /// Creates a new unsaved note draft.
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
      tags: const <String>[],
      updatedAt: now,
    );

    _draft = draft;

    _cancelAutosave();

    _setSyncStatus(SyncStatus.synced);

    debugPrint('[PRESENTER][NOTE] Note editor requested');

    _view?.showEditor(draft);
  }

  /// Opens the editor for an existing note.
  void openEditor(Note note) {
    debugPrint(
      '[PRESENTER][NOTE] Opening note: ${note.id}',
    );

    // Extra ownership protection at the presentation layer.
    if (note.userId != _userId) {
      debugPrint(
        '[PRESENTER][NOTE] Refused to open another user note',
      );

      _view?.showError(
        'You cannot edit this note.',
      );

      return;
    }

    _draft = note;

    _cancelAutosave();

    _setSyncStatus(SyncStatus.synced);

    _view?.showEditor(note);
  }

  /// Called whenever the user modifies the note content.
  ///
  /// The actual note content is never logged.
  void updateDraft(String content) {
    final draft = _draft;

    if (draft == null) {
      return;
    }

    _draft = draft.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    debugPrint('[PRESENTER][NOTE] Note draft changed');

    _setSyncStatus(SyncStatus.pending);

    _scheduleAutosave();
  }

  /// Updates the title of the current draft.
  void updateTitle(String? title) {
    final draft = _draft;

    if (draft == null) {
      return;
    }

    _draft = draft.copyWith(
      title: title,
      updatedAt: DateTime.now(),
    );

    debugPrint('[PRESENTER][NOTE] Note title changed');

    _setSyncStatus(SyncStatus.pending);

    _scheduleAutosave();
  }

  /// Updates tags on the current draft.
  void updateTags(List<String> tags) {
    final draft = _draft;

    if (draft == null) {
      return;
    }

    _draft = draft.copyWith(
      tags: List<String>.from(tags),
      updatedAt: DateTime.now(),
    );

    debugPrint('[PRESENTER][NOTE] Note tags changed');

    _setSyncStatus(SyncStatus.pending);

    _scheduleAutosave();
  }

  /// Saves the current draft immediately.
  ///
  /// Returns true when the note was successfully saved.
  Future<bool> saveNow() async {
    if (_draft == null) {
      return false;
    }

    debugPrint('[PRESENTER][NOTE] Explicit save requested');

    _cancelAutosave();

    final success = await _autosave();

    if (success) {
      _view?.closeEditor();
    }

    return success;
  }

  /// Discards the current draft and closes the editor.
  void cancelEdit() {
    debugPrint('[PRESENTER][NOTE] Cancelling note edit');

    _cancelAutosave();

    _draft = null;

    _setSyncStatus(SyncStatus.synced);

    _view?.closeEditor();
  }

  /// Deletes a note belonging to the current user.
  Future<bool> deleteNote(String id) async {
    debugPrint('[PRESENTER][NOTE] Deleting note');

    try {
      final success = await _noteRepository.delete(id);

      if (!success) {
        debugPrint(
          '[PRESENTER][NOTE] Repository reported delete failure',
        );

        _view?.showError(
          'Could not delete note.',
        );

        return false;
      }

      _notes.removeWhere(
        (note) => note.id == id,
      );

      // If the deleted note was being edited, close the editor.
      if (_draft?.id == id) {
        _draft = null;
        _cancelAutosave();
        _view?.closeEditor();
      }

      _view?.showNotes(
        List<Note>.unmodifiable(_notes),
      );

      debugPrint('[PRESENTER][NOTE] Note deleted');

      return true;
    } catch (e) {
      debugPrint(
        '[PRESENTER][NOTE] Delete failed: $e',
      );

      _view?.showError(
        'Failed to delete note.',
      );

      return false;
    }
  }

  /// Cancels timers and releases the view reference.
  void dispose() {
    debugPrint('[PRESENTER][NOTE] Disposing');

    _cancelAutosave();

    _draft = null;
    _notes = <Note>[];
    _view = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Schedules an autosave after the user stops typing.
  void _scheduleAutosave() {
    _cancelAutosave();

    _debounceTimer = Timer(
      _autosaveDelay,
      () {
        _debounceTimer = null;
        _autosave();
      },
    );
  }

  /// Cancels any pending autosave.
  void _cancelAutosave() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Performs the actual save operation.
  Future<bool> _autosave() async {
    final draft = _draft;

    if (draft == null) {
      return false;
    }

    // Don't save empty notes.
    if (draft.content.trim().isEmpty) {
      debugPrint(
        '[PRESENTER][NOTE] Empty note was not saved',
      );

      _setSyncStatus(SyncStatus.synced);

      return false;
    }

    debugPrint('[PRESENTER][NOTE] Autosave started');

    _setSyncStatus(SyncStatus.pending);

    try {
      debugPrint('[REPOSITORY][NOTE] Saving note');

      final saved = await _noteRepository.save(draft);

      // Make sure the saved note still belongs to this presenter.
      if (saved.userId != _userId) {
        throw Exception(
          'Repository returned a note belonging to another user.',
        );
      }

      _draft = saved;

      // Replace existing note or add a new one.
      final existingIndex = _notes.indexWhere(
        (note) => note.id == saved.id,
      );

      if (existingIndex >= 0) {
        _notes[existingIndex] = saved;
      } else {
        _notes.insert(0, saved);
      }

      _setSyncStatus(SyncStatus.synced);

      _view?.showNotes(
        List<Note>.unmodifiable(_notes),
      );

      _view?.showSaved();

      debugPrint(
        '[PRESENTER][NOTE] Autosave completed',
      );

      return true;
    } catch (e) {
      debugPrint(
        '[PRESENTER][NOTE] Autosave failed: $e',
      );

      // Keep the draft intact so the user can retry.
      _setSyncStatus(SyncStatus.error);

      return false;
    }
  }

  /// Updates sync status and notifies the view.
  void _setSyncStatus(SyncStatus status) {
    _syncStatus = status;

    _view?.showSyncStatus(_syncStatus);
  }
}