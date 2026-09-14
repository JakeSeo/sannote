import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/spot.dart';

class SpotRepository {
  SpotRepository(this._client);

  final SupabaseClient _client;

  /// 입구(시종점) 전체. entrances 뷰 = spots where is_entrance=1 (286행).
  Future<List<Spot>> fetchEntrances() async {
    final rows = await _client.from('entrances').select().order('spot_id');
    return rows.map(Spot.fromJson).toList();
  }
}

final spotRepositoryProvider = Provider<SpotRepository>(
  (ref) => SpotRepository(ref.watch(supabaseClientProvider)),
);
