import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/device/battery.dart';
import '../../../../core/device/notifications.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/mock_location_service.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../data/repositories/hike_repository_impl.dart';
import '../../domain/entities/hike.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/usecases/compute_course_coverage.dart';
import '../../domain/usecases/compute_moving_time.dart';
import '../../domain/usecases/finish_hike.dart';
import '../../domain/usecases/paint_track.dart';
import '../../domain/usecases/start_hike.dart';
import '../../domain/usecases/sync_visits.dart';

class RecordingState {
  const RecordingState({
    this.hike,
    this.course,
    this.track = const [],
    this.distanceKm = 0,
    this.lastFixAt,
    this.error,
    this.resumable,
    this.isPaused = false,
    this.pausedTotal = Duration.zero,
    this.pausedSince,
    this.lastMovedAt,
    this.movingTime = Duration.zero,
    this.lastFix,
  });

  /// 진행 중 산행 (null = 기록 안 함)
  final Hike? hike;

  /// 미리 고른 코스 (null = 자유 산행 → 종료 시 자동 판별)
  final CourseSummary? course;
  final List<GeoPoint> track;
  final double distanceKm;
  final DateTime? lastFixAt;
  final String? error;

  /// 앱이 죽었다 켜졌을 때 발견된 미종료 산행 (사용자에게 이어가기/종료 물어봄)
  final Hike? resumable;

  /// 휴식 표시 (UI 상태). 위치는 계속 저장되고, 시간은 어차피 점 기반 이동 시간이라 멈춰 있으면 자동으로 빠진다.
  final bool isPaused;
  final Duration pausedTotal;
  final DateTime? pausedSince;

  /// 마지막으로 이동(5m 이상)이 감지된 시각. 도착 후 종료를 잊었는지 판단용
  final DateTime? lastMovedAt;

  /// 실시간 이동 시간 (ComputeMovingTime과 같은 규칙으로 누적)
  final Duration movingTime;
  final TrackPoint? lastFix;

  /// 움직임이 없는 시간
  Duration get idleFor => lastMovedAt == null ? Duration.zero : DateTime.now().difference(lastMovedAt!);

  bool get isRecording => hike != null;

  Duration get pausedSoFar =>
      pausedTotal + (pausedSince == null ? Duration.zero : DateTime.now().difference(pausedSince!));

  /// 경과 시간 (일시정지 제외)
  Duration get elapsed => hike == null ? Duration.zero : DateTime.now().difference(hike!.startedAt) - pausedSoFar;

  RecordingState copyWith({
    Object? hike = _keep,
    Object? course = _keep,
    List<GeoPoint>? track,
    double? distanceKm,
    Object? lastFixAt = _keep,
    Object? error = _keep,
    Object? resumable = _keep,
    bool? isPaused,
    Duration? pausedTotal,
    Object? pausedSince = _keep,
    Object? lastMovedAt = _keep,
    Duration? movingTime,
    Object? lastFix = _keep,
  }) =>
      RecordingState(
        hike: hike == _keep ? this.hike : hike as Hike?,
        course: course == _keep ? this.course : course as CourseSummary?,
        track: track ?? this.track,
        distanceKm: distanceKm ?? this.distanceKm,
        lastFixAt: lastFixAt == _keep ? this.lastFixAt : lastFixAt as DateTime?,
        error: error == _keep ? this.error : error as String?,
        resumable: resumable == _keep ? this.resumable : resumable as Hike?,
        isPaused: isPaused ?? this.isPaused,
        pausedTotal: pausedTotal ?? this.pausedTotal,
        pausedSince: pausedSince == _keep ? this.pausedSince : pausedSince as DateTime?,
        lastMovedAt: lastMovedAt == _keep ? this.lastMovedAt : lastMovedAt as DateTime?,
        movingTime: movingTime ?? this.movingTime,
        lastFix: lastFix == _keep ? this.lastFix : lastFix as TrackPoint?,
      );
  static const _keep = Object();
}

/// 디버그 전용: `--dart-define=SANNOTE_AUTOFINISH=completed|partial` 이면 Mock 재생이 끝날 때 자동 종료
const _debugAutoFinish = String.fromEnvironment('SANNOTE_AUTOFINISH');

