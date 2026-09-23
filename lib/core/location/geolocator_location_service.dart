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
  ///
  /// 항상 가장 촘촘한 설정(3초/3m) 하나로만 구독한다. 백그라운드에서 절약하려고
  /// 취소→재구독을 하면 Android는 포그라운드 서비스가 백그라운드에서 다시 시작돼 막히고
  /// (12+ ForegroundServiceStartNotAllowedException, 10+ while-in-use 제한),
  /// iOS는 업데이트가 끊긴 순간 앱이 서스펜드돼 재구독이 실행되지 않는다.
  /// → 결과적으로 백그라운드 동안 점이 하나도 안 찍힌다. 솎아내기는 저장하는 쪽에서 한다.
  @override
  Stream<GeoPoint> positions() {
    const dense = TrackingProfile.foreground;
    final settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: dense.distanceM,
          intervalDuration: dense.interval,
          // 기록 시작(앱이 보이는 상태)에 켜져서 종료까지 살아 있어야 하는 서비스.
          // 이 알림이 곧 "기록 중" 표시다 — setOngoing 으로 스와이프해 지울 수 없게 한다.
          // Android 13+ 에서는 알림 권한이 있어야 보인다 (Notifications.ensurePermission).
          // 문구는 구독 시점에 고정된다: 거리·시간을 실시간으로 넣으려면 스트림을 다시 구독해야 하는데,
          // 백그라운드 재구독은 위치를 끊어먹으므로 하지 않는다 (positions 주석 참고).
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: '산책 기록 중',
            notificationText: '걸은 길을 그리고 있어요. 종료는 앱에서 눌러주세요.',
            notificationChannelName: '산책 기록',
            notificationIcon: AndroidResource(name: 'ic_stat_sannote'),
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      TargetPlatform.iOS => AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: dense.distanceM,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        ),
      _ => LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: dense.distanceM),
    };
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((p) => (lat: p.latitude, lon: p.longitude));
  }
}
