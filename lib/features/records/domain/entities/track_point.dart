import '../../../../core/geo/geo_point.dart';

class TrackPoint {
  const TrackPoint({required this.recordedAt, required this.position, this.accuracyM, this.altitudeM});

  final DateTime recordedAt;
  final GeoPoint position;
  final double? accuracyM;
  final double? altitudeM;
}
