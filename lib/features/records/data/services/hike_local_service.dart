import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';

/// drift 쿼리 모음. 도메인 타입 변환은 리포지토리에서.
class HikeLocalService {
  const HikeLocalService(this._db);

  final AppDatabase _db;

  Future<void> insertHike(HikesCompanion row) => _db.into(_db.hikes).insert(row);

  Future<void> insertPoint(TrackPointsCompanion row) => _db.into(_db.trackPoints).insert(row);

  Future<void> updateHike(String id, HikesCompanion patch) =>
      (_db.update(_db.hikes)..where((h) => h.id.equals(id))).write(patch);

  Future<void> deleteHike(String id) => _db.transaction(() async {
        await (_db.delete(_db.trackPoints)..where((p) => p.hikeId.equals(id))).go();
        await (_db.delete(_db.hikes)..where((h) => h.id.equals(id))).go();
      });

  Future<Hike?> hikeById(String id) => (_db.select(_db.hikes)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<Hike?> activeHike() =>
      (_db.select(_db.hikes)..where((h) => h.status.equals('recording'))..limit(1)).getSingleOrNull();

  SimpleSelectStatement<$HikesTable, Hike> _allOrdered() =>
      _db.select(_db.hikes)..orderBy([(h) => OrderingTerm.desc(h.startedAt)]);

  Future<List<Hike>> allHikes() => _allOrdered().get();

  Stream<List<Hike>> watchHikes() => _allOrdered().watch();

  Future<List<TrackPoint>> points(String hikeId) =>
      (_db.select(_db.trackPoints)..where((p) => p.hikeId.equals(hikeId))..orderBy([(p) => OrderingTerm.asc(p.seq)]))
          .get();

  Future<int> countPoints(String hikeId) async {
    final c = _db.trackPoints.seq.count();
    final q = _db.selectOnly(_db.trackPoints)
      ..addColumns([c])
      ..where(_db.trackPoints.hikeId.equals(hikeId));
    return (await q.getSingle()).read(c) ?? 0;
  }
}

final hikeLocalServiceProvider = Provider<HikeLocalService>((ref) => HikeLocalService(ref.watch(appDatabaseProvider)));
