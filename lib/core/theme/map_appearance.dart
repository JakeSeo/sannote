import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 지도 배경 표현 (네이버 지도 SDK 옵션). 산·코스가 주인공이 되도록 배경을 얼마나 조용히 할지.
enum MapAppearance {
  /// 네이버 기본: 상점·랜드마크 아이콘과 라벨 모두 표시
  normal('기본', '상점·랜드마크 아이콘 표시', symbolScale: 1.0, terrain: false),

  /// 아이콘·라벨 숨김 (symbolScale 0). 도로·건물·지명은 남지 않고 심볼만 사라짐
  quiet('조용히', '상점·랜드마크 아이콘 숨김', symbolScale: 0.0, terrain: false),

  /// 조용히 + 지형(음영·등고) 지도
  terrainQuiet('지형 · 조용히', '지형 지도 + 아이콘 숨김', symbolScale: 0.0, terrain: true);

  const MapAppearance(this.label, this.summary, {required this.symbolScale, required this.terrain});
  final String label;
  final String summary;
  final double symbolScale;
  final bool terrain;
}

/// 디버그 전용: `--dart-define=SANNOTE_MAP=quiet|terrainQuiet`
const _debugMap = String.fromEnvironment('SANNOTE_MAP');

class MapAppearanceNotifier extends Notifier<MapAppearance> {
  @override
  MapAppearance build() {
    if (kDebugMode && _debugMap.isNotEmpty) {
      return MapAppearance.values.where((v) => v.name == _debugMap).firstOrNull ?? MapAppearance.normal;
    }
    return MapAppearance.normal;
  }

  void set(MapAppearance v) => state = v;
}

final mapAppearanceProvider = NotifierProvider<MapAppearanceNotifier, MapAppearance>(MapAppearanceNotifier.new);
