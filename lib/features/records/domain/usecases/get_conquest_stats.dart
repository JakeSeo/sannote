import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../entities/conquest_stats.dart';
import '../entities/paint.dart';

/// 칠한 구간 집합 → 구간 수 / km / 입구 수 / 산군 스탬프 / 획득 코스 수.
class GetConquestStats {
  const GetConquestStats();

  ConquestStats call({
    required List<PaintedSegment> painted,
    required List<DiscoveredCourse> discovered,
    required List<Course> courses,
    required List<TrailSegment> segments,
    required List<Spot> entrances,
  }) {
    if (painted.isEmpty) return ConquestStats.empty;
    final segById = {for (final s in segments) s.segmentId: s};
    final ids = painted.map((p) => p.segmentId).where(segById.containsKey).toSet();
    final km = ids.fold(0.0, (sum, id) => sum + (segById[id]?.lengthKm ?? 0));
    final groups = painted.map((p) => p.mountainGroup).toSet();
    // 입구: 획득한 코스의 출발 입구
    final discoveredIds = discovered.map((d) => d.courseId).toSet();
    final entranceSet = {for (final e in entrances) e.spotId};
    final entranceIds = {
      for (final c in courses)
        if (discoveredIds.contains(c.courseId) && c.entranceSpotId != null && entranceSet.contains(c.entranceSpotId)) c.entranceSpotId!,
    };
    return ConquestStats(
      completedSegmentIds: ids,
      totalKm: km,
      entranceCount: entranceIds.length,
      completedHikeCount: discovered.length,
      mountainGroups: groups,
    );
  }
}

final getConquestStatsProvider = Provider<GetConquestStats>((_) => const GetConquestStats());
