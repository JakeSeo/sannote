import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/test_data.dart';
import '../../data/repositories/trail_repository_impl.dart';
import '../entities/trail_segment.dart';
import '../repositories/trail_repository.dart';

/// 등산로망 전체 조회. 좌표 2개 미만인 구간(그릴 수 없음)은 제외.
class GetTrailNetwork {
  const GetTrailNetwork(this._repo);

  final TrailRepository _repo;

  Future<List<TrailSegment>> call() async {
    final all = await _repo.getAllSegments();
    return all.where((s) => s.polyline.length >= 2 && TestData.show(s.mountainGroup)).toList(growable: false);
  }
}

final getTrailNetworkProvider = Provider<GetTrailNetwork>(
  (ref) => GetTrailNetwork(ref.watch(trailRepositoryProvider)),
);
