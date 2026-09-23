import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/notifications.dart';
import '../../../../core/geo/geo_point.dart';
import '../../../../core/location/location_provider.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../courses/domain/usecases/get_courses.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../../mountains/domain/usecases/get_mountains.dart';
import '../../../records/presentation/viewmodels/records_providers.dart';
import '../../../records/presentation/viewmodels/recording_view_model.dart';
import '../../../spots/domain/usecases/get_entrances.dart';
import '../../../trails/domain/usecases/get_trail_network.dart';
import 'map_state.dart';

/// 지도 화면 ViewModel. UseCase만 호출하고, View에는 [MapState]만 노출한다.
class MapViewModel extends Notifier<MapState> {
  /// 수도권 7개 산군이 한 화면에 들어오는 개요 카메라
  static const overviewCenter = (lat: 37.555, lon: 127.02);
  static const overviewZoom = 10.0;
  static const focusZoom = 13.0;

  /// 앱 첫 진입 줌: 반경 약 5km가 보여 가까운 산이 함께 잡힘
  static const myLocationZoom = 12.5;

  /// [내 위치] 버튼·기록 중 줌: 걷는 게 보이는 축척 (약 50m 스케일, 줌 17)
  static const walkingZoom = 17.0;


  var _cameraSeq = 0;

  @override
  MapState build() {
    _loadAll(); // 첫 await 이후에만 state를 건드리므로 build 중 state 변경 없음
    // 완주 통계는 listen으로 받아 상태에 합친다 (watch하면 build가 다시 돌아 선택 상태가 날아감)
    ref.listen(conquestStatsProvider, (_, next) {
      final v = next.value;
      if (v != null) state = state.copyWith(conquest: v);
    }, fireImmediately: true);
    ref.listen(discoveredSummariesProvider, (_, next) {
      final v = next.value;
      if (v != null) state = state.copyWith(discovered: v);
    }, fireImmediately: true);
    // 기록 중에는 기록 스트림의 트랙을 지도에 그리고, 마지막 위치를 내 위치로 쓴다 (GPS를 두 번 켜지 않기 위해)
    ref.listen(recordingViewModelProvider.select((s) => (s.isRecording, s.track)), (prev, r) {
      final (recording, track) = r;
      // 기록의 첫 위치가 들어오면 카메라를 그곳으로 (기록 시작 = 내 위치가 기준)
      final firstFix = recording && track.isNotEmpty && (prev?.$2.isEmpty ?? true);
      state = state.copyWith(
        liveTrack: recording ? track : const [],
        myLocation: track.lastOrNull ?? state.myLocation,
        cameraCommand: firstFix ? CameraFocus(++_cameraSeq, track.first, walkingZoom) : null,
      );
    });
    return const MapState();
  }

  // ---------- 내 위치 ----------

  /// 지도가 준비되면 호출. 권한을 요청하고(맥락: 지도) 내 위치로 카메라를 맞춘다.
  /// 거부되면 7개 산군 개요 카메라를 유지하고 안내 문구를 띄운다.
  Future<void> locateMe({bool moveCamera = true, double zoom = myLocationZoom}) async {
    final pos = await ref.read(locationServiceProvider).currentWithPermission();
    if (pos == null) {
      debugPrint('[map] 내 위치 없음 (권한 거부 또는 실패) → 개요 유지');
      state = state.copyWith(locationDenied: true);
      return;
    }
    debugPrint('[map] 내 위치 ${pos.lat.toStringAsFixed(5)}, ${pos.lon.toStringAsFixed(5)}');
    state = state.copyWith(
      myLocation: pos,
      locationDenied: false,
      cameraCommand: moveCamera ? CameraFocus(++_cameraSeq, pos, zoom) : null,
    );
    unawaited(_askNotificationPermissionOnce());
  }

  /// 기록 중 알림(Android 13+ POST_NOTIFICATIONS) 권한은 **지도 홈에서 미리** 한 번만 묻는다.
  /// 기록 시작 때 처음 물으면, 사용자가 팝업에 답하기 전에 앱을 나가는 순간
  /// 위치 스트림 시작이 막혀 기록이 통째로 날아간다 (RecordingViewModel.start 주석 참고).
  bool _askedNotification = false;

  Future<void> _askNotificationPermissionOnce() async {
    if (_askedNotification) return;
    _askedNotification = true;
    final noti = ref.read(notificationsProvider);
    if (await noti.hasPermission()) return;
    final ok = await noti.ensurePermission();
    debugPrint('[map] 기록 알림 권한: ${ok ? '허용' : '거부 — 기록 중 알림이 안 보입니다'}');
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

  /// 카메라가 멈췄을 때. (산책노트 피벗 후 자동 포커스 없음 — 밑그림은 항상 같은 회색)
  void onCameraIdle({required GeoPoint target, required double zoom}) {}

  /// 산 마커 탭: 포커스 + 카메라 이동
  void selectMountain(Mountain m) {
    final center = m.center;
    if (center == null) return;
    state = state.copyWith(
      selectedMountainGroup: m.mountainGroup,
      selectedCourse: null,
      explicitSelection: true,
      cameraCommand: CameraFocus(++_cameraSeq, center, focusZoom),
    );
  }

  /// 카드 닫기: 내 위치가 있으면 내 위치 기준으로, 없으면 7개 산군 개요로
  void showOverview() {
    final me = state.myLocation;
    state = state.copyWith(
      selectedMountainGroup: null,
      selectedCourse: null,
      explicitSelection: false,
      cameraCommand: me == null ? CameraOverview(++_cameraSeq) : CameraFocus(++_cameraSeq, me, myLocationZoom),
    );
  }

  /// 코스 선택: 구간 합산 → 요약 수치/폴리라인 계산, 코스 전체가 보이게 카메라 이동
  void selectCourse(Course course) {
    final all = state.segments.value;
    if (all == null) return;
    final byId = {for (final s in all) s.segmentId: s};
    final view = ref.read(getCourseSummariesProvider).summarize(course, byId);
    final stats = view.stats;
    debugPrint('[map] 코스 선택 "${course.name}": ${stats.segmentCount}구간 '
        '${stats.lengthKm.toStringAsFixed(2)}km 오름 예상 ${stats.estUpMin}분 '
        '난이도 ${stats.score.toStringAsFixed(1)}(${stats.level.label})');
    state = state.copyWith(
      selectedMountainGroup: course.mountainGroup,
      selectedCourse: view,
      explicitSelection: true,
      cameraCommand: view.polyline.isEmpty ? null : CameraFitPoints(++_cameraSeq, view.polyline),
    );
  }

  /// 코스 선택 해제 → 산군 포커스 상태로 복귀
  void clearCourse() {
    if (state.selectedCourse == null) return;
    state = state.copyWith(selectedCourse: null);
  }

  // ---------- 내부 ----------

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

final mapViewModelProvider = NotifierProvider<MapViewModel, MapState>(MapViewModel.new);
