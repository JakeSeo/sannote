import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trails/data/repositories/trail_repository_impl.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../../../trails/domain/repositories/trail_repository.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../entities/course.dart';
import '../entities/course_summary.dart';
import '../repositories/course_repository.dart';
import 'build_course_polyline.dart';
import 'compute_course_stats.dart';

/// 코스 전체를 구간과 합쳐 요약(거리/시간/난이도/폴리라인)으로 만든다.
class GetCourseSummaries {
  const GetCourseSummaries(this._courses, this._trails, this._stats, this._polyline);

  final CourseRepository _courses;
  final TrailRepository _trails;
  final ComputeCourseStats _stats;
  final BuildCoursePolyline _polyline;

  Future<List<CourseSummary>> call() async {
    final (courses, segments) = await (_courses.getAll(), _trails.getAllSegments()).wait;
    final byId = {for (final s in segments) s.segmentId: s};
    return courses.map((c) => summarize(c, byId)).toList(growable: false);
  }

  CourseSummary summarize(Course course, Map<String, TrailSegment> byId) {
    final ordered = <TrailSegment>[];
    final missing = <String>[];
    for (final id in course.segmentIds) {
      final s = byId[id];
      if (s == null) {
        missing.add(id);
      } else {
        ordered.add(s);
      }
    }
    if (missing.isNotEmpty) {
      debugPrint('[courses] "${course.name}"에 없는 구간 id: $missing');
    }
    return CourseSummary(
      course: course,
      segments: ordered,
      stats: _stats(ordered),
      polyline: _polyline(ordered),
      missingSegmentIds: missing,
    );
  }
}

final getCourseSummariesProvider = Provider<GetCourseSummaries>(
  (ref) => GetCourseSummaries(
    ref.watch(courseRepositoryProvider),
    ref.watch(trailRepositoryProvider),
    ref.watch(computeCourseStatsProvider),
    ref.watch(buildCoursePolylineProvider),
  ),
);
