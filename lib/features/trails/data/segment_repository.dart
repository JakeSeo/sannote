import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/trail_segment.dart';

class SegmentRepository {
  SegmentRepository(this._client);

  final SupabaseClient _client;

  /// PostgREST 기본 max-rows(1,000) 때문에 페이지로 나눠 전부 가져온다 (총 1,732행, 약 2MB).
  static const _pageSize = 1000;

  Future<List<TrailSegment>> fetchAll() async {
    final result = <TrailSegment>[];
    var from = 0;
    while (true) {
      final rows = await _client
          .from('segments')
          .select('segment_id, mountain_group, park_flag, length_km, polyline')
          .order('segment_id')
          .range(from, from + _pageSize - 1);
      result.addAll(rows.map(TrailSegment.fromJson));
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return result;
  }
}

final segmentRepositoryProvider = Provider<SegmentRepository>(
  (ref) => SegmentRepository(ref.watch(supabaseClientProvider)),
);
