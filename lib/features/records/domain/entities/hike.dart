enum HikeStatus {
  /// 기록 중
  recording,

  /// 사용자가 "완주"로 확인 → 코스 색칠 대상, visits 전송 대상
  completed,

  /// 일부만 걸음 → 기록은 남기되 색칠·전송 안 함
  partial,

  /// 사용자가 삭제 선택 (트랙은 지움)
  discarded;

  static HikeStatus parse(String s) => HikeStatus.values.firstWhere((v) => v.name == s, orElse: () => discarded);
}

/// 산행 1회 메타데이터. 트랙 좌표는 [TrackPoint]로 로컬에만 저장.
class Hike {
  const Hike({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.mountainGroup,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.distanceKm,
    required this.coverage,
    required this.syncedAt,
    required this.visitId,
  });

  final String id;
  final String courseId;
  final String courseName;
  final String mountainGroup;
  final DateTime startedAt;
  final DateTime? endedAt;
  final HikeStatus status;
  final double distanceKm;

  /// 코스 커버율 0~1 (종료 시 계산). null = 미계산
  final double? coverage;
  final DateTime? syncedAt;
  final String? visitId;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);
  int get durationMin => duration.inMinutes;
  bool get isCompleted => status == HikeStatus.completed;
  bool get needsSync => isCompleted && syncedAt == null;
}
