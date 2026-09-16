import 'package:flutter/material.dart';

import '../../domain/entities/course_stats.dart';
import '../../domain/entities/course_summary.dart';

/// 코스 목록 한 줄: 이름 · 산 · 거리/예상시간/난이도.
class CourseTile extends StatelessWidget {
  const CourseTile({super.key, required this.summary, required this.onTap, this.showMountain = true});

  final CourseSummary summary;
  final VoidCallback onTap;
  final bool showMountain;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = summary.stats;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.route, color: scheme.onPrimaryContainer),
        ),
        title: Text(summary.course.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (showMountain) summary.course.mountainGroup,
            '${s.lengthKm.toStringAsFixed(1)}km',
            '예상 ${formatMinutes(s.estUpMin)}',
          ].join(' · '),
          style: text.bodySmall,
        ),
        trailing: DifficultyBadge(level: s.level),
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.level});

  final DifficultyLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(level.label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

String formatMinutes(int min) {
  if (min < 60) return '약 $min분';
  final h = min ~/ 60, m = min % 60;
  return m == 0 ? '약 $h시간' : '약 $h시간 $m분';
}
