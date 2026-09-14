import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/entities/course_stats.dart';
import '../../../mountains/domain/entities/mountain.dart';
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
  });

  final AsyncValue<List<Mountain>> mountains;
  final AsyncValue<List<TrailSegment>> segments;
  final AsyncValue<List<Spot>> entrances;
  final AsyncValue<List<Course>> courses;

  /// 포커스된 산군 (null = 전체 개요)
  final String? selectedMountainGroup;

  /// 선택된 코스와 파생 정보 (null = 코스 미선택)
  final CourseView? selectedCourse;

  /// View가 1회 소비하는 카메라 이동 명령 (seq가 바뀔 때만 실행)
  final CameraCommand? cameraCommand;

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
  }) =>
      MapState(
        mountains: mountains ?? this.mountains,
        segments: segments ?? this.segments,
        entrances: entrances ?? this.entrances,
        courses: courses ?? this.courses,
        selectedMountainGroup: selectedMountainGroup == _keep
            ? this.selectedMountainGroup
            : selectedMountainGroup as String?,
        selectedCourse: selectedCourse == _keep ? this.selectedCourse : selectedCourse as CourseView?,
        cameraCommand: cameraCommand ?? this.cameraCommand,
      );

  static const _keep = Object();
}

/// 선택된 코스 + 구간 합산 결과 + 그릴 폴리라인.
class CourseView {
  const CourseView({
    required this.course,
    required this.segments,
    required this.stats,
    required this.polyline,
    required this.missingSegmentIds,
  });

  final Course course;
  final List<TrailSegment> segments;
  final CourseStats stats;
  final List<GeoPoint> polyline;

  /// courses.segment_ids 중 segments 테이블에 없는 id (데이터 오류 감지용)
  final List<String> missingSegmentIds;

  GeoPoint? get start => polyline.isEmpty ? null : polyline.first;
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
