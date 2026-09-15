import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/hike_repository_impl.dart';
import '../repositories/hike_repository.dart';

/// 산행 기록 삭제 (트랙 포함). 서버에 이미 올라간 visits 메타데이터는 남는다 (익명 집계용).
class DeleteHike {
  const DeleteHike(this._repo);

  final HikeRepository _repo;

  Future<void> call(String hikeId) => _repo.delete(hikeId);
}

final deleteHikeProvider = Provider<DeleteHike>((ref) => DeleteHike(ref.watch(hikeRepositoryProvider)));
