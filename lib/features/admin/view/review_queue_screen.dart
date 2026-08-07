import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../presenter/admin_course_presenter.dart';
import '../view/i_admin_course_review_view.dart'; // defined below

/// Displays the list of tutor course submissions awaiting admin review.
///
/// Uses [AdminCoursePresenter] to fetch pending courses and perform
/// approve / reject actions.
class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen>
    implements IAdminCourseReviewView {
  late final AdminCoursePresenter _presenter;

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingCourses = [];
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][ADMIN][COURSE] Review queue opened');
    _presenter = getIt<AdminCoursePresenter>();
    _presenter.view = this;
    _presenter.loadPendingCourses();
  }

  // ---------------------------------------------------------------------------
  // IAdminCourseReviewView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showPendingCourses(List<Map<String, dynamic>> courses) {
    setState(() {
      _pendingCourses = courses;
      _isLoading = false;
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
  void showApprovalSuccess(String courseId) {
    setState(() {
      _successMessage = 'Course approved.';
    });
    // Remove from local list immediately (optimistic) – better to refresh
    _presenter.loadPendingCourses();
  }

  @override
  void showRejectionSuccess(String courseId) {
    setState(() {
      _successMessage = 'Course rejected.';
    });
    _presenter.loadPendingCourses();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _onApprove(String courseId) async {
    debugPrint('[UI][ADMIN][COURSE] Approve pressed');
    await _presenter.approveCourse(courseId);
  }

  Future<void> _onReject(String courseId) async {
    debugPrint('[UI][ADMIN][COURSE] Reject pressed');
    // Optionally gather a reason here before calling presenter
    await _presenter.rejectCourse(courseId);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Review Queue')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _pendingCourses.isEmpty
                  ? const Center(child: Text('No pending courses.'))
                  : _buildCourseList(),
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
            onPressed: () => _presenter.loadPendingCourses(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingCourses.length,
      itemBuilder: (context, index) {
        final course = _pendingCourses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(course['title'] ?? 'Untitled'),
            subtitle: Text('Tutor: ${course['tutor_id'] ?? 'Unknown'}'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Additional info: submitted date, PR link, etc.
                    if (course['submitted_at'] != null)
                      Text('Submitted: ${_formatDate(course['submitted_at'])}'),
                    if (course['pull_request_url'] != null)
                      Text('PR: ${course['pull_request_url']}'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject'),
                          onPressed: () => _onReject(course['id']),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.green),
                          label: const Text('Approve'),
                          onPressed: () => _onApprove(course['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      final dt = DateTime.parse(dateValue.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateValue.toString();
    }
  }
}