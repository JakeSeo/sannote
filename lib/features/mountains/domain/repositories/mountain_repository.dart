import '../entities/mountain.dart';

abstract interface class MountainRepository {
  /// 산군 전체 (7건).
  Future<List<Mountain>> getAll();
}
