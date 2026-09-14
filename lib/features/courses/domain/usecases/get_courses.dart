import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/course_repository_impl.dart';
import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetCourses {
  const GetCourses(this._repo);

  final CourseRepository _repo;

  Future<List<Course>> call() => _repo.getAll();
}

final getCoursesProvider = Provider<GetCourses>(
  (ref) => GetCourses(ref.watch(courseRepositoryProvider)),
);
