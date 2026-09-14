import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/location/mock_location_service.dart';
import '../../domain/entities/hike.dart';
import '../../domain/usecases/compute_course_coverage.dart';
import '../viewmodels/recording_view_model.dart';
import 'widgets/track_map.dart';

/// 산행 기록 중 화면: 지도(코스 + 내 트랙) · 경과 시간 · 거리 · [종료].
class RecordingPage extends ConsumerWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingViewModelProvider);
    // 기록이 끝나면(수동 종료든 자동이든) 이 화면을 닫는다
    ref.listen(recordingViewModelProvider.select((s) => s.isRecording), (prev, next) {
      if (prev == true && !next && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final course = state.course;
    final isMock = ref.watch(locationServiceProvider) is MockLocationService;

    if (course == null || !state.isRecording) {
      // 종료 후 pop 되기 전 잠깐 또는 비정상 진입
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('기록 중인 산행이 없어요')));
    }

    final e = state.elapsed;
    final elapsed = '${e.inHours}:${(e.inMinutes % 60).toString().padLeft(2, '0')}:${(e.inSeconds % 60).toString().padLeft(2, '0')}';
    final since = state.lastFixAt == null ? null : DateTime.now().difference(state.lastFixAt!).inSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(course.course.name),
        actions: [if (isMock) const Padding(padding: EdgeInsets.only(right: 12), child: Chip(label: Text('MOCK')))],
      ),
      body: Column(
        children: [
          Expanded(child: TrackMap(course: course.polyline, track: state.track, live: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _Stat(label: '경과', value: elapsed),
                    _Stat(label: '거리', value: '${state.distanceKm.toStringAsFixed(2)}km'),
                    _Stat(
                      label: 'GPS',
                      value: state.track.isEmpty ? '대기 중' : '${state.track.length}점',
                      note: since == null ? null : '$since초 전',
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(state.error!, style: text.bodySmall?.copyWith(color: scheme.error)),
                ],
                const SizedBox(height: 8),
                Text('화면을 꺼도 기록은 계속돼요. 종료는 여기서 눌러주세요.', style: text.bodySmall),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _confirmFinish(context, ref),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('산행 종료'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 종료 확인: 커버율로 "제안"만 하고 완주/일부/삭제는 사용자가 고른다.
  Future<void> _confirmFinish(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(recordingViewModelProvider.notifier);
    final coverage = vm.suggestCoverage();
    final pct = (coverage * 100).round();
    final suggestComplete = coverage >= ComputeCourseCoverage.suggestCompleteAt;
    final status = await showDialog<HikeStatus>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('산행을 종료할까요?'),
        content: Text(
          '기록된 트랙이 코스의 약 $pct%를 지났어요.\n'
          '${suggestComplete ? '완주로 기록하면 이 코스가 지도에 색칠돼요.' : '완주로 기록할지 직접 선택해주세요.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(HikeStatus.discarded),
            child: const Text('기록 삭제'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(HikeStatus.partial),
            child: const Text('일부만 걸었어요'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(HikeStatus.completed),
            child: const Text('완주로 기록'),
          ),
        ],
      ),
    );
    if (status == null || !context.mounted) return;
    await vm.finish(status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (status) {
        HikeStatus.completed => '완주 기록이 저장됐어요. 지도에서 색칠된 길을 확인해보세요!',
        HikeStatus.partial => '산행 기록이 저장됐어요.',
        _ => '기록을 삭제했어요.',
      }),
    ));
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
          Text(value, style: text.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          if (note != null) Text(note!, style: text.bodySmall),
        ],
      ),
    );
  }
}
