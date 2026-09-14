import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/courses/domain/usecases/get_course_summaries.dart';
import '../location/location_provider.dart';
import '../location/mock_location_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

/// 디버그 빌드에서만 노출되는 개발자 메뉴 (톤앤매너 전환, 위치 소스 확인).
/// 릴리즈 빌드에서는 [show]가 아무것도 하지 않는다.
abstract final class DeveloperMenu {
  static bool get available => kDebugMode;

  static Future<void> show(BuildContext context) {
    if (!available) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _DeveloperMenuSheet(),
    );
  }
}

Future<void> _pickCourseForMock(BuildContext context, WidgetRef ref) async {
  final summaries = await ref.read(getCourseSummariesProvider).call();
  if (!context.mounted) return;
  final picked = await showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('재생할 코스'),
      children: [
        for (final (i, s) in summaries.indexed)
          SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop(i), child: Text(s.course.name)),
      ],
    ),
  );
  if (picked == null) return;
  final s = summaries[picked];
  ref.read(locationServiceProvider.notifier).useMockRoute(s.polyline, label: 'Mock · ${s.course.name} 재생');
}

class _DeveloperMenuSheet extends ConsumerWidget {
  const _DeveloperMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    final location = ref.watch(locationServiceProvider);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text('개발자 메뉴 (디버그 전용)', style: text.titleMedium),
          const SizedBox(height: 12),
          Text('테마 (확정: 숲 · 비교용 전환)', style: text.labelLarge),
          RadioGroup<ThemeVariant>(
            groupValue: variant,
            onChanged: (nv) => nv == null ? null : ref.read(themeVariantProvider.notifier).set(nv),
            child: Column(
              children: [
                for (final v in ThemeVariant.values)
                  RadioListTile<ThemeVariant>(value: v, title: Text(v.label), subtitle: Text(v.summary)),
              ],
            ),
          ),
          const Divider(),
          Text('위치 소스 (현재: ${location.label})', style: text.labelLarge),
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('실제 GPS'),
            onTap: () => ref.read(locationServiceProvider.notifier).useReal(),
          ),
          ListTile(
            leading: const Icon(Icons.push_pin_outlined),
            title: const Text('Mock · 고정 지점 (서울시청)'),
            onTap: () => ref.read(locationServiceProvider.notifier).useMockFixed(),
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Mock · 코스 재생 (60배속, ±10m 노이즈)'),
            subtitle: const Text('코스를 고르면 그 폴리라인을 따라 위치가 흘러가요'),
            onTap: () => _pickCourseForMock(context, ref),
          ),
          Text('${location is MockLocationService ? 'Mock 사용 중' : '실제 GPS 사용 중'} · 릴리즈 빌드는 항상 실제 GPS', style: text.bodySmall),
        ],
      ),
    );
  }
}
