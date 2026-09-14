import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../spots/domain/usecases/get_entrances.dart';
import '../../../trails/domain/usecases/get_trail_network.dart';
import '../../domain/entities/conquest_stats.dart';
import '../../domain/entities/hike.dart';
import '../../domain/usecases/get_completion_counts.dart';
import '../../domain/usecases/get_conquest_stats.dart';
import '../../domain/usecases/get_hikes.dart';

/// 로컬 산행 기록 (DB 변경 시 자동 갱신)
final hikesProvider = StreamProvider<List<Hike>>((ref) => ref.watch(getHikesProvider).watch());

/// 완주 코스 합집합 통계 (지도 헤더·색칠·내 기록 탭 공용)
final conquestStatsProvider = FutureProvider<ConquestStats>((ref) async {
  final hikes = await ref.watch(hikesProvider.future);
  if (!hikes.any((h) => h.isCompleted)) return ConquestStats.empty;
  final (summaries, segments, entrances) = await (
    ref.read(getCourseSummariesProvider).call(),
    ref.read(getTrailNetworkProvider).call(),
    ref.read(getEntrancesProvider).call(),
  ).wait;
  final stats = ref.read(getConquestStatsProvider).call(
        hikes: hikes,
        courses: summaries.map((s) => s.course).toList(),
        segments: segments,
        entrances: entrances,
      );
  debugPrint('[records] 정복 통계: 구간 ${stats.segmentCount} · ${stats.totalKm.toStringAsFixed(1)}km · 입구 ${stats.entranceCount}');
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
