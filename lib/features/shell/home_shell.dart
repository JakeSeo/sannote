import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../courses/domain/usecases/get_course_summaries.dart';
import '../explore/presentation/views/explore_page.dart';
import '../map/presentation/views/map_home_page.dart';
import '../records/domain/entities/hike.dart';
import '../records/presentation/viewmodels/recording_view_model.dart';
import '../records/presentation/views/records_page.dart';
import '../records/presentation/views/recording_page.dart';

/// 하단 탭: 지도(홈) / 탐색 / 내 기록.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    // 앱이 죽었다 켜졌을 때 남아 있는 기록 → 이어가기/종료 묻기 (자동 처리하지 않음)
    ref.listen(recordingViewModelProvider.select((s) => s.resumable), (_, hike) {
      if (hike != null) _askResume(hike);
    });
    final recording = ref.watch(recordingViewModelProvider.select((s) => s.isRecording));
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [MapHomePage(), ExplorePage(), RecordsPage()],
      ),
      floatingActionButton: recording
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordingPage())),
              icon: const Icon(Icons.fiber_manual_record),
              label: const Text('기록 중'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: '지도'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: '탐색'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: '내 기록'),
        ],
      ),
    );
  }

  Future<void> _askResume(Hike hike) async {
    final vm = ref.read(recordingViewModelProvider.notifier);
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('끝내지 않은 산행이 있어요'),
        content: Text('${hike.courseName} · ${hike.startedAt.month}/${hike.startedAt.day} 시작\n이어서 기록할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('finish'), child: const Text('일부로 저장하고 종료')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('resume'), child: const Text('이어가기')),
        ],
      ),
    );
    if (!mounted) return;
    final summaries = await ref.read(getCourseSummariesProvider).call();
    final course = summaries.where((s) => s.course.courseId == hike.courseId).firstOrNull;
    if (choice == 'resume' && course != null) {
      await vm.resume(course);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordingPage()));
    } else {
      // 코스를 못 찾았거나 종료 선택: 커버율 없이 일부 기록으로 마감
      await vm.resume(course ?? summaries.first);
      await vm.finish(HikeStatus.partial);
    }
    vm.dismissResumable();
  }
}
