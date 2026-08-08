import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/sync_status.dart';
import '../../notes/model/note.dart';
import '../../notes/model/note_context.dart';
import '../../notes/presenter/note_presenter.dart';
import '../../notes/view/i_note_view.dart';

/// Displays notes.
///
/// When [courseId] and [lessonId] are supplied:
///   - Shows notes belonging to that lesson.
///   - Allows creating notes for that lesson.
///
/// When no course/lesson is supplied:
///   - Shows ALL notes belonging to the current user.
///   - Each note displays its course and lesson.
///
/// This makes the same screen usable from:
///   1. The notes item in the sidebar.
///   2. A specific lesson.
class NotesListScreen extends StatefulWidget {
  final String? courseId;
  final String? lessonId;

  const NotesListScreen({
    super.key,
    this.courseId,
    this.lessonId, String? courseName,
  });

  bool get isLessonNotes =>
      courseId != null && lessonId != null;

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen>
    implements INoteView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  late final NotePresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------

  bool _isLoading = false;

  List<Note> _notes = <Note>[];

  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Editor state
  // ---------------------------------------------------------------------------

  bool _isEditing = false;

  Note? _editingNote;

  SyncStatus _syncStatus = SyncStatus.synced;

  final TextEditingController _noteContentController =
      TextEditingController();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    debugPrint('[UI][NOTE] Notes screen opened');

    _presenter = getIt<NotePresenter>();

    _presenter.view = this;

