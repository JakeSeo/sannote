import '../../../../core/geo/geo_point.dart';

/// 산악구조 위치표지판 (safety_points). 2016년 데이터 → 실물 검증 전까지 "참고용"으로만 표시.
class SafetyPoint {
  const SafetyPoint({
    required this.safetyId,
    required this.mountainGroup,
    required this.markerType,
    required this.markerNo,
    required this.agency,
    required this.locationDesc,
    required this.position,
  });

  final String safetyId;
  final String mountainGroup;
  final String? markerType;

  /// 119 신고 시 말하는 번호 (예: 2-1)
  final String? markerNo;
  final String? agency;
  final String? locationDesc;
  final GeoPoint position;
}
