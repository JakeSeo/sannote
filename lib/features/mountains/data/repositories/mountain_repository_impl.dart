import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/mountain.dart';
import '../../domain/repositories/mountain_repository.dart';
import '../services/mountain_service.dart';

class MountainRepositoryImpl implements MountainRepository {
  const MountainRepositoryImpl(this._service);

  final MountainService _service;

  @override
  Future<List<Mountain>> getAll() async {
    final rows = await _service.fetchAll();
    return rows.map(_toEntity).toList();
  }

  static Mountain _toEntity(Map<String, dynamic> json) {
    final lon = json['center_lon'];
    final lat = json['center_lat'];
    return Mountain(
      mountainGroup: json['mountain_group'] as String,
      sourceCodes: json['source_codes'] as String,
      regions: json['regions'] as String,
      segmentCount: (json['segment_count'] as num).toInt(),
      totalLengthKm: _toDouble(json['total_length_km'])!,
      entranceCount: (json['entrance_count'] as num).toInt(),
      center: lon == null || lat == null
          ? null
          : (lat: _toDouble(lat)!, lon: _toDouble(lon)!),
    );
  }

  /// numeric 컬럼은 PostgREST에서 문자열로 올 수 있어 둘 다 처리.
  static double? _toDouble(Object? v) => switch (v) {
        null => null,
        num n => n.toDouble(),
        String s => double.parse(s),
        _ => throw FormatException('숫자로 변환할 수 없음: $v'),
      };
}

final mountainRepositoryProvider = Provider<MountainRepository>(
  (ref) => MountainRepositoryImpl(ref.watch(mountainServiceProvider)),
);
