import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/presentation/widgets/course_tile.dart';
import '../../domain/entities/hike.dart';
import '../../domain/usecases/delete_hike.dart';
import '../viewmodels/hike_detail_view_model.dart';
import 'widgets/track_map.dart';

/// 기록 상세: 내가 걸은 트랙(파랑)을 코스(강조색)와 겹쳐 본다.
class HikeDetailPage extends ConsumerWidget {
  const HikeDetailPage({super.key, required this.hikeId});

  final String hikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(hikeDetailProvider(hikeId));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.hike.displayName ?? '기록'),
        actions: [
          if (detail.value != null)
            IconButton(
              tooltip: '기록 삭제',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, hikeId),
            ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('기록을 불러오지 못했어요')),
        data: (d) {
          if (d == null) return const Center(child: Text('기록이 없어요'));
          final h = d.hike;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              final map = TrackMap(course: d.course?.polyline ?? const [], track: d.track);
              final info = ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!isTablet) ...[
                    SizedBox(height: 280, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: map)),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _Stat('날짜', '${h.startedAt.year}.${h.startedAt.month}.${h.startedAt.day}'),
                          _Stat('거리', '${h.distanceKm.toStringAsFixed(2)}km'),
                          _Stat('이동 시간', formatMinutes(h.durationMin)),
                          _Stat(
                            '상태',
                            switch (h.status) {
                              HikeStatus.completed => '완주',
                              HikeStatus.partial => '일부',
                              HikeStatus.recording => '기록 중',
                              HikeStatus.discarded => '삭제',
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    [
                      'GPS 점 ${d.track.length}개',
                      '총 경과 ${formatMinutes(h.totalDuration.inMinutes)}',
                      if (!h.hasCourse) '자유 산행 (코스 미확정)',
                      if (h.coverage != null) '코스 커버율 약 ${(h.coverage! * 100).round()}%',
                      if (h.isCompleted) (h.syncedAt == null ? '서버 전송 대기' : '서버 전송 완료'),
                      if (h.batteryDrain != null) '배터리 ${h.batteryStart}% → ${h.batteryEnd}% (${h.batteryDrain}%p)',
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text('트랙 좌표는 이 기기에만 저장돼요. 서버에는 완주한 코스와 날짜, 소요시간만 올라가요.', style: text.bodySmall),
                ],
              );
              if (!isTablet) return info;
              return Row(children: [Expanded(flex: 5, child: map), Expanded(flex: 4, child: info)]);
            },
          );
        },
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('이 기록을 삭제할까요?'),
      content: const Text('트랙이 기기에서 지워지고 되돌릴 수 없어요. 완주로 칠해진 길도 이 기록이 마지막이면 회색으로 돌아가요.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ref.read(deleteHikeProvider).call(id);
  if (!context.mounted) return;
  Navigator.of(context).pop();
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(label, style: text.labelSmall), Text(value, style: text.titleSmall)],
      ),
    );
  }
}
