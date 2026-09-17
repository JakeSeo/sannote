import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../spots/domain/usecases/get_entrances.dart';
import '../../../trails/domain/usecases/get_trail_network.dart';
import '../../data/repositories/paint_repository_impl.dart';
import '../../domain/entities/conquest_stats.dart';
import '../../domain/entities/hike.dart';
import '../../domain/entities/paint.dart';
import '../../domain/usecases/get_completion_counts.dart';
import '../../domain/usecases/get_conquest_stats.dart';
import '../../domain/usecases/get_hikes.dart';

/// 로컬 산행 기록 (DB 변경 시 자동 갱신)
final hikesProvider = StreamProvider<List<Hike>>((ref) => ref.watch(getHikesProvider).watch());

/// 내가 칠한 구간
final paintedSegmentsProvider = StreamProvider<List<PaintedSegment>>((ref) => ref.watch(paintRepositoryProvider).watchPainted());

/// 획득한 코스 (로컬 기록)
final discoveredCoursesProvider = StreamProvider<List<DiscoveredCourse>>((ref) => ref.watch(paintRepositoryProvider).watchDiscovered());

/// 획득한 코스의 요약 (지도 표시·산책로 서랍용). 획득 순서(최근 먼저).
final discoveredSummariesProvider = FutureProvider<List<CourseSummary>>((ref) async {
  final discovered = await ref.watch(discoveredCoursesProvider.future);
  if (discovered.isEmpty) return const [];
  final summaries = await ref.read(getCourseSummariesProvider).call();
  final byId = {for (final s in summaries) s.course.courseId: s};
  final sorted = [...discovered]..sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
  return [for (final d in sorted) ?byId[d.courseId]];
});

/// 칠한 구간 기준 통계 (시트·산책로 서랍 공용)
final conquestStatsProvider = FutureProvider<ConquestStats>((ref) async {
  final painted = await ref.watch(paintedSegmentsProvider.future);
  final discovered = await ref.watch(discoveredCoursesProvider.future);
  if (painted.isEmpty) return ConquestStats.empty;
  final (summaries, segments, entrances) = await (
    ref.read(getCourseSummariesProvider).call(),
    ref.read(getTrailNetworkProvider).call(),
    ref.read(getEntrancesProvider).call(),
  ).wait;
  final stats = ref.read(getConquestStatsProvider).call(
        painted: painted,
        discovered: discovered,
        courses: summaries.map((s) => s.course).toList(),
        segments: segments,
        entrances: entrances,
      );
  debugPrint('[records] 칠한 구간 ${stats.segmentCount} · ${stats.totalKm.toStringAsFixed(1)}km · 획득 코스 ${stats.completedHikeCount}');
  return stats;
});

/// 코스별 총 완주자 수 (서버 익명 집계). 실패 시 빈 맵.
final completionCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    return await ref.watch(getCompletionCountsProvider).call();
  } catch (e) {
    debugPrint('[records] 완주자 수 조회 실패: $e');
    return const {};
  }
});
