import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/map/marker_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../explore/presentation/views/widgets/course_tile.dart';
import '../../../map/presentation/views/map_overlays.dart';
import '../../../safety/domain/entities/safety_point.dart';
import '../../../spots/domain/entities/spot.dart';
import '../viewmodels/course_detail_view_model.dart';

/// 코스 상세: 지도 + 요약 + 경유 스팟 + 구조표지판(참고용).
class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseDetailViewModelProvider(courseId));
    final vm = ref.read(courseDetailViewModelProvider(courseId).notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = state.summary;

    ref.listen(courseDetailViewModelProvider(courseId).select((st) => st.error), (_, e) {
      if (e == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('코스 정보를 불러오지 못했어요. 네트워크를 확인해주세요.'),
        action: SnackBarAction(label: '다시 시도', onPressed: vm.retry),
      ));
    });

    if (state.isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: FilledButton(onPressed: vm.retry, child: const Text('다시 시도'))),
      );
    }

    final stats = s.stats;
    return Scaffold(
      appBar: AppBar(title: Text(s.course.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final map = _CourseMap(summary: s, waypoints: state.waypoints, safetyPoints: state.safetyPoints);
          final content = ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (!isTablet) ...[
                SizedBox(height: 260, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: map)),
                const SizedBox(height: 12),
              ],
              Text(s.course.mountainGroup, style: text.labelLarge?.copyWith(color: scheme.primary)),
              const SizedBox(height: 4),
              if (s.course.description?.isNotEmpty == true) Text(s.course.description!, style: text.bodyMedium),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Stat(label: '거리', value: '${stats.lengthKm.toStringAsFixed(1)}km'),
                      _Stat(label: '예상 시간', value: formatMinutes(stats.estUpMin), note: '오름 기준 · 개인차 있음'),
                      _Stat(label: '난이도', value: stats.level.label, note: '예상'),
                    ],
                  ),
                ),
              ),
              if (s.missingSegmentIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('구간 ${s.missingSegmentIds.length}개를 찾을 수 없어 일부가 빠졌어요',
                      style: text.bodySmall?.copyWith(color: scheme.error)),
                ),
              const SizedBox(height: 20),
              Text('경유 지점', style: text.titleMedium),
              const SizedBox(height: 4),
              Text('코스 60m 이내 시설(지도의 파란 점) · 2016년 조사 자료라 현장과 다를 수 있어요', style: text.bodySmall),
              const SizedBox(height: 8),
              if (state.waypoints.isEmpty)
                Text('등록된 경유 시설이 없어요', style: text.bodySmall)
              else
                Card(
                  child: Column(
                    children: [
                      for (final (i, e) in state.waypointsByCategory.entries.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _WaypointRow(category: e.key, spots: e.value),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('구조 표지판', style: text.titleMedium),
                  const SizedBox(width: 8),
                  _ReferenceBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text('지도의 빨간 점. 119 신고 시 표지판 번호를 말하면 위치 확인이 빨라요. 2016년 자료로 실물 확인 전이라 참고용이에요.',
                  style: text.bodySmall),
              const SizedBox(height: 8),
              if (state.safetyPoints.isEmpty)
                Text('이 코스 주변에 등록된 표지판 정보가 없어요', style: text.bodySmall)
              else
                Card(
                  child: Column(
                    children: [
                      for (final (i, p) in state.safetyPoints.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        _SafetyRow(point: p),
                      ],
                    ],
                  ),
                ),
            ],
          );
          if (!isTablet) return content;
          // 태블릿: 지도 좌측 고정 + 우측 스크롤
          return Row(
            children: [
              Expanded(flex: 5, child: map),
              Expanded(flex: 4, child: content),
            ],
          );
        },
      ),
    );
  }
}

class _CourseMap extends ConsumerWidget {
  const _CourseMap({required this.summary, required this.waypoints, required this.safetyPoints});

