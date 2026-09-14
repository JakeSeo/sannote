import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/safety_repository_impl.dart';
import '../entities/safety_point.dart';
import '../repositories/safety_repository.dart';

class GetSafetyPoints {
  const GetSafetyPoints(this._repo);

  final SafetyRepository _repo;

  Future<List<SafetyPoint>> call(String mountainGroup) => _repo.getByMountain(mountainGroup);
}

final getSafetyPointsProvider = Provider<GetSafetyPoints>(
  (ref) => GetSafetyPoints(ref.watch(safetyRepositoryProvider)),
);
