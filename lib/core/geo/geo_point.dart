/// WGS84 좌표. 도메인 계층이 지도 SDK 타입(NLatLng)에 의존하지 않도록 분리.
typedef GeoPoint = ({double lat, double lon});

/// DB polyline jsonb `[[lon, lat], ...]` → GeoPoint 리스트.
List<GeoPoint> geoPointsFromLonLatJson(Object? raw) {
  if (raw is! List) {
    throw FormatException('polyline 형식이 배열이 아님: $raw');
  }
  return raw.map((p) {
    final pair = p as List;
    return (lon: (pair[0] as num).toDouble(), lat: (pair[1] as num).toDouble());
  }).toList(growable: false);
}
