import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/test_data.dart';
import '../../data/repositories/mountain_repository_impl.dart';
import '../entities/mountain.dart';
import '../repositories/mountain_repository.dart';

/// 산군 목록 조회. 구간 수 많은 순으로 정렬해 돌려준다.
class GetMountains {
  const GetMountains(this._repo);

  final MountainRepository _repo;

  Future<List<Mountain>> call() async {
    final list = (await _repo.getAll()).where((m) => TestData.show(m.mountainGroup)).toList();
    list.sort((a, b) => b.segmentCount.compareTo(a.segmentCount));
    return list;
  }
}

final getMountainsProvider = Provider<GetMountains>(
  (ref) => GetMountains(ref.watch(mountainRepositoryProvider)),
);
