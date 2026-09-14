import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/visit_repository_impl.dart';
import '../repositories/visit_repository.dart';

/// 코스별 총 완주자 수 (익명 집계). 표시 방식 결정: 정확한 수 그대로 (초기엔 작은 커뮤니티라 숨길 이유 없음).
class GetCompletionCounts {
  const GetCompletionCounts(this._repo);

  final VisitRepository _repo;

  Future<Map<String, int>> call() => _repo.completionCounts();
}

final getCompletionCountsProvider =
    Provider<GetCompletionCounts>((ref) => GetCompletionCounts(ref.watch(visitRepositoryProvider)));
