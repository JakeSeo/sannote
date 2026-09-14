import '../../../core/geo/geo_point.dart';

/// segments 테이블 1행 중 지도 렌더에 필요한 최소 필드.
class TrailSegment {
  const TrailSegment({
    required this.segmentId,
    required this.mountainGroup,
    required this.isPark,
    required this.lengthKm,
    required this.polyline,
  });

  final String segmentId;
  final String mountainGroup;

  /// park_flag=1: 공원 산책로형 (가로등·운동기구 근접 휴리스틱). 코스 구성 시 기본 제외.
  final bool isPark;
  final double? lengthKm;
  final List<GeoPoint> polyline;

  factory TrailSegment.fromJson(Map<String, dynamic> json) => TrailSegment(
        segmentId: json['segment_id'] as String,
        mountainGroup: json['mountain_group'] as String,
        isPark: (json['park_flag'] as num).toInt() == 1,
        lengthKm: switch (json['length_km']) {
          null => null,
          num n => n.toDouble(),
          String s => double.tryParse(s),
          _ => null,
        },
        polyline: geoPointsFromLonLatJson(json['polyline']),
      );
}
