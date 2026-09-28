import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sannote/core/geo/geo_point.dart';
import 'package:sannote/features/records/domain/entities/track_point.dart';
import 'package:sannote/features/records/presentation/viewmodels/recording_view_model.dart';

/// 기록을 켜둔 채 잊었는지 판단하는 규칙.
/// 실측 기준: 2026-09-23 밤샘 기록에서 실내 GPS 드리프트가 77×92m 안에 머물렀다.
void main() {
  final now = DateTime(2026, 9, 28, 23, 0);
  const after = Duration(minutes: 30);
  const base = (lat: 37.6373, lon: 127.0421);

  /// [minutesAgo] 전부터 지금까지 [spreadM] 반경으로 흩어진 점들
  List<TrackPoint> fixes({required int minutesAgo, required double spreadM, int everySec = 12}) {
    final rand = math.Random(3);
    final out = <TrackPoint>[];
    for (var t = minutesAgo * 60; t >= 0; t -= everySec) {
      final dLat = (rand.nextDouble() * 2 - 1) * spreadM / 111000;
      final dLon = (rand.nextDouble() * 2 - 1) * spreadM / 88000;
      out.add(TrackPoint(
        recordedAt: now.subtract(Duration(seconds: t)),
        position: (lat: base.lat + dLat, lon: base.lon + dLon),
      ));
    }
    return out;
  }

  String? reason(List<TrackPoint> f) =>
      RecordingViewModel.forgottenReason(now: now, fixes: f, after: after);

  test('실내 드리프트로 제자리면 알린다 (밤샘 방치 사례)', () {
    expect(reason(fixes(minutesAgo: 40, spreadM: 50)), contains('같은 자리'));
  });

  test('위치가 30분째 하나도 없으면 알린다', () {
    // 창보다 오래된 점만 있는 상태 = 그 뒤로 신호 없음
    expect(reason(fixes(minutesAgo: 90, spreadM: 50, everySec: 60).take(30).toList()),
        contains('신호가 없어요'));
    expect(reason(const []), contains('신호가 없어요'));
  });

  test('걷고 있으면 알리지 않는다', () {
    // 30분간 약 1.5km 이동
    final walking = [
      for (var t = 40 * 60; t >= 0; t -= 12)
        TrackPoint(
          recordedAt: now.subtract(Duration(seconds: t)),
          position: (lat: base.lat + (40 * 60 - t) * 0.0000055, lon: base.lon),
        ),
    ];
    expect(reason(walking), isNull);
  });

  test('아직 30분치 기록이 없으면 판단을 미룬다', () {
    expect(reason(fixes(minutesAgo: 10, spreadM: 20)), isNull);
  });

  test('반경 경계: 150m 넘게 벗어난 점이 있으면 제자리가 아니다', () {
    final f = fixes(minutesAgo: 40, spreadM: 30);
    f.add(TrackPoint(
      recordedAt: now.subtract(const Duration(minutes: 5)),
      position: (lat: base.lat + 200 / 111000, lon: base.lon),
    ));
    f.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    expect(reason(f), isNull);
  });
}
