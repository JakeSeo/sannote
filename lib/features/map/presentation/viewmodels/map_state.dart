import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../../records/domain/entities/conquest_stats.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../trails/domain/entities/trail_segment.dart';

/// 지도 화면의 단일 상태. View는 이 객체만 보고 그린다.
class MapState {
  const MapState({
    this.mountains = const AsyncValue.loading(),
    this.segments = const AsyncValue.loading(),
    this.entrances = const AsyncValue.loading(),
    this.courses = const AsyncValue.loading(),
    this.selectedMountainGroup,
    this.selectedCourse,
    this.cameraCommand,
    this.conquest = ConquestStats.empty,
    this.myLocation,
    this.locationDenied = false,
    this.liveTrack = const [],
    this.explicitSelection = false,
    this.discovered = const [],
  });

  final AsyncValue<List<Mountain>> mountains;
  final AsyncValue<List<TrailSegment>> segments;
  final AsyncValue<List<Spot>> entrances;
  final AsyncValue<List<Course>> courses;

  /// 포커스된 산군 (null = 전체 개요)
  final String? selectedMountainGroup;

  /// 선택된 코스와 파생 정보 (null = 코스 미선택)
  final CourseSummary? selectedCourse;

  /// View가 1회 소비하는 카메라 이동 명령 (seq가 바뀔 때만 실행)
  final CameraCommand? cameraCommand;

  /// 완주 코스 합집합 (색칠 대상 구간 + 헤더 숫자)
  final ConquestStats conquest;

  /// 내 현재 위치 (지도의 기준점). null = 아직 모름
  final GeoPoint? myLocation;

  /// 위치 권한이 거부됨 → 안내 문구 + 개요 카메라
  final bool locationDenied;

  /// 기록 중인 내 트랙 (기록이 끝나면 비움)
  final List<GeoPoint> liveTrack;

  /// true = 사용자가 직접 고른 선택(마커 탭·검색). 시트 내용과 뒤로가기는 이것만 따른다.
  /// false = 카메라 이동으로 근처 산이 자동 포커스된 상태(지도 강조만).
  final bool explicitSelection;

  Mountain? get explicitMountain => explicitSelection ? selectedMountain : null;

  /// 내가 칠한 구간들 (산별 색으로 그림)
  List<TrailSegment> get completedSegments => conquest.isEmpty
      ? const []
      : (segments.value ?? const []).where((s) => conquest.completedSegmentIds.contains(s.segmentId)).toList();

  /// 획득한 코스들 (지도에 표시·탭 가능). 미획득 코스는 지도에 없다
  final List<CourseSummary> discovered;

  bool get isLoading => mountains.isLoading || segments.isLoading || entrances.isLoading || courses.isLoading;

  Mountain? get selectedMountain =>
      mountains.value?.where((m) => m.mountainGroup == selectedMountainGroup).firstOrNull;

  List<TrailSegment> get focusSegments => selectedMountainGroup == null
      ? const []
      : (segments.value ?? const []).where((s) => s.mountainGroup == selectedMountainGroup).toList();

  List<Spot> get focusEntrances => selectedMountainGroup == null
      ? const []
      : (entrances.value ?? const []).where((e) => e.mountainGroup == selectedMountainGroup).toList();

  List<Course> get coursesOfSelectedMountain => selectedMountainGroup == null
      ? const []
      : (courses.value ?? const []).where((c) => c.mountainGroup == selectedMountainGroup).toList();

  MapState copyWith({
    AsyncValue<List<Mountain>>? mountains,
    AsyncValue<List<TrailSegment>>? segments,
    AsyncValue<List<Spot>>? entrances,
    AsyncValue<List<Course>>? courses,
    Object? selectedMountainGroup = _keep,
    Object? selectedCourse = _keep,
    CameraCommand? cameraCommand,
    ConquestStats? conquest,
    Object? myLocation = _keep,
    bool? locationDenied,
    List<GeoPoint>? liveTrack,
    bool? explicitSelection,
    List<CourseSummary>? discovered,
  }) =>
      MapState(
        mountains: mountains ?? this.mountains,
        segments: segments ?? this.segments,
        entrances: entrances ?? this.entrances,
        courses: courses ?? this.courses,
        selectedMountainGroup: selectedMountainGroup == _keep
            ? this.selectedMountainGroup
            : selectedMountainGroup as String?,
        selectedCourse: selectedCourse == _keep ? this.selectedCourse : selectedCourse as CourseSummary?,
        cameraCommand: cameraCommand ?? this.cameraCommand,
        conquest: conquest ?? this.conquest,
        myLocation: myLocation == _keep ? this.myLocation : myLocation as GeoPoint?,
        locationDenied: locationDenied ?? this.locationDenied,
        liveTrack: liveTrack ?? this.liveTrack,
        explicitSelection: explicitSelection ?? this.explicitSelection,
        discovered: discovered ?? this.discovered,
      );

  static const _keep = Object();
}

sealed class CameraCommand {
  const CameraCommand(this.seq);

  /// 명령 식별자. View는 마지막으로 처리한 seq와 다를 때만 실행한다.
  final int seq;
}

class CameraOverview extends CameraCommand {
  const CameraOverview(super.seq);
}

class CameraFocus extends CameraCommand {
  const CameraFocus(super.seq, this.target, this.zoom);
  final GeoPoint target;
  final double zoom;
}

class CameraFitPoints extends CameraCommand {
  const CameraFitPoints(super.seq, this.points);
  final List<GeoPoint> points;
}
