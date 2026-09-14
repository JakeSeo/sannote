import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../course_detail/presentation/views/course_detail_page.dart';
import '../../../explore/presentation/views/widgets/course_tile.dart';
import '../../../spots/domain/entities/entrance_access.dart';
import '../../../spots/domain/entities/spot.dart';
import '../viewmodels/mountain_detail_view_model.dart';

/// 산 상세: 소개 · 코스 리스트 · 입구 리스트(지하철 접근 정보).
class MountainDetailPage extends ConsumerWidget {
  const MountainDetailPage({super.key, required this.mountainGroup});

  final String mountainGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mountainDetailViewModelProvider(mountainGroup));
    final vm = ref.read(mountainDetailViewModelProvider(mountainGroup).notifier);
    final text = Theme.of(context).textTheme;
    final m = state.mountain;

    ref.listen(mountainDetailViewModelProvider(mountainGroup).select((s) => s.error), (_, e) {
      if (e == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('산 정보를 불러오지 못했어요. 네트워크를 확인해주세요.'),
        action: SnackBarAction(label: '다시 시도', onPressed: vm.retry),
      ));
    });

    return Scaffold(
      appBar: AppBar(title: Text(mountainGroup)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : m == null
              ? Center(child: FilledButton(onPressed: vm.retry, child: const Text('다시 시도')))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 600 ? 720.0 : double.infinity;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            // 소개
                            Text(
                              m.description?.trim().isNotEmpty == true
                                  ? m.description!
                                  : '${m.regions}에 있는 산군이에요. 등산로 ${m.totalLengthKm}km, '
                                      '${m.segmentCount}개 구간, 입구 ${m.entranceCount}곳이 등록돼 있어요.',
                              style: text.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                Chip(label: Text('등산로 ${m.totalLengthKm}km')),
                                Chip(label: Text('구간 ${m.segmentCount}개')),
                                Chip(label: Text('입구 ${m.entranceCount}곳')),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // 코스
                            Text('코스 ${state.courses.length}개', style: text.titleMedium),
                            const SizedBox(height: 8),
                            if (state.courses.isEmpty)
                              Text('큐레이션된 코스가 아직 없어요. 곧 추가할게요.', style: text.bodySmall),
                            for (final c in state.courses) ...[
                              CourseTile(
                                summary: c,
                                showMountain: false,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CourseDetailPage(courseId: c.course.courseId),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 16),
                            // 입구
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('입구 ${state.entrances.length}곳', style: text.titleMedium),
                                const SizedBox(width: 8),
                                Text('지하철 접근 정보 ${state.entrancesWithAccess}곳', style: text.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('접근 정보는 답사한 입구부터 순서대로 채워져요.', style: text.bodySmall),
                            const SizedBox(height: 8),
                            if (state.highlightedEntrances.isNotEmpty)
                              Card(
                                child: Column(
                                  children: [
                                    for (final (i, e) in state.highlightedEntrances.indexed) ...[
                                      if (i > 0) const Divider(height: 1),
                                      _EntranceRow(
                                        spot: e,
                                        access: state.access[e.spotId],
                                        courseName: state.courseStartNames[e.spotId],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '그 외 입구 ${state.entrances.length - state.highlightedEntrances.length}곳은 '
                                '지도 탭에서 산을 확대하면 초록 마커로 볼 수 있어요.',
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _EntranceRow extends StatelessWidget {
  const _EntranceRow({required this.spot, required this.access, this.courseName});

  final Spot spot;
  final EntranceAccess? access;

  /// 이 입구에서 출발하는 코스 이름 (있으면)
  final String? courseName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final a = access;
    final title = a == null
        ? (courseName == null ? '입구' : '$courseName 출발점')
        : '${a.stationName}${a.line == null ? '' : ' (${a.line})'}';
    final subtitle = [
      if (a != null) '역에서 도보 약 ${a.walkMin}분' else '지하철 접근 정보 준비 중',
      if (a?.note case final n? when n.isNotEmpty) n,
      if (a != null && courseName != null) '$courseName 출발점',
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: Icon(a == null ? Icons.hiking : Icons.subway, color: a == null ? scheme.outline : scheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: text.bodySmall),
    );
  }
}
