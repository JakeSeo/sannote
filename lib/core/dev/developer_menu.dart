import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../location/location_provider.dart';
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
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('위치 소스'),
            subtitle: Text(location.label),
            trailing: const Tooltip(
              message: '실제 GPS는 geolocator 패키지 승인 후 추가',
              child: Icon(Icons.info_outline),
            ),
          ),
        ],
      ),
    );
  }
}
