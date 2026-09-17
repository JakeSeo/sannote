import '../entities/paint.dart';

/// 칠한 구간·획득 코스 (로컬). 서버에는 올리지 않는다 (visits 메타데이터만).
abstract interface class PaintRepository {
  Future<Set<String>> paintedSegmentIds();
  Future<List<PaintedSegment>> paintedSegments();
  Stream<List<PaintedSegment>> watchPainted();

  /// 이미 칠한 구간은 건너뛰고 새로 칠한 id만 돌려준다
  Future<Set<String>> paint(Iterable<PaintedSegment> segments);

  Future<Set<String>> discoveredCourseIds();
  Future<List<DiscoveredCourse>> discoveredCourses();
  Stream<List<DiscoveredCourse>> watchDiscovered();
  Future<void> discover(Iterable<DiscoveredCourse> courses);

  /// 기록 삭제 시 그 기록으로 칠한 구간·획득 코스도 되돌린다
  Future<void> removeByHike(String hikeId);
}
