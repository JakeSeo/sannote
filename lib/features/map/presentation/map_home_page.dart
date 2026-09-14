import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mountains/domain/mountain.dart';
import '../../mountains/presentation/mountains_provider.dart';
import '../../spots/presentation/entrances_provider.dart';
import '../../trails/presentation/segments_provider.dart';
import 'map_overlays.dart';
import 'selected_mountain_provider.dart';

/// 홈 = 지도. 7개 산군 마커 + 등산로망 전체(회색). 산을 탭하거나 줌인하면 그 산군을 강조.
class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  // 수도권 7개 산군이 한 화면에 들어오는 초기 카메라
  static const _overviewCamera = NCameraPosition(target: NLatLng(37.555, 127.02), zoom: 10);
  static const _focusZoom = 13.0;

  /// 이 줌 이상에서 카메라 중심 근처 산군을 자동 선택, 미만이면 선택 해제
  static const _autoFocusZoom = 12.0;
  static const _autoFocusRadiusKm = 5.0;

  NaverMapController? _controller;
  bool _networkDrawn = false;
  String? _drawnFocusGroup;
  final Set<String> _drawnEntranceIds = {};

  @override
  Widget build(BuildContext context) {
    final mountains = ref.watch(mountainsProvider);
    final segments = ref.watch(segmentsProvider);
    final entrances = ref.watch(entrancesProvider);
    final selected = ref.watch(selectedMountainProvider);

    // 데이터/선택 변화 → 오버레이 동기화 (컨트롤러 준비 후)
    ref.listen(mountainsProvider, (_, next) => _onMountains(next));
    ref.listen(segmentsProvider, (_, next) => _syncNetwork());
    ref.listen(selectedMountainProvider, (_, _) => _syncFocus());
    ref.listen(entrancesProvider, (_, _) => _syncFocus());
    _listenErrors();

    final isLoading = segments.isLoading || mountains.isLoading || entrances.isLoading;
    final selectedMountain = mountains.value
        ?.where((m) => m.mountainGroup == selected)
        .firstOrNull;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 태블릿(600+)은 정보 카드를 좌측 패널로 옮길 자리. 지금은 동일 레이아웃.
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
                child: _TopBar(isLoading: isLoading),
              ),
              if (selectedMountain != null)
                Positioned(
                  left: isTablet ? 16 : 12,
                  right: isTablet ? null : 12,
                  bottom: safe.bottom + 12,
                  width: isTablet ? 360 : null,
                  child: _MountainCard(
                    mountain: selectedMountain,
                    onClose: _showOverview,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ---------- 지도 이벤트 ----------

  void _onMapReady(NaverMapController controller) {
    _controller = controller;
    debugPrint('[map] naver map ready');
    _onMountains(ref.read(mountainsProvider));
    _syncNetwork();
    _syncFocus();
  }

  Future<void> _onCameraIdle() async {
    final controller = _controller;
    final mountains = ref.read(mountainsProvider).value;
    if (controller == null || mountains == null) return;
    try {
      final cam = await controller.getCameraPosition();
      if (cam.zoom < _autoFocusZoom) {
        ref.read(selectedMountainProvider.notifier).select(null);
        return;
      }
      final nearest = _nearestMountain(mountains, cam.target);
      debugPrint('[map] 카메라 idle zoom=${cam.zoom.toStringAsFixed(1)} → ${nearest?.mountainGroup ?? '없음'}');
      ref.read(selectedMountainProvider.notifier).select(nearest?.mountainGroup);
    } catch (e) {
      debugPrint('[map] 카메라 위치 조회 실패: $e');
    }
  }

  Mountain? _nearestMountain(List<Mountain> mountains, NLatLng target) {
    Mountain? best;
    var bestKm = _autoFocusRadiusKm;
    for (final m in mountains) {
      if (m.centerLat == null || m.centerLon == null) continue;
      final d = _distanceKm(target.latitude, target.longitude, m.centerLat!, m.centerLon!);
      if (d < bestKm) {
        bestKm = d;
        best = m;
      }
    }
    return best;
  }

  void _onMountainTap(Mountain m) {
    ref.read(selectedMountainProvider.notifier).select(m.mountainGroup);
    final update = NCameraUpdate.scrollAndZoomTo(
      target: NLatLng(m.centerLat!, m.centerLon!),
      zoom: _focusZoom,
    )..setAnimation(duration: const Duration(milliseconds: 600));
    _controller?.updateCamera(update);
  }

  void _showOverview() {
    ref.read(selectedMountainProvider.notifier).select(null);
    final update = NCameraUpdate.fromCameraPosition(_overviewCamera)
      ..setAnimation(duration: const Duration(milliseconds: 600));
    _controller?.updateCamera(update);
  }

  // ---------- 오버레이 동기화 ----------

  Future<void> _onMountains(AsyncValue<List<Mountain>> value) async {
    final controller = _controller;
    final mountains = value.value;
    if (controller == null || mountains == null) return;
    final markers = <NAddableOverlay>{
      for (final m in mountains) ?MapOverlays.mountainMarker(m, onTap: _onMountainTap),
    };
    await _guard('산 마커', () => controller.addOverlayAll(markers));
    // 카메라 idle이 데이터 로드보다 먼저 발생한 경우를 위해 현재 카메라 기준으로 재판정
    await _onCameraIdle();
  }

  Future<void> _syncNetwork() async {
    final controller = _controller;
    final segments = ref.read(segmentsProvider).value;
    if (controller == null || segments == null || _networkDrawn) return;
    _networkDrawn = true;
    final sw = Stopwatch()..start();
    await _guard('등산로망', () => controller.addOverlayAll(MapOverlays.networkOverlays(segments)));
    debugPrint('[map] 등산로망 ${segments.length}구간 렌더 (${sw.elapsedMilliseconds}ms)');
    await _syncFocus();
  }

  Future<void> _syncFocus() async {
    final controller = _controller;
    if (controller == null) return;
    final group = ref.read(selectedMountainProvider);
    final segments = ref.read(segmentsProvider).value;
    final entrances = ref.read(entrancesProvider).value;
    // 아직 그릴 데이터가 없으면 대기 (segments/entrances 로드 시 다시 호출됨)
    if (group != null && segments == null) return;
    final entranceIdsWanted = group == null || entrances == null
        ? const <String>{}
        : entrances
            .where((e) => e.mountainGroup == group)
            .map((e) => '${MapOverlays.entranceIdPrefix}${e.spotId}')
            .toSet();
    if (group == _drawnFocusGroup && _drawnEntranceIds.length == entranceIdsWanted.length) return;

    // 이전 강조 제거
    await _guard('강조 제거', () async {
      if (_drawnFocusGroup != null) {
        await controller.deleteOverlay(
          const NOverlayInfo(type: NOverlayType.multipartPathOverlay, id: MapOverlays.focusTrailId),
        );
        await controller.deleteOverlay(
          const NOverlayInfo(type: NOverlayType.multipartPathOverlay, id: MapOverlays.focusParkId),
        );
      }
      for (final id in _drawnEntranceIds) {
        await controller.deleteOverlay(NOverlayInfo(type: NOverlayType.marker, id: id));
      }
    });
    _drawnFocusGroup = null;
    _drawnEntranceIds.clear();
    if (group == null || segments == null) return;

    final ofGroup = segments.where((s) => s.mountainGroup == group).toList();
    final overlays = <NAddableOverlay>{...MapOverlays.focusOverlays(ofGroup)};
    if (entrances != null) {
      final markers = MapOverlays.entranceMarkers(
        entrances.where((e) => e.mountainGroup == group).toList(),
      );
      overlays.addAll(markers);
      _drawnEntranceIds.addAll(markers.map((m) => m.info.id));
    }
    _drawnFocusGroup = group;
    await _guard('산군 강조', () => controller.addOverlayAll(overlays));
    debugPrint('[map] $group 강조: 구간 ${ofGroup.length}개, 입구 ${_drawnEntranceIds.length}곳');
  }

  Future<void> _guard(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('[map] $what 오버레이 실패: $e\n$st');
    }
  }

  void _listenErrors() {
    void show(String what) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$what을 불러오지 못했어요. 네트워크를 확인해주세요.'),
          action: SnackBarAction(
            label: '다시 시도',
            onPressed: () {
              ref.invalidate(mountainsProvider);
              ref.invalidate(segmentsProvider);
              ref.invalidate(entrancesProvider);
            },
          ),
        ),
      );
    }

    ref.listen(mountainsProvider, (_, next) => next.hasError ? show('산 정보') : null);
    ref.listen(segmentsProvider, (_, next) => next.hasError ? show('등산로') : null);
    ref.listen(entrancesProvider, (_, next) => next.hasError ? show('입구 정보') : null);
  }

  /// 하버사인 거리 (km)
  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Material(
          color: scheme.surface,
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('산노트', style: Theme.of(context).textTheme.titleMedium),
                if (isLoading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 6),
                  Text('등산로 불러오는 중', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MountainCard extends StatelessWidget {
  const _MountainCard({required this.mountain, required this.onClose});

  final Mountain mountain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mountain.mountainGroup, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${mountain.regions} · 등산로 ${mountain.totalLengthKm}km · 입구 ${mountain.entranceCount}곳',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text('아직 칠해지지 않은 길 ${mountain.segmentCount}구간', style: text.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: '전체 보기',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
