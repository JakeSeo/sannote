import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 기록 중 상시 알림(Android 포그라운드 서비스 알림) 권한.
///
/// Android 13+ 는 POST_NOTIFICATIONS 를 런타임에 받아야 알림이 보인다.
/// 권한이 없어도 서비스와 기록은 그대로 돌아간다 — 사용자에게 "기록 중"이 안 보일 뿐이다.
/// iOS·Android 12 이하는 항상 true.
class Notifications {
  const Notifications();

  static const _channel = MethodChannel('sannote/notifications');

  /// 이미 허용돼 있는지만 확인 (팝업 없음)
  Future<bool> hasPermission() => _invoke('hasPermission');

  /// 없으면 요청(팝업). 기록 시작처럼 맥락이 분명한 곳에서만 부른다.
  Future<bool> ensurePermission() => _invoke('ensurePermission');

  Future<bool> _invoke(String method) async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      debugPrint('[noti] $method 실패: $e');
      return false;
    }
  }
}

final notificationsProvider = Provider<Notifications>((_) => const Notifications());
