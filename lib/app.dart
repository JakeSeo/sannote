import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/course_detail/presentation/views/course_detail_page.dart';
import 'features/mountain_detail/presentation/views/mountain_detail_page.dart';
import 'features/shell/home_shell.dart';

/// 디버그 전용 시작 화면 지정 (스크린샷·수동 테스트용).
/// 예) `--dart-define=SANNOTE_START=explore` / `mountain:아차산·용마산` / `course:{course_id}`
const _debugStart = String.fromEnvironment('SANNOTE_START');

class SannoteApp extends ConsumerWidget {
  const SannoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    return MaterialApp(
      title: '산노트',
      theme: AppTheme.of(variant),
      home: _home(),
    );
  }

  Widget _home() {
    if (kDebugMode && _debugStart.isNotEmpty) {
      final (kind, arg) = switch (_debugStart.indexOf(':')) {
        -1 => (_debugStart, ''),
        final i => (_debugStart.substring(0, i), _debugStart.substring(i + 1)),
      };
      switch (kind) {
        case 'explore':
          return const HomeShell(initialIndex: 1);
        case 'mountain':
          return MountainDetailPage(mountainGroup: arg);
        case 'course':
          return CourseDetailPage(courseId: arg);
      }
    }
    return const HomeShell();
  }
}
