/// 서버(Supabase visits) — 메타데이터만. 트랙 좌표는 절대 올리지 않는다.
abstract interface class VisitRepository {
  /// 완주 기록 1건 전송 → visit_id
  Future<String> insert({
    required String userId,
    required String courseId,
    required DateTime visitedAt,
    required int durationMin,
  });

  /// 코스별 총 완주자 수 (익명 집계)
  Future<Map<String, int>> completionCounts();
}
