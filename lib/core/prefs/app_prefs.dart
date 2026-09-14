import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 작은 설정값 전용 (shared_preferences). 트랙·기록 데이터는 여기 넣지 않는다 (drift).
class AppPrefs {
  const AppPrefs(this._p);

  final SharedPreferencesAsync _p;

  static const _locationOptIn = 'location_opt_in';

  /// 사용자가 탐색 탭에서 [내 위치 사용]을 눌러 위치를 허용한 적이 있는지.
  /// true면 다음 실행부터 거리순 기준 위치를 자동으로 읽는다 (권한 팝업은 뜨지 않음 — 이미 허용된 경우만 읽음).
  Future<bool> get locationOptIn async => await _p.getBool(_locationOptIn) ?? false;
  Future<void> setLocationOptIn(bool v) => _p.setBool(_locationOptIn, v);
}

final appPrefsProvider = Provider<AppPrefs>((_) => AppPrefs(SharedPreferencesAsync()));
