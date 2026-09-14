import 'package:flutter/material.dart';

import '../../viewmodels/map_state.dart';

/// 코스 요약 카드: 거리 / 예상 시간 / 난이도 (구간 합산 자동 계산).
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.view, required this.onClose});

  final CourseView view;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stats = view.stats;
    final desc = view.course.description;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(view.course.name, style: text.titleMedium)),
                IconButton(tooltip: '코스 닫기', onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            if (desc != null && desc.isNotEmpty) ...[
              Text(desc, style: text.bodySmall),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                _Stat(label: '거리', value: '${stats.lengthKm.toStringAsFixed(1)}km'),
                _Stat(label: '예상 시간', value: _fmtMin(stats.estUpMin), note: '오름 기준'),
                _Stat(label: '난이도', value: stats.level.label, note: '예상'),
              ],
            ),
            if (view.missingSegmentIds.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '구간 ${view.missingSegmentIds.length}개를 찾을 수 없어 일부가 빠졌어요',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtMin(int min) {
    if (min < 60) return '약 $min분';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '약 $h시간' : '약 $h시간 $m분';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.note});

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
          Text(value, style: text.titleSmall),
          if (note != null) Text(note!, style: text.bodySmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
