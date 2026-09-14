import '../entities/spot.dart';

abstract interface class SpotRepository {
  /// 입구(시종점) 전체. entrances 뷰 = spots where is_entrance=1 (286건).
  Future<List<Spot>> getEntrances();
}
