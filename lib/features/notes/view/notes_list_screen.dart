import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../notes/model/note.dart';
import '../../notes/model/note_context.dart';
import '../../notes/presenter/note_presenter.dart';
import '../../notes/view/i_note_view.dart';

/// Screen that displays the user's saved notes and allows creating / editing
/// notes via an in-place editor.
///
/// Can optionally receive [courseId] and [lessonId] to filter notes and
/// provide context when adding a new note. If not provided, the "Add note"
/// button is disabled.
class NotesListScreen extends StatefulWidget {
  final String? courseId;
  final String? lessonId;

  const NotesListScreen({super.key, this.courseId, this.lessonId});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> implements INoteView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final NotePresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  List<Note> _notes = [];
  String? _errorMessage;

  // Editor state
  bool _isEditing = false;
  Note? _editingNote;
  SyncStatus _syncStatus = SyncStatus.synced;
  final TextEditingController _noteContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][NOTE] Notes screen opened');
    _presenter = getIt<NotePresenter>();
    _presenter.view = this;
    _presenter.loadNotes();
  }

  @override
  void dispose() {
    _noteContentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // INoteView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showNotes(List<Note> notes) {
    setState(() {
      _notes = notes;
      _isEditing = false;
      _editingNote = null;
    });
  }

  @override
  void showEditor(Note note) {
    setState(() {
      _isEditing = true;
      _editingNote = note;
      _noteContentController.text = note.content;
      _syncStatus = SyncStatus.synced;
    });
  }

  @override
  void showSaved() {
    // The success feedback can be a small snackbar or inline indicator.
    if (!_isEditing) return; // shouldn't happen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void showSyncStatus(SyncStatus status) {
    setState(() {
      _syncStatus = status;
    });
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    if (_isEditing) {
      // Show error in the editor context as well.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void closeEditor() {
    setState(() {
      _isEditing = false;
      _editingNote = null;
      _noteContentController.clear();
    });
    // Refresh the list after editor closes (notes might have been added/updated)
    _presenter.loadNotes();
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  void _onAddNote() {
    if (widget.courseId == null || widget.lessonId == null) return;
    final context = NoteContext(
      courseId: widget.courseId!,
      lessonId: widget.lessonId!,
    );
    debugPrint('[UI][NOTE] Create note requested');
    _presenter.createNote(context);
  }

  void _onNoteTap(Note note) {
    debugPrint('[UI][NOTE] Note selected');
    _presenter.openEditor(note);
  }

  void _onDeleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _presenter.deleteNote(note.id);
    }
  }

  // Editor actions
  void _onEditorContentChanged(String text) {
    _presenter.updateDraft(text);
  }

  void _onSaveEditor() {
    _presenter.saveNow();
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
        title: const Text('Notes'),
        actions: [
          if (widget.courseId != null && widget.lessonId != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add note',
              onPressed: _isEditing ? null : _onAddNote,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing && _editingNote != null
              ? _buildEditor()
              : _errorMessage != null
                  ? _buildErrorView()
                  : _notes.isEmpty
                      ? _buildEmptyState()
                      : _buildNoteList(),
    );
  }

  Widget _buildNoteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(note.title ?? 'Untitled',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.content.isNotEmpty)
                  Text(note.content,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  'Course: ${note.courseId} • Lesson: ${note.lessonId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            onTap: () => _onNoteTap(note),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _onDeleteNote(note),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No notes yet. Open a lesson and create your first note.'),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _presenter.loadNotes(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final note = _editingNote!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.id.isEmpty ? 'New note' : 'Edit note',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _buildSyncStatusIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          Text('Course: ${note.courseId} / Lesson: ${note.lessonId}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _noteContentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write your note...',
                border: OutlineInputBorder(),
              ),
              onChanged: _onEditorContentChanged,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _onCancelEditor,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onSaveEditor,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    switch (_syncStatus) {
      case SyncStatus.synced:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncStatus.pending:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red);
    }
  }
}

// Minimal NoteContext (should be defined in its own file).
// This is included here for compilation completeness.
class NoteContext {
  final String courseId;
  final String lessonId;

  const NoteContext({required this.courseId, required this.lessonId});
}