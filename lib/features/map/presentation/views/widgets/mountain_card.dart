import 'package:flutter/material.dart';

import '../../../../courses/domain/entities/course.dart';
import '../../../../mountains/domain/entities/mountain.dart';

/// 산군 포커스 카드: 요약 + 큐레이션된 코스 목록.
class MountainCard extends StatelessWidget {
  const MountainCard({
    super.key,
    required this.mountain,
    required this.courses,
    required this.onCourseTap,
    required this.onClose,
  });

  final Mountain mountain;
  final List<Course> courses;
  final void Function(Course) onCourseTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mountain.mountainGroup, style: text.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${mountain.regions} · 등산로 ${mountain.totalLengthKm}km · 입구 ${mountain.entranceCount}곳',
                        style: text.bodySmall,
                      ),
                      Text('아직 칠해지지 않은 길 ${mountain.segmentCount}구간', style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(tooltip: '전체 보기', onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            if (courses.isEmpty)
              Text('큐레이션된 코스가 아직 없어요', style: text.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in courses)
                    ActionChip(
                      avatar: const Icon(Icons.route, size: 16),
                      label: Text(c.name),
                      onPressed: () => onCourseTap(c),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
