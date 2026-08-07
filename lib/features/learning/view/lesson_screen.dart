import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/di.dart';
import '../../learning/model/exercise.dart';
import '../../learning/model/lesson.dart';
import '../../learning/presenter/lesson_presenter.dart';
import '../../learning/view/i_lesson_view.dart';

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

class _LessonScreenState extends State<LessonScreen> implements ILessonView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final LessonPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state (set by presenter via ILessonView methods)
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  Lesson? _lesson;
  List<Exercise> _exercises = [];
  bool _isCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][LESSON] Lesson opened');
    _presenter = getIt<LessonPresenter>();
    _presenter.view = this;
    _presenter.loadLesson(widget.courseId, widget.lessonId);
  }

  // ---------------------------------------------------------------------------
  // ILessonView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showLesson(Lesson lesson) {
    setState(() {
      _lesson = lesson;
    });
  }

  @override
  void showExercises(List<Exercise> exercises) {
    setState(() {
      _exercises = exercises;
    });
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  void markLessonCompleted() {
    setState(() {
      _isCompleted = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lesson marked as completed')));
  }

  @override
  void navigateToExercise(String exerciseId) {
    debugPrint('[UI][LESSON] Exercise selected: $exerciseId');
    Navigator.pushNamed(
      context,
      '/exercise',
      arguments: {
        'courseId': widget.courseId,
        'lessonId': widget.lessonId,
        'exerciseId': exerciseId,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  Future<void> _onCompletePressed() async {
    debugPrint('[UI][LESSON] Lesson completion requested');
    await _presenter.markLessonCompleted();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson?.title ?? 'Lesson'),
        actions: [
          if (!_isCompleted)
            TextButton.icon(
              onPressed: _onCompletePressed,
              icon: const Icon(Icons.check),
              label: const Text('Complete'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _lesson == null
          ? const Center(child: Text('Lesson not found'))
          : _buildContent(),
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
            onPressed: () =>
                _presenter.loadLesson(widget.courseId, widget.lessonId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use wider max width for readability on desktop.
          final maxWidth = constraints.maxWidth > 800
              ? 800.0
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Markdown content
                  if (_lesson!.content.isNotEmpty)
                    MarkdownBody(
                      data: _lesson!.content,
                      selectable: true,
                      // Keep default styling; code blocks will be rendered properly.
                    ),
                  const SizedBox(height: 24),

                  // Exercises section
                  if (_exercises.isNotEmpty) ...[
                    Text(
                      'Exercises',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._exercises.map(
                      (exercise) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(exercise.question),
                          subtitle: Text('Type: ${exercise.type}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => navigateToExercise(exercise.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _currentExerciseId;
  @override
  void navigateToNextExercise() {
    if (_exercises.isEmpty) {
      showCompletion();
      return;
    }

    final currentIndex = _currentExerciseId == null
        ? -1
        : _exercises.indexWhere(
            (exercise) => exercise.id == _currentExerciseId,
          );

    final nextIndex = currentIndex + 1;

    // No more exercises.
    if (nextIndex >= _exercises.length) {
      showCompletion();
      return;
    }

    final nextExercise = _exercises[nextIndex];

    _currentExerciseId = nextExercise.id;

    debugPrint('[UI][LESSON] Navigating to next exercise: ${nextExercise.id}');

    Navigator.pushNamed(
      context,
      '/exercise',
      arguments: {
        'courseId': widget.courseId,
        'lessonId': widget.lessonId,
        'exerciseId': nextExercise.id,
      },
    );
  }

  @override
  void showCompletion() {
    if (!mounted) return;

    setState(() {
      _isCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lesson completed!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    debugPrint('[UI][LESSON] Lesson completion displayed');
  }

  @override
  void showResult(bool correct, String? explanation) {
    if (!mounted) return;

    final message = correct ? 'Correct! 🎉' : 'Incorrect';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          content: explanation == null || explanation.trim().isEmpty
              ? Text(
                  correct
                      ? 'Well done!'
                      : 'Try reviewing the lesson and attempt it again.',
                )
              : Text(explanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    debugPrint(
      '[UI][LESSON] Exercise result: '
      '${correct ? 'correct' : 'incorrect'}',
    );
  }
}
