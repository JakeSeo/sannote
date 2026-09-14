import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../../mountains/domain/usecases/get_mountains.dart';
import '../../../spots/domain/entities/entrance_access.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../spots/domain/usecases/get_entrance_access.dart';
import '../../../spots/domain/usecases/get_entrances.dart';

class MountainDetailState {
  const MountainDetailState({
    this.mountain,
    this.entrances = const [],
    this.access = const {},
    this.courses = const [],
    this.isLoading = true,
    this.error,
  });

  final Mountain? mountain;

  /// 이 산군의 입구. 접근 정보가 있는 입구가 먼저 오도록 정렬됨.
  final List<Spot> entrances;
  final Map<String, EntranceAccess> access;
  final List<CourseSummary> courses;
  final bool isLoading;
  final Object? error;

  int get entrancesWithAccess => entrances.where((e) => access.containsKey(e.spotId)).length;

  /// 역 단위로 묶은 접근 정보. 가까운 역(최소 도보) 순.
  List<StationAccess> get stations {
    final byStation = <String, List<EntranceAccess>>{};
    for (final e in entrances) {
      final a = access[e.spotId];
      if (a != null) byStation.putIfAbsent(a.stationName, () => []).add(a);
    }
    final list = byStation.entries.map((en) {
      final walks = en.value.map((a) => a.walkMin).toList()..sort();
      final exits = en.value.map((a) => a.exitNo).whereType<String>().toSet().toList()
        ..sort((x, y) => (int.tryParse(x) ?? 0).compareTo(int.tryParse(y) ?? 0));
      return StationAccess(
        stationName: en.key,
        line: en.value.map((a) => a.line).whereType<String>().firstOrNull,
        exits: exits,
        entranceCount: en.value.length,
        minWalk: walks.first,
        maxWalk: walks.last,
        allEstimate: en.value.every((a) => a.isEstimate),
      );
    }).toList()
      ..sort((x, y) => x.minWalk.compareTo(y.minWalk));
    return list;
  }

  /// 코스 출발 입구의 접근 정보 (코스 이름 → 접근 정보)
  List<(String courseName, EntranceAccess? access)> get courseStarts => [
        for (final c in courses)
          if (c.course.entranceSpotId != null) (c.course.name, access[c.course.entranceSpotId!]),
      ];

  /// 코스 출발점으로 쓰이는 입구 spot_id → 코스 이름
  Map<String, String> get courseStartNames => {
        for (final c in courses)
          if (c.course.entranceSpotId != null) c.course.entranceSpotId!: c.course.name,
      };

  /// 목록에 보여줄 입구: 접근 정보가 있거나 코스 출발점인 것. 나머지는 건수만 표시.
  List<Spot> get highlightedEntrances {
    final starts = courseStartNames;
    return entrances.where((e) => access.containsKey(e.spotId) || starts.containsKey(e.spotId)).toList();
  }
}

/// 한 지하철역에서 갈 수 있는 입구들의 요약.
class StationAccess {
  const StationAccess({
    required this.stationName,
    required this.line,
    required this.exits,
    required this.entranceCount,
    required this.minWalk,
    required this.maxWalk,
    required this.allEstimate,
  });

  final String stationName;
  final String? line;
  final List<String> exits;
  final int entranceCount;
  final int minWalk;
  final int maxWalk;
  final bool allEstimate;
}

/// 산 상세 ViewModel (산군별 family).
class MountainDetailViewModel extends Notifier<MountainDetailState> {
  MountainDetailViewModel(this.mountainGroup);

  final String mountainGroup;

  @override
  MountainDetailState build() {
    _load();
    return const MountainDetailState();
  }

  Future<void> _load() async {
    try {
      final (mountains, entrances, access, courses) = await (
        ref.read(getMountainsProvider).call(),
        ref.read(getEntrancesProvider).call(),
        ref.read(getEntranceAccessProvider).call(mountainGroup),
        ref.read(getCourseSummariesProvider).call(),
      ).wait;
      final mine = entrances.where((e) => e.mountainGroup == mountainGroup).toList()
        ..sort((a, b) {
          final aHas = access.containsKey(a.spotId) ? 0 : 1;
          final bHas = access.containsKey(b.spotId) ? 0 : 1;
          return aHas != bHas ? aHas.compareTo(bHas) : a.spotId.compareTo(b.spotId);
        });
      state = MountainDetailState(
        mountain: mountains.where((m) => m.mountainGroup == mountainGroup).firstOrNull,
        entrances: mine,
        access: access,
        courses: courses.where((c) => c.course.mountainGroup == mountainGroup).toList(),
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('[mountain_detail] $mountainGroup 로드 실패: $e\n$st');
      state = MountainDetailState(isLoading: false, error: e);
    }
  }

  Future<void> retry() async {
    state = const MountainDetailState();
    await _load();
  }
}

final mountainDetailViewModelProvider =
    NotifierProvider.family<MountainDetailViewModel, MountainDetailState, String>(MountainDetailViewModel.new);
