import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mountain_palette.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../courses/domain/entities/course_summary.dart';
import '../../../courses/domain/usecases/get_course_summaries.dart';
import '../../../courses/presentation/widgets/course_tile.dart';
import '../../domain/entities/hike.dart';
import '../viewmodels/records_providers.dart';
import 'hike_detail_page.dart';
import 'reveal/course_reveal_overlay.dart';

/// 내가 모은 산책로: 통계 · 획득한 코스 카드(스탬프) · 아직 숨어 있는 산책로 수 · 산행 목록.
class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hikes = (ref.watch(hikesProvider).value ?? const <Hike>[]).where((h) => h.status != HikeStatus.recording).toList();
    final stats = ref.watch(conquestStatsProvider).value;
    final discovered = ref.watch(discoveredSummariesProvider).value ?? const <CourseSummary>[];
    final variant = ref.watch(themeVariantProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('내가 모은 산책로')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 600 ? 720.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _Big('칠한 길', '${(stats?.totalKm ?? 0).toStringAsFixed(1)}km', variant),
                          _Big('구간', '${stats?.segmentCount ?? 0}개', variant),
                          _Big('산책로', '${discovered.length}개', variant),
                          _Big('산', '${stats?.mountainGroups.length ?? 0}곳', variant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('모은 산책로 ${discovered.length}개', style: text.titleMedium),
                  const SizedBox(height: 4),
                  _HiddenCount(discoveredCount: discovered.length),
                  const SizedBox(height: 10),
                  if (discovered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('아직 모은 산책로가 없어요. 회색 길을 걸어 칠해보세요. 숨어 있던 산책로를 다 걸으면 여기 카드가 생겨요.',
                          style: text.bodyMedium),
                    ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                    children: [
                      for (final c in discovered)
                        _CourseStampCard(
                          summary: c,
                          color: variant.isSketch ? MountainPalette.of(c.course.mountainGroup, ink: variant.inkTone) : scheme.primary,
                          onTap: () => showCourseReveal(context, [c]), // 다시 보기 (연출 재생)
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('산책 ${hikes.length}회', style: text.titleMedium),
                  const SizedBox(height: 8),
                  if (hikes.isEmpty) Text('아직 기록이 없어요. 지도에서 [기록 시작]을 눌러보세요.', style: text.bodySmall),
                  for (final h in hikes) ...[
                    Card(
                      child: ListTile(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HikeDetailPage(hikeId: h.id))),
                        leading: Icon(h.hasCourse ? Icons.auto_awesome : Icons.directions_walk,
                            color: h.hasCourse ? scheme.primary : scheme.outline),
                        title: Text(h.hasCourse ? '${h.courseName} 획득' : '산책'),
                        subtitle: Text(
                          '${_date(h.startedAt)} · ${h.distanceKm.toStringAsFixed(1)}km · ${formatMinutes(h.durationMin)}',
                          style: text.bodySmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _date(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

/// "아직 숨어 있는 산책로 n개" — 전체 분모는 보여주지 않는 원칙이지만, 남은 수는 동기 부여로 허용
class _HiddenCount extends ConsumerWidget {
  const _HiddenCount({required this.discoveredCount});

  final int discoveredCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return FutureBuilder(
      future: ref.read(getCourseSummariesProvider).call(),
      builder: (context, snap) {
        final total = snap.data?.length;
        if (total == null) return const SizedBox.shrink();
        final hidden = total - discoveredCount;
        return Text(hidden <= 0 ? '숨어 있던 산책로를 모두 찾았어요!' : '아직 숨어 있는 산책로 $hidden개', style: text.bodySmall);
      },
    );
  }
}

class _CourseStampCard extends StatelessWidget {
  const _CourseStampCard({required this.summary, required this.color, required this.onTap});

  final CourseSummary summary;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = summary.stats;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                  child: CustomPaint(painter: _MiniCoursePainter(summary: summary, color: color)),
                ),
              ),
              const SizedBox(height: 8),
              Text(summary.course.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleSmall),
              Text('${summary.course.mountainGroup} · ${s.lengthKm.toStringAsFixed(1)}km', style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCoursePainter extends CustomPainter {
  const _MiniCoursePainter({required this.summary, required this.color});

  final CourseSummary summary;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = summary.polyline;
    if (pts.length < 2) return;
    var minLat = pts.first.lat, maxLat = pts.first.lat, minLon = pts.first.lon, maxLon = pts.first.lon;
    for (final p in pts) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    final w = (maxLon - minLon).abs().clamp(1e-9, double.infinity), h = (maxLat - minLat).abs().clamp(1e-9, double.infinity);
    final scale = (size.width / w < size.height / h) ? size.width / w : size.height / h;
    final ox = (size.width - w * scale) / 2, oy = (size.height - h * scale) / 2;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = Offset(ox + (pts[i].lon - minLon) * scale, oy + (maxLat - pts[i].lat) * scale);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _MiniCoursePainter old) => old.summary != summary || old.color != color;
}

class _Big extends StatelessWidget {
  const _Big(this.label, this.value, this.variant);

  final String label;
  final String value;
  final ThemeVariant variant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: variant.isSketch ? text.headlineSmall?.copyWith(fontSize: 24) : text.titleMedium),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}