/// 산행 기록 컨트롤러. 위치 스트림 구독 → 로컬 DB에 점 추가. 화면과 무관하게 살아 있어야 한다.
class RecordingViewModel extends Notifier<RecordingState> {
  StreamSubscription<GeoPoint>? _sub;
  Timer? _ticker;

  /// 첫 위치가 한참 안 들어오면 사용자에게 알린다 (스트림이 조용히 죽은 경우를 종료 때까지 모르지 않도록)
  Timer? _firstFixWatchdog;
  static const _firstFixTimeout = Duration(seconds: 90);
  TrackingProfile _profile = TrackingProfile.foreground;
  int? _batteryAtStart;

  @override
  RecordingState build() {
    ref.onDispose(_stopStream);
    _checkResumable();
    return const RecordingState();
  }

  Future<void> _checkResumable() async {
    final active = await ref.read(hikeRepositoryProvider).getActive();
    if (active != null) {
      debugPrint('[record] 미종료 산행 발견: ${active.courseName} (${active.startedAt})');
      state = state.copyWith(resumable: active);
    }
  }

  /// [기록 시작]. 코스는 옵션 — 지도 홈에서는 없이, 코스 화면에서는 그 코스로.
  Future<void> start({CourseSummary? course}) async {
    if (state.isRecording) return;
    final hike = await ref.read(startHikeProvider).call(course: course?.course);
    state = RecordingState(hike: hike, course: course, lastMovedAt: DateTime.now());
    // ⚠️ 여기서 _listen() 앞에 await 를 절대 넣지 말 것.
    // 위치 스트림(= Android 포그라운드 서비스)은 앱이 화면에 보이는 동안 시작해야 한다.
    // 권한 팝업 같은 걸 먼저 기다리면, 사용자가 답하기 전에 홈으로 나가는 순간
    // 스트림이 영영 시작되지 않거나(팝업 미응답) 백그라운드에서 시작돼 차단된다 → 점 0개.
    _listen();
    // 알림 권한은 스트림이 붙은 뒤에 따로 묻는다 (기록을 막지 않음)
    unawaited(_askNotificationPermission());
    _batteryAtStart = await ref.read(batteryProvider).level();
    debugPrint('[record] 시작: ${course?.course.name ?? '자유 산행'} (${ref.read(locationServiceProvider).label}) '
        '배터리 ${_batteryAtStart ?? '?'}%');
  }

  /// 미종료 산행 이어가기 (트랙 복원 후 스트림 재구독)
  Future<void> resume({CourseSummary? course}) async {
    final hike = state.resumable;
    if (hike == null) return;
    final points = await ref.read(hikeRepositoryProvider).getPoints(hike.id);
    state = RecordingState(
      hike: hike,
      course: course,
      track: points.map((p) => p.position).toList(),
      distanceKm: FinishHike.trackDistanceKm(points),
    );
    _listen(); // start()와 같은 이유로 await 보다 먼저
    unawaited(_askNotificationPermission());
  }

  void dismissResumable() => state = state.copyWith(resumable: null);

  /// 기록 중 알림(Android 13+)이 보이도록 권한을 묻는다. 기록 흐름을 막지 않게 항상 fire-and-forget.
  Future<void> _askNotificationPermission() async {
    final ok = await ref.read(notificationsProvider).ensurePermission();
    if (!ok) debugPrint('[record] 알림 권한 없음 — "산책 기록 중" 알림이 표시되지 않습니다 (기록은 계속됨)');
  }

  /// 화면 켜짐/꺼짐에 따라 저장 간격 프로필 전환 (Mock 재생 중에는 바꾸지 않음).
  ///
  /// **위치 스트림은 절대 다시 구독하지 않는다.** 백그라운드에서 재구독하면
  /// Android는 포그라운드 서비스를 백그라운드에서 다시 시작하는 셈이라 막히고,
  /// iOS는 업데이트가 끊긴 순간 앱이 서스펜드돼 재구독이 실행되지 않아서
  /// 백그라운드 동안 점이 한 개도 안 들어온다. 간격 조절은 [_onFix]에서 솎아내는 것으로 한다.
  void setProfile(TrackingProfile profile) {
    if (!state.isRecording || profile == _profile) return;
    if (ref.read(locationServiceProvider) is MockLocationService) return;
    _profile = profile;
    debugPrint('[record] 저장 간격 전환 → ${profile.name} (${profile.interval.inSeconds}s / ${profile.distanceM}m)');
  }

