import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../../core/location/location_provider.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../data/repositories/hike_repository_impl.dart';
import '../../domain/entities/hike.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/usecases/compute_course_coverage.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../domain/usecases/finish_hike.dart';
import '../../domain/usecases/match_course.dart';
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

  /// 일시정지 상태. 위치는 받아도 저장하지 않고, 경과 시간에서 제외한다.
  final bool isPaused;
  final Duration pausedTotal;
  final DateTime? pausedSince;

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
      );
  static const _keep = Object();
}

/// 디버그 전용: `--dart-define=SANNOTE_AUTOFINISH=completed|partial` 이면 Mock 재생이 끝날 때 자동 종료
const _debugAutoFinish = String.fromEnvironment('SANNOTE_AUTOFINISH');

/// 산행 기록 컨트롤러. 위치 스트림 구독 → 로컬 DB에 점 추가. 화면과 무관하게 살아 있어야 한다.
class RecordingViewModel extends Notifier<RecordingState> {
  StreamSubscription<GeoPoint>? _sub;
  Timer? _ticker;

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
    state = RecordingState(hike: hike, course: course);
    _listen();
    debugPrint('[record] 시작: ${course?.course.name ?? '자유 산행'} (${ref.read(locationServiceProvider).label})');
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
    _listen();
  }

  void dismissResumable() => state = state.copyWith(resumable: null);

  void _listen() {
    _stopStream();
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
  }

  /// 일시정지: 위치 저장 중단, 경과 시간 멈춤 (스트림은 유지해 재시작이 즉시 되도록)
  void pause() {
    if (!state.isRecording || state.isPaused) return;
    state = state.copyWith(isPaused: true, pausedSince: DateTime.now());
    debugPrint('[record] 일시정지');
  }

  void resumeRecording() {
    if (!state.isRecording || !state.isPaused) return;
    final since = state.pausedSince;
    state = state.copyWith(
      isPaused: false,
      pausedTotal: state.pausedTotal + (since == null ? Duration.zero : DateTime.now().difference(since)),
      pausedSince: null,
    );
    debugPrint('[record] 재시작 (누적 일시정지 ${state.pausedTotal.inSeconds}초)');
  }

  Future<void> _onFix(GeoPoint p) async {
    final hike = state.hike;
    if (hike == null) return;
    if (state.isPaused) {
      state = state.copyWith(lastFixAt: DateTime.now(), error: null);
      return;
    }
    final now = DateTime.now();
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
    // 실시간 거리도 종료 시와 같은 규칙(5m 미만 떨림 무시)으로 계산
    state = state.copyWith(track: track, distanceKm: FinishHike.trackDistanceKmOf(track), lastFixAt: now, error: null);
  }

  /// [종료] 1단계: 어느 코스를 걸었는지 판별.
  /// 미리 고른 코스가 있으면 그 코스의 커버율만, 없으면 모든 코스와 대조해 점수 순으로 돌려준다.
  Future<List<CourseMatch>> matchCourses() async {
    final pre = state.course;
    if (pre != null) {
      final cov = ref.read(computeCourseCoverageProvider).call(pre.polyline, state.track);
      return [CourseMatch(course: pre, coverage: cov, trackFit: 1)];
    }
    final all = await ref.read(getCourseSummariesProvider).call();
    final matches = ref.read(matchCourseProvider).call(state.track, all);
    debugPrint('[record] 코스 판별: ${matches.map((m) => '${m.course.course.name} ${(m.coverage * 100).round()}%').join(', ')}');
    return matches;
  }

  /// [종료] 2단계: 사용자가 확인한 상태·코스로 마감. 완주면 서버 전송 시도.
  Future<void> finish(HikeStatus status, {CourseMatch? match}) async {
    final hike = state.hike;
    if (hike == null) return;
    _stopStream();
    final course = match?.course ?? state.course;
    final coverage = match?.coverage;
    await ref.read(finishHikeProvider).call(
      hike.id,
      status: status,
      coverage: coverage,
      course: course?.course,
      pausedSec: state.pausedSoFar.inSeconds,
    );
    debugPrint('[record] 종료: ${course?.course.name ?? '자유 산행'} → ${status.name}, '
        '커버율 ${coverage == null ? '-' : '${(coverage * 100).round()}%'}, '
        '${state.track.length}점 ${state.distanceKm.toStringAsFixed(2)}km');
    state = const RecordingState();
    if (status == HikeStatus.completed && course != null) {
      unawaited(ref.read(syncVisitsProvider).call());
    }
  }

  /// 디버그 자동 종료: 판별 1위 코스로 마감 (없으면 자유 산행 일부)
  Future<void> _autoFinish(HikeStatus status) async {
    final matches = await matchCourses();
    final top = matches.firstOrNull;
    await finish(top == null ? HikeStatus.partial : status, match: top);
  }

  void _stopStream() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
  }
}

final recordingViewModelProvider = NotifierProvider<RecordingViewModel, RecordingState>(RecordingViewModel.new);