  final CourseSummary summary;
  final List<Spot> waypoints;
  final List<SafetyPoint> safetyPoints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppTheme.accentOf(ref.watch(themeVariantProvider));
    final points = summary.polyline;
    if (points.length < 2) return const ColoredBox(color: Color(0xFFEEEEEE));
    final bounds = NLatLngBounds.from(points.map(MapOverlays.toNLatLng));
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(target: bounds.center, zoom: 13),
        logoClickEnable: false,
        scaleBarEnable: false,
        rotationGesturesEnable: false,
        tiltGesturesEnable: false,
      ),
      onMapReady: (controller) async {
        final (wpIcon, dangerIcon, safetyIcon) = await (
          MarkerIcons.dot(const Color(0xFF1E88E5)),
          MarkerIcons.dot(const Color(0xFFE53935)),
          MarkerIcons.dot(const Color(0xFFD32F2F), px: 12),
        ).wait;
        final overlays = <NAddableOverlay>{
          NPathOverlay(
            id: 'course',
            coords: points.map(MapOverlays.toNLatLng).toList(),
            width: 7,
            color: accent,
            outlineWidth: 2,
            outlineColor: Colors.white,
            passedColor: accent,
            passedOutlineColor: Colors.white,
          ),
          NMarker(
            id: 'start',
            position: MapOverlays.toNLatLng(points.first),
            size: const Size(22, 30),
            caption: const NOverlayCaption(text: '출발', textSize: 11),
          ),
          for (final w in waypoints)
            NMarker(
              id: 'wp:${w.spotId}',
              position: MapOverlays.toNLatLng(w.position),
              icon: w.category == '위험지역' ? dangerIcon : wpIcon,
              size: const Size(14, 14),
              anchor: const NPoint(0.5, 0.5),
            )..setZIndex(40),
          for (final p in safetyPoints)
            NMarker(
              id: 'sf:${p.safetyId}',
              position: MapOverlays.toNLatLng(p.position),
              icon: safetyIcon,
              size: const Size(12, 12),
              anchor: const NPoint(0.5, 0.5),
              caption: NOverlayCaption(text: p.markerNo ?? '', textSize: 9),
            )..setZIndex(41),
        };
        try {
          await controller.addOverlayAll(overlays);
          // 레이아웃 직후엔 뷰 크기가 확정 전이라 fitBounds가 어긋남 → 한 프레임 뒤에 맞춘다
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await controller.updateCamera(
            NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(32)),
          );
        } catch (e) {
          debugPrint('[course_detail] 지도 오버레이 실패: $e');
        }
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          Text(value, style: text.titleMedium),
          if (note != null) Text(note!, style: text.bodySmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _WaypointRow extends StatelessWidget {
  const _WaypointRow({required this.category, required this.spots});

  final String category;
  final List<Spot> spots;

  static IconData _icon(String c) => switch (c) {
        '조망점' => Icons.landscape,
        '화장실' => Icons.wc,
        '음수대' => Icons.water_drop,
        '정자' => Icons.deck,
        '정상' => Icons.flag,
        '대피소' => Icons.house_siding,
        '위험지역' => Icons.warning_amber,
        _ => Icons.place,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDanger = category == '위험지역';
    final detail = spots.map((s) => s.type).whereType<String>().where((t) => t != category).toSet().join(', ');
    return ListTile(
      dense: true,
      leading: Icon(_icon(category), color: isDanger ? scheme.error : scheme.primary),
      title: Text('$category ${spots.length}곳'),
      subtitle: detail.isEmpty ? null : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({required this.point});

  final SafetyPoint point;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.local_hospital_outlined, color: Color(0xFFE53935)),
      title: Text('표지판 ${point.markerNo ?? '-'}'),
      subtitle: Text([point.locationDesc, point.agency].whereType<String>().join(' · ')),
    );
  }
}

class _ReferenceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('참고용', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
