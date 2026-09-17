import '../entities/hike.dart';
import '../entities/track_point.dart';

/// 로컬(기기) 산행 기록 저장소. 트랙은 여기에만 있다.
abstract interface class HikeRepository {
  /// 코스 없이(null) 시작하면 자유 산행. 종료 시 [finish]에서 코스를 채울 수 있다.
  Future<Hike> create({
    required String id,
    required DateTime startedAt,
    String? courseId,
    String? courseName,
    String? mountainGroup,
  });

  Future<void> appendPoint(String hikeId, TrackPoint point);

  Future<void> finish(
    String hikeId, {
    required DateTime endedAt,
    required HikeStatus status,
    required double distanceKm,
    required double? coverage,
    String? courseId,
    String? courseName,
    String? mountainGroup,
    int pausedSec = 0,
    int movingSec = 0,
    int? batteryStart,
    int? batteryEnd,
  });

  Future<void> markSynced(String hikeId, {required String visitId, required DateTime syncedAt});

  /// 옛 기록의 이동 시간 채우기 (스키마 v4 이전 기록)
  Future<void> updateMovingSec(String hikeId, int movingSec);

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
