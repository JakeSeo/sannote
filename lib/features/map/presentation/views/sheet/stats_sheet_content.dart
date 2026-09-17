import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/mountain_palette.dart';
import '../../../../../core/theme/theme_provider.dart';

import '../../../../courses/presentation/widgets/course_tile.dart';
import '../../../../records/domain/entities/hike.dart';
import '../../../../records/presentation/viewmodels/records_providers.dart';
import '../../../../records/presentation/viewmodels/recording_view_model.dart';
import '../../../../records/presentation/views/hike_detail_page.dart';
import '../../../../records/presentation/views/records_page.dart';

/// 선택이 없을 때 시트 내용: 내 통계 (칠한 길·완주·산행) + 다녀온 산 + 최근 산행.
class StatsSheetContent extends ConsumerWidget {
  const StatsSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(conquestStatsProvider).value;
    final hikes = (ref.watch(hikesProvider).value ?? const <Hike>[]).where((h) => h.status != HikeStatus.recording).toList();
    final recording = ref.watch(recordingViewModelProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final totalMin = hikes.fold(0, (sum, h) => sum + h.durationMin);
    final variant = ref.watch(themeVariantProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 접힌 상태에서 보이는 한 줄
        if (recording.isRecording)
          _LiveHeader(recording: recording)
        else
          Text(
            stats == null || stats.isEmpty
                ? '아직 칠한 길이 없어요. 기록을 시작해보세요'
                : '칠한 길 ${stats.segmentCount}구간 · ${stats.totalKm.toStringAsFixed(1)}km · 완주 ${stats.completedHikeCount}회',
            style: text.titleSmall,
          ),
        const SizedBox(height: 14),
        // 펼치면 보이는 통계
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _Tile('칠한 길', '${(stats?.totalKm ?? 0).toStringAsFixed(1)}km'),
            _Tile('완주 코스', '${stats?.completedHikeCount ?? 0}회'),
            _Tile('칠한 구간', '${stats?.segmentCount ?? 0}개'),
            _Tile('다녀온 산', '${stats?.mountainGroups.length ?? 0}곳'),
            _Tile('산행', '${hikes.length}회'),
            _Tile('총 시간', totalMin < 60 ? '$totalMin분' : '${totalMin ~/ 60}시간 ${totalMin % 60}분'),
          ],
        ),
        if (stats != null && stats.mountainGroups.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final g in stats.mountainGroups)
                variant.isSketch
                    ? _Stamp(label: g, color: MountainPalette.of(g, ink: variant.inkTone))
                    : Chip(avatar: const Icon(Icons.verified, size: 16), label: Text(g)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Text('최근 산행', style: text.titleSmall),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordsPage())),
              child: const Text('내 기록 전체'),
            ),
          ],
        ),
        if (hikes.isEmpty) Text('기록이 없어요', style: text.bodySmall),
        for (final h in hikes.take(3)) ...[
          Card(
            child: ListTile(
              dense: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HikeDetailPage(hikeId: h.id))),
              leading: Icon(h.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: h.isCompleted ? scheme.primary : scheme.outline),
              title: Text(h.displayName),
              subtitle: Text(
                '${h.startedAt.month}/${h.startedAt.day} · ${h.distanceKm.toStringAsFixed(1)}km · ${formatMinutes(h.durationMin)}',
                style: text.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.recording});

  final RecordingState recording;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String fmt(Duration e) =>
        '${e.inHours}:${(e.inMinutes % 60).toString().padLeft(2, '0')}:${(e.inSeconds % 60).toString().padLeft(2, '0')}';
    final elapsed = fmt(recording.movingTime);
    final total = fmt(recording.elapsed);
    final idleMin = recording.idleFor.inMinutes;
    final since = recording.lastFixAt == null ? null : DateTime.now().difference(recording.lastFixAt!).inSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(recording.isPaused ? Icons.free_breakfast : Icons.fiber_manual_record,
                size: 14, color: recording.isPaused ? Theme.of(context).colorScheme.outline : const Color(0xFFE53935)),
            const SizedBox(width: 6),
            Text(
              '${recording.isPaused ? '휴식 중 · 이동' : '이동'} $elapsed · ${recording.distanceKm.toStringAsFixed(2)}km · '
              'GPS ${recording.track.isEmpty ? '대기 중' : '${recording.track.length}점${since == null ? '' : ' ($since초 전)'}'}',
              style: text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        if (recording.error != null) ...[
          const SizedBox(height: 4),
          Text(recording.error!, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 2),
        Text(
          recording.track.isNotEmpty && idleMin >= 3
              ? '총 경과 $total · $idleMin분 동안 움직임이 없어요. 멈춘 시간은 이동 시간에 들어가지 않아요. 도착했다면 [정지]를 눌러주세요.'
              : '총 경과 $total · 위치는 계속 기록되고, 멈춰 있는 시간은 이동 시간에서 자동으로 빠져요',
          style: text.bodySmall,
        ),
        if (recording.course != null) ...[
          const SizedBox(height: 4),
          Text('코스: ${recording.course!.course.name}', style: text.bodySmall),
        ],
      ],
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final sketch = ref.watch(themeVariantProvider).isSketch;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sketch ? AppTheme.paperCard : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: sketch ? Border.all(color: AppTheme.paperLine) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: sketch
                  ? text.headlineSmall?.copyWith(fontSize: 24)
                  : text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

/// 색연필로 칠한 원형 스탬프 (다녀온 산)
class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(label, style: TextStyle(fontFamily: AppTheme.handwriting, fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.ink, height: 1.1)),
    );
  }
}
