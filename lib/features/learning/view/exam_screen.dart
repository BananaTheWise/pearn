import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../learning/model/exam.dart';
import '../../learning/model/exam_attempt.dart';
import '../../learning/presenter/exam_presenter.dart';
import '../../learning/view/i_exam_view.dart';

class ExamScreen extends StatefulWidget {
  final String examId; // corresponds to the exam file name or ID
  const ExamScreen({super.key, required this.examId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> implements IExamView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final ExamPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  Exam? _exam;
  int _currentQuestionIndex = 0;
  final Map<int, dynamic> _answers = {}; // question index -> answer
  ExamAttempt? _attempt;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][EXAM] Exam opened');
    _presenter = getIt<ExamPresenter>();
    _presenter.view = this;
    _presenter.loadExam(widget.examId);
  }

  // ---------------------------------------------------------------------------
  // IExamView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showExam(Exam exam) {
    setState(() {
      _exam = exam;
      _currentQuestionIndex = 0;
      _answers.clear();
      _attempt = null;
      _isSubmitting = false;
    });
  }

  @override
  void showQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  @override
  void showResult(ExamAttempt attempt) {
    debugPrint('[UI][EXAM] Exam result displayed');
    setState(() {
      _attempt = attempt;
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

  @override
  void navigateAfterExam() {
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  void _answerSelected(dynamic answer) {
    debugPrint('[UI][EXAM] Answer selected');
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _presenter.showQuestion(_currentQuestionIndex - 1);
    }
  }

  void _nextQuestion() {
    if (_exam != null && _currentQuestionIndex < _exam!.questions.length - 1) {
      _presenter.showQuestion(_currentQuestionIndex + 1);
    }
  }

  Future<void> _submitExam() async {
    // Prevent duplicate submission
    if (_isSubmitting || _attempt != null) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam'),
        content: const Text('Are you sure you want to submit your exam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    debugPrint('[UI][EXAM] Exam submission requested');
    setState(() {
      _isSubmitting = true;
    });

    await _presenter.submitExam(_answers);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exam?.title ?? 'Exam'),
        actions: [
          if (_exam != null && _attempt == null)
            TextButton(
              onPressed: _isSubmitting ? null : _submitExam,
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
          : _errorMessage != null
              ? _buildErrorView()
              : _attempt != null
                  ? _buildResultView()
                  : _exam != null
                      ? _buildExamView()
                      : const Center(child: Text('Exam not found')),
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
            onPressed: () => _presenter.loadExam(widget.examId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final attempt = _attempt!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attempt.passed ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: attempt.passed ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              attempt.passed ? 'Congratulations!' : 'Keep trying!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Score: ${attempt.score.toStringAsFixed(1)}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _presenter.navigateAfterExam(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamView() {
    final exam = _exam!;
    final totalQuestions = exam.questions.length;
    final currentQuestion = exam.questions[_currentQuestionIndex];
    final currentAnswer = _answers[_currentQuestionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _currentQuestionIndex / totalQuestions,
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${_currentQuestionIndex + 1} of $totalQuestions',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Question text
          Text(
            currentQuestion.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Answer options
          if (currentQuestion.options != null && currentQuestion.options!.isNotEmpty)
            ...currentQuestion.options!.map(
              (option) => RadioListTile<dynamic>(
                title: Text(option),
                value: option,
                groupValue: currentAnswer,
                onChanged: _answerSelected,
              ),
            )
          else
            TextField(
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
              ),
              onChanged: _answerSelected,
              controller: TextEditingController(text: currentAnswer?.toString() ?? ''),
            ),
          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentQuestionIndex > 0)
                OutlinedButton(
                  onPressed: _previousQuestion,
                  child: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              if (_currentQuestionIndex < totalQuestions - 1)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  child: const Text('Next'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}