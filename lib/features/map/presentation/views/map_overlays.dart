import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../../../courses/domain/entities/course_summary.dart';

/// 도메인 데이터 → 네이버 지도 오버레이 변환. 상태 없음.
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

  // 선택된 코스
  static const courseColor = Color(0xFFF4511E);
  static const courseWidth = 8.0;

  static const entranceColor = Color(0xFF2E7D32);

  // 완주해서 칠해진 길 (코어 루프). 회색 위에 강조색.
  static const doneColor = Color(0xFFE07A2F);
  static const doneWidth = 4.0;
  static const doneId = 'done:segments';

  /// 완주 구간 색칠 오버레이 (없으면 null)
  static NAddableOverlay? doneOverlay(List<TrailSegment> completed) => completed.isEmpty
      ? null
      : _multipart(id: doneId, segments: completed, color: doneColor, width: doneWidth, zIndex: 12);

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
  static const focusIds = [focusTrailId, focusParkId];

  /// 선택된 산군의 구간을 굵게. park_flag는 더 얇게.
  static Set<NAddableOverlay> focusOverlays(List<TrailSegment> segmentsOfGroup) {
    final trail = segmentsOfGroup.where((s) => !s.isPark).toList();
    final park = segmentsOfGroup.where((s) => s.isPark).toList();
    return {
      if (park.isNotEmpty)
        _multipart(id: focusParkId, segments: park, color: focusParkColor, width: focusParkWidth, zIndex: 10),
      if (trail.isNotEmpty)
        _multipart(id: focusTrailId, segments: trail, color: focusTrailColor, width: focusTrailWidth, zIndex: 11),
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

  /// 산군 마커 (center 없는 산은 생략).
  static NMarker? mountainMarker(Mountain m, {required void Function(Mountain) onTap}) {
    final c = m.center;
    if (c == null) return null;
    final marker = NMarker(
      id: mountainMarkerId(m.mountainGroup),
      position: toNLatLng(c),
      size: const Size(26, 36),
      caption: NOverlayCaption(text: m.mountainGroup, textSize: 13),
    );
    marker.setOnTapListener((_) => onTap(m));
    return marker;
  }

  static const entranceIdPrefix = 'ent:';
  static String entranceId(Spot s) => '$entranceIdPrefix${s.spotId}';

  /// 입구 마커. 산군 하나에 최대 99개라 겹치는 마커는 숨긴다.
  static Set<NAddableOverlay> entranceMarkers(List<Spot> entrances) => entrances
      .map((s) => NMarker(
            id: entranceId(s),
            position: toNLatLng(s.position),
            iconTintColor: entranceColor,
            size: const Size(14, 20),
            isHideCollidedMarkers: true,
          )..setZIndex(20))
      .toSet();

  static const coursePathId = 'course:path';
  static const courseStartId = 'course:start';
  static const courseIds = [coursePathId, courseStartId];

  /// 선택된 코스: 굵은 색 경로 + 출발 마커. 나머지는 회색 그대로.
  static Set<NAddableOverlay> courseOverlays(CourseSummary view) {
    if (view.polyline.length < 2) return const {};
    final path = NPathOverlay(
      id: coursePathId,
      coords: view.polyline.map(toNLatLng).toList(growable: false),
      width: courseWidth,
      color: courseColor,
      outlineWidth: 2,
      outlineColor: Colors.white,
      passedColor: courseColor,
      passedOutlineColor: Colors.white,
    )..setZIndex(30);
    final start = NMarker(
      id: courseStartId,
      position: toNLatLng(view.polyline.first),
      iconTintColor: courseColor,
      size: const Size(24, 34),
      caption: const NOverlayCaption(text: '출발', textSize: 12),
      isForceShowCaption: true,
    )..setZIndex(31);
    return {path, start};
  }

  static NOverlayInfo info(NOverlayType type, String id) => NOverlayInfo(type: type, id: id);
}
