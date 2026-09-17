import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/hike_repository_impl.dart';
import '../entities/hike.dart';
import '../repositories/hike_repository.dart';
import 'compute_moving_time.dart';

/// 스키마 v4 이전에 저장된 기록(moving_sec=0)에 이동 시간을 계산해 채운다. 앱 시작 시 1회.
class BackfillMovingTime {
  const BackfillMovingTime(this._repo, this._movingTime);

  final HikeRepository _repo;
  final ComputeMovingTime _movingTime;

  Future<int> call() async {
    var n = 0;
    for (final h in await _repo.getAll()) {
      if (h.status == HikeStatus.recording || h.movingSec > 0) continue;
      final points = await _repo.getPoints(h.id);
      if (points.length < 2) continue;
      await _repo.updateMovingSec(h.id, _movingTime(points).inSeconds);
      n++;
    }
    if (n > 0) debugPrint('[records] 이동 시간 채움: $n건');
    return n;
  }
}

final backfillMovingTimeProvider = Provider<BackfillMovingTime>(
    (ref) => BackfillMovingTime(ref.watch(hikeRepositoryProvider), ref.watch(computeMovingTimeProvider)));
