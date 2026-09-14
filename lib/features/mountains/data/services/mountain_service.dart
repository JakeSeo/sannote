import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Supabase mountains 테이블 접근. 원시 행(Map)만 다룬다.
class MountainService {
  const MountainService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAll() =>
      _client.from('mountains').select().order('mountain_group');
}

final mountainServiceProvider = Provider<MountainService>(
  (ref) => MountainService(ref.watch(supabaseClientProvider)),
);
