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

/// 검색 화면 상태: 검색어 + 산군 목록(정렬) + 코스 목록(필터).
class SearchState {
  const SearchState({
    this.mountains = const AsyncValue.loading(),
    this.courses = const AsyncValue.loading(),
    this.sort = MountainSort.distance,
    this.filter = const CourseFilter(),
    this.reference,
    this.query = '',
  });

  final AsyncValue<List<Mountain>> mountains;
  final AsyncValue<List<CourseSummary>> courses;
  final MountainSort sort;
  final CourseFilter filter;

  /// 거리순 기준 위치 (위치 서비스에서 가져옴. null이면 이름순만 의미 있음)
  final GeoPoint? reference;

  /// 검색어 (산·코스 이름 부분 일치)
  final String query;

  bool _matches(String text) => query.trim().isEmpty || text.toLowerCase().contains(query.trim().toLowerCase());

  /// 검색어에 맞는 산군 (정렬 적용)
  List<Mountain> get matchedMountains =>
      sortedMountains.where((m) => _matches(m.mountainGroup) || _matches(m.regions)).toList();

  /// 검색어에 맞는 코스 (필터는 ViewModel에서 추가 적용)
  List<CourseSummary> matchedCourses(List<CourseSummary> filtered) =>
      filtered.where((c) => _matches(c.course.name) || _matches(c.course.mountainGroup)).toList();

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

  SearchState copyWith({
    AsyncValue<List<Mountain>>? mountains,
    AsyncValue<List<CourseSummary>>? courses,
    MountainSort? sort,
    CourseFilter? filter,
    GeoPoint? reference,
    String? query,
  }) =>
      SearchState(
        mountains: mountains ?? this.mountains,
        courses: courses ?? this.courses,
        sort: sort ?? this.sort,
        filter: filter ?? this.filter,
        reference: reference ?? this.reference,
        query: query ?? this.query,
      );
}
