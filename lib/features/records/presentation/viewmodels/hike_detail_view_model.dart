import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../domain/entities/hike.dart';
import '../../domain/usecases/get_hikes.dart';

class HikeDetail {
  const HikeDetail({required this.hike, required this.track, required this.course});

  final Hike hike;
  final List<GeoPoint> track;

  /// 코스가 삭제됐을 수도 있어 null 가능
  final CourseSummary? course;
}

/// 기록 상세: 트랙 + 코스 폴리라인 겹쳐 보기.
final hikeDetailProvider = FutureProvider.family<HikeDetail?, String>((ref, hikeId) async {
  final hikes = ref.read(getHikesProvider);
  final hike = await hikes.byId(hikeId);
  if (hike == null) return null;
  final (points, summaries) = await (hikes.points(hikeId), ref.read(getCourseSummariesProvider).call()).wait;
  return HikeDetail(
    hike: hike,
    track: points.map((p) => p.position).toList(growable: false),
    course: summaries.where((s) => s.course.courseId == hike.courseId).firstOrNull,
  );
});
