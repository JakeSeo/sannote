import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/memo.dart';

import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../services/course_service.dart';

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this._service);

  final CourseService _service;
  final _memo = AsyncMemo<List<Course>>();

  @override
  Future<List<Course>> getAll() => _memo(() async {
        final rows = await _service.fetchAll();
        return rows.map(_toEntity).toList(growable: false);
      });

  static Course _toEntity(Map<String, dynamic> json) => Course(
        courseId: json['course_id'] as String,
        mountainGroup: json['mountain_group'] as String,
        name: json['name'] as String,
        segmentIds: (json['segment_ids'] as List).cast<String>(),
        entranceSpotId: json['entrance_spot'] as String?,
        description: json['description'] as String?,
      );
}

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepositoryImpl(ref.watch(courseServiceProvider)),
);
