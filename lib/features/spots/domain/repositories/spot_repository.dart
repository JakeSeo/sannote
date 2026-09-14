import '../entities/entrance_access.dart';
import '../entities/spot.dart';

abstract interface class SpotRepository {
  /// 입구(시종점) 전체. entrances 뷰 = spots where is_entrance=1 (286건).
  Future<List<Spot>> getEntrances();

  /// 산군의 스팟 전체 (분기점·가로등 등 포함, 수백 건).
  Future<List<Spot>> getSpotsOfMountain(String mountainGroup);

  /// 산군 입구들의 지하철 접근 정보. 테이블이 아직 없으면 빈 목록.
  Future<List<EntranceAccess>> getEntranceAccess(String mountainGroup);
}
