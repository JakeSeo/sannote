import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';

/// 트랙이 코스를 얼마나 덮었는지 (0~1). 코스 폴리라인 점 중 트랙 [radiusM] 이내에 있는 비율.
/// 완주 여부는 이 값으로 "제안"만 하고 최종 판정은 사용자가 한다 (안전 원칙: 자동 판정엔 수동 확인).
class ComputeCourseCoverage {
  const ComputeCourseCoverage();

  static const suggestCompleteAt = 0.8;

  double call(List<GeoPoint> course, List<GeoPoint> track, {double radiusM = 40}) {
    if (course.isEmpty || track.isEmpty) return 0;
    // 트랙을 격자(약 50m)로 인덱싱해 O(n·m)을 피한다
    const cell = 0.00045; // ≈ 50m
    final grid = <(int, int), List<GeoPoint>>{};
    for (final p in track) {
      grid.putIfAbsent(((p.lat / cell).floor(), (p.lon / cell).floor()), () => []).add(p);
    }
    var covered = 0;
    for (final c in course) {
      final ci = (c.lat / cell).floor(), cj = (c.lon / cell).floor();
      var hit = false;
      for (var di = -1; di <= 1 && !hit; di++) {
        for (var dj = -1; dj <= 1 && !hit; dj++) {
          for (final p in grid[(ci + di, cj + dj)] ?? const <GeoPoint>[]) {
            if (distanceKm(c, p) * 1000 <= radiusM) {
              hit = true;
              break;
            }
          }
        }
      }
      if (hit) covered++;
    }
    return math.min(1, covered / course.length);
  }
}

final computeCourseCoverageProvider = Provider<ComputeCourseCoverage>((_) => const ComputeCourseCoverage());
