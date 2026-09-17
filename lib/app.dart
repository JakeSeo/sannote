import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/dev/debug_auto_hike.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/map/presentation/views/map_home_page.dart';
import 'features/records/presentation/views/hike_detail_page.dart';
import 'features/records/presentation/views/records_page.dart';
import 'features/search/presentation/views/search_page.dart';
import 'features/settings/presentation/views/settings_page.dart';

/// 디버그 전용 시작 화면 지정 (스크린샷·수동 테스트용).
/// 예) `--dart-define=SANNOTE_START=records` / `mountain:아차산·용마산` / `course:{course_id}` / `autohike:...`
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
        case 'records':
          return const RecordsPage();
        case 'mountain':
          return MapHomePage(initialMountainGroup: arg);
        case 'course':
          return MapHomePage(initialCourseId: arg);
        case 'autohike':
          return DebugAutoHike(courseId: arg);
        case 'search':
          return const SearchPage();
        case 'settings':
          return const SettingsPage();
        case 'hike':
          return HikeDetailPage(hikeId: arg);
      }
    }
    return const MapHomePage();
  }
}
