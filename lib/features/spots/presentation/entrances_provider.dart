import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/spot_repository.dart';
import '../domain/spot.dart';

final entrancesProvider = FutureProvider<List<Spot>>((ref) async {
  try {
    final entrances = await ref.watch(spotRepositoryProvider).fetchEntrances();
    debugPrint('[supabase] entrances ${entrances.length}건 로드');
    return entrances;
  } catch (e, st) {
    debugPrint('[supabase] entrances 조회 실패: $e\n$st');
    rethrow;
  }
});
