import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/course_stats.dart';
import '../entities/course_summary.dart';

/// 예상 소요시간 구간 필터 (오름 기준).
enum DurationFilter {
  any('전체', 0, 1 << 30),
  under1h('1시간 이내', 0, 60),
  h1to2('1~2시간', 60, 120),
  h2to3('2~3시간', 120, 180),
  over3h('3시간 이상', 180, 1 << 30);

  const DurationFilter(this.label, this.minMin, this.maxMin);
  final String label;
  final int minMin;
  final int maxMin;

  bool accepts(int estUpMin) => estUpMin >= minMin && estUpMin < maxMin;
}

class CourseFilter {
  const CourseFilter({this.duration = DurationFilter.any, this.levels = const {}});

  final DurationFilter duration;

  /// 비어 있으면 전체 난이도
  final Set<DifficultyLevel> levels;

  bool get isDefault => duration == DurationFilter.any && levels.isEmpty;

  CourseFilter copyWith({DurationFilter? duration, Set<DifficultyLevel>? levels}) =>
      CourseFilter(duration: duration ?? this.duration, levels: levels ?? this.levels);
}

class FilterCourses {
  const FilterCourses();

  List<CourseSummary> call(List<CourseSummary> all, CourseFilter f) => all
      .where((c) => f.duration.accepts(c.stats.estUpMin))
      .where((c) => f.levels.isEmpty || f.levels.contains(c.stats.level))
      .toList(growable: false);
}

final filterCoursesProvider = Provider<FilterCourses>((_) => const FilterCourses());
