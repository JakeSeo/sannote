/// mountains 테이블 1행. 식별자는 이름이 아니라 mountain_group (동명이산 주의).
class Mountain {
  const Mountain({
    required this.mountainGroup,
    required this.sourceCodes,
    required this.regions,
    required this.segmentCount,
    required this.totalLengthKm,
    required this.entranceCount,
    this.centerLon,
    this.centerLat,
  });

  final String mountainGroup;
  final String sourceCodes;
  final String regions;
  final int segmentCount;
  final double totalLengthKm;
  final int entranceCount;
  final double? centerLon;
  final double? centerLat;

  factory Mountain.fromJson(Map<String, dynamic> json) => Mountain(
        mountainGroup: json['mountain_group'] as String,
        sourceCodes: json['source_codes'] as String,
        regions: json['regions'] as String,
        segmentCount: (json['segment_count'] as num).toInt(),
        totalLengthKm: _toDouble(json['total_length_km']),
        entranceCount: (json['entrance_count'] as num).toInt(),
        centerLon: json['center_lon'] == null ? null : _toDouble(json['center_lon']),
        centerLat: json['center_lat'] == null ? null : _toDouble(json['center_lat']),
      );

  /// numeric 컬럼은 PostgREST에서 문자열로 올 수 있어 둘 다 처리.
  static double _toDouble(Object? v) => switch (v) {
        num n => n.toDouble(),
        String s => double.parse(s),
        _ => throw FormatException('숫자로 변환할 수 없음: $v'),
      };

  @override
  String toString() =>
      'Mountain($mountainGroup, $regions, 구간 $segmentCount개, ${totalLengthKm}km, 입구 $entranceCount곳)';
}
