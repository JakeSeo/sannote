import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/visit_repository.dart';
import '../services/visit_service.dart';

class VisitRepositoryImpl implements VisitRepository {
  const VisitRepositoryImpl(this._service);

  final VisitService _service;

  @override
  Future<String> insert({
    required String userId,
    required String courseId,
    required DateTime visitedAt,
    required int durationMin,
  }) async {
    final row = await _service.insert({
      'user_id': userId,
      'course_id': courseId,
      'visited_at': visitedAt.toIso8601String().substring(0, 10),
      'duration_min': durationMin,
    });
    return row['visit_id'] as String;
  }

  @override
  Future<Map<String, int>> completionCounts() => _service.completionCounts();
}

final visitRepositoryProvider = Provider<VisitRepository>((ref) => VisitRepositoryImpl(ref.watch(visitServiceProvider)));
