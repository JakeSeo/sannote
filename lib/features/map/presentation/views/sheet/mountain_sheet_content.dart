import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../courses/domain/entities/course.dart';
import '../../../../courses/presentation/widgets/course_tile.dart';
import '../../../../mountain_detail/presentation/viewmodels/mountain_detail_view_model.dart';
import '../../../../mountains/domain/entities/mountain.dart';

/// 산군 선택 시 시트 내용: 소개 · 코스 목록 · 지하철로 가기.
class MountainSheetContent extends ConsumerWidget {
  const MountainSheetContent({super.key, required this.mountain, required this.onCourseTap});

  final Mountain mountain;
  final void Function(Course) onCourseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(mountainDetailViewModelProvider(mountain.mountainGroup));
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final m = mountain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(m.mountainGroup, style: text.titleMedium),
        const SizedBox(height: 2),
        Text('${m.regions} · 등산로 ${m.totalLengthKm}km · 입구 ${m.entranceCount}곳 · 아직 칠해지지 않은 길 ${m.segmentCount}구간',
            style: text.bodySmall),
        const SizedBox(height: 12),
        Text(
          m.description?.trim().isNotEmpty == true
              ? m.description!
              : '${m.regions}에 있는 산군이에요. 등산로 ${m.totalLengthKm}km, ${m.segmentCount}개 구간이 등록돼 있어요.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('코스 ${detail.courses.length}개', style: text.titleSmall),
        const SizedBox(height: 8),
        if (detail.isLoading) const LinearProgressIndicator(),
        if (!detail.isLoading && detail.courses.isEmpty) Text('큐레이션된 코스가 아직 없어요.', style: text.bodySmall),
        for (final c in detail.courses) ...[
          CourseTile(summary: c, showMountain: false, onTap: () => onCourseTap(c.course)),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Text('지하철로 가기', style: text.titleSmall),
        const SizedBox(height: 4),
        Text('"추정"은 지도 직선거리로 계산한 값이라 실제와 다를 수 있어요.', style: text.bodySmall),
        const SizedBox(height: 6),
        if (!detail.isLoading && detail.stations.isEmpty) Text('지하철 접근 정보가 아직 없어요.', style: text.bodySmall),
        for (final st in detail.stations.take(6))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.subway, color: scheme.primary),
            title: Text('${st.stationName}${st.line == null ? '' : ' (${st.line})'}'),
            subtitle: Text(
              '${st.exits.isEmpty ? '' : '${st.exits.join('·')}번 출구 → '}입구 ${st.entranceCount}곳 · 도보 '
              '${st.minWalk == st.maxWalk ? '약 ${st.minWalk}분' : '약 ${st.minWalk}~${st.maxWalk}분'}',
              style: text.bodySmall,
            ),
            trailing: st.allEstimate ? Text('추정', style: text.labelSmall) : null,
          ),
      ],
    );
  }
}
