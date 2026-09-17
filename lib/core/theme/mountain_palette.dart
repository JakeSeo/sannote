import 'package:flutter/material.dart';

/// 산군별 색연필 색. "칠한 길"과 코스 강조, 스탬프에 쓴다. 산마다 다른 색 = 스탬프북 느낌.
/// pastel(연)과 ink(진) 두 톤을 두고 테마가 고른다. 지도 배경(흰·연두·베이지) 위에서 구분되도록 채도를 잡았다.
abstract final class MountainPalette {
  static const _pastel = <String, Color>{
    '아차산·용마산': Color(0xFFF4A98A), // 살구
    '북한산': Color(0xFF8FC1E3), // 하늘
    '관악산': Color(0xFFB7A3E0), // 연보라
    '청계산': Color(0xFF8FD3C1), // 민트
    '인왕산': Color(0xFFF2D479), // 노랑
    '북악산': Color(0xFFF3A6B8), // 분홍
    '수락산·불암산': Color(0xFFB5D67A), // 연두
  };
  static const _ink = <String, Color>{
    '아차산·용마산': Color(0xFFE8794F),
    '북한산': Color(0xFF3F8FC7),
    '관악산': Color(0xFF8B6CD1),
    '청계산': Color(0xFF3FB39A),
    '인왕산': Color(0xFFE0B531),
    '북악산': Color(0xFFE2708D),
    '수락산·불암산': Color(0xFF8CB93D),
  };

  /// 등록되지 않은 산군(테스트 산군 등)은 이름 해시로 팔레트에서 고른다
  static Color pastelOf(String group) => _pastel[group] ?? _pastel.values.elementAt(group.hashCode.abs() % _pastel.length);
  static Color inkOf(String group) => _ink[group] ?? _ink.values.elementAt(group.hashCode.abs() % _ink.length);

  /// 테마 톤에 맞는 색
  static Color of(String group, {required bool ink}) => ink ? inkOf(group) : pastelOf(group);
}
