import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Colors;
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../viewmodels/map_state.dart';
import 'map_overlays.dart';

/// [MapState] → NaverMapController 오버레이 반영. 이미 그린 것과 비교해 바뀐 것만 갱신한다.
/// (View 계층의 렌더 보조 객체. 비즈니스 로직 없음)
class MapOverlaySync {
  MapOverlaySync(this._controller, {required this.onCourseTap, required MapStyle style}) : _style = style; // ignore: prefer_initializing_formals

  final NaverMapController _controller;
  final void Function(CourseSummary) onCourseTap;
  MapStyle _style;

  /// 테마가 바뀌면 색이 달린 오버레이(칠한 구간·획득 코스·선택 코스)를 다시 그린다
  void setStyle(MapStyle style) {
    _style = style;
    _doneCount = -1;
    _discoveredCount = -1;
    _courseId = '__redraw__';
  }

  bool _networkDrawn = false;
  String? _courseId;
  bool _courseDrawn = false;
  int _doneCount = -1;
  final Set<String> _doneIds = {};
  GeoPoint? _myLocation;
  int _liveCount = 0;

  Future<void> _queue = Future.value();

  /// 상태 반영. 연속 호출은 순서대로 직렬 실행한다 (동시에 addOverlay/deleteOverlay가 섞이면 누락됨).
  Future<void> apply(MapState s) {
    _queue = _queue.then((_) => _applyNow(s));
    return _queue;
  }

  Future<void> _applyNow(MapState s) async {
    await _syncNetwork(s);
    await _syncDone(s);
    await _syncDiscovered(s);
    await _syncCourse(s);
    await _syncMyLocation(s);
    await _syncLiveTrack(s);
  }

  final Set<String> _discoveredIds = {};
  int _discoveredCount = -1;

  /// 획득한 코스: 그 산의 색으로 굵게 + 탭하면 선택. 미획득 코스는 그리지 않는다.
  Future<void> _syncDiscovered(MapState s) async {
    if (s.discovered.length == _discoveredCount) return;
    _discoveredCount = s.discovered.length;
    for (final id in _discoveredIds) {
      await _delete(NOverlayType.pathOverlay, id);
    }
    _discoveredIds.clear();
    if (s.discovered.isEmpty) return;
    final overlays = <NAddableOverlay>{};
    for (final c in s.discovered) {
      if (c.polyline.length < 2) continue;
      final color = _style.colorOf(c.course.mountainGroup);
      final path = NPathOverlay(
        id: 'disc:${c.course.courseId}',
        coords: c.polyline.map(MapOverlays.toNLatLng).toList(growable: false),
        width: 7,
        color: color,
        outlineWidth: 2,
        outlineColor: Colors.white,
        passedColor: color,
        passedOutlineColor: Colors.white,
      )..setZIndex(25);
      path.setOnTapListener((_) => onCourseTap(c));
      overlays.add(path);
      _discoveredIds.add(path.info.id);
    }
    await _guard('획득 코스', () => _controller.addOverlayAll(overlays));
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

  Future<void> _syncNetwork(MapState s) async {
    final segments = s.segments.value;
    if (_networkDrawn || segments == null) return;
    _networkDrawn = true;
    final sw = Stopwatch()..start();
    await _guard('등산로망', () => _controller.addOverlayAll(MapOverlays.networkOverlays(segments)));
    debugPrint('[map] 등산로망 ${segments.length}구간 렌더 (${sw.elapsedMilliseconds}ms)');
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
