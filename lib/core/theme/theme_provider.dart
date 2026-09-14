import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

/// 디버그 전용: `--dart-define=SANNOTE_THEME=dawn` 으로 시작 시안 지정 (스크린샷용)
const _debugTheme = String.fromEnvironment('SANNOTE_THEME');

/// 현재 톤앤매너 시안. 결정 후엔 기본값을 확정 시안으로 바꾸고 전환 UI를 제거한다.
class ThemeVariantNotifier extends Notifier<ThemeVariant> {
  @override
  ThemeVariant build() {
    if (kDebugMode && _debugTheme.isNotEmpty) {
      return ThemeVariant.values.where((v) => v.name == _debugTheme).firstOrNull ?? ThemeVariant.forest;
    }
    return ThemeVariant.forest;
  }

  void set(ThemeVariant v) => state = v;
}

final themeVariantProvider = NotifierProvider<ThemeVariantNotifier, ThemeVariant>(ThemeVariantNotifier.new);
