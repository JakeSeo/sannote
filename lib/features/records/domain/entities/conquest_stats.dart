/// 홈 시트 통계. 내가 칠한 구간 집합 기준 (산책노트 피벗: 구간 단위 색칠). completedHikeCount = 획득 코스 수.
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
