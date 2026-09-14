import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/spot_repository_impl.dart';
import '../entities/entrance_access.dart';
import '../repositories/spot_repository.dart';

/// 산군 입구들의 지하철 접근 정보 → spot_id 로 조회할 수 있는 맵.
class GetEntranceAccess {
  const GetEntranceAccess(this._repo);

  final SpotRepository _repo;

  Future<Map<String, EntranceAccess>> call(String mountainGroup) async {
    final list = await _repo.getEntranceAccess(mountainGroup);
    return {for (final a in list) a.spotId: a};
  }
}

final getEntranceAccessProvider = Provider<GetEntranceAccess>(
  (ref) => GetEntranceAccess(ref.watch(spotRepositoryProvider)),
);
