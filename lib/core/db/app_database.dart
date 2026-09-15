import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// 산행 1회. GPS 트랙은 이 기기에만 저장되고 서버(visits)에는 메타데이터만 올라간다.
class Hikes extends Table {
  TextColumn get id => text()(); // uuid

  /// null = 자유 산행 (코스를 고르지 않고 시작). 종료 시 자동 판별로 채워질 수 있다.
  TextColumn get courseId => text().nullable()();
  TextColumn get courseName => text().nullable()();
  TextColumn get mountainGroup => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// recording / completed / partial / discarded  ([HikeStatus] 이름)
  TextColumn get status => text().withDefault(const Constant('recording'))();
  RealColumn get distanceKm => real().withDefault(const Constant(0))();

  /// 종료 시 계산한 코스 커버율 (0~1). 완주 판정 제안에 사용
  RealColumn get coverage => real().nullable()();

  /// 서버 visits에 올라간 시각. null = 전송 대기
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get visitId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TrackPoints extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get hikeId => text().references(Hikes, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get altitudeM => real().nullable()();
}

@DriftDatabase(tables: [Hikes, TrackPoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'sannote'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX idx_track_points_hike ON track_points (hike_id, seq)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: hikes.course_id / course_name / mountain_group nullable (자유 산행)
            await m.alterTable(TableMigration(hikes));
          }
        },
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
