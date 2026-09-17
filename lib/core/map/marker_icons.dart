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

  /// 색연필로 그린 작은 산(삼각형) 마커. [px]는 논리 픽셀 한 변.
  static Future<NOverlayImage> mountain(Color color, {double px = 30}) {
    final key = 'mtn:${color.toARGB32()}:$px';
    return _cache.putIfAbsent(key, () async {
      final bytes = await _renderMountain(color, px * 3);
      return NOverlayImage.fromByteArray(bytes, cacheKey: key);
    });
  }

  static Future<Uint8List> _renderMountain(Color color, double size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = size, h = size;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.96, h * 0.9)
      ..lineTo(w * 0.04, h * 0.9)
      ..close();
    // 종이 위 흰 테두리 → 색연필 채움 → 살짝 어긋난 진한 윤곽(손그림 느낌)
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = size * 0.16..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
    final outline = Path()
      ..moveTo(w * 0.52, h * 0.1)
      ..lineTo(w * 0.94, h * 0.88)
      ..lineTo(w * 0.07, h * 0.9)
      ..close();
    canvas.drawPath(outline, Paint()..color = _darken(color)..style = PaintingStyle.stroke..strokeWidth = size * 0.06..strokeJoin = StrokeJoin.round);
    // 눈 덮인 정상 느낌의 작은 흰 획
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.6, h * 0.3), Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = size * 0.05..strokeCap = StrokeCap.round);
    final image = await recorder.endRecording().toImage(size.ceil(), size.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static Color _darken(Color c) => HSLColor.fromColor(c).withLightness((HSLColor.fromColor(c).lightness - 0.25).clamp(0.0, 1.0)).toColor();

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
