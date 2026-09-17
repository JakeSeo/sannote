import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/recording_view_model.dart';
import 'reveal/course_reveal_overlay.dart';

/// [정지] → "기록을 저장할까요?" 한 번 확인 → 닿은 구간 색칠 → 획득한 코스가 있으면 연출.
Future<void> showFinishFlow(BuildContext context, WidgetRef ref) async {
  final vm = ref.read(recordingViewModelProvider.notifier);
  final s = ref.read(recordingViewModelProvider);
  final km = s.distanceKm.toStringAsFixed(2);
  final min = s.movingTime.inMinutes;
  final choice = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('산책을 마칠까요?'),
      content: Text(s.track.length < 2
          ? '아직 기록된 위치가 없어요. 기록을 지울까요?'
          : '$km km · 이동 약 $min분\n걸은 길이 지도에 칠해져요. 숨어 있던 산책로를 다 걸었다면 코스를 획득해요.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('기록 삭제')),
        if (s.track.length >= 2) FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('저장하고 마치기')),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final result = await vm.finish(discard: !choice);
  if (!context.mounted) return;
  if (!choice) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기록을 지웠어요.')));
    return;
  }
  if (result.discovered.isNotEmpty) {
    await showCourseReveal(context, result.discovered);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${result.discovered.first.course.name}${result.discovered.length > 1 ? ' 외 ${result.discovered.length - 1}개' : ''}를 내 산책로에 담았어요.'),
    ));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.newlyPainted.isEmpty
          ? '산책을 저장했어요. 이번엔 새로 칠한 길은 없어요.'
          : '산책을 저장했어요. 새로 칠한 길 ${result.newlyPainted.length}구간!'),
    ));
  }
}
