import 'dart:math' as math;

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

/// 하버사인 거리 (km).
double distanceKm(GeoPoint a, GeoPoint b) {
  const r = 6371.0;
  final dLat = _rad(b.lat - a.lat);
  final dLon = _rad(b.lon - a.lon);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * r * math.asin(math.sqrt(h));
}

double _rad(double deg) => deg * math.pi / 180;
