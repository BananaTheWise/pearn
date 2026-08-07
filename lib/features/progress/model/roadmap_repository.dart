import '../../progress/model/roadmap.dart';

/// Abstract contract for roadmap data persistence.
///
/// The concrete implementation ([RoadmapRepositorySupabase]) fetches roadmap
/// information from the backend database.
abstract class RoadmapRepository {
  /// Returns a single roadmap identified by [roadmapId].
  ///
  /// Returns `null` if the roadmap does not exist.
  Future<Roadmap?> getRoadmap(String roadmapId);

  /// Returns all available roadmaps.
  Future<List<Roadmap>> getAllRoadmaps();
}