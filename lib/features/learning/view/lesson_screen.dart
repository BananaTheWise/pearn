import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/di.dart';
import '../../learning/model/lesson.dart';
import '../../learning/presenter/lesson_presenter.dart';
import '../../learning/view/i_lesson_view.dart';

import '../../notes/model/note_context.dart';
import '../../notes/view/note_editor_screen.dart';

class LessonScreen extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    implements ILessonView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  late final LessonPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------

  bool _isLoading = true;
  Lesson? _lesson;
  bool _isCompleted = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    debugPrint(
      '[UI][LESSON] Lesson opened: '
      'course=${widget.courseId}, lesson=${widget.lessonId}',
    );

    _presenter = getIt<LessonPresenter>();
    _presenter.view = this;

    _presenter.loadLesson(
      widget.courseId,
      widget.lessonId,
    );
  }

  // ---------------------------------------------------------------------------
  // ILessonView
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
  void showLesson(Lesson lesson) {
    if (!mounted) return;

    setState(() {
      _lesson = lesson;
    });
  }

  @override
  void showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  void markLessonCompleted() {
    if (!mounted) return;

    setState(() {
      _isCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lesson marked as completed'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<void> _onCompletePressed() async {
    debugPrint(
      '[UI][LESSON] Lesson completion requested',
    );

    await _presenter.markLessonCompleted();
  }

  /// Opens the note editor for THIS lesson.
  ///
  /// The note is automatically associated with:
  ///   courseId = widget.courseId
  ///   lessonId = widget.lessonId
  Future<void> _onAddNotePressed() async {
    debugPrint(
      '[UI][LESSON] Creating note for '
      'course=${widget.courseId}, '
      'lesson=${widget.lessonId}',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          noteContext: NoteContext(
            courseId: widget.courseId,
            lessonId: widget.lessonId,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _lesson?.title ?? 'Lesson',
        ),
        actions: [
          // ---------------------------------------------------------------
          // Notes button
          // ---------------------------------------------------------------
          IconButton(
            onPressed: _onAddNotePressed,
            tooltip: 'Add note',
            icon: const Icon(
              Icons.note_add_outlined,
            ),
          ),

          // ---------------------------------------------------------------
          // Complete button
          // ---------------------------------------------------------------
          if (!_isCompleted)
            TextButton.icon(
              onPressed: _onCompletePressed,
              icon: const Icon(Icons.check),
              label: const Text('Complete'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _lesson == null
                  ? const Center(
                      child: Text('Lesson not found'),
                    )
                  : _buildContent(),
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
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                _presenter.loadLesson(
                  widget.courseId,
                  widget.lessonId,
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lesson content
  // ---------------------------------------------------------------------------

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep content readable on desktop.
          final maxWidth = constraints.maxWidth > 800
              ? 800.0
              : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------------------
                  // Lesson title
                  // ---------------------------------------------------------

                  Text(
                    _lesson!.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),

                  const SizedBox(height: 8),

                  // ---------------------------------------------------------
                  // Course / lesson information
                  // ---------------------------------------------------------

                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Course: ${widget.courseId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Lesson: ${widget.lessonId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ---------------------------------------------------------
                  // Quick note action
                  // ---------------------------------------------------------

                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.note_add_outlined,
                      ),
                      title: const Text(
                        'Take notes',
                      ),
                      subtitle: const Text(
                        'Create a note for this lesson',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: _onAddNotePressed,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------------------------------------------------------
                  // Markdown content
                  // ---------------------------------------------------------

                  if (_lesson!.content.isNotEmpty)
                    MarkdownBody(
                      data: _lesson!.content,
                      selectable: true,
                    ),

                  const SizedBox(height: 32),

                  // ---------------------------------------------------------
                  // Complete lesson button
                  // ---------------------------------------------------------

                  if (!_isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onCompletePressed,
                        icon: const Icon(
                          Icons.check_circle_outline,
                        ),
                        label: const Text(
                          'Mark lesson as completed',
                        ),
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: const Text(
                          'Lesson completed',
                        ),
                        subtitle: const Text(
                          'You have completed this lesson.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}