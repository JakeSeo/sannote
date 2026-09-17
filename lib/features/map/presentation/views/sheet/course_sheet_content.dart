import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../course_detail/presentation/viewmodels/course_detail_view_model.dart';
import '../../../../courses/domain/entities/course_summary.dart';
import '../../../../courses/presentation/widgets/course_tile.dart';
import '../../../../records/domain/entities/hike.dart';
import '../../../../records/presentation/viewmodels/records_providers.dart';
import '../../../../../core/theme/mountain_palette.dart';
import '../../../../../core/theme/theme_provider.dart';

/// 코스 선택 시 시트 내용: 설명 · 거리/예상시간/난이도 · 완주자 · 경유 지점 · 구조 표지판(참고용).
class CourseSheetContent extends ConsumerWidget {
  const CourseSheetContent({super.key, required this.summary});

  final CourseSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final detail = ref.watch(courseDetailViewModelProvider(s.course.courseId));
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final stats = s.stats;
    final myHikes = (ref.watch(hikesProvider).value ?? const <Hike>[])
        .where((h) => h.courseId == s.course.courseId && h.status != HikeStatus.recording)
        .toList();
    final total = ref.watch(completionCountsProvider).value?[s.course.courseId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (ref.watch(themeVariantProvider).isSketch) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: MountainPalette.of(s.course.mountainGroup, ink: ref.watch(themeVariantProvider).inkTone),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(s.course.name, style: text.titleMedium)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${s.course.mountainGroup} · ${stats.lengthKm.toStringAsFixed(1)}km · 예상 ${formatMinutes(stats.estUpMin)} · ${stats.level.label}',
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        if (s.course.description?.isNotEmpty == true) ...[
          Text(s.course.description!, style: text.bodyMedium),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            _Stat('거리', '${stats.lengthKm.toStringAsFixed(1)}km'),
            _Stat('예상 시간', formatMinutes(stats.estUpMin), note: '오름 기준 · 개인차 있음'),
            _Stat('난이도', stats.level.label, note: '예상'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          [
            total == null ? '완주자 수 불러오는 중' : (total == 0 ? '아직 완주자가 없어요. 첫 번째가 되어보세요' : '총 $total명 완주'),
            myHikes.isEmpty ? '내 기록 없음' : '내 기록 ${myHikes.length}회 · 완주 ${myHikes.where((h) => h.isCompleted).length}회',
          ].join(' · '),
          style: text.bodySmall,
        ),
        if (s.missingSegmentIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('구간 ${s.missingSegmentIds.length}개를 찾을 수 없어 일부가 빠졌어요', style: text.bodySmall?.copyWith(color: scheme.error)),
          ),
        const SizedBox(height: 16),
        Text('경유 지점', style: text.titleSmall),
        Text('코스 60m 이내 시설 · 2016년 조사 자료라 현장과 다를 수 있어요', style: text.bodySmall),
        const SizedBox(height: 6),
        if (detail.isLoading) const LinearProgressIndicator(),
        if (!detail.isLoading && detail.waypoints.isEmpty) Text('등록된 경유 시설이 없어요', style: text.bodySmall),
        for (final e in detail.waypointsByCategory.entries)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(_icon(e.key), color: e.key == '위험지역' ? scheme.error : scheme.primary),
            title: Text('${e.key} ${e.value.length}곳'),
            subtitle: Builder(builder: (_) {
              final d = e.value.map((s) => s.type).whereType<String>().where((t) => t != e.key).toSet().join(', ');
              return d.isEmpty ? const SizedBox.shrink() : Text(d, maxLines: 2, overflow: TextOverflow.ellipsis);
            }),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('구조 표지판', style: text.titleSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: scheme.outline), borderRadius: BorderRadius.circular(6)),
              child: Text('참고용', style: text.labelSmall),
            ),
          ],
        ),
        Text('119 신고 시 표지판 번호를 말하면 위치 확인이 빨라요. 2016년 자료로 실물 확인 전이라 참고용이에요.', style: text.bodySmall),
        const SizedBox(height: 6),
        if (!detail.isLoading && detail.safetyPoints.isEmpty) Text('이 코스 주변에 등록된 표지판 정보가 없어요', style: text.bodySmall),
        for (final p in detail.safetyPoints)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_hospital_outlined, color: Color(0xFFE53935)),
            title: Text('표지판 ${p.markerNo ?? '-'}'),
            subtitle: Text([p.locationDesc, p.agency].whereType<String>().join(' · ')),
          ),
      ],
    );
  }

  static IconData _icon(String c) => switch (c) {
        '조망점' => Icons.landscape,
        '화장실' => Icons.wc,
        '음수대' => Icons.water_drop,
        '정자' => Icons.deck,
        '정상' => Icons.flag,
        '대피소' => Icons.house_siding,
        '위험지역' => Icons.warning_amber,
        _ => Icons.place,
      };
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          Text(value, style: text.titleMedium),
          if (note != null) Text(note!, style: text.bodySmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
