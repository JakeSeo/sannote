/// courses 테이블 1행. 운영자가 segment_ids를 순서대로 큐레이션해 넣는다 (자동 생성 없음).
class Course {
  const Course({
    required this.courseId,
    required this.mountainGroup,
    required this.name,
    required this.segmentIds,
    required this.entranceSpotId,
    required this.description,
  });

  final String courseId;
  final String mountainGroup;
  final String name;

  /// 출발 → 도착 순서. 이어붙이면 코스 폴리라인.
  final List<String> segmentIds;
  final String? entranceSpotId;
  final String? description;
}
