/// 입구 접근 정보 (entrance_access 테이블). 자동 추정(OSM 직선거리 기반)과 사람이 검증한 값이 섞여 있다.
class EntranceAccess {
  const EntranceAccess({
    required this.spotId,
    required this.stationName,
    required this.line,
    required this.walkMin,
    required this.exitNo,
    required this.isEstimate,
    required this.note,
  });

  final String spotId;

  /// 예: 아차산역
  final String stationName;

  /// 예: 5호선 (OSM 자동 추정에는 없음)
  final String? line;

  /// 역 출구에서 입구까지 도보 예상 분
  final int walkMin;

  /// 출구 번호 (예: "1"). 모르면 null
  final String? exitNo;

  /// true = 자동 추정값(검증 전). UI에 "추정" 표시
  final bool isEstimate;

  /// 사람이 적은 안내 (추정값의 내부용 비고는 제외)
  final String? note;
}
