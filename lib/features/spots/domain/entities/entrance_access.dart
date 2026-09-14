/// 입구 접근 정보 (entrance_access 테이블). 운영자가 답사/로드뷰로 채운다. 없는 입구가 대부분.
class EntranceAccess {
  const EntranceAccess({
    required this.spotId,
    required this.stationName,
    required this.line,
    required this.walkMin,
    required this.note,
  });

  final String spotId;

  /// 예: 아차산역
  final String stationName;

  /// 예: 5호선
  final String? line;

  /// 역 출구에서 입구까지 도보 예상 분
  final int walkMin;
  final String? note;
}
