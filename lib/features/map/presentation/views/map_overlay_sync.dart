import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../viewmodels/map_state.dart';
import 'map_overlays.dart';

/// [MapState] → NaverMapController 오버레이 반영. 이미 그린 것과 비교해 바뀐 것만 갱신한다.
/// (View 계층의 렌더 보조 객체. 비즈니스 로직 없음)
class MapOverlaySync {
  MapOverlaySync(this._controller, {required this.onMountainTap, required MapStyle style}) : _style = style; // ignore: prefer_initializing_formals

  final NaverMapController _controller;
  final void Function(Mountain) onMountainTap;
  MapStyle _style;

  /// 테마가 바뀌면 색이 달린 오버레이(완주·코스·마커)를 다시 그린다
  void setStyle(MapStyle style) {
    _style = style;
    _doneCount = -1;
    _courseId = '__redraw__';
    _markersDrawn = false;
  }

  bool _networkDrawn = false;
  bool _markersDrawn = false;
  String? _focusGroup;
  int _focusEntranceCount = -1;
  final Set<String> _drawnFocusIds = {};
  final Set<String> _entranceIds = {};
  String? _courseId;
  bool _courseDrawn = false;
  int _doneCount = -1;
  final Set<String> _doneIds = {};
  final Set<String> _markerIds = {};
  GeoPoint? _myLocation;
  int _liveCount = 0;

  Future<void> _queue = Future.value();

  /// 상태 반영. 연속 호출은 순서대로 직렬 실행한다 (동시에 addOverlay/deleteOverlay가 섞이면 누락됨).
  Future<void> apply(MapState s) {
    _queue = _queue.then((_) => _applyNow(s));
    return _queue;
  }

  Future<void> _applyNow(MapState s) async {
    await _syncMarkers(s);
    await _syncNetwork(s);
    await _syncDone(s);
    await _syncFocus(s);
    await _syncCourse(s);
    await _syncMyLocation(s);
    await _syncLiveTrack(s);
  }

  static const _liveId = 'live:track';

  /// 기록 중인 트랙 (파랑). 점이 늘어날 때만 갱신, 기록이 끝나면 제거.
  Future<void> _syncLiveTrack(MapState s) async {
    final track = s.liveTrack;
    if (track.length == _liveCount) return;
    if (track.length < 2) {
      if (_liveCount >= 2) await _delete(NOverlayType.polylineOverlay, _liveId);
      _liveCount = track.length;
      return;
    }
    _liveCount = track.length;
    await _guard('실시간 트랙', () => _controller.addOverlay(NPolylineOverlay(
          id: _liveId,
          coords: track.map(MapOverlays.toNLatLng).toList(growable: false),
          color: const Color(0xFF1E88E5),
          width: 4,
          lineCap: NLineCap.round,
          lineJoin: NLineJoin.round,
        )..setZIndex(50)));
  }

  /// SDK 기본 위치 오버레이(파란 점)를 우리 위치 서비스 값으로 움직인다. SDK의 자체 추적/권한 요청은 쓰지 않는다.
  Future<void> _syncMyLocation(MapState s) async {
    final p = s.myLocation;
    if (p == null || p == _myLocation) return;
    _myLocation = p;
    await _guard('내 위치', () async {
      final overlay = _controller.getLocationOverlay();
      overlay.setPosition(MapOverlays.toNLatLng(p));
      overlay.setIsVisible(true);
    });
  }

  /// 완주 구간 색칠. 구간 집합이 바뀌었을 때만 다시 그린다.
  Future<void> _syncDone(MapState s) async {
    if (s.segments.value == null) return;
    final completed = s.completedSegments;
    if (completed.length == _doneCount) return;
    _doneCount = completed.length;
    for (final id in _doneIds) {
      await _delete(NOverlayType.multipartPathOverlay, id);
    }
    _doneIds.clear();
    if (completed.isEmpty) return;
    final overlays = MapOverlays.doneOverlays(completed, _style);
    _doneIds.addAll(overlays.map((o) => o.info.id));
    await _guard('완주 색칠', () => _controller.addOverlayAll(overlays));
    debugPrint('[map] 완주 구간 ${completed.length}개 색칠 (${_doneIds.length} 오버레이)');
  }

  Future<void> _syncMarkers(MapState s) async {
    final mountains = s.mountains.value;
    if (_markersDrawn || mountains == null) return;
    _markersDrawn = true;
    for (final id in _markerIds) {
      await _delete(NOverlayType.marker, id);
    }
    _markerIds.clear();
    final markers = <NAddableOverlay>{
      for (final m in mountains)
        ?MapOverlays.mountainMarker(m, onTap: onMountainTap, icon: _style.markerIcons[m.mountainGroup]),
    };
    _markerIds.addAll(markers.map((o) => o.info.id));
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
    final overlays = MapOverlays.courseOverlays(view, _style);
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
