import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../features/learning/model/enrollment.dart';
import '../../learning/model/chapter.dart';
import '../../learning/model/course.dart';
import '../../learning/presenter/course_detail_presenter.dart';
import '../../learning/view/i_course_detail_view.dart';
import '../model/enrollment.dart';

/// A set of available reaction emojis for courses.
const List<String> kCourseReactions = ['👍', '❤️', '😄', '🎉', '🤔', '👀'];

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    implements ICourseDetailView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final CourseDetailPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state (driven by the presenter)
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  Course? _course;
  List<Chapter> _chapters = [];
  Enrollment? _enrollment;
  String? _errorMessage;
  String? _userReaction;
  int _totalReactions = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][COURSE] Course detail opened: ${widget.courseId}');
    _presenter = getIt<CourseDetailPresenter>();
    _presenter.view = this;
    _presenter.loadCourse(widget.courseId);
  }

  // ---------------------------------------------------------------------------
  // ICourseDetailView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showCourse(Course course) {
    setState(() {
      _course = course;
    });
  }

  @override
  void showChapters(List<Chapter> chapters) {
    setState(() {
      _chapters = chapters;
    });
  }

  @override
  void showEnrollmentState(Enrollment? enrollment) {
    setState(() {
      _enrollment = enrollment;
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
  void navigateToLesson(String lessonId) {
    debugPrint('[UI][COURSE] Lesson selected: $lessonId');
    Navigator.pushNamed(
      context,
      '/lesson',
      arguments: {'courseId': widget.courseId, 'lessonId': lessonId},
    );
  }

  @override
  void showReactionState(String? userReaction, int totalReactions) {
    setState(() {
      _userReaction = userReaction;
      _totalReactions = totalReactions;
    });
  }

  // ---------------------------------------------------------------------------
  // User actions (all go through the presenter)
  // ---------------------------------------------------------------------------
  Future<void> _onReact(String emoji) async {
    debugPrint('[UI][COURSE] Course reaction selected');
    // If user taps the same emoji, remove reaction.
    if (_userReaction == emoji) {
      await _presenter.removeReaction();
    } else {
      await _presenter.reactToCourse(emoji);
    }
  }

  Future<void> _onEnroll() async {
    await _presenter.enrollInCourse();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.title ?? 'Course'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _course == null
                  ? const Center(child: Text('Course not found'))
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
            onPressed: () => _presenter.loadCourse(widget.courseId),
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
          final isWide = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course header
              Text(
                _course!.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_course!.description != null) ...[
                const SizedBox(height: 8),
                Text(_course!.description!),
              ],
              if (_course!.language != null || _course!.level != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_course!.language != null)
                      Chip(label: Text(_course!.language!)),
                    if (_course!.level != null)
                      Chip(label: Text(_course!.level!)),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Enrollment button
              _buildEnrollmentSection(),
              const SizedBox(height: 16),

              // Reaction section (course-only)
              _buildReactionSection(),
              const SizedBox(height: 24),

              // Chapters list
              Text('Chapters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_chapters.isEmpty)
                const Text('No chapters available.')
              else
                _buildChapterList(isWide),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnrollmentSection() {
    if (_enrollment == null) {
      return ElevatedButton.icon(
        onPressed: _onEnroll,
        icon: const Icon(Icons.login),
        label: const Text('Enroll'),
      );
    }
    final status = _enrollment!.status;
    final isCompleted = status == 'completed';
    final isActive = status == 'active';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.access_time,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(isCompleted ? 'Completed' : 'Enrolled'),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionSection() {
    // Only show for courses, not for other entities.
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('$_totalReactions', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            ...kCourseReactions.map((emoji) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _onReact(emoji),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: _userReaction == emoji
                          ? BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            )
                          : null,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList(bool isWide) {
    return Column(
      children: _chapters.map((chapter) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(chapter.title),
            subtitle: chapter.description != null
                ? Text(
                    chapter.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            children: chapter.lessons.map((lesson) {
              return ListTile(
                title: Text(lesson.title),
                leading: const Icon(Icons.menu_book),
                onTap: () => navigateToLesson(lesson.id),
                trailing: const Icon(Icons.chevron_right),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}