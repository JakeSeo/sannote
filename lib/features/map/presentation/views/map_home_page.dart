import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/developer_menu.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/map_appearance.dart';
import '../../../../core/theme/mountain_palette.dart';
import '../../../records/presentation/views/reveal/course_reveal_overlay.dart';
import '../../../../core/theme/paper_texture.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../records/domain/entities/hike.dart';
import '../../../records/presentation/viewmodels/recording_view_model.dart';
import '../../../records/presentation/views/finish_flow.dart';
import '../../../records/presentation/views/records_page.dart';
import '../../../settings/presentation/views/settings_page.dart';
import '../viewmodels/map_state.dart';
import '../viewmodels/map_view_model.dart';
import 'map_overlay_sync.dart';
import 'map_overlays.dart';
import 'sheet/course_sheet_content.dart';
import 'sheet/stats_sheet_content.dart';
import 'widgets/record_controls.dart';

/// 홈 = 지도 하나 (산책노트). 상단 손글씨 앱 이름 + 우상단 메뉴(내가 모은 산책로·설정).
/// 지도: 회색 밑그림 + 내가 칠한 구간(산별 색) + 획득한 코스(탭하면 시트에 설명). 검색 없음.
/// 하단 시트(통계) 위에 [기록 시작] → 기록 중 [휴식][정지].
class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key, this.initialCourseId});

  /// 디버그/딥링크용 초기 선택 (획득한 코스만 의미 있음)
  final String? initialCourseId;

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> with WidgetsBindingObserver {
  static final _overviewCamera = NCameraPosition(
    target: MapOverlays.toNLatLng(MapViewModel.overviewCenter),
    zoom: MapViewModel.overviewZoom,
  );
  static const _sheetMin = 0.14;
  static const _sheetMid = 0.45;
  static const _sheetMax = 0.9;

  NaverMapController? _controller;
  MapOverlaySync? _sync;
  int _handledCameraSeq = 0;
  final _sheet = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheet.dispose();
    super.dispose();
  }

  bool _askingFinish = false;

  /// 앱으로 돌아왔을 때 10분 넘게 움직임이 없었으면 종료를 제안한다 (자동 종료는 하지 않음)
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // 화면 꺼짐/백그라운드 → 느슨한 간격, 복귀 → 촘촘한 간격
    final vm = ref.read(recordingViewModelProvider.notifier);
    switch (s) {
      case AppLifecycleState.resumed:
        vm.setProfile(TrackingProfile.foreground);
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        vm.setProfile(TrackingProfile.background);
      default:
        break;
    }
    if (s != AppLifecycleState.resumed || _askingFinish) return;
    if (!ref.read(recordingViewModelProvider.notifier).shouldAskFinish()) return;
    _askingFinish = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final idle = ref.read(recordingViewModelProvider).idleFor.inMinutes;
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('도착하셨나요?'),
          content: Text('$idle분 동안 움직임이 없어요. 멈춘 시간은 이동 시간에 들어가지 않지만, 도착했다면 산행을 종료할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('계속 기록')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('종료하기')),
          ],
        ),
      );
      _askingFinish = false;
      if (yes == true && mounted) await showFinishFlow(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);

    ref.listen(mapViewModelProvider, (_, next) {
      _sync?.apply(next);
      _handleCamera(next.cameraCommand);
    });
    ref.listen(themeVariantProvider, (_, v) async {
      final sync = _sync;
      if (sync == null) return;
      sync.setStyle(await _buildStyle(v));
      if (mounted) await sync.apply(ref.read(mapViewModelProvider));
    });
    // 사용자가 직접 고른 선택(검색·마커 탭)에만 시트를 올린다. 카메라 이동에 따른 자동 포커스는 지도 강조만.
    ref.listen(mapViewModelProvider.select((s) => s.selectedCourse?.course.courseId), (prev, next) {
      if (prev != next && next != null) _snapSheet(_sheetMid);
    });
    // 디버그 자동 종료(autohike) 결과에 획득 코스가 있으면 연출 재생
    ref.listen(recordingViewModelProvider.select((s) => s.isRecording), (prev, next) {
      if (prev == true && !next) {
        final r = ref.read(recordingViewModelProvider.notifier).takeAutoResult();
        if (r != null && r.discovered.isNotEmpty) showCourseReveal(context, r.discovered);
      }
    });
    ref.listen(recordingViewModelProvider.select((s) => s.resumable), (_, hike) {
      if (hike != null) _askResume(hike);
    });
    _listenErrors();

    final course = state.selectedCourse;
    final hasSelection = course != null;
    final appearance = ref.watch(mapAppearanceProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (hasSelection) {
          vm.showOverview();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final safe = MediaQuery.paddingOf(context);
            final height = constraints.maxHeight;
            return Stack(
              children: [
                NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: _overviewCamera,
                    contentPadding: EdgeInsets.only(top: safe.top + 64, bottom: height * _sheetMin),
                    minZoom: 8,
                    logoClickEnable: false,
                    scaleBarEnable: false,
                    // 배경을 조용히: 상점·랜드마크 심볼 크기 0 = 숨김. 지형 타입은 음영·등고선
                    symbolScale: appearance.symbolScale,
                    mapType: appearance.terrain ? NMapType.terrain : NMapType.basic,
                  ),
                  onMapReady: _onMapReady,
                  onCameraIdle: _onCameraIdle,
                ),
                // 상단: 앱 이름 + 메뉴
                Positioned(
                  top: safe.top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _AppTitle(subtitle: course?.course.name, onClear: hasSelection ? vm.showOverview : null),
                      const Spacer(),
                      _HomeMenu(onLongPress: () => DeveloperMenu.show(context)),
                    ],
                  ),
                ),
                // 내 위치 버튼
                AnimatedBuilder(
                  animation: _sheet,
                  builder: (context, _) {
                    final extent = _sheet.isAttached ? _sheet.size : _sheetMin;
                    // 시트가 절반 이상 올라오면 지도 위 버튼들은 숨긴다 (검색바와 겹침 방지)
                    if (extent > _sheetMid + 0.05) return const SizedBox.shrink();
                    return Positioned(
                      right: 12,
                      bottom: height * extent + 68,
                      child: FloatingActionButton.small(
                        heroTag: 'my_location',
                        tooltip: '내 위치',
                        // 걷는 게 보이는 축척으로 (첫 진입은 주변 산이 보이는 줌, 버튼은 50m 스케일)
                        onPressed: () => vm.locateMe(zoom: MapViewModel.walkingZoom),
                        child: Icon(state.locationDenied ? Icons.location_disabled : Icons.my_location),
                      ),
                    );
                  },
                ),
                // 바텀시트
                DraggableScrollableSheet(
                  controller: _sheet,
                  initialChildSize: _sheetMin,
                  minChildSize: _sheetMin,
                  maxChildSize: _sheetMax,
                  snap: true,
                  snapSizes: const [_sheetMin, _sheetMid, _sheetMax],
                  builder: (context, scroll) => _SheetBody(
                    scroll: scroll,
                    onClose: hasSelection ? vm.showOverview : null,
                    child: course != null ? CourseSheetContent(summary: course) : const StatsSheetContent(),
                  ),
                ),
                // 시트 위 기록 버튼
                AnimatedBuilder(
                  animation: _sheet,
                  builder: (context, _) {
                    final extent = _sheet.isAttached ? _sheet.size : _sheetMin;
                    if (extent > _sheetMid + 0.05) return const SizedBox.shrink();
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: height * extent + 12,
                      child: Center(child: RecordControls(selectedCourse: course)),
                    );
                  },
                ),
                if (state.locationDenied && !hasSelection)
                  Positioned(
                    left: 12,
                    right: 12,
                    top: safe.top + 68,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text('위치 권한이 없어 서울 전체를 보여드려요. 설정에서 산노트의 위치 접근을 허용하면 내 주변 산부터 보여요.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _snapSheet(double size) {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(size, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // ---------- 지도 이벤트 ----------

  /// 테마 → 지도 스타일. 스케치북이면 산별 색연필 색 + 2겹 선.
  Future<MapStyle> _buildStyle(ThemeVariant v) async {
    if (!v.isSketch) return MapStyle.plain(AppTheme.accentOf(v));
    return MapStyle(colorOf: (g) => MountainPalette.of(g, ink: v.inkTone), pencil: true);
  }

  Future<void> _onMapReady(NaverMapController controller) async {
    debugPrint('[map] naver map ready');
    _controller = controller;
    final vm = ref.read(mapViewModelProvider.notifier);
    _sync = MapOverlaySync(controller, onCourseTap: (c) => vm.selectCourse(c.course), style: await _buildStyle(ref.read(themeVariantProvider)));
    _sync!.apply(ref.read(mapViewModelProvider));
    if (widget.initialCourseId != null) {
      final s = (await ref.read(getCourseSummariesProvider).call()).where((x) => x.course.courseId == widget.initialCourseId).firstOrNull;
      if (s != null) vm.selectCourse(s.course);
    } else {
      vm.locateMe();
    }
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
      CameraFocus(:final target, :final zoom) => NCameraUpdate.scrollAndZoomTo(target: MapOverlays.toNLatLng(target), zoom: zoom),
      CameraFitPoints(:final points) => NCameraUpdate.fitBounds(
          NLatLngBounds.from(points.map(MapOverlays.toNLatLng)),
          // 시트(중간 높이)와 상단 검색바에 가리지 않게
          padding: EdgeInsets.fromLTRB(40, 120, 40, MediaQuery.sizeOf(context).height * _sheetMid + 40),
        ),
    };
    update.setAnimation(duration: const Duration(milliseconds: 600));
    controller.updateCamera(update);
  }

  // ---------- 미종료 산행 복구 ----------

  Future<void> _askResume(Hike hike) async {
    final vm = ref.read(recordingViewModelProvider.notifier);
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('끝내지 않은 산책이 있어요'),
        content: Text('${hike.startedAt.month}/${hike.startedAt.day} 시작\n이어서 기록할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('finish'), child: const Text('저장하고 마치기')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('resume'), child: const Text('이어가기')),
        ],
      ),
    );
    if (!mounted) return;
    final summaries = await ref.read(getCourseSummariesProvider).call();
    final course = hike.courseId == null ? null : summaries.where((s) => s.course.courseId == hike.courseId).firstOrNull;
    await vm.resume(course: course);
    if (choice != 'resume') {
      final r = await vm.finish();
      if (mounted && r.discovered.isNotEmpty) await showCourseReveal(context, r.discovered);
    }
    vm.dismissResumable();
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

