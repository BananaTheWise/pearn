import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/sync_status.dart';
import '../../../core/services/supabase_service.dart';
import '../../notes/model/note.dart';
import '../../notes/model/note_context.dart';
import '../../notes/model/note_repository.dart';
import '../../notes/presenter/note_presenter.dart';
import '../../notes/view/i_note_view.dart';

/// Full-screen note editor.
///
/// Supports:
/// - Editing an existing note
/// - Creating a course note
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final NoteContext? noteContext;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.noteContext,
  }) : assert(
          note != null || noteContext != null,
          'Either note or noteContext must be provided.',
        );

  @override
  State<NoteEditorScreen> createState() =>
      _NoteEditorScreenState();
}

class _NoteEditorScreenState
    extends State<NoteEditorScreen>
    implements INoteView {
  late final NotePresenter _presenter;

  bool _isLoading = false;

  String? _errorMessage;

  SyncStatus _syncStatus =
      SyncStatus.synced;

  Note? _currentNote;

  final TextEditingController
      _contentController =
      TextEditingController();

  final TextEditingController
      _titleController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    debugPrint(
      '[UI][NOTE] Editor opened',
    );

    final repository =
        getIt<NoteRepository>();

    final userId =
        SupabaseService
                .instance
                .client
                .auth
                .currentUser
                ?.id ??
            '';

    _presenter = NotePresenter(
      noteRepository: repository,
      userId: userId,
    );

    _presenter.view = this;

    if (widget.note != null) {
      _presenter.openEditor(
        widget.note!,
      );
    } else if (widget.noteContext != null) {
      _presenter.createNote(
        widget.noteContext!,
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();

    _presenter.view = null;
    _presenter.dispose();

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
    // Not needed by the editor.
  }

  @override
  void showEditor(Note note) {
    if (!mounted) return;

    setState(() {
      _currentNote = note;

      _titleController.text =
          note.title ?? '';

      _contentController.text =
          note.content;

      _contentController.selection =
          TextSelection.collapsed(
        offset:
            _contentController.text.length,
      );

      _syncStatus =
          SyncStatus.synced;
    });
  }

  @override
  void showSaved() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text('Note saved'),
        duration:
            Duration(seconds: 1),
      ),
    );
  }

  @override
  void showSyncStatus(
    SyncStatus status,
  ) {
    if (!mounted) return;

    setState(() {
      _syncStatus = status;
    });
  }

  @override
  void showError(
    String message,
  ) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void closeEditor() {
    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onTitleChanged(String value) {
    _presenter.updateTitle(
      value.trim().isEmpty
          ? null
          : value,
    );
  }

  void _onContentChanged(
    String value,
  ) {
    _presenter.updateDraft(value);
  }

  Future<void> _onSave() async {
    await _presenter.saveNow();
  }

  void _onCancel() {
    _presenter.cancelEdit();
  }

  Future<void> _onDelete() async {
    final note = _currentNote;

    if (note == null || note.id.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Delete note'),
          content: const Text(
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted =
        await _presenter.deleteNote(
      note.id,
    );

    if (deleted &&
        mounted) {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final note = _currentNote;

    final isNew =
        note == null ||
            note.id.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew
              ? 'New Course Note'
              : 'Edit Note',
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child:
                _buildSyncIndicator(),
          ),
          if (!isNew)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip:
                  'Delete note',
              onPressed:
                  _onDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    final courseId =
        _currentNote?.courseId ?? '';

    return Padding(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Course: $courseId',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller:
                _titleController,
            decoration:
                const InputDecoration(
              labelText: 'Title',
              hintText:
                  'Note title',
              border:
                  OutlineInputBorder(),
            ),
            onChanged:
                _onTitleChanged,
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TextField(
              controller:
                  _contentController,
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
              ),
              onChanged:
                  _onContentChanged,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _onCancel,
                child:
                    const Text(
                  'Cancel',
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed:
                    _onSave,
                icon: const Icon(
                  Icons.save,
                ),
                label:
                    const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
              onPressed:
                  _onCancel,
              child:
                  const Text(
                'Go back',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIndicator() {
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
          child:
              CircularProgressIndicator(
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
}