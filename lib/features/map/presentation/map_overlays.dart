import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/geo/geo_point.dart';
import '../../mountains/domain/mountain.dart';
import '../../spots/domain/spot.dart';
import '../../trails/domain/trail_segment.dart';

/// 지도 오버레이 빌더 모음. 상태 없이 데이터 → 오버레이 변환만 담당.
///
/// 색 의미 (코어 루프): 회색 = 아직 안 걸은 길. M4에서 완주 구간이 색으로 채워진다.
abstract final class MapOverlays {
  // 전체 개요용 회색 등산로망
  static const trailColor = Color(0xFFA6A6A6);
  static const parkColor = Color(0xFFCFCFCF);
  static const trailWidth = 2.0;
  static const parkWidth = 1.0;

  // 선택된 산군 강조 (여전히 회색 계열 — "칠해진" 것과 구분)
  static const focusTrailColor = Color(0xFF616161);
  static const focusParkColor = Color(0xFFB8B8B8);
  static const focusTrailWidth = 4.0;
  static const focusParkWidth = 2.0;

  static const entranceColor = Color(0xFF2E7D32);

  static NLatLng toNLatLng(GeoPoint p) => NLatLng(p.lat, p.lon);

  /// 산군 × 등산로/공원 조합마다 1개의 멀티파트 오버레이 → 총 14개로 1,732구간 렌더.
  static Set<NAddableOverlay> networkOverlays(List<TrailSegment> segments) {
    final byGroup = <(String, bool), List<TrailSegment>>{};
    for (final s in segments) {
      byGroup.putIfAbsent((s.mountainGroup, s.isPark), () => []).add(s);
    }
    return byGroup.entries.map((e) {
      final (group, isPark) = e.key;
      return _multipart(
        id: 'net:$group:${isPark ? 'park' : 'trail'}',
        segments: e.value,
        color: isPark ? parkColor : trailColor,
        width: isPark ? parkWidth : trailWidth,
        zIndex: isPark ? 0 : 1,
      );
    }).toSet();
  }

  static const focusTrailId = 'focus:trail';
  static const focusParkId = 'focus:park';

  /// 선택된 산군의 구간을 굵게. park_flag는 더 얇게.
  static Set<NAddableOverlay> focusOverlays(List<TrailSegment> segmentsOfGroup) {
    final trail = segmentsOfGroup.where((s) => !s.isPark).toList();
    final park = segmentsOfGroup.where((s) => s.isPark).toList();
    return {
      if (park.isNotEmpty)
        _multipart(
          id: focusParkId,
          segments: park,
          color: focusParkColor,
          width: focusParkWidth,
          zIndex: 10,
        ),
      if (trail.isNotEmpty)
        _multipart(
          id: focusTrailId,
          segments: trail,
          color: focusTrailColor,
          width: focusTrailWidth,
          zIndex: 11,
        ),
    };
  }

  static NMultipartPathOverlay _multipart({
    required String id,
    required List<TrailSegment> segments,
    required Color color,
    required double width,
    required int zIndex,
  }) {
    final overlay = NMultipartPathOverlay(
      id: id,
      width: width,
      outlineWidth: 0,
      paths: segments
          .where((s) => s.polyline.length >= 2)
          .map((s) => NMultipartPath(
                coords: s.polyline.map(toNLatLng).toList(growable: false),
                color: color,
                outlineColor: Colors.transparent,
                passedColor: color,
                passedOutlineColor: Colors.transparent,
              ))
          .toList(growable: false),
    );
    overlay.setZIndex(zIndex);
    return overlay;
  }

  static String mountainMarkerId(String group) => 'mtn:$group';

  /// 산군 마커 (center_lon/lat 없는 산은 생략).
  static NMarker? mountainMarker(Mountain m, {required void Function(Mountain) onTap}) {
    final lat = m.centerLat;
    final lon = m.centerLon;
    if (lat == null || lon == null) return null;
    final marker = NMarker(
      id: mountainMarkerId(m.mountainGroup),
      position: NLatLng(lat, lon),
      size: const Size(26, 36),
      caption: NOverlayCaption(text: m.mountainGroup, textSize: 13),
      isHideCollidedCaptions: false,
    );
    marker.setOnTapListener((_) => onTap(m));
    return marker;
  }

  static const entranceIdPrefix = 'ent:';

  /// 입구 마커. 산군 하나에 최대 99개라 겹치는 마커는 숨긴다.
  static Set<NAddableOverlay> entranceMarkers(List<Spot> entrances) => entrances
      .map((s) => NMarker(
            id: '$entranceIdPrefix${s.spotId}',
            position: toNLatLng(s.position),
            iconTintColor: entranceColor,
            size: const Size(14, 20),
            isHideCollidedMarkers: true,
          )..setZIndex(20))
      .toSet();
}
