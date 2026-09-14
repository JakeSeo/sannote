import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Supabase spots / entrances(뷰) / entrance_access 접근.
class SpotService {
  const SpotService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchEntrances() =>
      _client.from('entrances').select().order('spot_id');

  Future<List<Map<String, dynamic>>> fetchSpotsOfMountain(String group) =>
      _client.from('spots').select().eq('mountain_group', group).order('spot_id');

  /// entrance_access 테이블은 마이그레이션(supabase/migrations) 적용 전엔 없을 수 있다 → 빈 목록.
  Future<List<Map<String, dynamic>>> fetchEntranceAccess(String group) async {
    try {
      return await _client.from('entrance_access').select().eq('mountain_group', group);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') {
        debugPrint('[supabase] entrance_access 테이블 없음 (마이그레이션 미적용) → 접근 정보 생략');
        return const [];
      }
      rethrow;
    }
  }
}

final spotServiceProvider = Provider<SpotService>(
  (ref) => SpotService(ref.watch(supabaseClientProvider)),
);
