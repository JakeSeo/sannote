import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/memo.dart';
import '../../domain/entities/entrance_access.dart';
import '../../domain/entities/spot.dart';
import '../../domain/repositories/spot_repository.dart';
import '../services/spot_service.dart';

class SpotRepositoryImpl implements SpotRepository {
  SpotRepositoryImpl(this._service);

  final SpotService _service;
  final _entrances = AsyncMemo<List<Spot>>();
  final _byMountain = <String, AsyncMemo<List<Spot>>>{};
  final _accessByMountain = <String, AsyncMemo<List<EntranceAccess>>>{};

  @override
  Future<List<Spot>> getEntrances() => _entrances(() async {
        final rows = await _service.fetchEntrances();
        return rows.map(_toSpot).toList(growable: false);
      });

  @override
  Future<List<Spot>> getSpotsOfMountain(String mountainGroup) =>
      _byMountain.putIfAbsent(mountainGroup, AsyncMemo.new)(() async {
        final rows = await _service.fetchSpotsOfMountain(mountainGroup);
        return rows.map(_toSpot).toList(growable: false);
      });

  @override
  Future<List<EntranceAccess>> getEntranceAccess(String mountainGroup) =>
      _accessByMountain.putIfAbsent(mountainGroup, AsyncMemo.new)(() async {
        final rows = await _service.fetchEntranceAccess(mountainGroup);
        return rows.map(_toAccess).toList(growable: false);
      });

  static Spot _toSpot(Map<String, dynamic> json) => Spot(
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

  static EntranceAccess _toAccess(Map<String, dynamic> json) => EntranceAccess(
        spotId: json['spot_id'] as String,
        stationName: json['station_name'] as String,
        line: json['line'] as String?,
        walkMin: (json['walk_min'] as num).toInt(),
        note: json['note'] as String?,
      );
}

final spotRepositoryProvider = Provider<SpotRepository>(
  (ref) => SpotRepositoryImpl(ref.watch(spotServiceProvider)),
);
