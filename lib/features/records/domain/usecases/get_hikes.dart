import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/hike_repository_impl.dart';
import '../entities/hike.dart';
import '../entities/track_point.dart';
import '../repositories/hike_repository.dart';

class GetHikes {
  const GetHikes(this._repo);

  final HikeRepository _repo;

  Stream<List<Hike>> watch() => _repo.watchAll();
  Future<List<Hike>> call() => _repo.getAll();
  Future<Hike?> byId(String id) => _repo.getById(id);
  Future<Hike?> active() => _repo.getActive();
  Future<List<TrackPoint>> points(String hikeId) => _repo.getPoints(hikeId);
}

final getHikesProvider = Provider<GetHikes>((ref) => GetHikes(ref.watch(hikeRepositoryProvider)));
