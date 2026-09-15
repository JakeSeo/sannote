import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/geolocator_location_service.dart';
import '../../../../core/location/location_provider.dart';
import '../../../courses/domain/entities/course_stats.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/filter_courses.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../mountains/domain/usecases/get_mountains.dart';
import 'explore_state.dart';

class ExploreViewModel extends Notifier<ExploreState> {
  @override
  ExploreState build() {
    _load();
    return const ExploreState();
  }

  Future<void> _load() async {
    await Future.wait([_loadMountains(), _loadCourses(), _loadReference()]);
  }

  Future<void> _loadMountains() async {
    final r = await AsyncValue.guard(() => ref.read(getMountainsProvider).call());
    if (r.hasError) debugPrint('[explore] mountains 실패: ${r.error}');
    state = state.copyWith(mountains: r);
  }

  Future<void> _loadCourses() async {
    final r = await AsyncValue.guard(() => ref.read(getCourseSummariesProvider).call());
    if (r.hasError) debugPrint('[explore] courses 실패: ${r.error}');
    state = state.copyWith(courses: r);
  }

  /// 팝업 없이, 이미 허용된 권한이 있을 때만 읽는다 (권한 요청은 지도 홈이 맡음).
  Future<void> _loadReference() async {
    final pos = await ref.read(locationServiceProvider).current();
    if (pos != null) state = state.copyWith(reference: pos);
  }

  /// 사용자가 [내 위치 사용]을 눌렀을 때만 권한을 요청한다.
  Future<bool> requestLocation() async {
    final service = ref.read(locationServiceProvider);
    if (service is GeolocatorLocationService && !await GeolocatorLocationService.ensurePermission()) return false;
    final pos = await service.current();
    if (pos == null) return false;
    state = state.copyWith(reference: pos);
    return true;
  }

  Future<void> retry() async {
    state = state.copyWith(
      mountains: state.mountains.hasError ? const AsyncValue.loading() : null,
      courses: state.courses.hasError ? const AsyncValue.loading() : null,
    );
    await _load();
  }

  void setSort(MountainSort sort) => state = state.copyWith(sort: sort);

  void setDuration(DurationFilter d) => state = state.copyWith(filter: state.filter.copyWith(duration: d));

  void toggleLevel(DifficultyLevel level) {
    final levels = {...state.filter.levels};
    levels.contains(level) ? levels.remove(level) : levels.add(level);
    state = state.copyWith(filter: state.filter.copyWith(levels: levels));
  }

  void clearFilter() => state = state.copyWith(filter: const CourseFilter());

  List<CourseSummary> get filteredCourses =>
      ref.read(filterCoursesProvider).call(state.courses.value ?? const [], state.filter);
}

final exploreViewModelProvider = NotifierProvider<ExploreViewModel, ExploreState>(ExploreViewModel.new);

/// 필터 적용된 코스 목록 (View가 watch)
final filteredCoursesProvider = Provider<List<CourseSummary>>((ref) {
  final s = ref.watch(exploreViewModelProvider);
  return ref.watch(filterCoursesProvider).call(s.courses.value ?? const [], s.filter);
});
