import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../mountains/domain/entities/mountain.dart';
import '../viewmodels/map_state.dart';
import 'map_overlays.dart';

/// [MapState] → NaverMapController 오버레이 반영. 이미 그린 것과 비교해 바뀐 것만 갱신한다.
/// (View 계층의 렌더 보조 객체. 비즈니스 로직 없음)
class MapOverlaySync {
  MapOverlaySync(this._controller, {required this.onMountainTap});

  final NaverMapController _controller;
  final void Function(Mountain) onMountainTap;

  bool _networkDrawn = false;
  bool _markersDrawn = false;
  String? _focusGroup;
  int _focusEntranceCount = -1;
  final Set<String> _drawnFocusIds = {};
  final Set<String> _entranceIds = {};
  String? _courseId;
  bool _courseDrawn = false;

  Future<void> _queue = Future.value();

  /// 상태 반영. 연속 호출은 순서대로 직렬 실행한다 (동시에 addOverlay/deleteOverlay가 섞이면 누락됨).
  Future<void> apply(MapState s) {
    _queue = _queue.then((_) => _applyNow(s));
    return _queue;
  }

  Future<void> _applyNow(MapState s) async {
    await _syncMarkers(s);
    await _syncNetwork(s);
    await _syncFocus(s);
    await _syncCourse(s);
  }

  Future<void> _syncMarkers(MapState s) async {
    final mountains = s.mountains.value;
    if (_markersDrawn || mountains == null) return;
    _markersDrawn = true;
    final markers = <NAddableOverlay>{
      for (final m in mountains) ?MapOverlays.mountainMarker(m, onTap: onMountainTap),
    };
    await _guard('산 마커', () => _controller.addOverlayAll(markers));
  }

  Future<void> _syncNetwork(MapState s) async {
    final segments = s.segments.value;
    if (_networkDrawn || segments == null) return;
    _networkDrawn = true;
    final sw = Stopwatch()..start();
    await _guard('등산로망', () => _controller.addOverlayAll(MapOverlays.networkOverlays(segments)));
    debugPrint('[map] 등산로망 ${segments.length}구간 렌더 (${sw.elapsedMilliseconds}ms)');
  }

  Future<void> _syncFocus(MapState s) async {
    final group = s.selectedMountainGroup;
    final focusSegments = s.focusSegments;
    final focusEntrances = s.focusEntrances;
    // 구간 데이터가 아직 없으면 대기 (로드되면 다음 apply에서 그림)
    if (group != null && s.segments.value == null) return;
    if (group == _focusGroup && focusEntrances.length == _focusEntranceCount) return;

    // 실제로 그린 것만 삭제 (없는 오버레이 삭제는 SDK assertion)
    for (final id in _drawnFocusIds) {
      await _delete(NOverlayType.multipartPathOverlay, id);
    }
    for (final id in _entranceIds) {
      await _delete(NOverlayType.marker, id);
    }
    _drawnFocusIds.clear();
    _entranceIds.clear();
    _focusGroup = group;
    _focusEntranceCount = focusEntrances.length;
    if (group == null) return;

    final focus = MapOverlays.focusOverlays(focusSegments);
    final markers = MapOverlays.entranceMarkers(focusEntrances);
    _drawnFocusIds.addAll(focus.map((o) => o.info.id));
    _entranceIds.addAll(markers.map((m) => m.info.id));
    await _guard('산군 강조', () => _controller.addOverlayAll({...focus, ...markers}));
    debugPrint('[map] $group 강조: 구간 ${focusSegments.length}개, 입구 ${markers.length}곳');
  }

  Future<void> _syncCourse(MapState s) async {
    final view = s.selectedCourse;
    final id = view?.course.courseId;
    if (id == _courseId) return;
    _courseId = id;
    if (_courseDrawn) {
      await _delete(NOverlayType.pathOverlay, MapOverlays.coursePathId);
      await _delete(NOverlayType.marker, MapOverlays.courseStartId);
      _courseDrawn = false;
    }
    if (view == null) return;
    final overlays = MapOverlays.courseOverlays(view);
    if (overlays.isEmpty) return;
    _courseDrawn = true;
    await _guard('코스 강조', () => _controller.addOverlayAll(overlays));
  }

  Future<void> _delete(NOverlayType type, String id) =>
      _guard('$id 삭제', () => _controller.deleteOverlay(MapOverlays.info(type, id)));

  Future<void> _guard(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('[map] $what 오버레이 실패: $e\n$st');
    }
  }
}
