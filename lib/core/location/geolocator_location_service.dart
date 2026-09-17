import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../geo/geo_point.dart';
import 'location_service.dart';

/// geolocator 기반 실제 GPS. 릴리즈 빌드에서는 이것만 쓴다.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  String get label => '실제 GPS (geolocator)';

  /// 권한 확인·요청. 거부되면 false. UI는 이 결과로 안내 문구를 띄운다.
  static Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('[gps] 위치 서비스 꺼짐');
      return false;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    final ok = p == LocationPermission.always || p == LocationPermission.whileInUse;
    if (!ok) debugPrint('[gps] 위치 권한 없음: $p');
    return ok;
  }

  /// 이미 허용된 권한이 있는지만 확인 (팝업 없음).
  static Future<bool> hasPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// 권한 팝업을 띄우지 않는다. 맥락 없는 시작 직후 요청을 피하기 위해 요청은 [ensurePermission]으로 분리.
  @override
  Future<GeoPoint?> current() async {
    if (!await hasPermission()) return null;
    return _read();
  }

  @override
  Future<GeoPoint?> currentWithPermission() async {
    if (!await ensurePermission()) return null;
    return _read();
  }

  Future<GeoPoint?> _read() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return (lat: p.latitude, lon: p.longitude);
    } catch (e) {
      debugPrint('[gps] 현재 위치 실패: $e');
      return null;
    }
  }

  /// 기록용 스트림. 화면 꺼져도 유지 (Android 포그라운드 서비스 / iOS 백그라운드 위치).
  @override
  Stream<GeoPoint> positions({TrackingProfile profile = TrackingProfile.foreground}) {
    final settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: profile.distanceM,
          intervalDuration: profile.interval,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: '산노트 기록 중',
            notificationText: '산행 트랙을 기록하고 있어요. 종료는 앱에서 눌러주세요.',
            enableWakeLock: true,
          ),
        ),
      TargetPlatform.iOS => AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: profile.distanceM,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        ),
      _ => LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: profile.distanceM),
    };
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((p) => (lat: p.latitude, lon: p.longitude));
  }
}
