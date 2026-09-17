import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';

class PaintLocalService {
  const PaintLocalService(this._db);

  final AppDatabase _db;

  Future<List<PaintedSegment>> painted() => _db.select(_db.paintedSegments).get();
  Stream<List<PaintedSegment>> watchPainted() => _db.select(_db.paintedSegments).watch();

  Future<void> insertPainted(List<PaintedSegmentsCompanion> rows) => _db.batch((b) => b.insertAll(_db.paintedSegments, rows, mode: InsertMode.insertOrIgnore));

  Future<List<DiscoveredCourse>> discovered() => _db.select(_db.discoveredCourses).get();
  Stream<List<DiscoveredCourse>> watchDiscovered() => _db.select(_db.discoveredCourses).watch();

  Future<void> insertDiscovered(List<DiscoveredCoursesCompanion> rows) => _db.batch((b) => b.insertAll(_db.discoveredCourses, rows, mode: InsertMode.insertOrIgnore));

  Future<void> deleteByHike(String hikeId) => _db.transaction(() async {
        await (_db.delete(_db.paintedSegments)..where((p) => p.hikeId.equals(hikeId))).go();
        await (_db.delete(_db.discoveredCourses)..where((d) => d.hikeId.equals(hikeId))).go();
      });
}

final paintLocalServiceProvider = Provider<PaintLocalService>((ref) => PaintLocalService(ref.watch(appDatabaseProvider)));
