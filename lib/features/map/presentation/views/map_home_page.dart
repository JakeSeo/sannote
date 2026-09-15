import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/developer_menu.dart';
import '../../../records/presentation/viewmodels/recording_view_model.dart';
import '../../../records/presentation/views/recording_page.dart';
import '../viewmodels/map_state.dart';
import '../viewmodels/map_view_model.dart';
import 'map_overlay_sync.dart';
import 'map_overlays.dart';
import 'widgets/course_card.dart';
import 'widgets/mountain_card.dart';
import 'widgets/top_bar.dart';

/// 홈 = 지도 (View). 상태와 로직은 [MapViewModel]에, 오버레이 반영은 [MapOverlaySync]에 위임.
class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  static final _overviewCamera = NCameraPosition(
    target: MapOverlays.toNLatLng(MapViewModel.overviewCenter),
    zoom: MapViewModel.overviewZoom,
  );

  NaverMapController? _controller;
  MapOverlaySync? _sync;
  int _handledCameraSeq = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);

    ref.listen(mapViewModelProvider, (_, next) {
      _sync?.apply(next);
      _handleCamera(next.cameraCommand);
    });
    _listenErrors();

    final mountain = state.selectedMountain;
    final course = state.selectedCourse;
    final recording = ref.watch(recordingViewModelProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 태블릿(600+)은 카드를 좌측 패널 폭으로 제한. 레이아웃 분기 자리.
          final isTablet = constraints.maxWidth >= 600;
          final safe = MediaQuery.paddingOf(context);
          return Stack(
            children: [
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: _overviewCamera,
                  contentPadding: safe,
                  minZoom: 8,
                  logoClickEnable: false,
                  scaleBarEnable: false,
                ),
                onMapReady: _onMapReady,
                onCameraIdle: _onCameraIdle,
              ),
              Positioned(
                top: safe.top + 8,
                left: 12,
                right: 12,
                child: MapTopBar(
                  isLoading: state.isLoading,
                  conquest: state.conquest,
                  onLongPress: () => DeveloperMenu.show(context),
                ),
              ),
              // 내 위치 버튼 (우하단)
              Positioned(
                right: 12,
                bottom: safe.bottom + (mountain != null ? 180 : 88),
                child: FloatingActionButton.small(
                  heroTag: 'my_location',
                  tooltip: '내 위치',
                  onPressed: () => vm.locateMe(),
                  child: Icon(state.locationDenied ? Icons.location_disabled : Icons.my_location),
                ),
              ),
              // 기록 시작 / 기록 중 (하단 중앙) — 산행의 시작과 끝은 이 화면에서
              Positioned(
                left: 0,
                right: 0,
                bottom: safe.bottom + (mountain != null ? 180 : 20),
                child: Center(child: _RecordButton(recording: recording)),
              ),
              if (state.locationDenied && mountain == null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: safe.bottom + 80,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text('위치 권한이 없어 서울 전체를 보여드려요. 설정에서 산노트의 위치 접근을 허용하면 내 주변 산부터 보여요.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                ),
              if (mountain != null)
                Positioned(
                  left: 12,
                  right: isTablet ? null : 12,
                  bottom: safe.bottom + 12,
                  width: isTablet ? 380 : null,
                  child: course != null
                      ? CourseCard(view: course, onClose: vm.clearCourse)
                      : MountainCard(
                          mountain: mountain,
                          courses: state.coursesOfSelectedMountain,
                          onCourseTap: vm.selectCourse,
                          onClose: vm.showOverview,
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onMapReady(NaverMapController controller) {
    debugPrint('[map] naver map ready');
    _controller = controller;
    _sync = MapOverlaySync(controller, onMountainTap: ref.read(mapViewModelProvider.notifier).selectMountain);
    _sync!.apply(ref.read(mapViewModelProvider));
    // 지도가 기준점 = 내 위치. 첫 진입에서 권한을 요청한다 (맥락이 분명한 곳)
    ref.read(mapViewModelProvider.notifier).locateMe();
  }

  Future<void> _onCameraIdle() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final cam = await controller.getCameraPosition();
      ref.read(mapViewModelProvider.notifier).onCameraIdle(
            target: (lat: cam.target.latitude, lon: cam.target.longitude),
            zoom: cam.zoom,
          );
    } catch (e) {
      debugPrint('[map] 카메라 위치 조회 실패: $e');
    }
  }

  void _handleCamera(CameraCommand? cmd) {
    final controller = _controller;
    if (cmd == null || controller == null || cmd.seq == _handledCameraSeq) return;
    _handledCameraSeq = cmd.seq;
    final update = switch (cmd) {
      CameraOverview() => NCameraUpdate.fromCameraPosition(_overviewCamera),
      CameraFocus(:final target, :final zoom) =>
        NCameraUpdate.scrollAndZoomTo(target: MapOverlays.toNLatLng(target), zoom: zoom),
      CameraFitPoints(:final points) => NCameraUpdate.fitBounds(
          NLatLngBounds.from(points.map(MapOverlays.toNLatLng)),
          padding: const EdgeInsets.fromLTRB(40, 120, 40, 220),
        ),
    };
    update.setAnimation(duration: const Duration(milliseconds: 600));
    controller.updateCamera(update);
  }

  void _listenErrors() {
    void show(String what) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$what을 불러오지 못했어요. 네트워크를 확인해주세요.'),
          action: SnackBarAction(label: '다시 시도', onPressed: ref.read(mapViewModelProvider.notifier).retry),
        ),
      );
    }

    ref.listen(mapViewModelProvider.select((s) => s.mountains.hasError), (_, e) => e ? show('산 정보') : null);
    ref.listen(mapViewModelProvider.select((s) => s.segments.hasError), (_, e) => e ? show('등산로') : null);
    ref.listen(mapViewModelProvider.select((s) => s.entrances.hasError), (_, e) => e ? show('입구 정보') : null);
    ref.listen(mapViewModelProvider.select((s) => s.courses.hasError), (_, e) => e ? show('코스 정보') : null);
  }
}


/// 하단 중앙 기록 버튼. 기록 중이면 경과 시간을 보여주고 누르면 기록 화면으로.
class _RecordButton extends ConsumerWidget {
  const _RecordButton({required this.recording});

  final RecordingState recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recording.isRecording) {
      final e = recording.elapsed;
      final elapsed = '${e.inHours}:${(e.inMinutes % 60).toString().padLeft(2, '0')}:${(e.inSeconds % 60).toString().padLeft(2, '0')}';
      return FilledButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordingPage())),
        icon: const Icon(Icons.fiber_manual_record, color: Color(0xFFE53935)),
        label: Text('기록 중 $elapsed'),
      );
    }
    return FilledButton.icon(
      onPressed: () async {
        // 코스를 고르지 않고 시작. 종료 시 어느 코스를 걸었는지 자동 판별한다.
        await ref.read(recordingViewModelProvider.notifier).start();
        if (!context.mounted) return;
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordingPage()));
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text('기록 시작'),
    );
  }
}
