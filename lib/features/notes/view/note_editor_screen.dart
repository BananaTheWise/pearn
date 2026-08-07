import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../notes/model/note.dart';
import '../../notes/model/note_context.dart';
import '../../notes/presenter/note_presenter.dart';
import '../../notes/view/i_note_view.dart';

/// Full‑screen note editor for creating or editing a note.
///
/// Accepts either an existing [Note] to edit, or a [NoteContext] to create
/// a new note from scratch.  All persistence is managed by [NotePresenter].
///
/// This screen implements [INoteView] so it can be controlled by the
/// presenter without direct access to repositories or services.
class NoteEditorScreen extends StatefulWidget {
  /// If non‑null, the editor opens in “edit” mode for this note.
  final Note? note;

  /// If non‑null, the editor opens in “create” mode with this context.
  final NoteContext? noteContext;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.noteContext,
  }) : assert(note != null || noteContext != null,
            'Either note or noteContext must be provided.');

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> implements INoteView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final NotePresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  String? _errorMessage;
  SyncStatus _syncStatus = SyncStatus.synced;

  final TextEditingController _contentController = TextEditingController();
  Note? _currentNote; // updated by the presenter via showEditor

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][NOTE] Editor opened');
    _presenter = getIt<NotePresenter>();
    _presenter.view = this;

    // Determine initial mode.
    if (widget.note != null) {
      // Edit an existing note – the presenter will set the draft and call showEditor.
      _presenter.openEditor(widget.note!);
    } else if (widget.noteContext != null) {
      // Create a new note.
      _presenter.createNote(widget.noteContext!);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
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
    // Not used in editor mode.
  }

  @override
  void showEditor(Note note) {
    setState(() {
      _currentNote = note;
      _contentController.text = note.content;
      _syncStatus = SyncStatus.synced; // reset indicator
    });
  }

  @override
  void showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void showSyncStatus(SyncStatus status) {
    setState(() {
      _syncStatus = status;
    });
    debugPrint('[UI][NOTE] Save status changed: $status');
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void closeEditor() {
    // Pop back to the previous screen (notes list or lesson).
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  void _onContentChanged(String text) {
    debugPrint('[UI][NOTE] Note changed');
    _presenter.updateDraft(text);
  }

  Future<void> _onSave() async {
    await _presenter.saveNow();
  }

  void _onCancel() {
    _presenter.cancelEdit();
  }

  Future<void> _onDelete() async {
    if (_currentNote == null || _currentNote!.id.isEmpty) return;
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
    if (confirm == true && _currentNote != null) {
      await _presenter.deleteNote(_currentNote!.id);
      // After deleting, close the editor.
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isNew = _currentNote == null || _currentNote!.id.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New note' : 'Edit note'),
        actions: [
          // Sync status indicator
          Center(child: _buildSyncIndicator()),
          const SizedBox(width: 8),
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete note',
              onPressed: _onDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    // Show course/lesson context if available.
    final courseId = _currentNote?.courseId ?? '';
    final lessonId = _currentNote?.lessonId ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course: $courseId  /  Lesson: $lessonId',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write your note...',
                border: OutlineInputBorder(),
              ),
              onChanged: _onContentChanged,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
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
            onPressed: _onCancel,
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator() {
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