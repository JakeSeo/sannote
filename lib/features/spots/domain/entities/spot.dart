import '../../../../core/geo/geo_point.dart';

/// spots 테이블 1행 (entrances 뷰 포함).
class Spot {
  const Spot({
    required this.spotId,
    required this.mountainGroup,
    required this.type,
    required this.category,
    required this.note,
    required this.isEntrance,
    required this.position,
  });

  final String spotId;
  final String mountainGroup;
  final String? type;
  final String? category;
  final String? note;
  final bool isEntrance;
  final GeoPoint position;
}
