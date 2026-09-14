import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/spot_repository_impl.dart';
import '../entities/spot.dart';
import '../repositories/spot_repository.dart';

/// 산군의 스팟 전체 조회.
class GetMountainSpots {
  const GetMountainSpots(this._repo);

  final SpotRepository _repo;

  Future<List<Spot>> call(String mountainGroup) => _repo.getSpotsOfMountain(mountainGroup);
}

final getMountainSpotsProvider = Provider<GetMountainSpots>(
  (ref) => GetMountainSpots(ref.watch(spotRepositoryProvider)),
);
