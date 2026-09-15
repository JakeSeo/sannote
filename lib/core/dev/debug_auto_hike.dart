import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/courses/domain/usecases/get_course_summaries.dart';
import '../../features/records/presentation/viewmodels/recording_view_model.dart';
import '../../features/records/presentation/views/recording_page.dart';
import '../../features/shell/home_shell.dart';
import '../location/location_provider.dart';

/// 디버그 전용 (`SANNOTE_START=autohike:<course_id>` 또는 `autohike:free:<course_id>`): Mock 코스 재생으로 기록을 자동 시작해
/// 책상에서 기록→종료→색칠 전체 플로우를 검증한다. 릴리즈 코드 경로에서는 절대 쓰이지 않는다.
class DebugAutoHike extends ConsumerStatefulWidget {
  const DebugAutoHike({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<DebugAutoHike> createState() => _DebugAutoHikeState();
}

class _DebugAutoHikeState extends ConsumerState<DebugAutoHike> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final free = widget.courseId.startsWith('free:');
    final id = free ? widget.courseId.substring(5) : widget.courseId;
    final summaries = await ref.read(getCourseSummariesProvider).call();
    final s = summaries.where((x) => x.course.courseId == id).firstOrNull ?? summaries.first;
    ref.read(locationServiceProvider.notifier).useMockRoute(s.polyline, label: 'Mock · ${s.course.name} 재생');
    // free: 코스를 고르지 않고 시작 → 종료 시 자동 판별이 이 코스를 찾아내야 한다
    await ref.read(recordingViewModelProvider.notifier).start(course: free ? null : s);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordingPage()));
  }

  @override
  Widget build(BuildContext context) => const HomeShell();
}
