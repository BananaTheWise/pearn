import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../progress/model/progress.dart';
import '../../progress/presenter/progress_presenter.dart';
import '../../progress/view/i_progress_view.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> implements IProgressView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final ProgressPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  String? _errorMessage;

  int _streak = 0;
  int _level = 0;
  int _totalXp = 0;
  List<Progress> _courseProgresses = [];

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][PROGRESS] Progress screen initialized');
    _presenter = getIt<ProgressPresenter>();
    _presenter.view = this; // attach this view (concrete class) to the presenter
    _presenter.loadProgress();
  }

  // ---------------------------------------------------------------------------
  // IProgressView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showProgress(Progress progress) {
    // Presenter calls this once per enrolled course while loading.
    // Add it to the list (or replace if it's already there).
    setState(() {
      final index =
          _courseProgresses.indexWhere((p) => p.courseId == progress.courseId);
      if (index != -1) {
        _courseProgresses[index] = progress;
      } else {
        _courseProgresses.add(progress);
      }
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
  void showUpdatedProgress(Progress progress) {
    // Update the matching course in the list
    setState(() {
      final index = _courseProgresses.indexWhere((p) => p.courseId == progress.courseId);
      if (index != -1) {
        _courseProgresses[index] = progress;
      } else {
        _courseProgresses.add(progress);
      }
    });
  }

  @override
  void showStreak(int streak) {
    setState(() {
      _streak = streak;
    });
  }

  @override
  void showLevel(int level) {
    setState(() {
      _level = level;
    });
  }

  @override
  void showXp(int xp) {
    setState(() {
      _totalXp = xp;
    });
  }

  // ---------------------------------------------------------------------------
  // Additional method for the presenter to load all course progress at once
  // ---------------------------------------------------------------------------
  void showAllCourseProgress(List<Progress> progresses) {
    setState(() {
      _courseProgresses = progresses;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
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
            onPressed: () => _presenter.loadProgress(),
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
              // Overall stats card
              _buildStatsCard(isWide),
              const SizedBox(height: 24),
              // Course progress list
              Text('Course Progress', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (_courseProgresses.isEmpty)
                const Text('No progress data yet. Start learning!')
              else
                ..._courseProgresses.map((progress) => _buildCourseCard(progress, isWide)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(bool isWide) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Streak', '$_streak days', Icons.local_fire_department),
                  _buildStatItem('Level', '$_level', Icons.stars),
                  _buildStatItem('Total XP', '$_totalXp', Icons.emoji_events),
                ],
              )
            : Column(
                children: [
                  _buildStatItem('Streak', '$_streak days', Icons.local_fire_department),
                  const SizedBox(height: 12),
                  _buildStatItem('Level', '$_level', Icons.stars),
                  const SizedBox(height: 12),
                  _buildStatItem('Total XP', '$_totalXp', Icons.emoji_events),
                ],
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCourseCard(Progress progress, bool isWide) {
    final totalLessons = progress.completedLessonIds.length; // We don't have total lesson count here.
    // In a real app, the presenter would provide total lesson count or completion percentage.
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course: ${progress.courseId}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: totalLessons > 0 ? (totalLessons / 10).clamp(0.0, 1.0) : 0.0,
            ),
            const SizedBox(height: 4),
            Text('${progress.completedLessonIds.length} lessons completed',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

}