  void _listen() {
    _stopStream();
    debugPrint('[record] 위치 스트림 구독 (${ref.read(locationServiceProvider).label})');
    _sub = ref.read(locationServiceProvider).positions().listen(
      _onFix,
      onError: (Object e) {
        debugPrint('[record] 위치 스트림 오류: $e');
        state = state.copyWith(
          error: '위치를 받을 수 없어 기록이 진행되지 않아요. 위치 권한과 GPS를 확인한 뒤 종료하고 다시 시작해주세요.',
        );
      },
      onDone: () {
        // 실제 GPS 스트림은 끝나지 않는다. Mock 재생이 끝난 경우에만 온다.
        debugPrint('[record] 위치 스트림 종료 (mock 재생 끝)');
        if (kDebugMode && _debugAutoFinish.isNotEmpty && state.isRecording) {
          final status = HikeStatus.values.firstWhere((v) => v.name == _debugAutoFinish, orElse: () => HikeStatus.partial);
          unawaited(_autoFinish(status));
        }
      },
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRecording) state = state.copyWith(); // 경과 시간 갱신
    });
    _firstFixWatchdog = Timer(_firstFixTimeout, () {
      if (!state.isRecording || state.track.isNotEmpty) return;
      debugPrint('[record] ${_firstFixTimeout.inSeconds}초째 위치 0점 — 스트림이 열리지 않았을 수 있음');
      state = state.copyWith(
        error: '아직 위치 신호를 못 받았어요. 하늘이 보이는 곳으로 나가보고, 그래도 안 되면 기록을 종료했다 다시 시작해주세요.',
      );
    });
  }

  /// 휴식 표시. 리스닝과 저장은 그대로 계속된다 (UI 상태만 바뀜)
  void pause() {
    if (!state.isRecording || state.isPaused) return;
    state = state.copyWith(isPaused: true, pausedSince: DateTime.now());
    debugPrint('[record] 휴식 표시');
  }

  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;
    final since = state.pausedSince;
    final now = DateTime.now();
    state = state.copyWith(
      isPaused: false,
      pausedTotal: state.pausedTotal + (since == null ? Duration.zero : now.difference(since)),
      pausedSince: null,
    );
    debugPrint('[record] 휴식 해제 (누적 ${state.pausedTotal.inSeconds}초)');
  }

  /// 움직임이 [threshold] 이상 없으면 true → UI가 "도착하셨나요?" 확인을 띄운다 (자동 종료는 하지 않음)
  bool shouldAskFinish({Duration threshold = const Duration(minutes: 10)}) =>
      state.isRecording && state.track.isNotEmpty && state.idleFor >= threshold;

  /// 배경 프로필에서는 들어온 점을 다 저장하지 않고 솎아낸다.
  /// (스트림 자체는 항상 촘촘하게 받는다 — 재구독하면 백그라운드 위치가 끊기므로)
  bool _tooSoon(GeoPoint p, DateTime now) {
    if (_profile == TrackingProfile.foreground) return false;
    final prev = state.lastFix;
    if (prev == null) return false;
    final movedM = distanceKm(prev.position, p) * 1000;
    return now.difference(prev.recordedAt) < _profile.interval && movedM < _profile.distanceM;
  }

  Future<void> _onFix(GeoPoint p) async {
    final hike = state.hike;
    if (hike == null) return;
    _firstFixWatchdog?.cancel(); // 한 점이라도 들어오면 스트림은 살아 있다
    _firstFixWatchdog = null;
    final now = DateTime.now();
    if (_tooSoon(p, now)) return;
    if (state.track.length < 3 || state.track.length % 20 == 0) {
      debugPrint('[record] 위치 수신 #${state.track.length + 1}: ${p.lat.toStringAsFixed(5)}, ${p.lon.toStringAsFixed(5)}');
    }
    try {
      await ref.read(hikeRepositoryProvider).appendPoint(hike.id, TrackPoint(recordedAt: now, position: p));
    } catch (e, st) {
      debugPrint('[record] 점 저장 실패: $e\n$st');
      state = state.copyWith(error: '기록 저장에 실패했어요. 저장 공간을 확인해주세요.');
      return;
    }
    final track = [...state.track, p];
    final fix = TrackPoint(recordedAt: now, position: p);
    // 이동 시간: 이전 점과의 간격 중 실제로 움직인 구간만 누적 (종료 시 ComputeMovingTime과 같은 규칙)
    final prev = state.lastFix;
    final step = prev == null ? Duration.zero : ComputeMovingTime.step(prev.recordedAt, prev.position, now, p);
    state = state.copyWith(
      track: track,
      distanceKm: FinishHike.trackDistanceKmOf(track), // 실시간 거리도 종료 시와 같은 규칙(5m 미만 떨림 무시)
      lastFixAt: now,
      lastFix: fix,
      movingTime: state.movingTime + step,
      lastMovedAt: step > Duration.zero || prev == null ? now : state.lastMovedAt,
      error: null,
    );
  }

  /// [종료]: 기록을 저장하고 트랙에 닿은 구간을 칠한다. 구간이 다 칠해진 코스가 있으면 획득.
  /// 반환값은 획득 연출용. [discard]면 기록만 지운다.
  Future<PaintResult> finish({bool discard = false}) async {
    final hike = state.hike;
    if (hike == null) return PaintResult.empty;
    _stopStream();
    final track = state.track;
    final batteryAtEnd = await ref.read(batteryProvider).level();
    if (discard) {
      await ref.read(finishHikeProvider).call(hike.id, status: HikeStatus.discarded, coverage: null);
      debugPrint('[record] 삭제: ${track.length}점');
      state = const RecordingState();
      _batteryAtStart = null;
      _profile = TrackingProfile.foreground;
      return PaintResult.empty;
    }
    // 1) 구간 색칠 + 코스 획득
    final result = await ref.read(paintTrackProvider).call(hikeId: hike.id, track: track);
    // 2) 기록 마감. 획득한 코스가 있으면 첫 코스를 기록에 연결(completed) → visits 전송 대상
    final got = result.discovered.firstOrNull;
    final coverage = got == null ? null : ref.read(computeCourseCoverageProvider).call(got.polyline, track);
    await ref.read(finishHikeProvider).call(
      hike.id,
      status: got == null ? HikeStatus.partial : HikeStatus.completed,
      coverage: coverage,
      course: got?.course,
      batteryStart: _batteryAtStart,
      batteryEnd: batteryAtEnd,
    );
    final drain = _batteryAtStart != null && batteryAtEnd != null ? '${_batteryAtStart! - batteryAtEnd}%p 소모' : '?';
    debugPrint('[record] 종료: ${got?.course.name ?? '산책'} · 새로 칠한 구간 ${result.newlyPainted.length} · 획득 ${result.discovered.length}, '
        '${track.length}점 ${state.distanceKm.toStringAsFixed(2)}km, 이동 ${state.movingTime.inSeconds}초 / 총 ${state.elapsed.inSeconds}초, '
        '배터리 ${_batteryAtStart ?? '?'}% → ${batteryAtEnd ?? '?'}% ($drain, 프로필 ${_profile.name})');
    // 디버그 자동 종료면 상태를 비우기 전에 결과를 남겨 홈의 리스너가 연출을 재생할 수 있게 한다
    if (_autoMode) _lastAutoResult = result;
    state = const RecordingState();
    _batteryAtStart = null;
    _profile = TrackingProfile.foreground;
    if (got != null) unawaited(ref.read(syncVisitsProvider).call());
    return result;
  }

  /// 디버그 자동 종료
  Future<void> _autoFinish(HikeStatus status) async {
    _autoMode = true;
    await finish(discard: status == HikeStatus.discarded);
    _autoMode = false;
  }

  /// 디버그 자동 종료 결과 (연출 트리거용)
  bool _autoMode = false;
  PaintResult? _lastAutoResult;
  PaintResult? takeAutoResult() {
    final r = _lastAutoResult;
    _lastAutoResult = null;
    return r;
  }

  void _stopStream() {
    _sub?.cancel();
    _sub = null;
    _firstFixWatchdog?.cancel();
    _firstFixWatchdog = null;
    _ticker?.cancel();
    _ticker = null;
  }
}

final recordingViewModelProvider = NotifierProvider<RecordingViewModel, RecordingState>(RecordingViewModel.new);
