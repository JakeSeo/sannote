import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_stats.dart';
import '../../../courses/domain/usecases/filter_courses.dart';
import '../../../courses/presentation/widgets/course_tile.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../viewmodels/search_state.dart';
import '../viewmodels/search_view_model.dart';

/// 검색 결과로 지도 홈에 돌려주는 선택.
sealed class SearchSelection {
  const SearchSelection(this.query);

  /// 뒤로가기로 검색 화면을 다시 열 때 복원할 검색어
  final String query;
}

class MountainSelection extends SearchSelection {
  const MountainSelection(this.mountainGroup, super.query);
  final String mountainGroup;
}

class CourseSelection extends SearchSelection {
  const CourseSelection(this.courseId, super.query);
  final String courseId;
}

/// 검색 화면: 상단 텍스트 필드 + 산/코스 결과. 지도 앱처럼 결과를 누르면 지도로 돌아가 해당 대상으로 이동한다.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final _controller = TextEditingController(text: widget.initialQuery);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchViewModelProvider.notifier).setQuery(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);
    final courses = ref.watch(searchedCoursesProvider);
    final text = Theme.of(context).textTheme;
    final mountains = state.matchedMountains;
    final f = state.filter;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          onChanged: vm.setQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '산, 코스 검색',
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      vm.setQuery('');
                    },
                  ),
          ),
        ),
      ),
      body: state.mountains.isLoading || state.courses.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                // 코스 조건
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final d in DurationFilter.values)
                      ChoiceChip(label: Text(d.label), selected: f.duration == d, onSelected: (_) => vm.setDuration(d)),
                    for (final l in DifficultyLevel.values)
                      FilterChip(label: Text(l.label), selected: f.levels.contains(l), onSelected: (_) => vm.toggleLevel(l)),
                  ],
                ),
                const SizedBox(height: 16),
                // 코스
                Row(
                  children: [
                    Text('코스 ${courses.length}개', style: text.titleSmall),
                    const Spacer(),
                    if (!f.isDefault) TextButton(onPressed: vm.clearFilter, child: const Text('조건 초기화')),
                  ],
                ),
                if (courses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      (state.courses.value ?? const []).isEmpty ? '큐레이션된 코스가 아직 없어요' : '조건에 맞는 코스가 없어요',
                      style: text.bodySmall,
                    ),
                  ),
                for (final c in courses) ...[
                  CourseTile(
                    summary: c,
                    onTap: () => Navigator.of(context).pop(CourseSelection(c.course.courseId, state.query)),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                // 산
                Row(
                  children: [
                    Text('산 ${mountains.length}곳', style: text.titleSmall),
                    const Spacer(),
                    for (final s in MountainSort.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(s.label),
                          selected: state.sort == s,
                          onSelected: (_) => vm.setSort(s),
                        ),
                      ),
                  ],
                ),
                if (state.sort == MountainSort.distance && state.reference == null)
                  Row(
                    children: [
                      Expanded(child: Text('위치를 허용하면 가까운 산부터 보여드려요', style: text.bodySmall)),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await vm.requestLocation();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('위치 권한이 없어 이름순으로 보여드려요.')));
                          }
                        },
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('내 위치 사용'),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                for (final m in mountains) ...[
                  _MountainTile(
                    mountain: m,
                    distanceKm: state.distanceTo(m),
                    courseCount: state.courseCountOf(m),
                    onTap: () => Navigator.of(context).pop(MountainSelection(m.mountainGroup, state.query)),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

class _MountainTile extends StatelessWidget {
  const _MountainTile({required this.mountain, required this.distanceKm, required this.courseCount, required this.onTap});

  final Mountain mountain;
  final double? distanceKm;
  final int courseCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.terrain, color: scheme.onPrimaryContainer),
        ),
        title: Text(mountain.mountainGroup),
        subtitle: Text(
          '${mountain.regions} · 등산로 ${mountain.totalLengthKm}km · 입구 ${mountain.entranceCount}곳'
          '${courseCount > 0 ? ' · 코스 $courseCount개' : ''}',
          style: text.bodySmall,
        ),
        trailing: distanceKm == null
            ? null
            : Text('${distanceKm!.toStringAsFixed(distanceKm! < 10 ? 1 : 0)}km', style: text.labelLarge),
      ),
    );
  }
}
