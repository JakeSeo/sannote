import '../entities/safety_point.dart';

abstract interface class SafetyRepository {
  Future<List<SafetyPoint>> getByMountain(String mountainGroup);
}
