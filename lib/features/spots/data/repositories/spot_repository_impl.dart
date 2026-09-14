import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/spot.dart';
import '../../domain/repositories/spot_repository.dart';
import '../services/spot_service.dart';

class SpotRepositoryImpl implements SpotRepository {
  const SpotRepositoryImpl(this._service);

  final SpotService _service;

  @override
  Future<List<Spot>> getEntrances() async {
    final rows = await _service.fetchEntrances();
    return rows.map(_toEntity).toList(growable: false);
  }

  static Spot _toEntity(Map<String, dynamic> json) => Spot(
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

final spotRepositoryProvider = Provider<SpotRepository>(
  (ref) => SpotRepositoryImpl(ref.watch(spotServiceProvider)),
);
