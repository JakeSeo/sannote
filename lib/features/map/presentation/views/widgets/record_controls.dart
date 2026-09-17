import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/location/geolocator_location_service.dart';
import '../../../../../core/location/location_provider.dart';
import '../../../../../core/location/mock_location_service.dart';
import '../../../../courses/domain/entities/course_summary.dart';
import '../../../../records/presentation/viewmodels/recording_view_model.dart';
import '../../../../records/presentation/views/finish_flow.dart';

/// 시트 위에 떠 있는 기록 버튼. 시작 전: [기록 시작] (코스가 선택돼 있으면 그 코스로), 기록 중: [휴식/재시작] [정지].
/// 휴식은 표시용이며 위치 저장은 계속된다. 멈춘 시간은 이동 시간 계산에서 자동으로 빠진다.
class RecordControls extends ConsumerWidget {
  const RecordControls({super.key, this.selectedCourse});

  final CourseSummary? selectedCourse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recording = ref.watch(recordingViewModelProvider);
    final vm = ref.read(recordingViewModelProvider.notifier);
    if (!recording.isRecording) {
      return FilledButton.icon(
        onPressed: () => _start(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: Text(selectedCourse == null ? '기록 시작' : '이 코스로 기록 시작'),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: recording.isPaused ? vm.resumeRecording : vm.pause,
          icon: Icon(recording.isPaused ? Icons.directions_walk : Icons.free_breakfast_outlined),
          label: Text(recording.isPaused ? '다시 출발' : '휴식'),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () => showFinishFlow(context, ref),
          icon: const Icon(Icons.stop),
          label: const Text('정지'),
        ),
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final location = ref.read(locationServiceProvider);
    if (location is! MockLocationService && !await GeolocatorLocationService.ensurePermission()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한이 필요해요. 설정에서 산노트의 위치 접근을 허용해주세요.')),
      );
      return;
    }
    await ref.read(recordingViewModelProvider.notifier).start(course: selectedCourse);
  }
}
