import '../../../../core/geo/geo_point.dart';

/// segments 테이블 1행 중 지도 렌더·코스 합산에 필요한 필드.
class TrailSegment {
  const TrailSegment({
    required this.segmentId,
    required this.mountainGroup,
    required this.isPark,
    required this.lengthKm,
    required this.upMin,
    required this.downMin,
    required this.difficulty,
    required this.polyline,
  });

  final String segmentId;
  final String mountainGroup;

  /// park_flag=1: 공원 산책로형 (가로등·운동기구 근접 휴리스틱). 코스 구성 시 기본 제외.
  final bool isPark;
  final double? lengthKm;

  /// 원본 데이터의 오름/내림 예상 소요시간(분). 실측 아님 → 항상 "예상"으로 표기.
  final int? upMin;
  final int? downMin;

  /// 원본 표기 그대로: 쉬움 / 중간 / 어려움 (null 가능)
  final String? difficulty;
  final List<GeoPoint> polyline;

  GeoPoint? get start => polyline.isEmpty ? null : polyline.first;
  GeoPoint? get end => polyline.isEmpty ? null : polyline.last;
}
