import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

class SafetyService {
  const SafetyService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchByMountain(String group) =>
      _client.from('safety_points').select().eq('mountain_group', group).order('marker_no');
}

final safetyServiceProvider = Provider<SafetyService>(
  (ref) => SafetyService(ref.watch(supabaseClientProvider)),
);
