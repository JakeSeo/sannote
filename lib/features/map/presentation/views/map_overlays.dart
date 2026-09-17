import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../../spots/domain/entities/spot.dart';
import '../../../trails/domain/entities/trail_segment.dart';
import '../../../courses/domain/entities/course_summary.dart';

/// 테마가 정하는 지도 표현. 스케치북 테마는 산별 색연필 색과 2겹 선을 쓴다.
class MapStyle {
  const MapStyle({required this.colorOf, required this.pencil, this.markerIcons = const {}});

  /// 산군 → 칠하는 색 (코스 강조·완주 색칠·마커)
  final Color Function(String mountainGroup) colorOf;

  /// true = 색연필 느낌(넓고 옅은 선 + 좁고 진한 선)
  final bool pencil;

  /// 산군 → 손그림 마커 아이콘 (없으면 기본 핀)
  final Map<String, NOverlayImage> markerIcons;

  /// 기본(숲) 스타일: 단일 주황
  static MapStyle plain(Color accent) => MapStyle(colorOf: (_) => accent, pencil: false);
}

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

  // 완주해서 칠해진 길 (코어 루프). 회색 위에 산별 색.
  static const doneWidth = 4.0;

  /// 완주 구간 색칠 오버레이. 산군별로 나눠 그 산의 색으로. 색연필 스타일은 2겹(옅고 넓게 + 진하고 좁게).
  static Set<NAddableOverlay> doneOverlays(List<TrailSegment> completed, MapStyle style) {
    final byGroup = <String, List<TrailSegment>>{};
    for (final s in completed) {
      byGroup.putIfAbsent(s.mountainGroup, () => []).add(s);
    }
    final out = <NAddableOverlay>{};
    for (final e in byGroup.entries) {
      final c = style.colorOf(e.key);
      if (style.pencil) {
        out.add(_multipart(id: 'done:${e.key}:soft', segments: e.value, color: c.withValues(alpha: 0.35), width: 11, zIndex: 12));
        out.add(_multipart(id: 'done:${e.key}:core', segments: e.value, color: c.withValues(alpha: 0.9), width: 5, zIndex: 13));
      } else {
        out.add(_multipart(id: 'done:${e.key}:core', segments: e.value, color: c, width: doneWidth, zIndex: 12));
      }
    }
    return out;
  }

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

  /// 산군 마커 (center 없는 산은 생략). [icon]이 있으면 손그림 산 아이콘.
  static NMarker? mountainMarker(Mountain m, {required void Function(Mountain) onTap, NOverlayImage? icon}) {
    final c = m.center;
    if (c == null) return null;
    final marker = NMarker(
      id: mountainMarkerId(m.mountainGroup),
      position: toNLatLng(c),
      icon: icon,
      size: icon == null ? const Size(26, 36) : const Size(30, 30),
      anchor: icon == null ? NMarker.defaultAnchor : const NPoint(0.5, 0.9),
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

  /// 선택된 코스: 굵은 색 경로 + 출발 마커. 나머지는 회색 그대로. 색은 그 산의 색.
  static Set<NAddableOverlay> courseOverlays(CourseSummary view, MapStyle style) {
    if (view.polyline.length < 2) return const {};
    final color = style.colorOf(view.course.mountainGroup);
    final path = NPathOverlay(
      id: coursePathId,
      coords: view.polyline.map(toNLatLng).toList(growable: false),
      width: courseWidth,
      color: color,
      outlineWidth: style.pencil ? 3 : 2,
      outlineColor: style.pencil ? color.withValues(alpha: 0.3) : Colors.white,
      passedColor: color,
      passedOutlineColor: Colors.white,
    )..setZIndex(30);
    final start = NMarker(
      id: courseStartId,
      position: toNLatLng(view.polyline.first),
      iconTintColor: color,
      size: const Size(24, 34),
      caption: const NOverlayCaption(text: '출발', textSize: 12),
      isForceShowCaption: true,
    )..setZIndex(31);
    return {path, start};
  }

  static NOverlayInfo info(NOverlayType type, String id) => NOverlayInfo(type: type, id: id);
}
