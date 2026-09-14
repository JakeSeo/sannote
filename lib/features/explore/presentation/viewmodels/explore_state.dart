import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/filter_courses.dart';
import '../../../mountains/domain/entities/mountain.dart';

enum MountainSort {
  distance('거리순'),
  name('이름순');

  const MountainSort(this.label);
  final String label;
}

/// 탐색 탭 상태: 산군 목록(정렬) + 코스 목록(필터).
class ExploreState {
  const ExploreState({
    this.mountains = const AsyncValue.loading(),
    this.courses = const AsyncValue.loading(),
    this.sort = MountainSort.distance,
    this.filter = const CourseFilter(),
    this.reference,
  });

  final AsyncValue<List<Mountain>> mountains;
  final AsyncValue<List<CourseSummary>> courses;
  final MountainSort sort;
  final CourseFilter filter;

  /// 거리순 기준 위치 (위치 서비스에서 가져옴. null이면 이름순만 의미 있음)
  final GeoPoint? reference;

  double? distanceTo(Mountain m) {
    final r = reference;
    final c = m.center;
    if (r == null || c == null) return null;
    return distanceKm(r, c);
  }

  List<Mountain> get sortedMountains {
    final list = [...?mountains.value];
    switch (sort) {
      case MountainSort.name:
        list.sort((a, b) => a.mountainGroup.compareTo(b.mountainGroup));
      case MountainSort.distance:
        list.sort((a, b) => (distanceTo(a) ?? 1e9).compareTo(distanceTo(b) ?? 1e9));
    }
    return list;
  }

  int courseCountOf(Mountain m) =>
      (courses.value ?? const []).where((c) => c.course.mountainGroup == m.mountainGroup).length;

  ExploreState copyWith({
    AsyncValue<List<Mountain>>? mountains,
    AsyncValue<List<CourseSummary>>? courses,
    MountainSort? sort,
    CourseFilter? filter,
    GeoPoint? reference,
  }) =>
      ExploreState(
        mountains: mountains ?? this.mountains,
        courses: courses ?? this.courses,
        sort: sort ?? this.sort,
        filter: filter ?? this.filter,
        reference: reference ?? this.reference,
      );
}
