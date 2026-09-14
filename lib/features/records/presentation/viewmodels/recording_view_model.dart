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
import '../../domain/usecases/finish_hike.dart';
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
  });

  /// 진행 중 산행 (null = 기록 안 함)
  final Hike? hike;
  final CourseSummary? course;
  final List<GeoPoint> track;
  final double distanceKm;
  final DateTime? lastFixAt;
  final String? error;

  /// 앱이 죽었다 켜졌을 때 발견된 미종료 산행 (사용자에게 이어가기/종료 물어봄)
  final Hike? resumable;

  bool get isRecording => hike != null;
  Duration get elapsed => hike == null ? Duration.zero : DateTime.now().difference(hike!.startedAt);

  RecordingState copyWith({
    Object? hike = _keep,
    Object? course = _keep,
    List<GeoPoint>? track,
    double? distanceKm,
    Object? lastFixAt = _keep,
    Object? error = _keep,
    Object? resumable = _keep,
  }) =>
      RecordingState(
        hike: hike == _keep ? this.hike : hike as Hike?,
        course: course == _keep ? this.course : course as CourseSummary?,
        track: track ?? this.track,
        distanceKm: distanceKm ?? this.distanceKm,
        lastFixAt: lastFixAt == _keep ? this.lastFixAt : lastFixAt as DateTime?,
        error: error == _keep ? this.error : error as String?,
        resumable: resumable == _keep ? this.resumable : resumable as Hike?,
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

  /// [시작]
  Future<void> start(CourseSummary course) async {
    if (state.isRecording) return;
    final hike = await ref.read(startHikeProvider).call(course.course);
    state = RecordingState(hike: hike, course: course);
    _listen();
    debugPrint('[record] 시작: ${course.course.name} (${ref.read(locationServiceProvider).label})');
  }

  /// 미종료 산행 이어가기 (트랙 복원 후 스트림 재구독)
  Future<void> resume(CourseSummary course) async {
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
        state = state.copyWith(error: '위치를 받을 수 없어요. 위치 권한과 GPS를 확인해주세요.');
      },
      onDone: () {
        // 실제 GPS 스트림은 끝나지 않는다. Mock 재생이 끝난 경우에만 온다.
        debugPrint('[record] 위치 스트림 종료 (mock 재생 끝)');
        if (kDebugMode && _debugAutoFinish.isNotEmpty && state.isRecording) {
          final status = HikeStatus.values.firstWhere((v) => v.name == _debugAutoFinish, orElse: () => HikeStatus.partial);
          unawaited(finish(status));
        }
      },
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRecording) state = state.copyWith(); // 경과 시간 갱신
    });
  }

  Future<void> _onFix(GeoPoint p) async {
    final hike = state.hike;
    if (hike == null) return;
    final now = DateTime.now();
    await ref.read(hikeRepositoryProvider).appendPoint(hike.id, TrackPoint(recordedAt: now, position: p));
    final track = [...state.track, p];
    // 실시간 거리도 종료 시와 같은 규칙(5m 미만 떨림 무시)으로 계산
    state = state.copyWith(track: track, distanceKm: FinishHike.trackDistanceKmOf(track), lastFixAt: now, error: null);
  }

  /// [종료] 1단계: 커버율 계산해 제안값 반환. 실제 마감은 [finish]에서 사용자 선택으로.
  double suggestCoverage() {
    final course = state.course;
    if (course == null) return 0;
    return ref.read(computeCourseCoverageProvider).call(course.polyline, state.track);
  }

  /// [종료] 2단계: 사용자가 고른 상태로 마감. 완주면 서버 전송 시도.
  Future<void> finish(HikeStatus status) async {
    final hike = state.hike;
    if (hike == null) return;
    _stopStream();
    final coverage = suggestCoverage();
    await ref.read(finishHikeProvider).call(hike.id, status: status, coverage: coverage);
    debugPrint('[record] 종료: ${hike.courseName} → ${status.name}, 커버율 ${(coverage * 100).toStringAsFixed(0)}%, '
        '${state.track.length}점 ${state.distanceKm.toStringAsFixed(2)}km');
    state = const RecordingState();
    if (status == HikeStatus.completed) {
      unawaited(ref.read(syncVisitsProvider).call());
    }
  }

  void _stopStream() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
  }
}

final recordingViewModelProvider = NotifierProvider<RecordingViewModel, RecordingState>(RecordingViewModel.new);
