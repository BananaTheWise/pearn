import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../learning/model/course.dart';
import '../../learning/presenter/course_catalog_presenter.dart';
import '../../learning/view/i_course_catalog_view.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen>
    implements ICourseCatalogView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final CourseCatalogPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  List<Course> _courses = [];
  String? _errorMessage;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][COURSE] Course catalog initialized');
    _presenter = getIt<CourseCatalogPresenter>();
    _presenter.view = this; // attach this view to the presenter
    _presenter.loadCourses(); // trigger initial load
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ICourseCatalogView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showCourses(List<Course> courses) {
    setState(() {
      _courses = courses;
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
  void navigateToCourse(String courseId) {
    debugPrint('[UI][COURSE] Course selected: $courseId');
    Navigator.pushNamed(context, '/course-detail', arguments: courseId);
  }

  @override
  void showEmptyState() {
    setState(() {
      _courses = [];
      _errorMessage = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  List<Course> get _filteredCourses {
    if (_searchQuery.isEmpty) return _courses;
    return _courses.where((course) {
      return course.title.toLowerCase().contains(_searchQuery) ||
          (course.language?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search bar
          if (_courses.isNotEmpty || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          // Content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _presenter.loadCourses(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final courses = _filteredCourses;

    if (courses.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text('No courses match your search.'));
    }

    if (courses.isEmpty) {
      return const Center(child: Text('No courses available.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _CourseCard(
              course: course,
              onTap: () => _presenter.openCourse(course.id),
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder icon – replace with actual assets when available
              Icon(Icons.book, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                course.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (course.description != null) ...[
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    course.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (course.level != null)
                Chip(label: Text(course.level!), visualDensity: VisualDensity.compact),
            ],
          ),
        ),
      ),
    );
  }
}