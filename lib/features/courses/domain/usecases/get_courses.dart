import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/test_data.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetCourses {
  const GetCourses(this._repo);

  final CourseRepository _repo;

  Future<List<Course>> call() async =>
      (await _repo.getAll()).where((c) => TestData.show(c.mountainGroup)).toList(growable: false);
}

final getCoursesProvider = Provider<GetCourses>(
  (ref) => GetCourses(ref.watch(courseRepositoryProvider)),
);
