import 'package:flutter/material.dart';

import '../../../../records/domain/entities/conquest_stats.dart';

class MapTopBar extends StatelessWidget {
  const MapTopBar({super.key, required this.isLoading, this.conquest = ConquestStats.empty, this.onLongPress});

  final bool isLoading;

  /// 홈 정복 스탯: "구간 47개 · 12.3km · 입구 5곳" (내 누적만, 분모 없음)
  final ConquestStats conquest;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Material(
        color: scheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('산노트', style: text.titleMedium),
                  if (isLoading) ...[
                    const SizedBox(width: 10),
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 6),
                    Text('등산로 불러오는 중', style: text.bodySmall),
                  ],
                ],
              ),
              if (!conquest.isEmpty)
                Text(
                  '구간 ${conquest.segmentCount}개 · ${conquest.totalKm.toStringAsFixed(1)}km · 입구 ${conquest.entranceCount}곳',
                  style: text.bodySmall?.copyWith(color: scheme.primary),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
