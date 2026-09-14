import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../geo/geo_point.dart';
import 'geolocator_location_service.dart';
import 'location_service.dart';
import 'mock_location_service.dart';

/// 디버그 전용: `--dart-define=SANNOTE_LOCATION=mock` 이면 Mock(서울시청)으로 시작 (시뮬레이터 테스트용)
const _debugLocation = String.fromEnvironment('SANNOTE_LOCATION');

/// 현재 활성 위치 서비스. 릴리즈는 항상 실제 GPS. 디버그에서만 개발자 메뉴로 mock 전환 가능.
class LocationServiceNotifier extends Notifier<LocationService> {
  @override
  LocationService build() {
    if (kDebugMode && _debugLocation == 'mock') {
      return MockLocationService.fixed(MockLocationService.seoulCityHall);
    }
    return const GeolocatorLocationService();
  }

  void useReal() => state = const GeolocatorLocationService();

  void useMockFixed([GeoPoint point = MockLocationService.seoulCityHall]) {
    if (!kDebugMode) return;
    state = MockLocationService.fixed(point);
  }

  /// 코스 폴리라인 재생. speedFactor 60 = 1시간 산행을 1분에.
  void useMockRoute(List<GeoPoint> route, {String label = 'Mock · 코스 재생', double speedFactor = 60}) {
    if (!kDebugMode) return;
    state = MockLocationService.route(route, speedFactor: speedFactor, label: label);
  }

  bool get isMock => state is MockLocationService;
}

final locationServiceProvider =
    NotifierProvider<LocationServiceNotifier, LocationService>(LocationServiceNotifier.new);
