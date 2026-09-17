import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

/// 디버그 전용: `--dart-define=SANNOTE_THEME=dawn` 으로 시작 시안 지정 (스크린샷용)
const _debugTheme = String.fromEnvironment('SANNOTE_THEME');

/// 현재 테마. 기본은 확정안 forest. 디버그 빌드에서만 비교용 시안으로 전환 가능.
class ThemeVariantNotifier extends Notifier<ThemeVariant> {
  @override
  ThemeVariant build() {
    if (kDebugMode && _debugTheme.isNotEmpty) {
      return ThemeVariant.values.where((v) => v.name == _debugTheme).firstOrNull ?? ThemeVariant.forest;
    }
    return ThemeVariant.sketchInk; // 산책노트 기본: 스케치북(진). 연/진은 획득 연출 보고 최종 결정
  }

  void set(ThemeVariant v) => state = v;
}

final themeVariantProvider = NotifierProvider<ThemeVariantNotifier, ThemeVariant>(ThemeVariantNotifier.new);
