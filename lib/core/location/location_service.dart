import '../geo/geo_point.dart';

/// 위치 스트림 추상화. 실제 GPS(geolocator)와 [MockLocationService]를 교체 가능하게 한다.
/// GPS 관련 기능은 전부 mock으로 책상에서 테스트할 수 있어야 함 (CLAUDE.md).
abstract interface class LocationService {
  /// 현재 위치 1회. 권한 팝업 없이, 이미 허용된 경우에만 값을 준다.
  Future<GeoPoint?> current();

  /// 현재 위치 1회. 권한이 없으면 요청(팝업)한다. 지도 홈처럼 맥락이 분명한 곳에서만 부른다.
  Future<GeoPoint?> currentWithPermission();

  /// 위치 변화 스트림 (M4 기록용).
  Stream<GeoPoint> positions();

  /// 사람이 읽는 소스 이름 (개발자 메뉴 표시용)
  String get label;
}
