import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../explore/presentation/views/widgets/course_tile.dart';
import '../../domain/entities/hike.dart';
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
      appBar: AppBar(title: Text(detail.value?.hike.courseName ?? '기록')),
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
                          _Stat('시간', formatMinutes(h.durationMin)),
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
                      if (h.coverage != null) '코스 커버율 약 ${(h.coverage! * 100).round()}%',
                      if (h.isCompleted) (h.syncedAt == null ? '서버 전송 대기' : '서버 전송 완료'),
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
