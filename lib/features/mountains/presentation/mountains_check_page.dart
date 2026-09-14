import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mountains_provider.dart';

/// M0 연결 확인용 임시 화면. M1에서 지도 홈으로 대체된다.
class MountainsCheckPage extends ConsumerWidget {
  const MountainsCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mountains = ref.watch(mountainsProvider);

    ref.listen(mountainsProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('산 정보를 불러오지 못했어요. 네트워크를 확인해주세요.')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('산노트 · Supabase 연결 확인')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 태블릿(가로 600 이상) 레이아웃 분기 자리. 지금은 동일하게 렌더.
          final isTablet = constraints.maxWidth >= 600;
          return mountains.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('불러오기 실패'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => ref.invalidate(mountainsProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
            data: (list) => ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 0),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = list[i];
                return ListTile(
                  title: Text(m.mountainGroup),
                  subtitle: Text('${m.regions} · 구간 ${m.segmentCount}개 · 입구 ${m.entranceCount}곳'),
                  trailing: Text('${m.totalLengthKm} km'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
