import '../geo/geo_point.dart';

/// 위치 스트림 추상화. 실제 GPS(geolocator)와 [MockLocationService]를 교체 가능하게 한다.
/// GPS 관련 기능은 전부 mock으로 책상에서 테스트할 수 있어야 함 (CLAUDE.md).
abstract interface class LocationService {
  /// 현재 위치 1회. 권한이 없거나 알 수 없으면 null.
  Future<GeoPoint?> current();

  /// 위치 변화 스트림 (M4 기록용).
  Stream<GeoPoint> positions();

  /// 사람이 읽는 소스 이름 (개발자 메뉴 표시용)
  String get label;
}
