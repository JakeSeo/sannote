import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/geo/geo_point.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/mountain_palette.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../courses/domain/entities/course_summary.dart';
import '../../../../courses/presentation/widgets/course_tile.dart';

/// 코스 획득 연출. 지도 위 코스 모양이 "툭" 튀어 올라 중앙으로 떠오르며 뱅글 돌고,
/// 회색에서 그 산의 색연필 색으로 채워진다. 색연필 가루 파티클 + 손글씨 "코스 획득!" + 햅틱.
/// 탭하거나 끝나면 카드가 서랍(우상단 메뉴 방향)으로 날아가며 닫힌다.
Future<void> showCourseReveal(BuildContext context, List<CourseSummary> courses) async {
  for (final c in courses) {
    if (!context.mounted) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => _RevealPage(summary: c),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
    ));
  }
}

class _RevealPage extends ConsumerStatefulWidget {
  const _RevealPage({required this.summary});

  final CourseSummary summary;

  @override
  ConsumerState<_RevealPage> createState() => _RevealPageState();
}

class _RevealPageState extends ConsumerState<_RevealPage> with TickerProviderStateMixin {
  late final _main = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  bool _closing = false;

  // 단계: 0~.18 튀어오름(pop) → .18~.75 회전+색 채움 → .55~1 텍스트/카드
  late final _pop = CurvedAnimation(parent: _main, curve: const Interval(0, 0.18, curve: Curves.elasticOut));
  late final _spin = CurvedAnimation(parent: _main, curve: const Interval(0.15, 0.75, curve: Curves.easeInOutCubic));
  late final _fill = CurvedAnimation(parent: _main, curve: const Interval(0.3, 0.75, curve: Curves.easeOut));
  late final _text = CurvedAnimation(parent: _main, curve: const Interval(0.6, 0.85, curve: Curves.easeOutBack));
  late final _particles = CurvedAnimation(parent: _main, curve: const Interval(0.12, 0.9, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _main.addListener(() {
      // 회전 절정에서 한 번 더
      if (_main.value > 0.45 && _main.value < 0.47) HapticFeedback.heavyImpact();
    });
    _main.addStatusListener((s) {
      if (s == AnimationStatus.completed) Future.delayed(const Duration(milliseconds: 1600), _close);
    });
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    HapticFeedback.selectionClick();
    await _exit.forward();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _main.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variant = ref.watch(themeVariantProvider);
    final group = widget.summary.course.mountainGroup;
    final color = variant.isSketch ? MountainPalette.of(group, ink: variant.inkTone) : AppTheme.accentOf(variant);
    final text = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final stats = widget.summary.stats;

    return GestureDetector(
      onTap: _close,
      child: AnimatedBuilder(
        animation: Listenable.merge([_main, _exit]),
        builder: (context, _) {
          final exit = Curves.easeInCubic.transform(_exit.value);
          // 종료: 카드가 우상단(메뉴=서랍) 방향으로 축소되며 날아감
          final flyOffset = Offset(size.width * 0.35 * exit, -size.height * 0.4 * exit);
          final flyScale = 1 - 0.85 * exit;
          return Material(
            color: Colors.black.withValues(alpha: 0.55 * (1 - exit)),
            child: Stack(
              children: [
                // 파티클 (색연필 가루)
                Positioned.fill(
                  child: CustomPaint(painter: _ParticlePainter(progress: _particles.value, color: color, fade: 1 - exit)),
                ),
                Center(
                  child: Transform.translate(
                    offset: flyOffset,
                    child: Transform.scale(
                      scale: flyScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 코스 모양 카드: 튀어오름 + Y축 회전 2바퀴 + 색 채움
                          Transform.scale(
                            scale: 0.2 + 0.8 * _pop.value,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0012)
                                ..rotateY(_spin.value * math.pi * 4)
                                ..rotateZ(math.sin(_pop.value * math.pi) * 0.08),
                              child: _CourseShapeCard(
                                polyline: widget.summary.polyline,
                                color: color,
                                fill: _fill.value,
                                paper: variant.isSketch ? AppTheme.paperCard : Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // 손글씨 "코스 획득!" + 이름 (스탬프처럼 찍힘)
                          Transform.scale(
                            scale: _text.value.clamp(0.0, 1.2),
                            child: Opacity(
                              opacity: _text.value.clamp(0.0, 1.0),
                              child: Column(
                                children: [
                                  Text('코스 획득!',
                                      style: TextStyle(
                                        fontFamily: AppTheme.handwriting,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1,
                                        shadows: [Shadow(color: color, offset: const Offset(2, 3), blurRadius: 0)],
                                      )),
                                  const SizedBox(height: 8),
                                  Text(widget.summary.course.name,
                                      textAlign: TextAlign.center,
                                      style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$group · ${stats.lengthKm.toStringAsFixed(1)}km · 예상 ${formatMinutes(stats.estUpMin)}',
                                    style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                                  ),
                                  const SizedBox(height: 18),
                                  Text('탭해서 내 산책로에 담기', style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 코스 폴리라인을 종이 카드에 그린다. fill 0→1로 회색 밑그림 위에 색연필이 칠해진다.
class _CourseShapeCard extends StatelessWidget {
  const _CourseShapeCard({required this.polyline, required this.color, required this.fill, required this.paper});

  final List<GeoPoint> polyline;
  final Color color;
  final double fill;
  final Color paper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(22),
      child: CustomPaint(painter: _CoursePainter(polyline: polyline, color: color, fill: fill)),
    );
  }
}

class _CoursePainter extends CustomPainter {
  const _CoursePainter({required this.polyline, required this.color, required this.fill});

  final List<GeoPoint> polyline;
  final Color color;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (polyline.length < 2) return;
    var minLat = double.infinity, maxLat = -double.infinity, minLon = double.infinity, maxLon = -double.infinity;
    for (final p in polyline) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLon = math.min(minLon, p.lon);
      maxLon = math.max(maxLon, p.lon);
    }
    final cosLat = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final w = (maxLon - minLon) * cosLat, h = maxLat - minLat;
    final scale = math.min(size.width / (w == 0 ? 1 : w), size.height / (h == 0 ? 1 : h));
    final ox = (size.width - w * scale) / 2, oy = (size.height - h * scale) / 2;
    Offset pt(GeoPoint p) => Offset(ox + (p.lon - minLon) * cosLat * scale, oy + (maxLat - p.lat) * scale);

    final path = Path()..moveTo(pt(polyline.first).dx, pt(polyline.first).dy);
    for (final p in polyline.skip(1)) {
      path.lineTo(pt(p).dx, pt(p).dy);
    }
    // 밑그림 (연필)
    canvas.drawPath(path, Paint()..color = const Color(0xFFB8B8B8)..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    if (fill <= 0) return;
    // 색연필: 앞에서부터 fill 비율만큼 칠해진다 (넓고 옅게 + 좁고 진하게)
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold(0.0, (s, m) => s + m.length);
    var remain = total * fill;
    final colored = Path();
    for (final m in metrics) {
      if (remain <= 0) break;
      final len = math.min(remain, m.length);
      colored.addPath(m.extractPath(0, len), Offset.zero);
      remain -= len;
    }
    canvas.drawPath(colored, Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    canvas.drawPath(colored, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    // 출발점
    canvas.drawCircle(pt(polyline.first), 6, Paint()..color = Colors.white);
    canvas.drawCircle(pt(polyline.first), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CoursePainter old) => old.fill != fill || old.color != color || old.polyline != polyline;
}

/// 색연필 가루 파티클: 중앙에서 사방으로 튀어 떨어진다
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.color, required this.fade});

  final double progress;
  final Color color;
  final double fade;
  static final _rand = math.Random(7);
  static final _seeds = List.generate(70, (_) => (_rand.nextDouble() * math.pi * 2, 0.5 + _rand.nextDouble(), _rand.nextDouble(), 2.0 + _rand.nextDouble() * 4));

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = Offset(size.width / 2, size.height / 2 - 40);
    final hsl = HSLColor.fromColor(color);
    for (final (angle, speed, tint, r) in _seeds) {
      final t = progress;
      final dist = speed * 260 * Curves.easeOutCubic.transform(t);
      final gravity = 220 * t * t;
      final p = c + Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.7 + gravity);
      final alpha = (1 - t).clamp(0.0, 1.0) * fade;
      final col = hsl.withLightness((hsl.lightness + (tint - 0.5) * 0.3).clamp(0.0, 1.0)).toColor().withValues(alpha: alpha);
      canvas.drawCircle(p, r * (1 - t * 0.5), Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress || old.fade != fade;
}
