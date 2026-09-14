import '../entities/hike.dart';
import '../entities/track_point.dart';

/// 로컬(기기) 산행 기록 저장소. 트랙은 여기에만 있다.
abstract interface class HikeRepository {
  Future<Hike> create({
    required String id,
    required String courseId,
    required String courseName,
    required String mountainGroup,
    required DateTime startedAt,
  });

  Future<void> appendPoint(String hikeId, TrackPoint point);

  Future<void> finish(
    String hikeId, {
    required DateTime endedAt,
    required HikeStatus status,
    required double distanceKm,
    required double? coverage,
  });

  Future<void> markSynced(String hikeId, {required String visitId, required DateTime syncedAt});

  Future<void> delete(String hikeId);

  Future<Hike?> getById(String hikeId);

  /// 앱이 죽었다 살아난 경우 남아 있는 recording 상태 산행
  Future<Hike?> getActive();

  Future<List<Hike>> getAll();

  /// 변화 스트림 (기록 추가/종료 시 UI 갱신용)
  Stream<List<Hike>> watchAll();

  Future<List<TrackPoint>> getPoints(String hikeId);

  Future<int> countPoints(String hikeId);
}
