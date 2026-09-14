import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/developer_menu.dart';
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
