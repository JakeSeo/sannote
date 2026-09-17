import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../../../trails/domain/usecases/get_trail_network.dart';
import '../../data/repositories/paint_repository_impl.dart';
import '../entities/paint.dart';
import '../repositories/paint_repository.dart';

/// 종료 결과: 이번 산행으로 새로 칠한 구간과 새로 획득한 코스.
class PaintResult {
  const PaintResult({required this.paintedSegmentIds, required this.newlyPainted, required this.discovered});

  /// 트랙에 닿은 구간 전체 (이미 칠한 것 포함)
  final Set<String> paintedSegmentIds;

  /// 이번에 처음 칠한 구간
  final Set<String> newlyPainted;

  /// 이번에 획득한 코스 (연출 대상)
  final List<CourseSummary> discovered;

  static const empty = PaintResult(paintedSegmentIds: {}, newlyPainted: {}, discovered: []);
}

/// 트랙 → 닿은 구간을 칠하고, 구간이 다 칠해진 코스를 획득 처리한다 (산책노트 코어 루프).
///
/// 구간 판정: 구간 폴리라인 점의 [segmentRatio] 이상이 트랙 [radiusM] 안에 있으면 칠함.
/// 코스 판정: 코스 구간 중 칠해진 비율이 [courseRatio] 이상이면 획득. 안전 원칙상 자동 판정이지만
/// 사용자는 종료 시 "기록 저장"을 한 번 확인한다.
class PaintTrack {
  const PaintTrack(this._paint, this._trails, this._courses);

  final PaintRepository _paint;
  final GetTrailNetwork _trails;
  final GetCourseSummaries _courses;

  static const radiusM = 40.0;
  static const segmentRatio = 0.6;
  static const courseRatio = 0.9;

  Future<PaintResult> call({required String hikeId, required List<GeoPoint> track}) async {
    if (track.length < 2) return PaintResult.empty;
    final segments = await _trails();
    final touched = _touchedSegments(segments, track);
    final now = DateTime.now();
    final newly = await _paint.paint([
      for (final s in touched) PaintedSegment(segmentId: s.segmentId, mountainGroup: s.mountainGroup, hikeId: hikeId, paintedAt: now),
    ]);

    // 코스 획득: 전체 칠한 구간 기준으로 다시 본다 (이전 산행에서 칠한 것과 합쳐서)
    final allPainted = await _paint.paintedSegmentIds();
    final already = await _paint.discoveredCourseIds();
    final discovered = <CourseSummary>[];
    for (final c in await _courses()) {
      if (already.contains(c.course.courseId) || c.course.segmentIds.isEmpty) continue;
      final hit = c.course.segmentIds.where(allPainted.contains).length;
      if (hit / c.course.segmentIds.length >= courseRatio) discovered.add(c);
    }
    if (discovered.isNotEmpty) {
      await _paint.discover([
        for (final c in discovered) DiscoveredCourse(courseId: c.course.courseId, hikeId: hikeId, discoveredAt: now),
      ]);
    }
    debugPrint('[paint] 닿은 구간 ${touched.length} · 새로 칠함 ${newly.length} · 획득 코스 ${discovered.map((c) => c.course.name).toList()}');
    return PaintResult(
      paintedSegmentIds: touched.map((s) => s.segmentId).toSet(),
      newlyPainted: newly,
      discovered: discovered,
    );
  }

  /// 트랙 격자 인덱스로 각 구간의 근접 비율 계산
  static List<TrailSegment> _touchedSegments(List<TrailSegment> segments, List<GeoPoint> track) {
    const cell = 0.00045; // ≈ 50m
    final grid = <(int, int), List<GeoPoint>>{};
    var minLat = double.infinity, maxLat = -double.infinity, minLon = double.infinity, maxLon = -double.infinity;
    for (final p in track) {
      grid.putIfAbsent(((p.lat / cell).floor(), (p.lon / cell).floor()), () => []).add(p);
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLon = math.min(minLon, p.lon);
      maxLon = math.max(maxLon, p.lon);
    }
    final pad = (radiusM + 50) / 111000;
    bool near(GeoPoint c) {
      final ci = (c.lat / cell).floor(), cj = (c.lon / cell).floor();
      for (var di = -1; di <= 1; di++) {
        for (var dj = -1; dj <= 1; dj++) {
          for (final p in grid[(ci + di, cj + dj)] ?? const <GeoPoint>[]) {
            if (distanceKm(c, p) * 1000 <= radiusM) return true;
          }
        }
      }
      return false;
    }

    final out = <TrailSegment>[];
    for (final s in segments) {
      if (s.polyline.isEmpty) continue;
      // 트랙 범위 밖 구간은 빠르게 제외
      final first = s.polyline.first;
      if (first.lat < minLat - pad || first.lat > maxLat + pad || first.lon < minLon - pad || first.lon > maxLon + pad) {
        final last = s.polyline.last;
        if (last.lat < minLat - pad || last.lat > maxLat + pad || last.lon < minLon - pad || last.lon > maxLon + pad) continue;
      }
      final hit = s.polyline.where(near).length;
      if (hit / s.polyline.length >= segmentRatio) out.add(s);
    }
    return out;
  }
}

final paintTrackProvider = Provider<PaintTrack>((ref) => PaintTrack(
      ref.watch(paintRepositoryProvider),
      ref.watch(getTrailNetworkProvider),
      ref.watch(getCourseSummariesProvider),
    ));
