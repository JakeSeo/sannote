import '../geo/geo_point.dart';

/// 기록 간격 프로필. GPS 칩은 어느 쪽이든 계속 켜져 있어 배터리 차이는 작고,
/// 저장 점 수와 화면 갱신 빈도만 다르다.
enum TrackingProfile {
  /// 화면 켜짐: 실시간으로 선이 자라는 게 보이도록 촘촘히
  foreground(interval: Duration(seconds: 3), distanceM: 3),

  /// 화면 꺼짐: 보는 사람이 없으니 점 수를 절제
  background(interval: Duration(seconds: 12), distanceM: 5);

  const TrackingProfile({required this.interval, required this.distanceM});
  final Duration interval;
  final int distanceM;
}

/// 위치 스트림 추상화. 실제 GPS(geolocator)와 [MockLocationService]를 교체 가능하게 한다.
/// GPS 관련 기능은 전부 mock으로 책상에서 테스트할 수 있어야 함 (CLAUDE.md).
abstract interface class LocationService {
  /// 현재 위치 1회. 권한 팝업 없이, 이미 허용된 경우에만 값을 준다.
  Future<GeoPoint?> current();

  /// 현재 위치 1회. 권한이 없으면 요청(팝업)한다. 지도 홈처럼 맥락이 분명한 곳에서만 부른다.
  Future<GeoPoint?> currentWithPermission();

  /// 위치 변화 스트림 (M4 기록용). [profile]로 전경(촘촘)/배경(느슨) 간격을 고른다.
  Stream<GeoPoint> positions({TrackingProfile profile = TrackingProfile.foreground});

  /// 사람이 읽는 소스 이름 (개발자 메뉴 표시용)
  String get label;
}
