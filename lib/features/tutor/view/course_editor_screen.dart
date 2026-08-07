import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../tutor/presenter/tutor_course_editor_presenter.dart';
import '../../tutor/view/i_tutor_course_editor_view.dart';

/// Screen where a tutor creates or edits a course and submits it for review.
///
/// [courseId] is null when creating a new course, otherwise it contains the
/// ID of the course to edit.
class TutorCourseEditorScreen extends StatefulWidget {
  final String? courseId;
  const TutorCourseEditorScreen({super.key, this.courseId});

  @override
  State<TutorCourseEditorScreen> createState() => _TutorCourseEditorScreenState();
}

class _TutorCourseEditorScreenState extends State<TutorCourseEditorScreen>
    implements ITutorCourseEditorView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final TutorCourseEditorPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = true;        // initial load
  bool _isSubmitting = false;    // submission in progress
  String? _errorMessage;
  String? _validationError;
  String? _pullRequestUrl;       // success after submission

  // Form fields for basic course metadata (based on Course model)
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _languageController = TextEditingController();
  final _levelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][TUTOR] Course editor opened');
    _presenter = getIt<TutorCourseEditorPresenter>();
    _presenter.view = this;
    // If editing existing course, load it; else start blank
    _presenter.loadCourse(widget.courseId);
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _languageController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ITutorCourseEditorView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showCourseEditor(Map<String, dynamic> courseData) {
    // Pre-fill the form
    _idController.text = courseData['id'] as String? ?? '';
    _titleController.text = courseData['title'] as String? ?? '';
    _descriptionController.text = courseData['description'] as String? ?? '';
    _languageController.text = courseData['language'] as String? ?? '';
    _levelController.text = courseData['level'] as String? ?? '';

    // If editing an existing course, disable ID editing? Keep editable for now.
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void showValidationError(String message) {
    setState(() {
      _validationError = message;
      _isSubmitting = false;
    });
  }

  @override
  void showSubmitting(bool submitting) {
    setState(() {
      _isSubmitting = submitting;
      if (submitting) {
        _validationError = null;
        _errorMessage = null;
      }
    });
  }

  @override
  void showSubmissionSuccess(String pullRequestUrl) {
    setState(() {
      _pullRequestUrl = pullRequestUrl;
      _isSubmitting = false;
    });
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isSubmitting = false;
    });
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  Future<void> _onSubmit() async {
    debugPrint('[UI][TUTOR] Course submission requested');

    // Basic client-side validation before passing to presenter
    if (!_formKey.currentState!.validate()) return;

    final courseData = <String, dynamic>{
      'id': _idController.text.trim(),
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'language': _languageController.text.trim(),
      'level': _levelController.text.trim(),
      // Chapters etc. would be added by a more complex editor
    };

    await _presenter.submitCourse(courseData);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseId == null ? 'Create course' : 'Edit course'),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isSubmitting) ? null : _onSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pullRequestUrl != null
              ? _buildSuccessView()
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_validationError!, style: const TextStyle(color: Colors.red)),
              ),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Course ID', border: OutlineInputBorder()),
              enabled: widget.courseId == null, // only editable for new courses
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'ID is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _languageController,
              decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _levelController,
              decoration: const InputDecoration(labelText: 'Level (e.g., beginner)', border: OutlineInputBorder()),
            ),
            // Future: chapters / lessons editor would go here
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Course submitted for review!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('The admin will review your submission.'),
            if (_pullRequestUrl != null) ...[
              const SizedBox(height: 16),
              // Ideally a clickable link, but for now just display it
              Text('Pull Request: $_pullRequestUrl',
                  style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}