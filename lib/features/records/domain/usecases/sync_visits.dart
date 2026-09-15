import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_service.dart';
import '../../data/repositories/hike_repository_impl.dart';
import '../../data/repositories/visit_repository_impl.dart';
import '../repositories/hike_repository.dart';
import '../repositories/visit_repository.dart';

/// 완주했지만 아직 서버에 없는 산행을 visits로 전송 (메타데이터만).
/// 오프라인/로그인 실패면 그대로 대기시키고 다음 기회에 재시도한다.
class SyncVisits {
  const SyncVisits(this._hikes, this._visits, this._auth);

  final HikeRepository _hikes;
  final VisitRepository _visits;
  final AuthService _auth;

  /// 전송 성공 건수. 로그인 불가면 -1.
  Future<int> call() async {
    final pending = (await _hikes.getAll()).where((h) => h.needsSync).toList();
    if (pending.isEmpty) return 0;
    final userId = await _auth.ensureSession();
    if (userId == null) {
      debugPrint('[sync] 익명 세션 없음 → ${pending.length}건 대기');
      return -1;
    }
    var ok = 0;
    for (final h in pending) {
      try {
        final visitId = await _visits.insert(
          userId: userId,
          courseId: h.courseId!,
          visitedAt: h.startedAt,
          durationMin: h.durationMin,
        );
        await _hikes.markSynced(h.id, visitId: visitId, syncedAt: DateTime.now());
        ok++;
      } catch (e) {
        debugPrint('[sync] visits 전송 실패(${h.displayName}): $e');
      }
    }
    debugPrint('[sync] visits 전송 $ok/${pending.length}건');
    return ok;
  }
}

final syncVisitsProvider = Provider<SyncVisits>((ref) => SyncVisits(
      ref.watch(hikeRepositoryProvider),
      ref.watch(visitRepositoryProvider),
      ref.watch(authServiceProvider),
    ));
