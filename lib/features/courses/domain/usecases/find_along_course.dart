import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';

/// 코스 폴리라인에서 [radiusM] 이내에 있는 지점을 골라 코스 진행 순서대로 돌려준다.
/// 스팟(조망점/화장실/음수대)과 구조표지판 모두에 쓰는 범용 유즈케이스.
class FindAlongCourse {
  const FindAlongCourse();

  List<T> call<T>(
    List<GeoPoint> polyline,
    Iterable<T> items,
    GeoPoint Function(T) positionOf, {
    double radiusM = 60,
  }) {
    if (polyline.length < 2) return const [];
    final hits = <(int order, T item)>[];
    for (final item in items) {
      final p = positionOf(item);
      var best = double.infinity;
      var bestIdx = -1;
      for (var i = 0; i < polyline.length - 1; i++) {
        final d = _distToSegmentM(p, polyline[i], polyline[i + 1]);
        if (d < best) {
          best = d;
          bestIdx = i;
        }
      }
      if (best <= radiusM) hits.add((bestIdx, item));
    }
    hits.sort((a, b) => a.$1.compareTo(b.$1));
    return hits.map((h) => h.$2).toList(growable: false);
  }

  /// 점-선분 최단거리(m). 짧은 거리라 평면 근사(경도에 cos(lat) 보정).
  static double _distToSegmentM(GeoPoint p, GeoPoint a, GeoPoint b) {
    const mPerDegLat = 111320.0;
    final mPerDegLon = 111320.0 * math.cos(p.lat * math.pi / 180);
    final px = (p.lon - a.lon) * mPerDegLon, py = (p.lat - a.lat) * mPerDegLat;
    final bx = (b.lon - a.lon) * mPerDegLon, by = (b.lat - a.lat) * mPerDegLat;
    final len2 = bx * bx + by * by;
    final t = (len2 == 0 ? 0.0 : (px * bx + py * by) / len2).clamp(0.0, 1.0);
    final dx = px - t * bx, dy = py - t * by;
    return math.sqrt(dx * dx + dy * dy);
  }
}

final findAlongCourseProvider = Provider<FindAlongCourse>((_) => const FindAlongCourse());
