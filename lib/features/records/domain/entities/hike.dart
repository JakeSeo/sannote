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
    this.pausedSec = 0,
    this.movingSec = 0,
  });

  final String id;

  /// null = 자유 산행 (코스 미확정)
  final String? courseId;
  final String? courseName;
  final String? mountainGroup;
  final DateTime startedAt;
  final DateTime? endedAt;
  final HikeStatus status;
  final double distanceKm;

  /// 코스 커버율 0~1 (종료 시 계산). null = 미계산
  final double? coverage;
  final DateTime? syncedAt;
  final String? visitId;

  /// 수동 일시정지 누적 초
  final int pausedSec;

  /// 이동 시간(초). 0이면(옛 기록·점 없음) 총 경과에서 일시정지를 뺀 값을 대신 쓴다
  final int movingSec;

  /// 총 경과 (시작~종료, 일시정지 제외)
  Duration get totalDuration => (endedAt ?? DateTime.now()).difference(startedAt) - Duration(seconds: pausedSec);

  /// 표시용 소요시간 = 이동 시간. 멈춰 있던 시간(도착 후 종료를 잊은 경우 등)은 빠진다
  Duration get duration => movingSec > 0 ? Duration(seconds: movingSec) : totalDuration;
  int get durationMin => duration.inMinutes;
  bool get hasCourse => courseId != null;
  String get displayName => courseName ?? '자유 산행';

  /// 완주 = 코스가 확정되고 사용자가 완주로 확인한 기록만
  bool get isCompleted => status == HikeStatus.completed && hasCourse;
  bool get needsSync => isCompleted && syncedAt == null;
}
