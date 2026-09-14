import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../course_detail/presentation/views/course_detail_page.dart';
import '../../../explore/presentation/views/widgets/course_tile.dart';
import '../../../spots/domain/entities/entrance_access.dart';
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
                            // 지하철로 가기
                            Text('지하철로 가기', style: text.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '입구 ${state.entrances.length}곳 중 ${state.entrancesWithAccess}곳이 지하철역 1.5km 안에 있어요. '
                              '"추정"은 지도 직선거리로 계산한 값이라 실제와 다를 수 있어요.',
                              style: text.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            if (state.courseStarts.isNotEmpty) ...[
                              Card(
                                child: Column(
                                  children: [
                                    for (final (i, cs) in state.courseStarts.indexed) ...[
                                      if (i > 0) const Divider(height: 1),
                                      _CourseStartRow(courseName: cs.$1, access: cs.$2),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (state.stations.isEmpty)
                              Text('지하철 접근 정보가 아직 없어요.', style: text.bodySmall)
                            else
                              Card(
                                child: Column(
                                  children: [
                                    for (final (i, st) in state.stations.indexed) ...[
                                      if (i > 0) const Divider(height: 1),
                                      _StationRow(station: st),
                                    ],
                                  ],
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

class _CourseStartRow extends StatelessWidget {
  const _CourseStartRow({required this.courseName, required this.access});

  final String courseName;
  final EntranceAccess? access;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final a = access;
    return ListTile(
      dense: true,
      leading: Icon(Icons.flag, color: scheme.primary),
      title: Text('$courseName 출발점'),
      subtitle: Text(
        a == null
            ? '지하철 접근 정보 준비 중'
            : '${a.stationName}${a.exitNo == null ? '' : ' ${a.exitNo}번 출구'}에서 도보 약 ${a.walkMin}분'
                '${a.note == null ? '' : ' · ${a.note}'}',
        style: text.bodySmall,
      ),
      trailing: a?.isEstimate == true ? const _EstimateBadge() : null,
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({required this.station});

  final StationAccess station;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = station;
    final walk = s.minWalk == s.maxWalk ? '약 ${s.minWalk}분' : '약 ${s.minWalk}~${s.maxWalk}분';
    final exits = s.exits.isEmpty ? '' : ' ${s.exits.join('·')}번 출구';
    return ListTile(
      dense: true,
      leading: Icon(Icons.subway, color: scheme.primary),
      title: Text('${s.stationName}${s.line == null ? '' : ' (${s.line})'}'),
      subtitle: Text('$exits → 입구 ${s.entranceCount}곳 · 도보 $walk'.trimLeft(), style: text.bodySmall),
      trailing: s.allEstimate ? const _EstimateBadge() : null,
    );
  }
}

class _EstimateBadge extends StatelessWidget {
  const _EstimateBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: scheme.outline), borderRadius: BorderRadius.circular(6)),
      child: Text('추정', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
