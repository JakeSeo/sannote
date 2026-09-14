import '../../../core/geo/geo_point.dart';

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

  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
        spotId: json['spot_id'] as String,
        mountainGroup: json['mountain_group'] as String,
        type: json['type'] as String?,
        category: json['category'] as String?,
        note: json['note'] as String?,
        isEntrance: (json['is_entrance'] as num).toInt() == 1,
        position: (
          lat: (json['lat'] as num).toDouble(),
          lon: (json['lon'] as num).toDouble(),
        ),
      );
}
