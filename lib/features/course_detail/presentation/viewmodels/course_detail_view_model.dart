import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/find_along_course.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../safety/domain/entities/safety_point.dart';
import '../../../safety/domain/usecases/get_safety_points.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../spots/domain/usecases/get_mountain_spots.dart';

/// 코스 상세에 보여줄 경유 스팟 카테고리 (spots.category 원본 표기 기준)
const waypointCategories = {'조망점', '화장실', '음수대', '정자', '정상', '대피소', '유적(문화, 역사)', '위험지역'};

class CourseDetailState {
  const CourseDetailState({
    this.summary,
    this.waypoints = const [],
    this.safetyPoints = const [],
    this.isLoading = true,
    this.error,
  });

  final CourseSummary? summary;

  /// 코스 60m 이내 경유 스팟, 진행 순서
  final List<Spot> waypoints;

  /// 코스 120m 이내 구조 표지판 (참고용)
  final List<SafetyPoint> safetyPoints;
  final bool isLoading;
  final Object? error;

  Map<String, List<Spot>> get waypointsByCategory {
    final map = <String, List<Spot>>{};
    for (final w in waypoints) {
      map.putIfAbsent(w.category ?? '기타', () => []).add(w);
    }
    return map;
  }
}

class CourseDetailViewModel extends Notifier<CourseDetailState> {
  CourseDetailViewModel(this.courseId);

  final String courseId;

  @override
  CourseDetailState build() {
    _load();
    return const CourseDetailState();
  }

  Future<void> _load() async {
    try {
      final summaries = await ref.read(getCourseSummariesProvider).call();
      final summary = summaries.where((s) => s.course.courseId == courseId).firstOrNull;
      if (summary == null) {
        state = const CourseDetailState(isLoading: false, error: '코스를 찾을 수 없음');
        return;
      }
      final group = summary.course.mountainGroup;
      final (spots, safety) = await (
        ref.read(getMountainSpotsProvider).call(group),
        ref.read(getSafetyPointsProvider).call(group),
      ).wait;
      final along = ref.read(findAlongCourseProvider);
      final waypoints = along(
        summary.polyline,
        spots.where((s) => waypointCategories.contains(s.category)),
        (s) => s.position,
        radiusM: 60,
      );
      final safetyAlong = along(summary.polyline, safety, (p) => p.position, radiusM: 120);
      debugPrint('[course_detail] ${summary.course.name}: 경유 스팟 ${waypoints.length}, 구조표지판 ${safetyAlong.length}');
      state = CourseDetailState(summary: summary, waypoints: waypoints, safetyPoints: safetyAlong, isLoading: false);
    } catch (e, st) {
      debugPrint('[course_detail] $courseId 로드 실패: $e\n$st');
      state = CourseDetailState(isLoading: false, error: e);
    }
  }

  Future<void> retry() async {
    state = const CourseDetailState();
    await _load();
  }
}

final courseDetailViewModelProvider =
    NotifierProvider.family<CourseDetailViewModel, CourseDetailState, String>(CourseDetailViewModel.new);
