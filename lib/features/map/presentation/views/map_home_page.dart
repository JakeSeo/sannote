import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/developer_menu.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../records/domain/entities/hike.dart';
import '../../../records/presentation/viewmodels/recording_view_model.dart';
import '../../../records/presentation/views/records_page.dart';
import '../../../search/presentation/views/search_page.dart';
import '../../../settings/presentation/views/settings_page.dart';
import '../viewmodels/map_state.dart';
import '../viewmodels/map_view_model.dart';
import 'map_overlay_sync.dart';
import 'map_overlays.dart';
import 'sheet/course_sheet_content.dart';
import 'sheet/mountain_sheet_content.dart';
import 'sheet/stats_sheet_content.dart';
import 'widgets/record_controls.dart';

/// 홈 = 지도 하나. 상단 검색바 + 메뉴, 하단 바텀시트(통계/산/코스), 시트 위 기록 버튼.
/// 탭 없음. 검색 결과를 고르면 지도가 그 대상으로 이동하고 시트에 설명이 뜬다.
/// 뒤로가기: 선택이 있으면 검색 화면으로 돌아가고, 없으면 앱 종료.
class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key, this.initialCourseId, this.initialMountainGroup});

  /// 디버그/딥링크용 초기 선택
  final String? initialCourseId;
  final String? initialMountainGroup;

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
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

  /// 마지막 검색어 (뒤로가기로 검색 화면 복원용). null = 검색을 거치지 않은 선택
  String? _lastQuery;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapViewModelProvider);
    final vm = ref.read(mapViewModelProvider.notifier);

    ref.listen(mapViewModelProvider, (_, next) {
      _sync?.apply(next);
      _handleCamera(next.cameraCommand);
    });
    // 사용자가 직접 고른 선택(검색·마커 탭)에만 시트를 올린다. 카메라 이동에 따른 자동 포커스는 지도 강조만.
    ref.listen(mapViewModelProvider.select((s) => (s.explicitMountain?.mountainGroup, s.selectedCourse?.course.courseId)),
        (prev, next) {
      if (prev != next && (next.$1 != null || next.$2 != null)) _snapSheet(_sheetMid);
    });
    ref.listen(recordingViewModelProvider.select((s) => s.resumable), (_, hike) {
      if (hike != null) _askResume(hike);
    });
    _listenErrors();

    final mountain = state.explicitMountain;
    final course = state.selectedCourse;
    final hasSelection = mountain != null || course != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (hasSelection) {
          // 선택 → 검색 화면으로 돌아가기 (지도 앱과 같은 뒤로가기 동선)
          final q = _lastQuery;
          vm.showOverview();
          if (q != null) _openSearch(initialQuery: q);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
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
                  ),
                  onMapReady: _onMapReady,
                  onCameraIdle: _onCameraIdle,
                ),
                // 상단: 검색바 + 메뉴
                Positioned(
                  top: safe.top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTablet ? 480 : double.infinity),
                          child: _SearchBar(
                            label: course?.course.name ?? mountain?.mountainGroup ?? _lastQuery,
                            onTap: () => _openSearch(initialQuery: _lastQuery ?? ''),
                            onClear: hasSelection ? vm.showOverview : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                        onPressed: () => vm.locateMe(),
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
                    child: course != null
                        ? CourseSheetContent(summary: course)
                        : mountain != null
                            ? MountainSheetContent(mountain: mountain, onCourseTap: vm.selectCourse)
                            : const StatsSheetContent(),
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
                    top: safe.top + 64,
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

  // ---------- 검색 ----------

  Future<void> _openSearch({String initialQuery = ''}) async {
    final result = await Navigator.of(context).push<SearchSelection>(
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: initialQuery)),
    );
    if (result == null || !mounted) return;
    _lastQuery = result.query;
    final vm = ref.read(mapViewModelProvider.notifier);
    switch (result) {
      case CourseSelection(:final courseId):
        final summaries = await ref.read(getCourseSummariesProvider).call();
        final s = summaries.where((x) => x.course.courseId == courseId).firstOrNull;
        if (s != null) vm.selectCourse(s.course);
      case MountainSelection(:final mountainGroup):
        final m = ref.read(mapViewModelProvider).mountains.value?.where((x) => x.mountainGroup == mountainGroup).firstOrNull;
        if (m != null) vm.selectMountain(m);
    }
  }

  void _snapSheet(double size) {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(size, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // ---------- 지도 이벤트 ----------

  void _onMapReady(NaverMapController controller) {
    debugPrint('[map] naver map ready');
    _controller = controller;
    final vm = ref.read(mapViewModelProvider.notifier);
    _sync = MapOverlaySync(controller, onMountainTap: vm.selectMountain);
    _sync!.apply(ref.read(mapViewModelProvider));
    if (widget.initialCourseId != null || widget.initialMountainGroup != null) {
      _applyInitialSelection();
    } else {
      vm.locateMe();
    }
  }

  Future<void> _applyInitialSelection() async {
    final vm = ref.read(mapViewModelProvider.notifier);
    if (widget.initialCourseId != null) {
      final s = (await ref.read(getCourseSummariesProvider).call())
          .where((x) => x.course.courseId == widget.initialCourseId)
          .firstOrNull;
      if (s != null) vm.selectCourse(s.course);
    } else {
      // 산 데이터가 로드될 때까지 잠깐 대기
      for (var i = 0; i < 20; i++) {
        final m = ref.read(mapViewModelProvider).mountains.value?.where((x) => x.mountainGroup == widget.initialMountainGroup).firstOrNull;
        if (m != null) {
          vm.selectMountain(m);
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
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
        title: const Text('끝내지 않은 산행이 있어요'),
        content: Text('${hike.displayName} · ${hike.startedAt.month}/${hike.startedAt.day} 시작\n이어서 기록할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('finish'), child: const Text('일부로 저장하고 종료')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('resume'), child: const Text('이어가기')),
        ],
      ),
    );
    if (!mounted) return;
    final summaries = await ref.read(getCourseSummariesProvider).call();
    final course = hike.courseId == null ? null : summaries.where((s) => s.course.courseId == hike.courseId).firstOrNull;
    await vm.resume(course: course);
    if (choice != 'resume') await vm.finish(HikeStatus.partial);
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, this.label, this.onClear});

  final VoidCallback onTap;
  final String? label;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label == null || label!.isEmpty ? '산, 코스 검색' : label!,
                  style: text.bodyLarge?.copyWith(color: label == null || label!.isEmpty ? scheme.onSurfaceVariant : scheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                GestureDetector(onTap: onClear, child: Icon(Icons.close, size: 20, color: scheme.onSurfaceVariant)),
            ],
          ),
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
            PopupMenuItem(value: 'records', child: ListTile(leading: Icon(Icons.history), title: Text('내 기록'))),
            PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('설정'))),
          ],
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.scroll, required this.child, this.onClose});

  final ScrollController scroll;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
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
      ),
    );
  }
}
