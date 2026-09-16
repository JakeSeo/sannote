import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/developer_menu.dart';
import '../../../../core/location/location_provider.dart';
import '../../../records/domain/usecases/sync_visits.dart';
import '../../../records/presentation/viewmodels/records_providers.dart';

/// 설정: 위치·데이터 안내, 서버 전송, (디버그) 개발자 메뉴.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final location = ref.watch(locationServiceProvider);
    final pending = (ref.watch(hikesProvider).value ?? const []).where((h) => h.needsSync).length;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('위치'),
            subtitle: Text('${location.label}\n위치는 산행 기록과 내 주변 산 표시에만 쓰고, 트랙은 이 기기에만 저장돼요.'),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('완주 기록 서버 전송'),
            subtitle: Text(pending == 0 ? '대기 중인 기록 없음' : '대기 $pending건 · 코스·날짜·소요시간만 올라가요'),
            trailing: pending == 0
                ? null
                : TextButton(
                    onPressed: () async {
                      final n = await ref.read(syncVisitsProvider).call();
                      if (!context.mounted) return;
                      ref.invalidate(completionCountsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(n < 0 ? '로그인이 안 되어 전송하지 못했어요.' : '$n건 전송했어요.'),
                      ));
                    },
                    child: const Text('지금 전송'),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('데이터 출처'),
            subtitle: const Text('등산로·시설·구조표지판: 산림청 공공데이터(2016년 조사). 현장과 다를 수 있어요.'),
            isThreeLine: true,
          ),
          if (DeveloperMenu.available) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.developer_mode),
              title: const Text('개발자 메뉴'),
              subtitle: Text('디버그 빌드 전용', style: text.bodySmall),
              onTap: () => DeveloperMenu.show(context),
            ),
          ],
        ],
      ),
    );
  }
}
