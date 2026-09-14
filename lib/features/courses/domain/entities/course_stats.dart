/// 코스 요약 수치. 구간 합산으로 자동 계산 (DB의 캐시 컬럼이 아니라 이 값이 표시 기준).
class CourseStats {
  const CourseStats({
    required this.lengthKm,
    required this.estUpMin,
    required this.estDownMin,
    required this.segmentCount,
    required this.score,
  });

  final double lengthKm;

  /// 원본 데이터 기반 예상값. UI에는 항상 "예상"을 붙여 표기한다.
  final int estUpMin;
  final int estDownMin;
  final int segmentCount;

  /// 난이도 점수 (공식은 [DifficultyFormula] 참조)
  final double score;

  DifficultyLevel get level => DifficultyFormula.levelOf(score);
}

enum DifficultyLevel {
  beginner('초급'),
  intermediate('중급'),
  advanced('상급');

  const DifficultyLevel(this.label);
  final String label;
}

/// 난이도 공식 초안 (BACKLOG M2 🔴 결정 대상 — 승인 전까지 변경 가능).
///
///   점수 = 거리(km) × 0.6 + 오름 예상시간(h) × 2 + 어려움 구간 비율 × 3 + 중간 구간 비율 × 1.5
///   초급 < 5, 중급 5~9, 상급 > 9
///
/// 예) 아차산역→해맞이 3.1km/56분 → 3.7 초급, 청계산 매봉급 6km/2.5h → 8.6 중급,
///     북한산 백운대급 8km/4h → 12.8 상급
/// tools/insert_course.py 의 계산과 반드시 동일하게 유지.
abstract final class DifficultyFormula {
  static const beginnerMax = 5.0;
  static const intermediateMax = 9.0;

  static double score({
    required double lengthKm,
    required int upMin,
    required double hardRatio,
    required double mediumRatio,
  }) =>
      lengthKm * 0.6 + (upMin / 60) * 2 + hardRatio * 3 + mediumRatio * 1.5;

  static DifficultyLevel levelOf(double score) {
    if (score < beginnerMax) return DifficultyLevel.beginner;
    if (score <= intermediateMax) return DifficultyLevel.intermediate;
    return DifficultyLevel.advanced;
  }
}
