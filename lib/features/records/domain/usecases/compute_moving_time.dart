import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../entities/track_point.dart';

/// 이동 시간: 연속 점 사이 간격 중 "실제로 움직인" 구간만 합산한다.
/// 위치는 5m 이상 이동할 때만 저장되므로 멈춰 있으면 점이 안 들어오고, 그 공백은 자동으로 빠진다.
/// 공백이 [maxGap]보다 길면 정지로 보고 제외한다 (GPS 끊김도 이동 시간에 넣지 않음).
class ComputeMovingTime {
  const ComputeMovingTime();

  static const maxGap = Duration(minutes: 2);
  static const minMoveM = 5.0;

  Duration call(List<TrackPoint> points) {
    var total = Duration.zero;
    for (var i = 1; i < points.length; i++) {
      total += step(points[i - 1].recordedAt, points[i - 1].position, points[i].recordedAt, points[i].position);
    }
    return total;
  }

  /// 한 구간이 이동 시간에 기여하는 양 (기록 중 실시간 누적에도 같은 규칙 사용)
  static Duration step(DateTime t0, GeoPoint p0, DateTime t1, GeoPoint p1) {
    final gap = t1.difference(t0);
    if (gap <= Duration.zero || gap > maxGap) return Duration.zero;
    if (distanceKm(p0, p1) * 1000 < minMoveM) return Duration.zero;
    return gap;
  }
}

final computeMovingTimeProvider = Provider<ComputeMovingTime>((_) => const ComputeMovingTime());
