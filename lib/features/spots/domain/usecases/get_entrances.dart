import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/test_data.dart';
import '../../data/repositories/spot_repository_impl.dart';
import '../entities/spot.dart';
import '../repositories/spot_repository.dart';

class GetEntrances {
  const GetEntrances(this._repo);

  final SpotRepository _repo;

  Future<List<Spot>> call() async =>
      (await _repo.getEntrances()).where((e) => TestData.show(e.mountainGroup)).toList(growable: false);
}

final getEntrancesProvider = Provider<GetEntrances>(
  (ref) => GetEntrances(ref.watch(spotRepositoryProvider)),
);
