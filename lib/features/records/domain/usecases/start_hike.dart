import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/uuid.dart';
import '../../../courses/domain/entities/course.dart';
import '../../data/repositories/hike_repository_impl.dart';
import '../entities/hike.dart';
import '../repositories/hike_repository.dart';

/// 코스 화면 [시작]: 로컬에 recording 상태 산행을 만든다.
class StartHike {
  const StartHike(this._repo);

  final HikeRepository _repo;

  Future<Hike> call(Course course) => _repo.create(
        id: uuidV4(),
        courseId: course.courseId,
        courseName: course.name,
        mountainGroup: course.mountainGroup,
        startedAt: DateTime.now(),
      );
}

final startHikeProvider = Provider<StartHike>((ref) => StartHike(ref.watch(hikeRepositoryProvider)));
