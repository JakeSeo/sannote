import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/usecases/build_course_polyline.dart';
import '../../../courses/domain/usecases/compute_course_stats.dart';
import '../../../courses/domain/usecases/get_courses.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../../mountains/domain/usecases/get_mountains.dart';
import '../../../records/presentation/viewmodels/records_providers.dart';
import '../../../spots/domain/usecases/get_entrances.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../../../trails/domain/usecases/get_trail_network.dart';
import 'map_state.dart';

/// 지도 화면 ViewModel. UseCase만 호출하고, View에는 [MapState]만 노출한다.
class MapViewModel extends Notifier<MapState> {
  /// 수도권 7개 산군이 한 화면에 들어오는 개요 카메라
  static const overviewCenter = (lat: 37.555, lon: 127.02);
  static const overviewZoom = 10.0;
  static const focusZoom = 13.0;

  /// 이 줌 이상에서 카메라 중심 근처 산군을 자동 선택, 미만이면 선택 해제
  static const autoFocusZoom = 12.0;
  static const autoFocusRadiusKm = 5.0;

  var _cameraSeq = 0;

  @override
  MapState build() {
    _loadAll(); // 첫 await 이후에만 state를 건드리므로 build 중 state 변경 없음
    // 완주 통계는 listen으로 받아 상태에 합친다 (watch하면 build가 다시 돌아 선택 상태가 날아감)
    ref.listen(conquestStatsProvider, (_, next) {
      final v = next.value;
      if (v != null) state = state.copyWith(conquest: v);
    }, fireImmediately: true);
    return const MapState();
  }

  // ---------- 데이터 로드 ----------

  Future<void> _loadAll() => Future.wait([
        _loadMountains(),
        _loadSegments(),
        _loadEntrances(),
        _loadCourses(),
      ]);

  Future<void> _loadMountains() async {
    final r = await AsyncValue.guard(() => ref.read(getMountainsProvider).call());
    _log('mountains', r, (v) => '${v.length}건');
    state = state.copyWith(mountains: r);
  }

  Future<void> _loadSegments() async {
    final r = await AsyncValue.guard(() => ref.read(getTrailNetworkProvider).call());
    _log('segments', r, (v) => '${v.length}건');
    state = state.copyWith(segments: r);
  }

  Future<void> _loadEntrances() async {
    final r = await AsyncValue.guard(() => ref.read(getEntrancesProvider).call());
    _log('entrances', r, (v) => '${v.length}건');
    state = state.copyWith(entrances: r);
  }

  Future<void> _loadCourses() async {
    final r = await AsyncValue.guard(() => ref.read(getCoursesProvider).call());
    _log('courses', r, (v) => '${v.length}건');
    state = state.copyWith(courses: r);
  }

  /// 실패한 데이터만 다시 불러온다.
  Future<void> retry() async {
    final tasks = <Future<void>>[
      if (state.mountains.hasError) _loadMountains(),
      if (state.segments.hasError) _loadSegments(),
      if (state.entrances.hasError) _loadEntrances(),
      if (state.courses.hasError) _loadCourses(),
    ];
    if (tasks.isEmpty) return;
    state = state.copyWith(
      mountains: state.mountains.hasError ? const AsyncValue.loading() : null,
      segments: state.segments.hasError ? const AsyncValue.loading() : null,
      entrances: state.entrances.hasError ? const AsyncValue.loading() : null,
      courses: state.courses.hasError ? const AsyncValue.loading() : null,
    );
    await Future.wait(tasks);
  }

  // ---------- 사용자 이벤트 ----------

  /// 카메라가 멈췄을 때. 줌인 상태면 중심 근처 산군을 자동 포커스한다.
  void onCameraIdle({required GeoPoint target, required double zoom}) {
    final mountains = state.mountains.value;
    if (mountains == null) return;
    final next = zoom < autoFocusZoom ? null : _nearestMountain(mountains, target)?.mountainGroup;
    if (next == state.selectedMountainGroup) return;
    debugPrint('[map] 카메라 idle zoom=${zoom.toStringAsFixed(1)} → ${next ?? '없음'}');
    state = state.copyWith(selectedMountainGroup: next, selectedCourse: null);
  }

  /// 산 마커 탭: 포커스 + 카메라 이동
  void selectMountain(Mountain m) {
    final center = m.center;
    if (center == null) return;
    state = state.copyWith(
      selectedMountainGroup: m.mountainGroup,
      selectedCourse: null,
      cameraCommand: CameraFocus(++_cameraSeq, center, focusZoom),
    );
  }

  void showOverview() {
    state = state.copyWith(
      selectedMountainGroup: null,
      selectedCourse: null,
      cameraCommand: CameraOverview(++_cameraSeq),
    );
  }

  /// 코스 선택: 구간 합산 → 요약 수치/폴리라인 계산, 코스 전체가 보이게 카메라 이동
  void selectCourse(Course course) {
    final all = state.segments.value;
    if (all == null) return;
    final byId = {for (final s in all) s.segmentId: s};
    final ordered = <TrailSegmentOrNull>[for (final id in course.segmentIds) byId[id]];
    final missing = [
      for (var i = 0; i < ordered.length; i++)
        if (ordered[i] == null) course.segmentIds[i],
    ];
    if (missing.isNotEmpty) {
      debugPrint('[map] 코스 "${course.name}"에 없는 구간 id: $missing');
    }
    final segments = ordered.nonNulls.toList(growable: false);
    final stats = ref.read(computeCourseStatsProvider).call(segments);
    final polyline = ref.read(buildCoursePolylineProvider).call(segments);
    final view = CourseView(
      course: course,
      segments: segments,
      stats: stats,
      polyline: polyline,
      missingSegmentIds: missing,
    );
    debugPrint('[map] 코스 선택 "${course.name}": ${stats.segmentCount}구간 '
        '${stats.lengthKm.toStringAsFixed(2)}km 오름 예상 ${stats.estUpMin}분 '
        '난이도 ${stats.score.toStringAsFixed(1)}(${stats.level.label})');
    state = state.copyWith(
      selectedMountainGroup: course.mountainGroup,
      selectedCourse: view,
      cameraCommand: polyline.isEmpty ? null : CameraFitPoints(++_cameraSeq, polyline),
    );
  }

  /// 코스 선택 해제 → 산군 포커스 상태로 복귀
  void clearCourse() {
    if (state.selectedCourse == null) return;
    state = state.copyWith(selectedCourse: null);
  }

  // ---------- 내부 ----------

  Mountain? _nearestMountain(List<Mountain> mountains, GeoPoint target) {
    Mountain? best;
    var bestKm = autoFocusRadiusKm;
    for (final m in mountains) {
      final c = m.center;
      if (c == null) continue;
      final d = distanceKm(target, c);
      if (d < bestKm) {
        bestKm = d;
        best = m;
      }
    }
    return best;
  }

  void _log<T>(String what, AsyncValue<T> r, String Function(T) summary) {
    switch (r) {
      case AsyncData(:final value):
        debugPrint('[supabase] $what ${summary(value)} 로드');
      case AsyncError(:final error, :final stackTrace):
        debugPrint('[supabase] $what 조회 실패: $error\n$stackTrace');
      default:
        break;
    }
  }
}

typedef TrailSegmentOrNull = TrailSegment?;

final mapViewModelProvider = NotifierProvider<MapViewModel, MapState>(MapViewModel.new);
