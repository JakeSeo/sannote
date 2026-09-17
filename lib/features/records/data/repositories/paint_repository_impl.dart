import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart' as db;
import '../../domain/entities/paint.dart';
import '../../domain/repositories/paint_repository.dart';
import '../services/paint_local_service.dart';

class PaintRepositoryImpl implements PaintRepository {
  const PaintRepositoryImpl(this._service);

  final PaintLocalService _service;

  @override
  Future<Set<String>> paintedSegmentIds() async => (await _service.painted()).map((r) => r.segmentId).toSet();

  @override
  Future<List<PaintedSegment>> paintedSegments() async => (await _service.painted()).map(_toPainted).toList(growable: false);

  @override
  Stream<List<PaintedSegment>> watchPainted() => _service.watchPainted().map((rows) => rows.map(_toPainted).toList(growable: false));

  @override
  Future<Set<String>> paint(Iterable<PaintedSegment> segments) async {
    final before = await paintedSegmentIds();
    final fresh = segments.where((s) => !before.contains(s.segmentId)).toList();
    if (fresh.isEmpty) return const {};
    await _service.insertPainted([
      for (final s in fresh)
        db.PaintedSegmentsCompanion.insert(segmentId: s.segmentId, mountainGroup: s.mountainGroup, hikeId: s.hikeId, paintedAt: s.paintedAt),
    ]);
    return fresh.map((s) => s.segmentId).toSet();
  }

  @override
  Future<Set<String>> discoveredCourseIds() async => (await _service.discovered()).map((r) => r.courseId).toSet();

  @override
  Future<List<DiscoveredCourse>> discoveredCourses() async => (await _service.discovered()).map(_toDiscovered).toList(growable: false);

  @override
  Stream<List<DiscoveredCourse>> watchDiscovered() => _service.watchDiscovered().map((rows) => rows.map(_toDiscovered).toList(growable: false));

  @override
  Future<void> discover(Iterable<DiscoveredCourse> courses) => _service.insertDiscovered([
        for (final c in courses) db.DiscoveredCoursesCompanion.insert(courseId: c.courseId, hikeId: c.hikeId, discoveredAt: c.discoveredAt),
      ]);

  @override
  Future<void> removeByHike(String hikeId) => _service.deleteByHike(hikeId);

  static PaintedSegment _toPainted(db.PaintedSegment r) =>
      PaintedSegment(segmentId: r.segmentId, mountainGroup: r.mountainGroup, hikeId: r.hikeId, paintedAt: r.paintedAt);
  static DiscoveredCourse _toDiscovered(db.DiscoveredCourse r) =>
      DiscoveredCourse(courseId: r.courseId, hikeId: r.hikeId, discoveredAt: r.discoveredAt);
}

final paintRepositoryProvider = Provider<PaintRepository>((ref) => PaintRepositoryImpl(ref.watch(paintLocalServiceProvider)));
