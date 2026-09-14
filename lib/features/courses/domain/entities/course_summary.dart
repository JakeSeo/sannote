import '../../../../core/geo/geo_point.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import 'course.dart';
import 'course_stats.dart';

/// 코스 + 구간 합산 결과 + 폴리라인. 목록/상세 화면의 기본 단위.
class CourseSummary {
  const CourseSummary({
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
