/// 홈 지도 헤더 "구간 47개 · 12.3km · 입구 5곳". 완주 코스들의 segment_ids 합집합 집계 (맵매칭 불필요).
/// 내 누적 숫자만 — 전체 대비 분모/진행률은 표시하지 않는다.
class ConquestStats {
  const ConquestStats({
    required this.completedSegmentIds,
    required this.totalKm,
    required this.entranceCount,
    required this.completedHikeCount,
    required this.mountainGroups,
  });

  static const empty = ConquestStats(
    completedSegmentIds: {},
    totalKm: 0,
    entranceCount: 0,
    completedHikeCount: 0,
    mountainGroups: {},
  );

  final Set<String> completedSegmentIds;
  final double totalKm;
  final int entranceCount;
  final int completedHikeCount;

  /// 다녀온 산군 (스탬프)
  final Set<String> mountainGroups;

  int get segmentCount => completedSegmentIds.length;
  bool get isEmpty => completedSegmentIds.isEmpty;
}
