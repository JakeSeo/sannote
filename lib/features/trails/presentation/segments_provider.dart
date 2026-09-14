import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/segment_repository.dart';
import '../domain/trail_segment.dart';

/// 등산로 구간 전체. 앱 생명주기 동안 1회 로드 후 메모리 캐시.
final segmentsProvider = FutureProvider<List<TrailSegment>>((ref) async {
  try {
    final segments = await ref.watch(segmentRepositoryProvider).fetchAll();
    debugPrint('[supabase] segments ${segments.length}건 로드');
    return segments;
  } catch (e, st) {
    debugPrint('[supabase] segments 조회 실패: $e\n$st');
    rethrow;
  }
});