    _loadInitialNotes();
  }

  Future<void> _loadInitialNotes() async {
    if (!mounted) return;

    final courseId = widget.courseId;
    final lessonId = widget.lessonId;

    if (courseId != null && lessonId != null) {
      debugPrint(
        '[UI][NOTE] Loading notes for '
        'course=$courseId lesson=$lessonId',
      );

      await _presenter.loadLessonNotes(
        NoteContext(
          courseId: courseId,
          lessonId: lessonId,
        ),
      );
    } else {
      debugPrint('[UI][NOTE] Loading all user notes');

      await _presenter.loadNotes();
    }
  }

  @override
  void dispose() {
    _noteContentController.dispose();

    // Important:
    // Do not leave this screen registered as the presenter view.
    _presenter.view = null;

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // INoteView
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    if (!mounted) return;

    setState(() {
      _isLoading = loading;

      if (loading) {
        _errorMessage = null;
      }
    });
  }

  @override
  void showNotes(List<Note> notes) {
    if (!mounted) return;

    setState(() {
      _notes = List<Note>.from(notes);
      _errorMessage = null;
    });
  }

  @override
  void showEditor(Note note) {
    if (!mounted) return;

    setState(() {
      _isEditing = true;
      _editingNote = note;

      _noteContentController.text = note.content;

      _noteContentController.selection =
          TextSelection.collapsed(
        offset: _noteContentController.text.length,
      );

      _syncStatus = SyncStatus.synced;
      _errorMessage = null;
    });
  }

  @override
  void showSaved() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void showSyncStatus(SyncStatus status) {
    if (!mounted) return;

    setState(() {
      _syncStatus = status;
    });

    debugPrint(
      '[UI][NOTE] Save status changed: $status',
    );
  }

  @override
  void showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void closeEditor() {
    if (!mounted) return;

    setState(() {
      _isEditing = false;
      _editingNote = null;
      _noteContentController.clear();
      _syncStatus = SyncStatus.synced;
    });

    _loadInitialNotes();
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  void _onAddNote() {
    final courseId = widget.courseId;
    final lessonId = widget.lessonId;

    if (courseId == null || lessonId == null) {
      debugPrint(
        '[UI][NOTE] Cannot create note without lesson context',
      );

      return;
    }

    debugPrint(
      '[UI][NOTE] Creating note for '
      'course=$courseId lesson=$lessonId',
    );

    _presenter.createNote(
      NoteContext(
        courseId: courseId,
        lessonId: lessonId,
      ),
    );
  }

  void _onNoteTap(Note note) {
    debugPrint(
      '[UI][NOTE] Note selected: ${note.id}',
    );

    _presenter.openEditor(note);
  }

  Future<void> _onDeleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete note'),
          content: const Text(
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _presenter.deleteNote(note.id);
  }

  void _onEditorContentChanged(String text) {
    _presenter.updateDraft(text);
  }

  Future<void> _onSaveEditor() async {
    await _presenter.saveNow();
  }

  void _onCancelEditor() {
    _presenter.cancelEdit();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Note'
              : widget.isLessonNotes
                  ? 'Lesson Notes'
                  : 'My Notes',
        ),
        actions: [
          if (!_isEditing &&
              widget.courseId != null &&
              widget.lessonId != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add note',
              onPressed: _onAddNote,
            ),

          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _buildSyncStatusIndicator(),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null && !_isEditing
              ? _buildErrorView()
              : _isEditing
                  ? _buildEditor()
                  : _buildNotesBody(),
    );
  }

  Widget _buildNotesBody() {
    if (_notes.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNoteList();
  }

  // ---------------------------------------------------------------------------
  // Notes list
  // ---------------------------------------------------------------------------

  Widget _buildNoteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final Note note = _notes[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),

            leading: CircleAvatar(
              child: const Icon(Icons.note_alt_outlined),
            ),

            title: Text(
              note.title?.trim().isNotEmpty == true
                  ? note.title!
                  : 'Untitled note',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (note.content.trim().isNotEmpty)
                    Text(
                      note.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Course information.
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Course: ${note.courseId}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Lesson information.
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Lesson: ${note.lessonId}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Updated: ${_formatDate(note.updatedAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ),

            onTap: () => _onNoteTap(note),

            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip: 'Delete note',
              onPressed: () => _onDeleteNote(note),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final bool isLesson = widget.isLessonNotes;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.note_alt_outlined,
              size: 64,
            ),

            const SizedBox(height: 16),

            Text(
              isLesson
                  ? 'No notes for this lesson'
                  : 'No notes yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isLesson
                  ? 'Create a note for this lesson.'
                  : 'Open a lesson and create your first note.',
              textAlign: TextAlign.center,
            ),

            if (isLesson) ...[
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _onAddNote,
                icon: const Icon(Icons.add),
                label: const Text('Create note'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),

            const SizedBox(height: 16),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadInitialNotes,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Editor
  // ---------------------------------------------------------------------------

  Widget _buildEditor() {
    final Note? note = _editingNote;

    if (note == null) {
      return const SizedBox.shrink();
    }

    final bool isNew = note.id.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isNew ? 'New note' : 'Edit note',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
              ),
              _buildSyncStatusIndicator(),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Course: ${note.courseId}',
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),

          const SizedBox(height: 4),

          Text(
            'Lesson: ${note.lessonId}',
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),

          const SizedBox(height: 16),

          Expanded(
            child: TextField(
              controller:
                  _noteContentController,
              maxLines: null,
              expands: true,
              textAlignVertical:
                  TextAlignVertical.top,
              decoration:
                  const InputDecoration(
                hintText:
                    'Write your note...',
                border:
                    OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged:
                  _onEditorContentChanged,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _onCancelEditor,
                child:
                    const Text('Cancel'),
              ),

              const SizedBox(width: 8),

              ElevatedButton.icon(
                onPressed:
                    _onSaveEditor,
                icon:
                    const Icon(Icons.save),
                label:
                    const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sync indicator
  // ---------------------------------------------------------------------------

  Widget _buildSyncStatusIndicator() {
    switch (_syncStatus) {
      case SyncStatus.synced:
        return const Icon(
          Icons.cloud_done,
          color: Colors.green,
        );

      case SyncStatus.pending:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );

      case SyncStatus.error:
        return const Icon(
          Icons.cloud_off,
          color: Colors.red,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    final year =
        local.year.toString().padLeft(4, '0');
    final month =
        local.month.toString().padLeft(2, '0');
    final day =
        local.day.toString().padLeft(2, '0');
    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}

