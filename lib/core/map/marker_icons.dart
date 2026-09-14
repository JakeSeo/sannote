import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 런타임에 그린 점(dot) 마커 아이콘. 기본 핀 아이콘의 틴트는 색이 섞여 의도대로 안 나오고,
/// 원형 오버레이는 미터 단위라 축척에 따라 사라지므로 픽셀 고정 이미지 마커를 쓴다.
abstract final class MarkerIcons {
  static final _cache = <String, Future<NOverlayImage>>{};

  /// [color] 채움 + 흰 테두리의 원. [px]는 논리 픽셀 지름.
  static Future<NOverlayImage> dot(Color color, {double px = 14}) {
    final key = 'dot:${color.toARGB32()}:$px';
    return _cache.putIfAbsent(key, () async {
      final bytes = await _renderDot(color, px * 3); // 3x 해상도
      return NOverlayImage.fromByteArray(bytes, cacheKey: key);
    });
  }

  static Future<Uint8List> _renderDot(Color color, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final c = Offset(size / 2, size / 2);
    canvas.drawCircle(c, size / 2, Paint()..color = Colors.white);
    canvas.drawCircle(c, size / 2 - size * 0.12, Paint()..color = color);
    final image = await recorder.endRecording().toImage(size.ceil(), size.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
