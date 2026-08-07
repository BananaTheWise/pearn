import 'package:flutter/foundation.dart';

import '../../../core/models/enrollment.dart';
import '../../progress/model/roadmap.dart';
import '../../progress/model/roadmap_repository.dart';
import '../../progress/model/progress_repository.dart';
import '../../progress/model/progress.dart';
import '../../progress/view/i_roadmap_view.dart';

/// Coordinates between the roadmap UI and the data layer.
///
/// Fetches the roadmap and optionally loads progress for the courses it contains.
class RoadmapPresenter {
  final RoadmapRepository _roadmapRepository;
  final ProgressRepository? _progressRepository; // optional – for course progress
  final String _userId;

  IRoadmapView? _view;

  RoadmapPresenter({
    required RoadmapRepository roadmapRepository,
    required String userId,
    ProgressRepository? progressRepository,
  })  : _roadmapRepository = roadmapRepository,
        _userId = userId,
        _progressRepository = progressRepository;

  /// Attaches the view that will receive UI updates.
  set view(IRoadmapView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // 1. loadRoadmap
  // ---------------------------------------------------------------------------
  Future<void> loadRoadmap() async {
    debugPrint('[PRESENTER][ROADMAP] Loading roadmap');
    _view?.showLoading(true);

    try {
      // Fetch the first available roadmap (or you could accept a roadmap ID).
      final roadmaps = await _roadmapRepository.getAllRoadmaps();
      if (roadmaps.isEmpty) {
        _view?.showError('No roadmap available.');
        return;
      }

      final roadmap = roadmaps.first; // Use the first roadmap for now
      _view?.showRoadmap(roadmap);
      debugPrint('[PRESENTER][ROADMAP] Roadmap loaded');

      // Optionally load progress for each course in the roadmap
      if (_progressRepository != null) {
        for (final stage in roadmap.stages) {
          if (stage.courseId != null) {
            try {
              final progress = await _progressRepository!
                  .getProgress(_userId, stage.courseId!);
              _view?.showCourseProgress(stage.courseId!, progress);
            } catch (_) {
              // non-fatal – show no progress for this course
              _view?.showCourseProgress(stage.courseId!, null);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PRESENTER][ROADMAP] Roadmap loading failed');
      _view?.showError('Unable to load roadmap. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. openCourse
  // ---------------------------------------------------------------------------
  void openCourse(String courseId) {
    if (courseId.trim().isEmpty) {
      _view?.showError('Invalid course identifier.');
      return;
    }
    _view?.navigateToCourse(courseId);
  }
}