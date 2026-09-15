import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../explore/presentation/views/widgets/course_tile.dart';
import '../../domain/entities/hike.dart';
import '../../domain/usecases/sync_visits.dart';
import '../viewmodels/records_providers.dart';
import 'hike_detail_page.dart';

/// 내 기록: 정복 스탯 · 산군 스탬프 · 산행 목록.
class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hikes = ref.watch(hikesProvider);
    final stats = ref.watch(conquestStatsProvider).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final list = hikes.value ?? const <Hike>[];
    final pending = list.where((h) => h.needsSync).length;

    return Scaffold(
      appBar: AppBar(title: const Text('내 기록')),
      body: hikes.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 600 ? 720.0 : double.infinity;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('내가 칠한 길', style: text.labelLarge),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _Big(label: '구간', value: '${stats?.segmentCount ?? 0}개'),
                                    _Big(label: '거리', value: '${(stats?.totalKm ?? 0).toStringAsFixed(1)}km'),
                                    _Big(label: '입구', value: '${stats?.entranceCount ?? 0}곳'),
                                    _Big(label: '완주', value: '${stats?.completedHikeCount ?? 0}회'),
                                  ],
                                ),
                                if (stats != null && stats.mountainGroups.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text('다녀온 산', style: text.labelLarge),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      for (final g in stats.mountainGroups)
                                        Chip(avatar: const Icon(Icons.verified, size: 16), label: Text(g)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (pending > 0) ...[
                          const SizedBox(height: 8),
                          _SyncNotice(pending: pending),
                        ],
                        const SizedBox(height: 20),
                        Text('산행 ${list.length}회', style: text.titleMedium),
                        const SizedBox(height: 8),
                        if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('아직 기록이 없어요. 코스 화면에서 [산행 시작]을 눌러보세요.', style: text.bodyMedium),
                          ),
                        for (final h in list) ...[
                          Card(
                            child: ListTile(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => HikeDetailPage(hikeId: h.id)),
                              ),
                              leading: Icon(
                                switch (h.status) {
                                  HikeStatus.completed => Icons.check_circle,
                                  HikeStatus.recording => Icons.fiber_manual_record,
                                  _ => Icons.radio_button_unchecked,
                                },
                                color: h.isCompleted ? scheme.primary : scheme.outline,
                              ),
                              title: Text(h.displayName),
                              subtitle: Text(
                                '${_date(h.startedAt)} · ${h.distanceKm.toStringAsFixed(1)}km · ${formatMinutes(h.durationMin)}',
                                style: text.bodySmall,
                              ),
                              trailing: Text(
                                switch (h.status) {
                                  HikeStatus.completed => '완주',
                                  HikeStatus.partial => '일부',
                                  HikeStatus.recording => '기록 중',
                                  HikeStatus.discarded => '삭제',
                                },
                                style: text.labelMedium,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _date(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(value, style: text.titleMedium), Text(label, style: text.bodySmall)],
      ),
    );
  }
}

class _SyncNotice extends ConsumerWidget {
  const _SyncNotice({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud_upload_outlined),
        title: Text('완주 기록 $pending건 전송 대기', style: text.bodyMedium),
        subtitle: Text('기록은 이 기기에 안전하게 저장돼 있어요. 네트워크가 되면 완주 사실만 서버에 보내요.', style: text.bodySmall),
        trailing: TextButton(
          onPressed: () async {
            final n = await ref.read(syncVisitsProvider).call();
            if (!context.mounted) return;
            ref.invalidate(completionCountsProvider);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(n < 0 ? '로그인이 안 되어 전송하지 못했어요. 나중에 다시 시도돼요.' : '$n건 전송했어요.'),
            ));
          },
          child: const Text('지금 전송'),
        ),
      ),
    );
  }
}
