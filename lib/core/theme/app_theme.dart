import 'package:flutter/material.dart';

/// 톤앤매너 시안. M3 🔴 결정 대상 — 개발자 메뉴에서 실시간 전환해 비교한다.
enum ThemeVariant {
  /// A. 숲: 진녹색 + 따뜻한 미색. 차분하고 자연스러운 느낌
  forest('A. 숲', '진녹색 + 미색, 둥근 카드'),

  /// B. 새벽: 남색 + 주황 포인트. 또렷하고 젊은 느낌
  dawn('B. 새벽', '남색 + 주황 포인트, 각진 카드');

  const ThemeVariant(this.label, this.summary);
  final String label;
  final String summary;
}

abstract final class AppTheme {
  static ThemeData of(ThemeVariant v) => switch (v) {
        ThemeVariant.forest => _forest(),
        ThemeVariant.dawn => _dawn(),
      };

  /// 코스/강조 색 (지도 경로, 완주 색칠의 기준색). 테마마다 다르다.
  static Color accentOf(ThemeVariant v) => switch (v) {
        ThemeVariant.forest => const Color(0xFFE07A2F),
        ThemeVariant.dawn => const Color(0xFFFF6D3D),
      };

  static ThemeData _forest() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6B3E),
      primary: const Color(0xFF2E6B3E),
      surface: const Color(0xFFFAF8F2),
    );
    return _base(scheme).copyWith(
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  static ThemeData _dawn() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F3A5F),
      primary: const Color(0xFF1F3A5F),
      secondary: const Color(0xFFFF6D3D),
      surface: const Color(0xFFF5F7FA),
    );
    return _base(scheme).copyWith(
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) => ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: scheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primaryContainer,
        ),
        listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
        dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      );
}
