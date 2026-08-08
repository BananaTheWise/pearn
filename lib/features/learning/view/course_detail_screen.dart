import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../learning/model/chapter.dart';
import '../../learning/model/course.dart';
import '../../learning/presenter/course_detail_presenter.dart';
import '../../learning/view/exercise_screen.dart';
import '../../learning/view/i_course_detail_view.dart';
import '../../learning/model/enrollment.dart';
import '../../notes/view/notes_list_screen.dart';

/// Available course reaction emojis.
const List<String> kCourseReactions = <String>[
  '👍',
  '❤️',
  '😄',
  '🎉',
  '🤔',
  '👀',
];

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailScreen> createState() =>
      _CourseDetailScreenState();
}

class _CourseDetailScreenState
    extends State<CourseDetailScreen>
    implements ICourseDetailView {
  late final CourseDetailPresenter _presenter;

  bool _isLoading = true;

  Course? _course;

  List<Chapter> _chapters =
      <Chapter>[];

  Enrollment? _enrollment;

  String? _errorMessage;

  String? _userReaction;

  int _totalReactions = 0;

  @override
  void initState() {
    super.initState();

    debugPrint(
      '[UI][COURSE] Course detail opened: '
      '${widget.courseId}',
    );

    _presenter =
        getIt<CourseDetailPresenter>();

    _presenter.view = this;

    _presenter.loadCourse(
      widget.courseId,
    );
  }

  @override
  void dispose() {
    _presenter.view = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ICourseDetailView
  // ---------------------------------------------------------------------------

  @override
  void showLoading(
    bool loading,
  ) {
    if (!mounted) return;

    setState(() {
      _isLoading = loading;

      if (loading) {
        _errorMessage = null;
      }
    });
  }

  @override
  void showCourse(
    Course course,
  ) {
    if (!mounted) return;

    setState(() {
      _course = course;
    });
  }

  @override
  void showChapters(
    List chapters,
  ) {
    if (!mounted) return;

    setState(() {
      _chapters =
          List<Chapter>.from(
        chapters,
      );
    });
  }

  @override
  void showEnrollmentState(
    Enrollment? enrollment,
  ) {
    if (!mounted) return;

    setState(() {
      _enrollment = enrollment;
    });
  }

  @override
  void showError(
    String message,
  ) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  void navigateToLesson(
    String lessonId,
  ) {
    debugPrint(
      '[UI][COURSE] Lesson selected: '
      '$lessonId',
    );

    Navigator.pushNamed(
      context,
      '/lesson',
      arguments: {
        'courseId':
            widget.courseId,
        'lessonId':
            lessonId,
      },
    );
  }

  @override
  void showReactionState(
    String? userReaction,
    int totalReactions,
  ) {
    if (!mounted) return;

    setState(() {
      _userReaction =
          userReaction;

      _totalReactions =
          totalReactions;
    });
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<void> _onReact(
    String emoji,
  ) async {
    debugPrint(
      '[UI][COURSE] Course reaction selected',
    );

    if (_userReaction == emoji) {
      await _presenter.removeReaction();
    } else {
      await _presenter.reactToCourse(
        emoji,
      );
    }
  }

  Future<void> _onEnroll() async {
    await _presenter.enrollInCourse();
  }

  void _onOpenCourseNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotesListScreen(
          courseId:
              widget.courseId,
          courseName:
              _course?.title,
        ),
      ),
    );
  }

  void _onOpenChapterExercises(
    Chapter chapter,
  ) {
    if (chapter.lessons.isEmpty) {
      return;
    }

    debugPrint(
      '[UI][COURSE] Chapter exercises opened: '
      '${chapter.id}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExerciseScreen(
          courseId:
              widget.courseId,
          lessonId:
              chapter.lessons.first.id,
          exerciseId: '',
          chapterLessonIds:
              chapter.lessons
                  .map(
                    (lesson) =>
                        lesson.id,
                  )
                  .toList(),
        ),
      ),
    );
  }

  void _onOpenFinalExam() {
    debugPrint(
      '[UI][COURSE] Final exam opened: '
      '${widget.courseId}',
    );

    Navigator.pushNamed(
      context,
      '/exam',
      arguments: {
        'courseId': widget.courseId,
        'examId': 'final',
      },
    );
  }

  void _onOpenChapterExam(
    Chapter chapter,
  ) {
    debugPrint(
      '[UI][COURSE] Chapter exam opened: '
      '${chapter.id}',
    );

    Navigator.pushNamed(
      context,
      '/exam',
      arguments: {
        'courseId': widget.courseId,
        'examId': chapter.id,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _course?.title ??
              'Course',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.note_alt_outlined,
            ),
            tooltip:
                'Course notes',
            onPressed:
                _onOpenCourseNotes,
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
              : _course == null
                  ? const Center(
                      child: Text(
                        'Course not found',
                      ),
                    )
                  : _buildContent(),
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
              _errorMessage!,
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
              onPressed: () =>
                  _presenter
                      .loadCourse(
                widget.courseId,
              ),
              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final course = _course!;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium,
          ),

          if (course.description != null) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              course.description!,
            ),
          ],

          if (course.language != null ||
              course.level != null) ...[
            const SizedBox(
              height: 8,
            ),
            Wrap(
              spacing: 8,
              children: [
                if (course.language !=
                    null)
                  Chip(
                    label: Text(
                      course.language!,
                    ),
                  ),
                if (course.level !=
                    null)
                  Chip(
                    label: Text(
                      course.level!,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          _buildEnrollmentSection(),

          const SizedBox(
            height: 12,
          ),

          _buildCourseNotesButton(),

          const SizedBox(
            height: 16,
          ),

          _buildReactionSection(),

          const SizedBox(
            height: 24,
          ),

          Text(
            'Chapters',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(
            height: 8,
          ),

          if (_chapters.isEmpty)
            const Text(
              'No chapters available.',
            )
          else
            _buildChapterList(),

          const SizedBox(
            height: 16,
          ),

          _buildFinalExamButton(),
        ],
      ),
    );
  }

  Widget _buildCourseNotesButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed:
            _onOpenCourseNotes,
        icon: const Icon(
          Icons.note_alt_outlined,
        ),
        label: const Text(
          'Course Notes',
        ),
      ),
    );
  }

  Widget _buildEnrollmentSection() {
    if (_enrollment == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed:
              _onEnroll,
          icon: const Icon(
            Icons.login,
          ),
          label:
              const Text('Enroll'),
        ),
      );
    }

    final status =
        _enrollment!.status;

    final isCompleted =
        status == 'completed';

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle
                  : Icons.access_time,
              color:
                  isCompleted
                      ? Colors.green
                      : Colors.orange,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              isCompleted
                  ? 'Completed'
                  : 'Enrolled',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionSection() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            Text(
              '$_totalReactions',
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Wrap(
                spacing: 4,
                children: [
                  for (final emoji
                      in kCourseReactions)
                    InkWell(
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                      onTap: () =>
                          _onReact(
                        emoji,
                      ),
                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .all(
                          6,
                        ),
                        decoration:
                            _userReaction ==
                                    emoji
                                ? BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    )
                                        .colorScheme
                                        .primary
                                        .withOpacity(
                                          0.2,
                                        ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  )
                                : null,
                        child: Text(
                          emoji,
                          style:
                              const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalExamButton() {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.fact_check_outlined,
        ),
        title: const Text(
          'Final Exam',
        ),
        subtitle: const Text(
          'Test what you\'ve learned in this course',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: _onOpenFinalExam,
      ),
    );
  }

  Widget _buildChapterList() {
    return Column(
      children: [
        for (final chapter
            in _chapters)
          Card(
            margin:
                const EdgeInsets.only(
              bottom: 8,
            ),
            child:
                ExpansionTile(
              title:
                  Text(chapter.title),
              subtitle:
                  chapter.description !=
                          null
                      ? Text(
                          chapter
                              .description!,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        )
                      : null,
              children: [
                for (final lesson
                    in chapter.lessons)
                  ListTile(
                    title:
                        Text(
                      lesson.title,
                    ),
                    leading:
                        const Icon(
                      Icons.menu_book,
                    ),
                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () =>
                        navigateToLesson(
                      lesson.id,
                    ),
                  ),

                if (chapter
                    .lessons
                    .isNotEmpty)
                  ListTile(
                    title:
                        const Text(
                      'Exercises',
                    ),
                    leading:
                        const Icon(
                      Icons.edit_note,
                    ),
                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () =>
                        _onOpenChapterExercises(
                      chapter,
                    ),
                  ),

                ListTile(
                  title: const Text(
                    'Chapter Exam',
                  ),
                  leading: const Icon(
                    Icons.fact_check_outlined,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () =>
                      _onOpenChapterExam(
                    chapter,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}