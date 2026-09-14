import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/geo/geo_point.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../map/presentation/views/map_overlays.dart';

/// 코스 폴리라인(강조색) 위에 내가 걸은 트랙(파랑)을 겹쳐 그리는 지도.
/// [live]가 true면 트랙이 바뀔 때마다 갱신하고 카메라를 마지막 위치로 따라간다.
class TrackMap extends ConsumerStatefulWidget {
  const TrackMap({super.key, required this.course, required this.track, this.live = false});

  final List<GeoPoint> course;
  final List<GeoPoint> track;
  final bool live;

  static const trackColor = Color(0xFF1E88E5);

  @override
  ConsumerState<TrackMap> createState() => _TrackMapState();
}

class _TrackMapState extends ConsumerState<TrackMap> {
  NaverMapController? _controller;
  bool _trackDrawn = false;

  @override
  void didUpdateWidget(covariant TrackMap old) {
    super.didUpdateWidget(old);
    if (widget.live && widget.track.length != old.track.length) _drawTrack();
  }

  Future<void> _drawTrack() async {
    final c = _controller;
    if (c == null || widget.track.length < 2) return;
    try {
      final line = NPolylineOverlay(
        id: 'track',
        coords: widget.track.map(MapOverlays.toNLatLng).toList(),
        color: TrackMap.trackColor,
        width: 4,
        lineCap: NLineCap.round,
        lineJoin: NLineJoin.round,
      )..setZIndex(50);
      await c.addOverlay(line); // 같은 id → 갱신
      _trackDrawn = true;
      if (widget.live) {
        await c.updateCamera(NCameraUpdate.scrollAndZoomTo(target: MapOverlays.toNLatLng(widget.track.last)));
      }
    } catch (e) {
      debugPrint('[track_map] 트랙 그리기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accentOf(ref.watch(themeVariantProvider));
    final all = [...widget.course, ...widget.track];
    if (all.isEmpty) return const ColoredBox(color: Color(0xFFEEEEEE));
    final bounds = NLatLngBounds.from(all.map(MapOverlays.toNLatLng));
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(target: bounds.center, zoom: 14),
        logoClickEnable: false,
        scaleBarEnable: false,
        rotationGesturesEnable: false,
        tiltGesturesEnable: false,
      ),
      onMapReady: (controller) async {
        _controller = controller;
        try {
          if (widget.course.length >= 2) {
            await controller.addOverlay(NPathOverlay(
              id: 'course',
              coords: widget.course.map(MapOverlays.toNLatLng).toList(),
              width: 7,
              color: accent.withValues(alpha: 0.85),
              outlineWidth: 1,
              outlineColor: Colors.white,
              passedColor: accent,
              passedOutlineColor: Colors.white,
            )..setZIndex(30));
          }
          await _drawTrack();
          if (!widget.live || !_trackDrawn) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            await controller.updateCamera(NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(32)));
          }
        } catch (e) {
          debugPrint('[track_map] 오버레이 실패: $e');
        }
      },
    );
  }
}
