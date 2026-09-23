import 'dart:async';
import 'dart:math' as math;

import '../geo/geo_point.dart';
import 'location_service.dart';

/// 고정 지점 또는 코스 폴리라인을 재생하는 가짜 위치 서비스.
///
/// - [MockLocationService.fixed]: 한 지점만 반환 (거리순 정렬 등 테스트)
/// - [MockLocationService.route]: polyline 좌표를 [interval] 간격으로 재생.
///   ±[noiseMeters] 노이즈와 [speedFactor] 배속 지원 (1시간 산행을 1분에 재생 → speedFactor 60).
class MockLocationService implements LocationService {
  MockLocationService.fixed(this._fixed, {this.label = 'Mock · 고정 지점'})
      : _route = const [],
        interval = Duration.zero,
        noiseMeters = 0,
        speedFactor = 1;

  MockLocationService.route(
    List<GeoPoint> route, {
    this.interval = const Duration(seconds: 15),
    this.noiseMeters = 10,
    this.speedFactor = 1,
    this.label = 'Mock · 코스 재생',
    double sampleSpacingM = 15,
  })  : _route = resample(route, sampleSpacingM),
        _fixed = route.isEmpty ? null : route.first;

  /// 폴리라인을 [spacingM] 간격 점으로 리샘플 (실제 GPS는 걷는 속도 × 간격만큼 떨어진 점을 준다).
  static List<GeoPoint> resample(List<GeoPoint> line, double spacingM) {
    if (line.length < 2 || spacingM <= 0) return List.of(line);
    final out = <GeoPoint>[line.first];
    var carry = 0.0; // 다음 샘플까지 남은 거리(m)
    for (var i = 1; i < line.length; i++) {
      final a = line[i - 1], b = line[i];
      final segM = distanceKm(a, b) * 1000;
      var pos = spacingM - carry;
      while (pos <= segM) {
        final t = pos / segM;
        out.add((lat: a.lat + (b.lat - a.lat) * t, lon: a.lon + (b.lon - a.lon) * t));
        pos += spacingM;
      }
      carry = segM - (pos - spacingM);
    }
    if (out.last != line.last) out.add(line.last);
    return out;
  }

  /// 서울시청. 실기기 GPS 붙이기 전 기본 기준 위치.
  static const seoulCityHall = (lat: 37.5666, lon: 126.9784);

  final GeoPoint? _fixed;
  final List<GeoPoint> _route;
  final Duration interval;
  final double noiseMeters;
  final double speedFactor;
  @override
  final String label;

  final _rand = math.Random(7);

  @override
  Future<GeoPoint?> current() async => _fixed;

  @override
  Future<GeoPoint?> currentWithPermission() async => _fixed;

  @override
  Stream<GeoPoint> positions() async* {
    if (_route.isEmpty) {
      if (_fixed != null) yield _fixed;
      return;
    }
    final tick = Duration(microseconds: (interval.inMicroseconds / speedFactor).round());
    for (final p in _route) {
      yield _jitter(p);
      await Future<void>.delayed(tick);
    }
  }

  GeoPoint _jitter(GeoPoint p) {
    if (noiseMeters <= 0) return p;
    // 1도 ≈ 111km (위도), 경도는 cos(lat) 보정
    final dLat = (_rand.nextDouble() * 2 - 1) * noiseMeters / 111000;
    final dLon = (_rand.nextDouble() * 2 - 1) * noiseMeters / (111000 * math.cos(p.lat * math.pi / 180));
    return (lat: p.lat + dLat, lon: p.lon + dLon);
  }
}
