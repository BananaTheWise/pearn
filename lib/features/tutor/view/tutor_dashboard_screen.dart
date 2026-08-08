import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../tutor/model/student_stat.dart';
import '../../tutor/model/student_summary.dart';
import '../../tutor/presenter/tutor_analytics_presenter.dart';
import '../../tutor/view/i_tutor_dashboard_view.dart';

/// Tutor's main dashboard screen.
///
/// Displays course/student statistics and provides actions to manage courses.
/// All data is retrieved through [TutorAnalyticsPresenter].
class TutorDashboardScreen extends StatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  State<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends State<TutorDashboardScreen>
    implements ITutorDashboardView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final TutorAnalyticsPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<StudentSummary> _students = [];
  StudentStat? _selectedStudentStat;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][TUTOR] Tutor dashboard opened');
    _presenter = getIt<TutorAnalyticsPresenter>();
    _presenter.view = this;
    _presenter.loadDashboard();
  }

  // ---------------------------------------------------------------------------
  // ITutorDashboardView
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showDashboard(Map<String, dynamic> data) {
    debugPrint('[UI][TUTOR] Dashboard loaded');
    setState(() {
      _dashboardData = data;
      _isLoading = false;
    });
  }

  @override
  void showStudents(List<StudentSummary> students) {
    setState(() {
      _students = students;
    });
  }

  @override
  void showStudentStats(StudentStat stats) {
    setState(() {
      _selectedStudentStat = stats;
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
  void openCourseEditor(String? courseId) {
    debugPrint('[UI][TUTOR] Course editor requested');
    // Navigate to the tutor course editor screen.
    Navigator.pushNamed(
      context,
      '/tutor-course-editor',
      arguments: courseId, // null for new course, String for existing
    );
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  void _onCreateCourse() {
    _presenter.openCourseEditor(null); // new course
  }

  void _onStudentTap(StudentSummary student) {
    // For simplicity, we fetch stats for the first course from the dashboard;
    // in reality we'd select a course. We'll rely on the presenter to decide.
    // We'll just ask presenter to load stats for a default course.
    // Alternatively, we can show a dialog to pick a course.
    // We'll keep it simple: presenter.loadStudentStats(studentId) but we need courseId.
    // We'll implement a method that takes studentId and courseId.
    // For now, we'll trigger nothing until architecture defines course selection.
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create new course',
            onPressed: _onCreateCourse,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
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
            onPressed: () => _presenter.loadDashboard(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final studentCount = _dashboardData['student_count'] ?? 0;
    final courseCount = _dashboardData['course_count'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Courses',
                      '$courseCount',
                      Icons.book,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Students',
                      '$studentCount',
                      Icons.people,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Student list section
              Text('Students', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_students.isEmpty)
                const Text('No students enrolled yet.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      title: Text(student.username),
                      leading: const Icon(Icons.person),
                      onTap: () => _onStudentTap(student),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}