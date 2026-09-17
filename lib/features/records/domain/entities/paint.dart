/// 칠한 구간 1개
class PaintedSegment {
  const PaintedSegment({required this.segmentId, required this.mountainGroup, required this.hikeId, required this.paintedAt});

  final String segmentId;
  final String mountainGroup;
  final String hikeId;
  final DateTime paintedAt;
}

/// 획득한 코스 1개
class DiscoveredCourse {
  const DiscoveredCourse({required this.courseId, required this.hikeId, required this.discoveredAt});

  final String courseId;
  final String hikeId;
  final DateTime discoveredAt;
}
