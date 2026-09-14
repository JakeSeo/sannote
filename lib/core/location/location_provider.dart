import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';
import 'mock_location_service.dart';

/// 현재 활성 위치 서비스. 실제 GPS 구현(geolocator)은 패키지 승인 후 추가하고,
/// 디버그 빌드의 개발자 메뉴에서만 mock ↔ 실제를 전환한다 (릴리즈는 실제만).
class LocationServiceNotifier extends Notifier<LocationService> {
  @override
  LocationService build() => MockLocationService.fixed(MockLocationService.seoulCityHall);

  void use(LocationService service) => state = service;
}

final locationServiceProvider =
    NotifierProvider<LocationServiceNotifier, LocationService>(LocationServiceNotifier.new);
