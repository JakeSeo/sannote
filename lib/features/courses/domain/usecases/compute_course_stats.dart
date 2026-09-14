import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trails/domain/entities/trail_segment.dart';
import '../entities/course_stats.dart';

/// 코스에 속한 구간들을 합산해 거리/예상시간/난이도를 계산한다.
class ComputeCourseStats {
  const ComputeCourseStats();

  CourseStats call(List<TrailSegment> segments) {
    var lengthKm = 0.0;
    var up = 0;
    var down = 0;
    var hard = 0;
    var medium = 0;
    for (final s in segments) {
      lengthKm += s.lengthKm ?? 0;
      up += s.upMin ?? 0;
      down += s.downMin ?? 0;
      switch (s.difficulty) {
        case '어려움':
          hard++;
        case '중간':
          medium++;
      }
    }
    final n = segments.isEmpty ? 1 : segments.length;
    return CourseStats(
      lengthKm: lengthKm,
      estUpMin: up,
      estDownMin: down,
      segmentCount: segments.length,
      score: DifficultyFormula.score(
        lengthKm: lengthKm,
        upMin: up,
        hardRatio: hard / n,
        mediumRatio: medium / n,
      ),
    );
  }
}

final computeCourseStatsProvider = Provider<ComputeCourseStats>((_) => const ComputeCourseStats());
