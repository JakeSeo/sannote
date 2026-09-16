import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/hike.dart';
import '../../domain/usecases/compute_course_coverage.dart';
import '../../domain/usecases/match_course.dart';
import '../viewmodels/recording_view_model.dart';

/// [정지] → 어느 코스를 걸었는지 자동 판별 1위를 기본으로 보여주고, 사용자가 한 번 확인한다.
Future<void> showFinishFlow(BuildContext context, WidgetRef ref) async {
  final vm = ref.read(recordingViewModelProvider.notifier);
  final matches = await vm.matchCourses();
  if (!context.mounted) return;
  final top = matches.firstOrNull;
  final pct = top == null ? 0 : (top.coverage * 100).round();
  final suggestComplete = top != null && top.coverage >= ComputeCourseCoverage.suggestCompleteAt;

  final result = await showDialog<(HikeStatus, CourseMatch?)>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(top == null ? '산행을 종료할까요?' : top.course.course.name),
      content: Text(
        top == null
            ? '일치하는 코스를 찾지 못했어요. 자유 산행으로 저장할 수 있어요.'
            : '이 코스의 약 $pct%를 걸으셨어요.\n'
                '${suggestComplete ? '완주로 기록하면 이 코스가 지도에 색칠돼요.' : '완주로 기록할지 직접 선택해주세요.'}'
                '${matches.length > 1 ? '\n\n다른 후보: ${matches.skip(1).take(2).map((m) => '${m.course.course.name} ${(m.coverage * 100).round()}%').join(', ')}' : ''}',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop((HikeStatus.discarded, null)), child: const Text('기록 삭제')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop((HikeStatus.partial, top)),
          child: Text(top == null ? '자유 산행으로 저장' : '일부만 걸었어요'),
        ),
        if (top != null)
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop((HikeStatus.completed, top)),
            child: const Text('완주로 기록'),
          ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;
  final (status, match) = result;
  await vm.finish(status, match: match);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(switch (status) {
      HikeStatus.completed => '완주 기록이 저장됐어요. 지도에서 색칠된 길을 확인해보세요!',
      HikeStatus.partial => match == null ? '자유 산행으로 저장됐어요.' : '산행 기록이 저장됐어요.',
      _ => '기록을 삭제했어요.',
    }),
  ));
}