/// 좌상단 앱 이름 (손글씨). 코스가 선택돼 있으면 아래에 코스 이름 + 닫기.
class _AppTitle extends ConsumerWidget {
  const _AppTitle({this.subtitle, this.onClear});

  final String? subtitle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sketch = ref.watch(themeVariantProvider).isSketch;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('산책노트',
                style: sketch
                    ? TextStyle(fontFamily: AppTheme.handwriting, fontSize: 26, fontWeight: FontWeight.w700, color: scheme.onSurface, height: 1)
                    : text.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(width: 10),
              Container(width: 1, height: 20, color: scheme.outlineVariant),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(subtitle!, style: text.bodyMedium, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              GestureDetector(onTap: onClear, child: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeMenu extends StatelessWidget {
  const _HomeMenu({required this.onLongPress});

  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Material(
        color: scheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: PopupMenuButton<String>(
          tooltip: '메뉴',
          icon: const Icon(Icons.menu),
          onSelected: (v) {
            switch (v) {
              case 'records':
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecordsPage()));
              case 'settings':
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'records', child: ListTile(leading: Icon(Icons.collections_bookmark_outlined), title: Text('내가 모은 산책로'))),
            PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('설정'))),
          ],
        ),
      ),
    );
  }
}

class _SheetBody extends ConsumerWidget {
  const _SheetBody({required this.scroll, required this.child, this.onClose});

  final ScrollController scroll;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sketch = ref.watch(themeVariantProvider).isSketch;
    final list = ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          if (onClose != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(onPressed: onClose, icon: const Icon(Icons.close, size: 16), label: const Text('닫기')),
            ),
          child,
        ],
      );
    return Material(
      color: sketch ? Colors.transparent : scheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: sketch ? PaperTexture(color: AppTheme.paper, child: list) : list,
    );
  }
}
