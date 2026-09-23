import '../geo/geo_point.dart';

/// 기록 간격 프로필. GPS 칩은 어느 쪽이든 계속 켜져 있어 배터리 차이는 작고,
/// **저장하는 점 수만** 다르다.
///
/// 주의: 이 프로필은 플랫폼 위치 스트림 설정이 아니라 Dart 쪽 솎아내기 기준이다.
/// 기록 중에 플랫폼 스트림을 다시 구독하면 백그라운드에서 위치가 끊기기 때문
/// ([LocationService.positions] 주석 참고).
enum TrackingProfile {
  /// 화면 켜짐: 실시간으로 선이 자라는 게 보이도록 들어오는 점을 그대로 저장
  foreground(interval: Duration(seconds: 3), distanceM: 3),

  /// 화면 꺼짐: 보는 사람이 없으니 점 수를 절제 (12초 & 5m 이상일 때만 저장)
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

  /// 위치 변화 스트림 (M4 기록용). 가장 촘촘한 간격으로 계속 흘려보낸다.
  ///
  /// **기록 중에는 절대 취소했다 다시 구독하지 말 것.** 백그라운드에서 재구독하면
  /// Android는 포그라운드 서비스를 백그라운드에서 다시 시작하는 꼴이라 막히고(12+),
  /// iOS는 업데이트가 끊긴 순간 앱이 서스펜드돼 재구독 자체가 실행되지 않는다.
  /// 저장 간격 조절은 [TrackingProfile]로 받는 쪽에서 솎아낸다.
  Stream<GeoPoint> positions();

  /// 사람이 읽는 소스 이름 (개발자 메뉴 표시용)
  String get label;
}
