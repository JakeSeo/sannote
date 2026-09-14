import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../entities/conquest_stats.dart';
import '../entities/hike.dart';

/// 완주한 코스들의 segment_ids 합집합 → 구간 수 / km / 입구 수 / 산군 스탬프.
class GetConquestStats {
  const GetConquestStats();

  ConquestStats call({
    required List<Hike> hikes,
    required List<Course> courses,
    required List<TrailSegment> segments,
    required List<Spot> entrances,
  }) {
    final completedCourseIds = {for (final h in hikes) if (h.isCompleted) h.courseId};
    if (completedCourseIds.isEmpty) return ConquestStats.empty;
    final courseById = {for (final c in courses) c.courseId: c};
    final segById = {for (final s in segments) s.segmentId: s};
    final segIds = <String>{};
    final entranceIds = <String>{};
    final groups = <String>{};
    for (final id in completedCourseIds) {
      final c = courseById[id];
      if (c == null) continue;
      segIds.addAll(c.segmentIds.where(segById.containsKey));
      if (c.entranceSpotId != null) entranceIds.add(c.entranceSpotId!);
      groups.add(c.mountainGroup);
    }
    final km = segIds.fold(0.0, (sum, id) => sum + (segById[id]?.lengthKm ?? 0));
    final entranceSet = {for (final e in entrances) e.spotId};
    return ConquestStats(
      completedSegmentIds: segIds,
      totalKm: km,
      entranceCount: entranceIds.where(entranceSet.contains).length,
      completedHikeCount: hikes.where((h) => h.isCompleted).length,
      mountainGroups: groups,
    );
  }
}

final getConquestStatsProvider = Provider<GetConquestStats>((_) => const GetConquestStats());
