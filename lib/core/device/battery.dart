import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 배터리 잔량(%) 조회. 개발용 소모 측정에 쓴다 (기록 시작/종료 로그·DB).
/// 알 수 없으면 null (시뮬레이터, 채널 미구현 등).
class Battery {
  const Battery();

  static const _channel = MethodChannel('sannote/battery');

  Future<int?> level() async {
    try {
      final v = await _channel.invokeMethod<int>('level');
      return v == null || v < 0 ? null : v;
    } catch (e) {
      debugPrint('[battery] 조회 실패: $e');
      return null;
    }
  }
}

final batteryProvider = Provider<Battery>((_) => const Battery());
