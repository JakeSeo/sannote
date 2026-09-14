import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dev/developer_menu.dart';
import '../../../course_detail/presentation/views/course_detail_page.dart';
import '../../../courses/domain/entities/course_stats.dart';
import '../../../courses/domain/usecases/filter_courses.dart';
import '../../../mountain_detail/presentation/views/mountain_detail_page.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../viewmodels/explore_state.dart';
import '../viewmodels/explore_view_model.dart';
import 'widgets/course_tile.dart';

/// 탐색 탭: [산] 산군 리스트(거리순/이름순) / [코스] 조건 필터(소요시간·난이도) + 코스 리스트.
class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreViewModelProvider);
    final vm = ref.read(exploreViewModelProvider.notifier);
    ref.listen(exploreViewModelProvider.select((s) => s.mountains.hasError || s.courses.hasError), (_, err) {
      if (!err) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('산 정보를 불러오지 못했어요. 네트워크를 확인해주세요.'),
        action: SnackBarAction(label: '다시 시도', onPressed: vm.retry),
      ));
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => DeveloperMenu.show(context),
          child: const Text('탐색'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final maxWidth = isTablet ? 720.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('산'), icon: Icon(Icons.terrain)),
                        ButtonSegment(value: 1, label: Text('코스'), icon: Icon(Icons.route)),
                      ],
                      selected: {_segment},
                      onSelectionChanged: (s) => setState(() => _segment = s.first),
                      showSelectedIcon: false,
                    ),
                  ),
                  Expanded(child: _segment == 0 ? _MountainList(state: state) : _CourseList(state: state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MountainList extends ConsumerWidget {
  const _MountainList({required this.state});

  final ExploreState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(exploreViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;
    if (state.mountains.isLoading) return const Center(child: CircularProgressIndicator());
    final list = state.sortedMountains;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Text('산 ${list.length}곳', style: text.labelLarge),
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
        if (state.sort == MountainSort.distance && state.reference != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('현재 위치 기준 직선거리', style: text.bodySmall),
          ),
        const SizedBox(height: 8),
        for (final m in list) ...[
          _MountainTile(mountain: m, distanceKm: state.distanceTo(m), courseCount: state.courseCountOf(m)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MountainTile extends StatelessWidget {
  const _MountainTile({required this.mountain, required this.distanceKm, required this.courseCount});

  final Mountain mountain;
  final double? distanceKm;
  final int courseCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => MountainDetailPage(mountainGroup: mountain.mountainGroup)),
        ),
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

class _CourseList extends ConsumerWidget {
  const _CourseList({required this.state});

  final ExploreState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(exploreViewModelProvider.notifier);
    final courses = ref.watch(filteredCoursesProvider);
    final text = Theme.of(context).textTheme;
    if (state.courses.isLoading) return const Center(child: CircularProgressIndicator());
    final f = state.filter;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('예상 소요시간 (오름 기준)', style: text.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final d in DurationFilter.values)
              ChoiceChip(label: Text(d.label), selected: f.duration == d, onSelected: (_) => vm.setDuration(d)),
          ],
        ),
        const SizedBox(height: 12),
        Text('난이도 (예상)', style: text.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (final l in DifficultyLevel.values)
              FilterChip(label: Text(l.label), selected: f.levels.contains(l), onSelected: (_) => vm.toggleLevel(l)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('코스 ${courses.length}개', style: text.labelLarge),
            const Spacer(),
            if (!f.isDefault) TextButton(onPressed: vm.clearFilter, child: const Text('필터 초기화')),
          ],
        ),
        const SizedBox(height: 4),
        if (courses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                (state.courses.value ?? const []).isEmpty ? '큐레이션된 코스가 아직 없어요' : '조건에 맞는 코스가 없어요',
                style: text.bodyMedium,
              ),
            ),
          ),
        for (final c in courses) ...[
          CourseTile(
            summary: c,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => CourseDetailPage(courseId: c.course.courseId)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
