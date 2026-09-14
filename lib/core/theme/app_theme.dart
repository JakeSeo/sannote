import 'package:flutter/material.dart';

/// 톤앤매너. 2026-09-14 결정: **숲(forest)** 확정.
/// dawn은 비교용 시안으로만 남겨 두며(개발자 메뉴 전환), 릴리즈에는 forest만 쓴다.
enum ThemeVariant {
  /// 확정안. 진녹색 + 따뜻한 미색, 둥근 카드
  forest('숲 (확정)', '진녹색 + 미색, 둥근 카드'),

  /// 비교용 시안 (미채택)
  dawn('새벽 (미채택 시안)', '남색 + 주황 포인트, 각진 카드');

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
