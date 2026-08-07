import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../learning/model/exercise.dart';
import '../../learning/presenter/exercise_presenter.dart';
import '../../learning/view/i_exercise_view.dart';

class ExerciseScreen extends StatefulWidget {
  final String courseId;
  final String lessonId;
  final String exerciseId;

  const ExerciseScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.exerciseId,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> implements IExerciseView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final ExercisePresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state (controlled by presenter via IExerciseView)
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  Exercise? _exercise;
  bool? _answerCorrect;
  String? _explanation;
  String? _errorMessage;
  bool _isCompleted = false;

  // Form state
  final _answerController = TextEditingController();
  String? _selectedOption; // for multiple choice

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][EXERCISE] Exercise opened');
    _presenter = getIt<ExercisePresenter>();
    _presenter.view = this;
    _presenter.loadExercise(widget.courseId, widget.lessonId, widget.exerciseId);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IExerciseView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showExercise(Exercise exercise) {
    setState(() {
      _exercise = exercise;
      _answerCorrect = null;
      _explanation = null;
      _selectedOption = null;
      _answerController.clear();
    });
  }

  @override
  void showResult(bool correct, String? explanation) {
    debugPrint('[UI][EXERCISE] Exercise result displayed');
    setState(() {
      _answerCorrect = correct;
      _explanation = explanation;
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
  void navigateToNextExercise() {
    // Presenter will provide the next exercise ID and navigate.
    // For simplicity, we'll pop back to the previous screen.
    Navigator.pop(context);
  }

  @override
  void showCompletion() {
    setState(() {
      _isCompleted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All exercises completed!')),
    );
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  Future<void> _onSubmitAnswer() async {
    String answer;
    if (_exercise!.options != null && _exercise!.options!.isNotEmpty) {
      // Multiple choice
      if (_selectedOption == null) return; // nothing selected
      answer = _selectedOption!;
    } else {
      answer = _answerController.text.trim();
      if (answer.isEmpty) return;
    }
    debugPrint('[UI][EXERCISE] Answer submitted');
    await _presenter.submitAnswer(answer);
  }

  void _onNextPressed() {
    _presenter.nextExercise();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise?.question ?? 'Exercise'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _exercise == null
                  ? const Center(child: Text('Exercise not found'))
                  : _buildContent(),
      floatingActionButton: _exercise != null && _answerCorrect != null
          ? FloatingActionButton.extended(
              onPressed: _onNextPressed,
              label: const Text('Next'),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
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
            onPressed: () => _presenter.loadExercise(
                widget.courseId, widget.lessonId, widget.exerciseId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final exercise = _exercise!;
    final hasOptions = exercise.options != null && exercise.options!.isNotEmpty;
    final isDisabled = _answerCorrect != null; // after answer, disable input

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.question,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          if (hasOptions)
            ...exercise.options!.map(
              (option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _selectedOption,
                onChanged: isDisabled ? null : (value) {
                  setState(() {
                    _selectedOption = value;
                  });
                },
              ),
            )
          else
            TextField(
              controller: _answerController,
              enabled: !isDisabled,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 24),
          if (!isDisabled)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSubmitAnswer,
                child: const Text('Submit'),
              ),
            ),
          if (_answerCorrect != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _answerCorrect!
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _answerCorrect! ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _answerCorrect! ? 'Correct!' : 'Incorrect',
                    style: TextStyle(
                      color: _answerCorrect! ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_explanation != null) ...[
                    const SizedBox(height: 8),
                    Text(_explanation!),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}