import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course_summary.dart';
import 'compute_course_coverage.dart';

/// 트랙과 코스의 일치도.
class CourseMatch {
  const CourseMatch({required this.course, required this.coverage, required this.trackFit});

  final CourseSummary course;

  /// 코스 폴리라인 중 트랙 40m 이내에 있는 비율 (코스를 얼마나 걸었나)
  final double coverage;

  /// 트랙 점 중 코스 40m 이내에 있는 비율 (코스를 벗어나지 않았나)
  final double trackFit;

  /// 정렬 점수. 커버율 위주, 이탈은 보조
  double get score => coverage * 0.7 + trackFit * 0.3;
}

/// 종료한 트랙이 어느 코스인지 자동 판별 (코스 단위. 구간 단위 맵매칭은 v2).
/// 기록 시 코스를 안 골랐을 때 쓴다. 결과는 점수 순, 최소 커버율 미만은 제외.
class MatchCourse {
  const MatchCourse(this._coverage);

  final ComputeCourseCoverage _coverage;

  static const minCoverage = 0.6;

  List<CourseMatch> call(List<GeoPoint> track, List<CourseSummary> courses) {
    if (track.length < 2) return const [];
    final bounds = _bounds(track);
    final out = <CourseMatch>[];
    for (final c in courses) {
      if (c.polyline.length < 2 || !_overlaps(bounds, _bounds(c.polyline), padKm: 0.3)) continue;
      final cov = _coverage(c.polyline, track);
      if (cov < minCoverage) continue;
      final fit = _coverage(track, c.polyline); // 대칭 계산: 트랙 점이 코스 근처에 있는 비율
      out.add(CourseMatch(course: c, coverage: cov, trackFit: fit));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  static (double, double, double, double) _bounds(List<GeoPoint> pts) {
    var minLat = double.infinity, maxLat = -double.infinity, minLon = double.infinity, maxLon = -double.infinity;
    for (final p in pts) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLon = math.min(minLon, p.lon);
      maxLon = math.max(maxLon, p.lon);
    }
    return (minLat, maxLat, minLon, maxLon);
  }

  static bool _overlaps((double, double, double, double) a, (double, double, double, double) b, {required double padKm}) {
    final pad = padKm / 111; // 대략 도 단위
    return a.$1 - pad <= b.$2 && b.$1 - pad <= a.$2 && a.$3 - pad <= b.$4 && b.$3 - pad <= a.$4;
  }
}

final matchCourseProvider = Provider<MatchCourse>((ref) => MatchCourse(ref.watch(computeCourseCoverageProvider)));
