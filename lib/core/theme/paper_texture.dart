import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 종이 질감: 바탕색 위에 아주 옅은 점 노이즈. 스케치북 테마에서 시트·카드 배경에 쓴다.
class PaperTexture extends StatelessWidget {
  const PaperTexture({super.key, required this.color, this.child, this.borderRadius});

  final Color color;
  final Widget? child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CustomPaint(
        painter: _PaperPainter(color),
        child: child,
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final rand = math.Random(42);
    final grain = Paint()..color = const Color(0xFF6B5B45).withValues(alpha: 0.045);
    final count = (size.width * size.height / 260).clamp(200, 4000).toInt();
    for (var i = 0; i < count; i++) {
      final r = 0.4 + rand.nextDouble() * 0.9;
      canvas.drawCircle(Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height), r, grain);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter old) => old.color != color;
}
