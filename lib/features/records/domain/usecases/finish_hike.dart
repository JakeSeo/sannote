import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course.dart';
import '../../data/repositories/hike_repository_impl.dart';
import '../entities/hike.dart';
import '../entities/track_point.dart';
import '../repositories/hike_repository.dart';
import 'compute_moving_time.dart';

/// 종료: 거리 계산 + 사용자가 고른 상태(완주/일부/삭제)로 마감.
class FinishHike {
  const FinishHike(this._repo, this._movingTime);

  final HikeRepository _repo;
  final ComputeMovingTime _movingTime;

  /// [course]가 있으면 그 코스로 확정(자동 판별 결과 또는 미리 고른 코스). 없으면 자유 산행으로 남는다.
  Future<void> call(
    String hikeId, {
    required HikeStatus status,
    required double? coverage,
    Course? course,
    int pausedSec = 0,
    int? batteryStart,
    int? batteryEnd,
  }) async {
    if (status == HikeStatus.discarded) {
      await _repo.delete(hikeId);
      return;
    }
    final points = await _repo.getPoints(hikeId);
    await _repo.finish(
      hikeId,
      endedAt: DateTime.now(),
      status: status,
      distanceKm: trackDistanceKm(points),
      coverage: coverage,
      courseId: course?.courseId,
      courseName: course?.name,
      mountainGroup: course?.mountainGroup,
      pausedSec: pausedSec,
      movingSec: _movingTime(points).inSeconds,
      batteryStart: batteryStart,
      batteryEnd: batteryEnd,
    );
  }

  /// 정확도 50m 초과 점 제외, [minStepM] 미만 이동은 GPS 떨림으로 보고 합산하지 않는다.
  static const minStepM = 5.0;

  static double trackDistanceKm(List<TrackPoint> points) =>
      trackDistanceKmOf(points.where((p) => (p.accuracyM ?? 0) <= 50).map((p) => p.position));

  static double trackDistanceKmOf(Iterable<GeoPoint> positions) {
    GeoPoint? prev;
    var km = 0.0;
    for (final p in positions) {
      if (prev == null) {
        prev = p;
        continue;
      }
      final d = distanceKm(prev, p);
      if (d * 1000 < minStepM) continue; // 제자리 떨림: 기준점 유지
      km += d;
      prev = p;
    }
    return km;
  }
}

final finishHikeProvider = Provider<FinishHike>(
    (ref) => FinishHike(ref.watch(hikeRepositoryProvider), ref.watch(computeMovingTimeProvider)));
