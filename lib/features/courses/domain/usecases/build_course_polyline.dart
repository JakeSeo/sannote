import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../trails/domain/entities/trail_segment.dart';

/// 순서대로 나열된 구간을 하나의 폴리라인으로 이어붙인다.
///
/// 원본 구간의 좌표 방향은 진행 방향과 무관하므로, 앞 구간의 끝점과 더 가까운 쪽이
/// 시작이 되도록 구간을 뒤집어 연결한다. 노드 클러스터링 잔여로 생긴 수십 m 틈은 그대로 잇는다.
class BuildCoursePolyline {
  const BuildCoursePolyline();

  List<GeoPoint> call(List<TrailSegment> ordered) {
    final result = <GeoPoint>[];
    for (var i = 0; i < ordered.length; i++) {
      var pts = ordered[i].polyline;
      if (pts.isEmpty) continue;
      if (result.isEmpty) {
        // 첫 구간: 다음 구간과 가까운 끝이 뒤로 가도록 방향 결정
        if (ordered.length > 1 && ordered[1].polyline.isNotEmpty) {
          final next = ordered[1].polyline;
          final endToNext = _minToEnds(pts.last, next);
          final startToNext = _minToEnds(pts.first, next);
          if (startToNext < endToNext) pts = pts.reversed.toList();
        }
      } else {
        final prevEnd = result.last;
        if (distanceKm(prevEnd, pts.last) < distanceKm(prevEnd, pts.first)) {
          pts = pts.reversed.toList();
        }
      }
      result.addAll(pts);
    }
    return result;
  }

  static double _minToEnds(GeoPoint p, List<GeoPoint> other) {
    final a = distanceKm(p, other.first);
    final b = distanceKm(p, other.last);
    return a < b ? a : b;
  }
}

final buildCoursePolylineProvider = Provider<BuildCoursePolyline>((_) => const BuildCoursePolyline());
