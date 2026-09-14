import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mountain_repository.dart';
import '../domain/mountain.dart';

/// 산군 목록. 에러는 UI에서 스낵바로 안내하고 상세는 콘솔에 남긴다.
final mountainsProvider = FutureProvider<List<Mountain>>((ref) async {
  try {
    final mountains = await ref.watch(mountainRepositoryProvider).fetchAll();
    debugPrint('[supabase] mountains ${mountains.length}건 로드');
    for (final m in mountains) {
      debugPrint('[supabase]   $m');
    }
    return mountains;
  } catch (e, st) {
    debugPrint('[supabase] mountains 조회 실패: $e\n$st');
    rethrow;
  }
});
