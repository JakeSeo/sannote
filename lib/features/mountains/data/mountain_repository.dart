import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/mountain.dart';

class MountainRepository {
  MountainRepository(this._client);

  final SupabaseClient _client;

  /// 산군 전체 조회 (7건). 구간 수 많은 순.
  Future<List<Mountain>> fetchAll() async {
    final rows = await _client
        .from('mountains')
        .select()
        .order('segment_count', ascending: false);
    return rows.map(Mountain.fromJson).toList();
  }
}

final mountainRepositoryProvider = Provider<MountainRepository>(
  (ref) => MountainRepository(ref.watch(supabaseClientProvider)),
);
