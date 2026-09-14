import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Supabase spots / entrances(뷰) 접근.
class SpotService {
  const SpotService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchEntrances() =>
      _client.from('entrances').select().order('spot_id');
}

final spotServiceProvider = Provider<SpotService>(
  (ref) => SpotService(ref.watch(supabaseClientProvider)),
);
