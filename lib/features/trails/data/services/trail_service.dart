import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Supabase segments 테이블 접근.
class TrailService {
  const TrailService(this._client);

  final SupabaseClient _client;

  /// PostgREST 기본 max-rows(1,000) 때문에 페이지로 나눠 전부 가져온다 (총 1,732행, 약 2MB).
  static const _pageSize = 1000;

  Future<List<Map<String, dynamic>>> fetchAllSegments() async {
    final result = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final rows = await _client
          .from('segments')
          .select('segment_id, mountain_group, park_flag, length_km, up_min, down_min, difficulty, polyline')
          .order('segment_id')
          .range(from, from + _pageSize - 1);
      result.addAll(rows);
      if (rows.length < _pageSize) break;
      from += _pageSize;
    }
    return result;
  }
}

final trailServiceProvider = Provider<TrailService>(
  (ref) => TrailService(ref.watch(supabaseClientProvider)),
);
