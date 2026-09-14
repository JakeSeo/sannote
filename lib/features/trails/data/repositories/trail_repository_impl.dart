import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/geo_point.dart';
import '../../domain/entities/trail_segment.dart';
import '../../domain/repositories/trail_repository.dart';
import '../services/trail_service.dart';

class TrailRepositoryImpl implements TrailRepository {
  const TrailRepositoryImpl(this._service);

  final TrailService _service;

  @override
  Future<List<TrailSegment>> getAllSegments() async {
    final rows = await _service.fetchAllSegments();
    return rows.map(_toEntity).toList(growable: false);
  }

  static TrailSegment _toEntity(Map<String, dynamic> json) => TrailSegment(
        segmentId: json['segment_id'] as String,
        mountainGroup: json['mountain_group'] as String,
        isPark: (json['park_flag'] as num).toInt() == 1,
        lengthKm: switch (json['length_km']) {
          num n => n.toDouble(),
          String s => double.tryParse(s),
          _ => null,
        },
        upMin: (json['up_min'] as num?)?.toInt(),
        downMin: (json['down_min'] as num?)?.toInt(),
        difficulty: json['difficulty'] as String?,
        polyline: geoPointsFromLonLatJson(json['polyline']),
      );
}

final trailRepositoryProvider = Provider<TrailRepository>(
  (ref) => TrailRepositoryImpl(ref.watch(trailServiceProvider)),
);
