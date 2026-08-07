import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../progress/model/progress.dart';
import '../../progress/model/roadmap.dart';
import '../../progress/presenter/roadmap_presenter.dart';
import '../../progress/view/i_roadmap_view.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> implements IRoadmapView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final RoadmapPresenter _presenter;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  String? _errorMessage;

  Roadmap? _roadmap;
  final Map<String, Progress?> _courseProgress = {}; // courseId → progress

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][ROADMAP] Roadmap opened');
    _presenter = getIt<RoadmapPresenter>();
    _presenter.view = this;
    _presenter.loadRoadmap(); // load the roadmap (presenter decides which one)
  }

  // ---------------------------------------------------------------------------
  // IRoadmapView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showRoadmap(Roadmap roadmap) {
    debugPrint('[UI][ROADMAP] Roadmap loaded');
    setState(() {
      _roadmap = roadmap;
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
    debugPrint('[UI][ROADMAP] Course selected: $courseId');
    Navigator.pushNamed(context, '/course-detail', arguments: courseId);
  }

  @override
  void showCourseProgress(String courseId, Progress? progress) {
    setState(() {
      _courseProgress[courseId] = progress;
    });
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------
  void _onStageTap(String? courseId) {
    if (courseId != null && courseId.isNotEmpty) {
      _presenter.openCourse(courseId);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Roadmap')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _roadmap == null
                  ? const Center(child: Text('No roadmap available.'))
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
            onPressed: () => _presenter.loadRoadmap(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final stages = _roadmap!.stages;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roadmap header
              Text(_roadmap!.title, style: Theme.of(context).textTheme.headlineMedium),
              if (_roadmap!.description != null) ...[
                const SizedBox(height: 8),
                Text(_roadmap!.description!),
              ],
              const SizedBox(height: 24),
              // Stages
              ...stages.asMap().entries.map((entry) {
                final index = entry.key;
                final stage = entry.value;
                return _buildStageTile(stage, index, isWide);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStageTile(RoadmapStage stage, int index, bool isWide) {
    final progress = _courseProgress[stage.courseId];
    final completedLessons = progress?.completedLessonIds.length ?? 0;
    // Total lessons is unknown here; we could use progress? to derive a percentage if needed.
    // For simplicity we just show count.

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage number / connector
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      completedLessons > 0 ? Colors.green : Colors.grey,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (index < _roadmap!.stages.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Stage details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.title, style: Theme.of(context).textTheme.titleMedium),
                  if (stage.description != null)
                    Text(stage.description!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  if (stage.courseId != null) ...[
                    LinearProgressIndicator(
                      value: completedLessons > 0 ? (completedLessons / 5).clamp(0.0, 1.0) : 0.0,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedLessons lessons completed',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (stage.courseId != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _onStageTap(stage.courseId),
              ),
          ],
        ),
      ),
    );
  }
}