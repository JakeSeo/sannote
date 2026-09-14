import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/memo.dart';
import '../../domain/entities/safety_point.dart';
import '../../domain/repositories/safety_repository.dart';
import '../services/safety_service.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._service);

  final SafetyService _service;
  final _byMountain = <String, AsyncMemo<List<SafetyPoint>>>{};

  @override
  Future<List<SafetyPoint>> getByMountain(String mountainGroup) =>
      _byMountain.putIfAbsent(mountainGroup, AsyncMemo.new)(() async {
        final rows = await _service.fetchByMountain(mountainGroup);
        return rows.map(_toEntity).toList(growable: false);
      });

  static SafetyPoint _toEntity(Map<String, dynamic> json) => SafetyPoint(
        safetyId: json['safety_id'] as String,
        mountainGroup: json['mountain_group'] as String,
        markerType: json['marker_type'] as String?,
        markerNo: json['marker_no'] as String?,
        agency: json['agency'] as String?,
        locationDesc: json['location_desc'] as String?,
        position: (lat: (json['lat'] as num).toDouble(), lon: (json['lon'] as num).toDouble()),
      );
}

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepositoryImpl(ref.watch(safetyServiceProvider)),
);
