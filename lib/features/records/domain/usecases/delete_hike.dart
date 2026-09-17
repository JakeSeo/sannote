import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/hike_repository_impl.dart';
import '../repositories/hike_repository.dart';
import '../repositories/paint_repository.dart';
import '../../data/repositories/paint_repository_impl.dart';

/// 산행 기록 삭제 (트랙 + 그 기록으로 칠한 구간·획득 코스). 서버에 이미 올라간 visits 메타데이터는 남는다.
class DeleteHike {
  const DeleteHike(this._repo, this._paint);

  final HikeRepository _repo;
  final PaintRepository _paint;

  Future<void> call(String hikeId) async {
    await _paint.removeByHike(hikeId);
    await _repo.delete(hikeId);
  }
}

final deleteHikeProvider = Provider<DeleteHike>((ref) => DeleteHike(ref.watch(hikeRepositoryProvider), ref.watch(paintRepositoryProvider)));
