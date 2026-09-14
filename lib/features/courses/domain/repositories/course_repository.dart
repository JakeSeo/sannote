import '../entities/course.dart';

abstract interface class CourseRepository {
  /// 큐레이션된 코스 전체 (v1은 소수라 한 번에 로드).
  Future<List<Course>> getAll();
}
