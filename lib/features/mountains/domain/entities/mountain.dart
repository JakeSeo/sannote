import '../../../../core/geo/geo_point.dart';

/// mountains 테이블 1행. 식별자는 이름이 아니라 mountain_group (동명이산 주의).
class Mountain {
  const Mountain({
    required this.mountainGroup,
    required this.sourceCodes,
    required this.regions,
    required this.segmentCount,
    required this.totalLengthKm,
    required this.entranceCount,
    this.center,
    this.description,
  });

  final String mountainGroup;
  final String sourceCodes;
  final String regions;
  final int segmentCount;
  final double totalLengthKm;
  final int entranceCount;
  final GeoPoint? center;

  /// 산 소개 (mountains.description, 운영자가 채움. 없으면 null)
  final String? description;

  @override
  String toString() =>
      'Mountain($mountainGroup, $regions, 구간 $segmentCount개, ${totalLengthKm}km, 입구 $entranceCount곳)';
}
