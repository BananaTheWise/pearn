import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'roadmap.dart';
import 'roadmap_repository.dart';

/// Concrete implementation of [RoadmapRepository] using Supabase.
///
/// Fetches roadmap data and their stages from the `roadmaps` and
/// `roadmap_stages` tables.
class RoadmapRepositorySupabase implements RoadmapRepository {
  final SupabaseService _supabaseService;

  RoadmapRepositorySupabase(this._supabaseService);

  // ---------------------------------------------------------------------------
  // getRoadmap
  // ---------------------------------------------------------------------------
  @override
  Future<Roadmap?> getRoadmap(String roadmapId) async {
    debugPrint('[REPOSITORY][ROADMAP] Loading roadmap');
    debugPrint('[DB] Roadmap query started');

    try {
      // 1. Fetch the roadmap row
      final roadmapResponse = await _supabaseService.client
          .from('roadmaps')
          .select()
          .eq('id', roadmapId)
          .maybeSingle();

      if (roadmapResponse == null) {
        debugPrint('[REPOSITORY][ROADMAP] Roadmap not found');
        return null;
      }

      // 2. Fetch stages for this roadmap
      final stagesResponse = await _supabaseService.client
          .from('roadmap_stages')
          .select()
          .eq('roadmap_id', roadmapId)
          .order('order', ascending: true);

      final stages = (stagesResponse as List<dynamic>)
          .map((e) => RoadmapStage.fromMap(e as Map<String, dynamic>))
          .toList();

      // 3. Build the full Roadmap object
      final roadmap = Roadmap(
        id: roadmapResponse['id'] as String,
        title: roadmapResponse['title'] as String,
        description: roadmapResponse['description'] as String?,
        stages: stages,
      );

      debugPrint('[DB] Roadmap query completed');
      debugPrint('[REPOSITORY][ROADMAP] Roadmap loaded');
      return roadmap;
    } catch (e) {
      debugPrint('[ERROR][DB][ROADMAP] Roadmap query failed');
      debugPrint('Reason: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getAllRoadmaps
  // ---------------------------------------------------------------------------
  @override
  Future<List<Roadmap>> getAllRoadmaps() async {
    debugPrint('[REPOSITORY][ROADMAP] Loading all roadmaps');
    debugPrint('[DB] Roadmap query started');

    try {
      // 1. Fetch all roadmaps
      final roadmapsResponse = await _supabaseService.client
          .from('roadmaps')
          .select();

      final roadmapsList = (roadmapsResponse as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (roadmapsList.isEmpty) {
        debugPrint('[DB] Roadmap query completed – no roadmaps');
        return [];
      }

      final roadmapIds = roadmapsList.map((r) => r['id'] as String).toList();

      // 2. Fetch all stages for all those roadmaps in one query
      final stagesResponse = await _supabaseService.client
          .from('roadmap_stages')
          .select()
          .inFilter('roadmap_id', roadmapIds)
          .order('order', ascending: true);

      final stagesList = (stagesResponse as List<dynamic>)
          .map((e) => RoadmapStage.fromMap(e as Map<String, dynamic>))
          .toList();

      // 3. Group stages by roadmap_id
      final stagesByRoadmap = <String, List<RoadmapStage>>{};
      for (final stage in stagesList) {
        // We need to know the roadmap_id for each stage – it's not in the
        // RoadmapStage model, so we need to store it temporarily. We'll add a
        // helper to extract from the map.
        // For simplicity, we already have the stages in a list; we'll need
        // to rebuild from raw maps to get the roadmap_id.
      }

      // Better: re-fetch stages in a structured way: use raw maps.
      final stagesRaw = (stagesResponse as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Now group
      final groupedStages = <String, List<RoadmapStage>>{};
      for (final rawStage in stagesRaw) {
        final roadmapId = rawStage['roadmap_id'] as String;
        final stage = RoadmapStage.fromMap(rawStage);
        groupedStages.putIfAbsent(roadmapId, () => []).add(stage);
      }

      // 4. Build Roadmap objects
      final roadmaps = roadmapsList.map((r) {
        final id = r['id'] as String;
        return Roadmap(
          id: id,
          title: r['title'] as String,
          description: r['description'] as String?,
          stages: groupedStages[id] ?? [],
        );
      }).toList();

      debugPrint('[DB] Roadmap query completed');
      debugPrint('[REPOSITORY][ROADMAP] Roadmaps loaded: ${roadmaps.length}');
      return roadmaps;
    } catch (e) {
      debugPrint('[ERROR][DB][ROADMAP] Roadmap query failed');
      debugPrint('Reason: $e');
      rethrow;
    }
  }
}