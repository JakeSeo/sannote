import 'package:flutter/material.dart';

/// 톤앤매너. 2026-09-14 결정: **숲(forest)** 확정.
/// dawn은 비교용 시안으로만 남겨 두며(개발자 메뉴 전환), 릴리즈에는 forest만 쓴다.
enum ThemeVariant {
  /// 확정안. 진녹색 + 따뜻한 미색, 둥근 카드
  forest('숲 (확정)', '진녹색 + 미색, 둥근 카드'),

  /// 비교용 시안 (미채택)
  dawn('새벽 (미채택 시안)', '남색 + 주황 포인트, 각진 카드'),

  /// 스케치북 시안 1: 종이 바탕 + 연한 파스텔 색연필 + 손글씨 제목 전체
  sketch('스케치북 · 연', '종이 바탕, 파스텔 색연필, 손글씨 제목'),

  /// 스케치북 시안 2: 종이 바탕 + 진한 색연필 + 손글씨는 포인트(앱 이름·큰 숫자)만
  sketchInk('스케치북 · 진', '종이 바탕, 진한 색연필, 손글씨는 포인트만');

  /// 스케치북 계열인지 (종이 질감·손글씨·산별 색연필 적용)
  bool get isSketch => this == ThemeVariant.sketch || this == ThemeVariant.sketchInk;

  /// 색연필 톤: 진한 색을 쓰는가
  bool get inkTone => this == ThemeVariant.sketchInk;

  /// 제목 전체에 손글씨를 쓰는가 (false면 포인트에만)
  bool get handwritingTitles => this == ThemeVariant.sketch;

  const ThemeVariant(this.label, this.summary);
  final String label;
  final String summary;
}

abstract final class AppTheme {
  static ThemeData of(ThemeVariant v) => switch (v) {
        ThemeVariant.forest => _forest(),
        ThemeVariant.dawn => _dawn(),
        ThemeVariant.sketch => _sketch(ink: false, handwritingTitles: true),
        ThemeVariant.sketchInk => _sketch(ink: true, handwritingTitles: false),
      };

  /// 코스/강조 색 (지도 경로, 완주 색칠의 기준색). 스케치북은 산별 팔레트를 쓰므로 여기 값은 기본색.
  static Color accentOf(ThemeVariant v) => switch (v) {
        ThemeVariant.forest => const Color(0xFFE07A2F),
        ThemeVariant.dawn => const Color(0xFFFF6D3D),
        ThemeVariant.sketch => const Color(0xFFE8794F),
        ThemeVariant.sketchInk => const Color(0xFFE8794F),
      };

  // 스케치북 공통 색
  static const paper = Color(0xFFFBF7EE);
  static const paperCard = Color(0xFFFFFEFA);
  static const paperLine = Color(0xFFE6DFD0);
  static const ink = Color(0xFF2F3A2F);
  static const inkSoft = Color(0xFF6B7A6B);
  static const handwriting = 'Gaegu';

  static ThemeData _sketch({required bool ink, required bool handwritingTitles}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTheme.ink,
      primary: AppTheme.ink,
      onPrimary: paper,
      primaryContainer: const Color(0xFFE9E2D2),
      onPrimaryContainer: AppTheme.ink,
      secondary: const Color(0xFFE8794F),
      secondaryContainer: const Color(0xFFFBE3D6),
      surface: paper,
      onSurface: AppTheme.ink,
      onSurfaceVariant: inkSoft,
      outline: const Color(0xFFB9B0A0),
      outlineVariant: paperLine,
    );
    final base = _base(scheme);
    TextStyle? hand(TextStyle? t, {double? size, FontWeight? weight}) =>
        t?.copyWith(fontFamily: handwriting, fontSize: size, fontWeight: weight ?? FontWeight.w700, height: 1.15);
    final tt = base.textTheme;
    final text = tt.copyWith(
      // 앱 이름·큰 숫자·헤드라인은 두 시안 모두 손글씨
      displayLarge: hand(tt.displayLarge),
      displayMedium: hand(tt.displayMedium),
      displaySmall: hand(tt.displaySmall),
      headlineMedium: hand(tt.headlineMedium, size: 30),
      headlineSmall: hand(tt.headlineSmall, size: 26),
      // 제목 전체 손글씨는 시안 1만
      titleLarge: handwritingTitles ? hand(tt.titleLarge, size: 26) : tt.titleLarge,
      titleMedium: handwritingTitles ? hand(tt.titleMedium, size: 22) : tt.titleMedium,
      titleSmall: handwritingTitles ? hand(tt.titleSmall, size: 19) : tt.titleSmall,
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: paper,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: paper,
        titleTextStyle: (handwritingTitles ? hand(tt.titleLarge, size: 26) : tt.titleLarge)?.copyWith(color: AppTheme.ink),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: paperCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: paperLine),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(side: BorderSide(color: paperLine)),
        backgroundColor: paperCard,
        selectedColor: Color(0xFFE9E2D2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.ink,
          foregroundColor: paper,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: handwritingTitles ? const TextStyle(fontFamily: handwriting, fontSize: 20, fontWeight: FontWeight.w700) : null,
        ),
      ),
      dividerTheme: const DividerThemeData(color: paperLine),
    );
  }

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
