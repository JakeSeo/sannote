import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Supabase visits 테이블. 메타데이터만 다룬다.
class VisitService {
  const VisitService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> insert(Map<String, dynamic> row) async {
    final rows = await _client.from('visits').insert(row).select();
    return rows.first;
  }

  /// 코스별 완주자 수. RPC(course_completion_counts, 마이그레이션 0002)가 있으면 그것을,
  /// 없으면 visits를 직접 읽어 집계 (RLS 잠금 전까지만 동작).
  Future<Map<String, int>> completionCounts() async {
    try {
      final rows = await _client.rpc('course_completion_counts') as List;
      return {for (final r in rows) r['course_id'] as String: (r['count'] as num).toInt()};
    } on PostgrestException catch (e) {
      debugPrint('[supabase] course_completion_counts RPC 없음(${e.code}) → visits 직접 집계');
    }
    final rows = await _client.from('visits').select('course_id');
    final counts = <String, int>{};
    for (final r in rows) {
      final id = r['course_id'] as String?;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }
}

final visitServiceProvider = Provider<VisitService>((ref) => VisitService(ref.watch(supabaseClientProvider)));
