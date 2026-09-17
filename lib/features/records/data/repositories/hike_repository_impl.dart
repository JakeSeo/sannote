import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart' as db;
import '../../domain/entities/hike.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/repositories/hike_repository.dart';
import '../services/hike_local_service.dart';

class HikeRepositoryImpl implements HikeRepository {
  const HikeRepositoryImpl(this._service);

  final HikeLocalService _service;

  @override
  Future<Hike> create({
    required String id,
    required DateTime startedAt,
    String? courseId,
    String? courseName,
    String? mountainGroup,
  }) async {
    await _service.insertHike(db.HikesCompanion.insert(
      id: id,
      courseId: Value(courseId),
      courseName: Value(courseName),
      mountainGroup: Value(mountainGroup),
      startedAt: startedAt,
    ));
    return (await getById(id))!;
  }

  @override
  Future<void> appendPoint(String hikeId, TrackPoint p) => _service.insertPoint(db.TrackPointsCompanion.insert(
        hikeId: hikeId,
        recordedAt: p.recordedAt,
        lat: p.position.lat,
        lon: p.position.lon,
        accuracyM: Value(p.accuracyM),
        altitudeM: Value(p.altitudeM),
      ));

  @override
  Future<void> finish(
    String hikeId, {
    required DateTime endedAt,
    required HikeStatus status,
    required double distanceKm,
    required double? coverage,
    String? courseId,
    String? courseName,
    String? mountainGroup,
    int pausedSec = 0,
    int movingSec = 0,
    int? batteryStart,
    int? batteryEnd,
  }) =>
      _service.updateHike(
        hikeId,
        db.HikesCompanion(
          endedAt: Value(endedAt),
          pausedSec: Value(pausedSec),
          movingSec: Value(movingSec),
          batteryStart: Value(batteryStart),
          batteryEnd: Value(batteryEnd),
          status: Value(status.name),
          distanceKm: Value(distanceKm),
          coverage: Value(coverage),
          courseId: courseId == null ? const Value.absent() : Value(courseId),
          courseName: courseName == null ? const Value.absent() : Value(courseName),
          mountainGroup: mountainGroup == null ? const Value.absent() : Value(mountainGroup),
        ),
      );

  @override
  Future<void> markSynced(String hikeId, {required String visitId, required DateTime syncedAt}) =>
      _service.updateHike(hikeId, db.HikesCompanion(visitId: Value(visitId), syncedAt: Value(syncedAt)));

  @override
  Future<void> updateMovingSec(String hikeId, int movingSec) =>
      _service.updateHike(hikeId, db.HikesCompanion(movingSec: Value(movingSec)));

  @override
  Future<void> delete(String hikeId) => _service.deleteHike(hikeId);

  @override
  Future<Hike?> getById(String hikeId) async => _toEntity(await _service.hikeById(hikeId));

  @override
  Future<Hike?> getActive() async => _toEntity(await _service.activeHike());

  @override
  Future<List<Hike>> getAll() async => (await _service.allHikes()).map((r) => _toEntity(r)!).toList();

  @override
  Stream<List<Hike>> watchAll() => _service.watchHikes().map((rows) => rows.map((r) => _toEntity(r)!).toList());

  @override
  Future<List<TrackPoint>> getPoints(String hikeId) async => (await _service.points(hikeId))
      .map((r) => TrackPoint(
            recordedAt: r.recordedAt,
            position: (lat: r.lat, lon: r.lon),
            accuracyM: r.accuracyM,
            altitudeM: r.altitudeM,
          ))
      .toList(growable: false);

  @override
  Future<int> countPoints(String hikeId) => _service.countPoints(hikeId);

  static Hike? _toEntity(db.Hike? r) => r == null
      ? null
      : Hike(
          id: r.id,
          courseId: r.courseId,
          courseName: r.courseName,
          mountainGroup: r.mountainGroup,
          startedAt: r.startedAt,
          endedAt: r.endedAt,
          status: HikeStatus.parse(r.status),
          distanceKm: r.distanceKm,
          coverage: r.coverage,
          syncedAt: r.syncedAt,
          visitId: r.visitId,
          pausedSec: r.pausedSec,
          movingSec: r.movingSec,
          batteryStart: r.batteryStart,
          batteryEnd: r.batteryEnd,
        );
}

final hikeRepositoryProvider = Provider<HikeRepository>((ref) => HikeRepositoryImpl(ref.watch(hikeLocalServiceProvider)));
