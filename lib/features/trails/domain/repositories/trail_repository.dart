import '../entities/trail_segment.dart';

abstract interface class TrailRepository {
  /// 등산로 구간 전체 (1,732건).
  Future<List<TrailSegment>> getAllSegments();
}
