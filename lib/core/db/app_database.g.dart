// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HikesTable extends Hikes with TableInfo<$HikesTable, Hike> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HikesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mountainGroupMeta = const VerificationMeta(
    'mountainGroup',
  );
  @override
  late final GeneratedColumn<String> mountainGroup = GeneratedColumn<String>(
    'mountain_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('recording'),
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverageMeta = const VerificationMeta(
    'coverage',
  );
  @override
  late final GeneratedColumn<double> coverage = GeneratedColumn<double>(
    'coverage',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedSecMeta = const VerificationMeta(
    'pausedSec',
  );
  @override
  late final GeneratedColumn<int> pausedSec = GeneratedColumn<int>(
    'paused_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _movingSecMeta = const VerificationMeta(
    'movingSec',
  );
  @override
  late final GeneratedColumn<int> movingSec = GeneratedColumn<int>(
    'moving_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _batteryStartMeta = const VerificationMeta(
    'batteryStart',
  );
  @override
  late final GeneratedColumn<int> batteryStart = GeneratedColumn<int>(
    'battery_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryEndMeta = const VerificationMeta(
    'batteryEnd',
  );
  @override
  late final GeneratedColumn<int> batteryEnd = GeneratedColumn<int>(
    'battery_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    courseName,
    mountainGroup,
    startedAt,
    endedAt,
    status,
    distanceKm,
    coverage,
    pausedSec,
    movingSec,
    batteryStart,
    batteryEnd,
    syncedAt,
    visitId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hikes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Hike> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    }
    if (data.containsKey('mountain_group')) {
      context.handle(
        _mountainGroupMeta,
        mountainGroup.isAcceptableOrUnknown(
          data['mountain_group']!,
          _mountainGroupMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    }
    if (data.containsKey('coverage')) {
      context.handle(
        _coverageMeta,
        coverage.isAcceptableOrUnknown(data['coverage']!, _coverageMeta),
      );
    }
    if (data.containsKey('paused_sec')) {
      context.handle(
        _pausedSecMeta,
        pausedSec.isAcceptableOrUnknown(data['paused_sec']!, _pausedSecMeta),
      );
    }
    if (data.containsKey('moving_sec')) {
      context.handle(
        _movingSecMeta,
        movingSec.isAcceptableOrUnknown(data['moving_sec']!, _movingSecMeta),
      );
    }
    if (data.containsKey('battery_start')) {
      context.handle(
        _batteryStartMeta,
        batteryStart.isAcceptableOrUnknown(
          data['battery_start']!,
          _batteryStartMeta,
        ),
      );
    }
    if (data.containsKey('battery_end')) {
      context.handle(
        _batteryEndMeta,
        batteryEnd.isAcceptableOrUnknown(data['battery_end']!, _batteryEndMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Hike map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hike(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      ),
      courseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_name'],
      ),
      mountainGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mountain_group'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      coverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage'],
      ),
      pausedSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_sec'],
      )!,
      movingSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_sec'],
      )!,
      batteryStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_start'],
      ),
      batteryEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_end'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
    );
  }

  @override
  $HikesTable createAlias(String alias) {
    return $HikesTable(attachedDatabase, alias);
  }
}

class Hike extends DataClass implements Insertable<Hike> {
  final String id;

  /// null = 자유 산행 (코스를 고르지 않고 시작). 종료 시 자동 판별로 채워질 수 있다.
  final String? courseId;
  final String? courseName;
  final String? mountainGroup;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// recording / completed / partial / discarded  ([HikeStatus] 이름)
  final String status;
  final double distanceKm;

  /// 종료 시 계산한 코스 커버율 (0~1). 완주 판정 제안에 사용
  final double? coverage;

  /// 수동 일시정지 누적 초
  final int pausedSec;

  /// 이동 시간(초): 점 사이 간격 중 실제로 움직인 구간 합 (ComputeMovingTime). 표시용 소요시간
  final int movingSec;

  /// 개발용: 시작/종료 시 배터리 % (모르면 null)
  final int? batteryStart;
  final int? batteryEnd;

  /// 서버 visits에 올라간 시각. null = 전송 대기
  final DateTime? syncedAt;
  final String? visitId;
  const Hike({
    required this.id,
    this.courseId,
    this.courseName,
    this.mountainGroup,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.distanceKm,
    this.coverage,
    required this.pausedSec,
    required this.movingSec,
    this.batteryStart,
    this.batteryEnd,
    this.syncedAt,
    this.visitId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || courseId != null) {
      map['course_id'] = Variable<String>(courseId);
    }
    if (!nullToAbsent || courseName != null) {
      map['course_name'] = Variable<String>(courseName);
    }
    if (!nullToAbsent || mountainGroup != null) {
      map['mountain_group'] = Variable<String>(mountainGroup);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['status'] = Variable<String>(status);
    map['distance_km'] = Variable<double>(distanceKm);
    if (!nullToAbsent || coverage != null) {
      map['coverage'] = Variable<double>(coverage);
    }
    map['paused_sec'] = Variable<int>(pausedSec);
    map['moving_sec'] = Variable<int>(movingSec);
    if (!nullToAbsent || batteryStart != null) {
      map['battery_start'] = Variable<int>(batteryStart);
    }
    if (!nullToAbsent || batteryEnd != null) {
      map['battery_end'] = Variable<int>(batteryEnd);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    return map;
  }

  HikesCompanion toCompanion(bool nullToAbsent) {
    return HikesCompanion(
      id: Value(id),
      courseId: courseId == null && nullToAbsent
          ? const Value.absent()
          : Value(courseId),
      courseName: courseName == null && nullToAbsent
          ? const Value.absent()
          : Value(courseName),
      mountainGroup: mountainGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(mountainGroup),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: Value(status),
      distanceKm: Value(distanceKm),
      coverage: coverage == null && nullToAbsent
          ? const Value.absent()
          : Value(coverage),
      pausedSec: Value(pausedSec),
      movingSec: Value(movingSec),
      batteryStart: batteryStart == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryStart),
      batteryEnd: batteryEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryEnd),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
    );
  }

  factory Hike.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Hike(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String?>(json['courseId']),
      courseName: serializer.fromJson<String?>(json['courseName']),
      mountainGroup: serializer.fromJson<String?>(json['mountainGroup']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      coverage: serializer.fromJson<double?>(json['coverage']),
      pausedSec: serializer.fromJson<int>(json['pausedSec']),
      movingSec: serializer.fromJson<int>(json['movingSec']),
      batteryStart: serializer.fromJson<int?>(json['batteryStart']),
      batteryEnd: serializer.fromJson<int?>(json['batteryEnd']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      visitId: serializer.fromJson<String?>(json['visitId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String?>(courseId),
      'courseName': serializer.toJson<String?>(courseName),
      'mountainGroup': serializer.toJson<String?>(mountainGroup),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'status': serializer.toJson<String>(status),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'coverage': serializer.toJson<double?>(coverage),
      'pausedSec': serializer.toJson<int>(pausedSec),
      'movingSec': serializer.toJson<int>(movingSec),
      'batteryStart': serializer.toJson<int?>(batteryStart),
      'batteryEnd': serializer.toJson<int?>(batteryEnd),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'visitId': serializer.toJson<String?>(visitId),
    };
  }

  Hike copyWith({
    String? id,
    Value<String?> courseId = const Value.absent(),
    Value<String?> courseName = const Value.absent(),
    Value<String?> mountainGroup = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? status,
    double? distanceKm,
    Value<double?> coverage = const Value.absent(),
    int? pausedSec,
    int? movingSec,
    Value<int?> batteryStart = const Value.absent(),
    Value<int?> batteryEnd = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> visitId = const Value.absent(),
  }) => Hike(
    id: id ?? this.id,
    courseId: courseId.present ? courseId.value : this.courseId,
    courseName: courseName.present ? courseName.value : this.courseName,
    mountainGroup: mountainGroup.present
        ? mountainGroup.value
        : this.mountainGroup,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    distanceKm: distanceKm ?? this.distanceKm,
    coverage: coverage.present ? coverage.value : this.coverage,
    pausedSec: pausedSec ?? this.pausedSec,
    movingSec: movingSec ?? this.movingSec,
    batteryStart: batteryStart.present ? batteryStart.value : this.batteryStart,
    batteryEnd: batteryEnd.present ? batteryEnd.value : this.batteryEnd,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    visitId: visitId.present ? visitId.value : this.visitId,
  );
  Hike copyWithCompanion(HikesCompanion data) {
    return Hike(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      courseName: data.courseName.present
          ? data.courseName.value
          : this.courseName,
      mountainGroup: data.mountainGroup.present
          ? data.mountainGroup.value
          : this.mountainGroup,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      coverage: data.coverage.present ? data.coverage.value : this.coverage,
      pausedSec: data.pausedSec.present ? data.pausedSec.value : this.pausedSec,
      movingSec: data.movingSec.present ? data.movingSec.value : this.movingSec,
      batteryStart: data.batteryStart.present
          ? data.batteryStart.value
          : this.batteryStart,
      batteryEnd: data.batteryEnd.present
          ? data.batteryEnd.value
          : this.batteryEnd,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Hike(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('courseName: $courseName, ')
          ..write('mountainGroup: $mountainGroup, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('coverage: $coverage, ')
          ..write('pausedSec: $pausedSec, ')
          ..write('movingSec: $movingSec, ')
          ..write('batteryStart: $batteryStart, ')
          ..write('batteryEnd: $batteryEnd, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('visitId: $visitId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    courseName,
    mountainGroup,
    startedAt,
    endedAt,
    status,
    distanceKm,
    coverage,
    pausedSec,
    movingSec,
    batteryStart,
    batteryEnd,
    syncedAt,
    visitId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Hike &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.courseName == this.courseName &&
          other.mountainGroup == this.mountainGroup &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.distanceKm == this.distanceKm &&
          other.coverage == this.coverage &&
          other.pausedSec == this.pausedSec &&
          other.movingSec == this.movingSec &&
          other.batteryStart == this.batteryStart &&
          other.batteryEnd == this.batteryEnd &&
          other.syncedAt == this.syncedAt &&
          other.visitId == this.visitId);
}

class HikesCompanion extends UpdateCompanion<Hike> {
  final Value<String> id;
  final Value<String?> courseId;
  final Value<String?> courseName;
  final Value<String?> mountainGroup;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> status;
  final Value<double> distanceKm;
  final Value<double?> coverage;
  final Value<int> pausedSec;
  final Value<int> movingSec;
  final Value<int?> batteryStart;
  final Value<int?> batteryEnd;
  final Value<DateTime?> syncedAt;
  final Value<String?> visitId;
  final Value<int> rowid;
  const HikesCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.courseName = const Value.absent(),
    this.mountainGroup = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.coverage = const Value.absent(),
    this.pausedSec = const Value.absent(),
    this.movingSec = const Value.absent(),
    this.batteryStart = const Value.absent(),
    this.batteryEnd = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.visitId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HikesCompanion.insert({
    required String id,
    this.courseId = const Value.absent(),
    this.courseName = const Value.absent(),
    this.mountainGroup = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.coverage = const Value.absent(),
    this.pausedSec = const Value.absent(),
    this.movingSec = const Value.absent(),
    this.batteryStart = const Value.absent(),
    this.batteryEnd = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.visitId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt);
  static Insertable<Hike> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? courseName,
    Expression<String>? mountainGroup,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<double>? distanceKm,
    Expression<double>? coverage,
    Expression<int>? pausedSec,
    Expression<int>? movingSec,
    Expression<int>? batteryStart,
    Expression<int>? batteryEnd,
    Expression<DateTime>? syncedAt,
    Expression<String>? visitId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (courseName != null) 'course_name': courseName,
      if (mountainGroup != null) 'mountain_group': mountainGroup,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (coverage != null) 'coverage': coverage,
      if (pausedSec != null) 'paused_sec': pausedSec,
      if (movingSec != null) 'moving_sec': movingSec,
      if (batteryStart != null) 'battery_start': batteryStart,
      if (batteryEnd != null) 'battery_end': batteryEnd,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (visitId != null) 'visit_id': visitId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HikesCompanion copyWith({
    Value<String>? id,
    Value<String?>? courseId,
    Value<String?>? courseName,
    Value<String?>? mountainGroup,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? status,
    Value<double>? distanceKm,
    Value<double?>? coverage,
    Value<int>? pausedSec,
    Value<int>? movingSec,
    Value<int?>? batteryStart,
    Value<int?>? batteryEnd,
    Value<DateTime?>? syncedAt,
    Value<String?>? visitId,
    Value<int>? rowid,
  }) {
    return HikesCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      mountainGroup: mountainGroup ?? this.mountainGroup,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      coverage: coverage ?? this.coverage,
      pausedSec: pausedSec ?? this.pausedSec,
      movingSec: movingSec ?? this.movingSec,
      batteryStart: batteryStart ?? this.batteryStart,
      batteryEnd: batteryEnd ?? this.batteryEnd,
      syncedAt: syncedAt ?? this.syncedAt,
      visitId: visitId ?? this.visitId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (mountainGroup.present) {
      map['mountain_group'] = Variable<String>(mountainGroup.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (coverage.present) {
      map['coverage'] = Variable<double>(coverage.value);
    }
    if (pausedSec.present) {
      map['paused_sec'] = Variable<int>(pausedSec.value);
    }
    if (movingSec.present) {
      map['moving_sec'] = Variable<int>(movingSec.value);
    }
    if (batteryStart.present) {
      map['battery_start'] = Variable<int>(batteryStart.value);
    }
    if (batteryEnd.present) {
      map['battery_end'] = Variable<int>(batteryEnd.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HikesCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('courseName: $courseName, ')
          ..write('mountainGroup: $mountainGroup, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('coverage: $coverage, ')
          ..write('pausedSec: $pausedSec, ')
          ..write('movingSec: $movingSec, ')
          ..write('batteryStart: $batteryStart, ')
          ..write('batteryEnd: $batteryEnd, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('visitId: $visitId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _hikeIdMeta = const VerificationMeta('hikeId');
  @override
  late final GeneratedColumn<String> hikeId = GeneratedColumn<String>(
    'hike_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES hikes (id)',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    hikeId,
    recordedAt,
    lat,
    lon,
    accuracyM,
    altitudeM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('hike_id')) {
      context.handle(
        _hikeIdMeta,
        hikeId.isAcceptableOrUnknown(data['hike_id']!, _hikeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hikeIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  TrackPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPoint(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      hikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hike_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      ),
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPoint extends DataClass implements Insertable<TrackPoint> {
  final int seq;
  final String hikeId;
  final DateTime recordedAt;
  final double lat;
  final double lon;
  final double? accuracyM;
  final double? altitudeM;
  const TrackPoint({
    required this.seq,
    required this.hikeId,
    required this.recordedAt,
    required this.lat,
    required this.lon,
    this.accuracyM,
    this.altitudeM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['hike_id'] = Variable<String>(hikeId);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || altitudeM != null) {
      map['altitude_m'] = Variable<double>(altitudeM);
    }
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      seq: Value(seq),
      hikeId: Value(hikeId),
      recordedAt: Value(recordedAt),
      lat: Value(lat),
      lon: Value(lon),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      altitudeM: altitudeM == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeM),
    );
  }

  factory TrackPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPoint(
      seq: serializer.fromJson<int>(json['seq']),
      hikeId: serializer.fromJson<String>(json['hikeId']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      altitudeM: serializer.fromJson<double?>(json['altitudeM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'hikeId': serializer.toJson<String>(hikeId),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'altitudeM': serializer.toJson<double?>(altitudeM),
    };
  }

  TrackPoint copyWith({
    int? seq,
    String? hikeId,
    DateTime? recordedAt,
    double? lat,
    double? lon,
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> altitudeM = const Value.absent(),
  }) => TrackPoint(
    seq: seq ?? this.seq,
    hikeId: hikeId ?? this.hikeId,
    recordedAt: recordedAt ?? this.recordedAt,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    altitudeM: altitudeM.present ? altitudeM.value : this.altitudeM,
  );
  TrackPoint copyWithCompanion(TrackPointsCompanion data) {
    return TrackPoint(
      seq: data.seq.present ? data.seq.value : this.seq,
      hikeId: data.hikeId.present ? data.hikeId.value : this.hikeId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPoint(')
          ..write('seq: $seq, ')
          ..write('hikeId: $hikeId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, hikeId, recordedAt, lat, lon, accuracyM, altitudeM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPoint &&
          other.seq == this.seq &&
          other.hikeId == this.hikeId &&
          other.recordedAt == this.recordedAt &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.accuracyM == this.accuracyM &&
          other.altitudeM == this.altitudeM);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPoint> {
  final Value<int> seq;
  final Value<String> hikeId;
  final Value<DateTime> recordedAt;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> accuracyM;
  final Value<double?> altitudeM;
  const TrackPointsCompanion({
    this.seq = const Value.absent(),
    this.hikeId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.altitudeM = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    this.seq = const Value.absent(),
    required String hikeId,
    required DateTime recordedAt,
    required double lat,
    required double lon,
    this.accuracyM = const Value.absent(),
    this.altitudeM = const Value.absent(),
  }) : hikeId = Value(hikeId),
       recordedAt = Value(recordedAt),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<TrackPoint> custom({
    Expression<int>? seq,
    Expression<String>? hikeId,
    Expression<DateTime>? recordedAt,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? accuracyM,
    Expression<double>? altitudeM,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (hikeId != null) 'hike_id': hikeId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (altitudeM != null) 'altitude_m': altitudeM,
    });
  }

  TrackPointsCompanion copyWith({
    Value<int>? seq,
    Value<String>? hikeId,
    Value<DateTime>? recordedAt,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? accuracyM,
    Value<double?>? altitudeM,
  }) {
    return TrackPointsCompanion(
      seq: seq ?? this.seq,
      hikeId: hikeId ?? this.hikeId,
      recordedAt: recordedAt ?? this.recordedAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracyM: accuracyM ?? this.accuracyM,
      altitudeM: altitudeM ?? this.altitudeM,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (hikeId.present) {
      map['hike_id'] = Variable<String>(hikeId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('seq: $seq, ')
          ..write('hikeId: $hikeId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM')
          ..write(')'))
        .toString();
  }
}

class $PaintedSegmentsTable extends PaintedSegments
    with TableInfo<$PaintedSegmentsTable, PaintedSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaintedSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mountainGroupMeta = const VerificationMeta(
    'mountainGroup',
  );
  @override
  late final GeneratedColumn<String> mountainGroup = GeneratedColumn<String>(
    'mountain_group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hikeIdMeta = const VerificationMeta('hikeId');
  @override
  late final GeneratedColumn<String> hikeId = GeneratedColumn<String>(
    'hike_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paintedAtMeta = const VerificationMeta(
    'paintedAt',
  );
  @override
  late final GeneratedColumn<DateTime> paintedAt = GeneratedColumn<DateTime>(
    'painted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    segmentId,
    mountainGroup,
    hikeId,
    paintedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'painted_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaintedSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('mountain_group')) {
      context.handle(
        _mountainGroupMeta,
        mountainGroup.isAcceptableOrUnknown(
          data['mountain_group']!,
          _mountainGroupMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mountainGroupMeta);
    }
    if (data.containsKey('hike_id')) {
      context.handle(
        _hikeIdMeta,
        hikeId.isAcceptableOrUnknown(data['hike_id']!, _hikeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hikeIdMeta);
    }
    if (data.containsKey('painted_at')) {
      context.handle(
        _paintedAtMeta,
        paintedAt.isAcceptableOrUnknown(data['painted_at']!, _paintedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paintedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {segmentId};
  @override
  PaintedSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaintedSegment(
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      mountainGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mountain_group'],
      )!,
      hikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hike_id'],
      )!,
      paintedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}painted_at'],
      )!,
    );
  }

  @override
  $PaintedSegmentsTable createAlias(String alias) {
    return $PaintedSegmentsTable(attachedDatabase, alias);
  }
}

class PaintedSegment extends DataClass implements Insertable<PaintedSegment> {
  final String segmentId;
  final String mountainGroup;
  final String hikeId;
  final DateTime paintedAt;
  const PaintedSegment({
    required this.segmentId,
    required this.mountainGroup,
    required this.hikeId,
    required this.paintedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['segment_id'] = Variable<String>(segmentId);
    map['mountain_group'] = Variable<String>(mountainGroup);
    map['hike_id'] = Variable<String>(hikeId);
    map['painted_at'] = Variable<DateTime>(paintedAt);
    return map;
  }

  PaintedSegmentsCompanion toCompanion(bool nullToAbsent) {
    return PaintedSegmentsCompanion(
      segmentId: Value(segmentId),
      mountainGroup: Value(mountainGroup),
      hikeId: Value(hikeId),
      paintedAt: Value(paintedAt),
    );
  }

  factory PaintedSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaintedSegment(
      segmentId: serializer.fromJson<String>(json['segmentId']),
      mountainGroup: serializer.fromJson<String>(json['mountainGroup']),
      hikeId: serializer.fromJson<String>(json['hikeId']),
      paintedAt: serializer.fromJson<DateTime>(json['paintedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'segmentId': serializer.toJson<String>(segmentId),
      'mountainGroup': serializer.toJson<String>(mountainGroup),
      'hikeId': serializer.toJson<String>(hikeId),
      'paintedAt': serializer.toJson<DateTime>(paintedAt),
    };
  }

  PaintedSegment copyWith({
    String? segmentId,
    String? mountainGroup,
    String? hikeId,
    DateTime? paintedAt,
  }) => PaintedSegment(
    segmentId: segmentId ?? this.segmentId,
    mountainGroup: mountainGroup ?? this.mountainGroup,
    hikeId: hikeId ?? this.hikeId,
    paintedAt: paintedAt ?? this.paintedAt,
  );
  PaintedSegment copyWithCompanion(PaintedSegmentsCompanion data) {
    return PaintedSegment(
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      mountainGroup: data.mountainGroup.present
          ? data.mountainGroup.value
          : this.mountainGroup,
      hikeId: data.hikeId.present ? data.hikeId.value : this.hikeId,
      paintedAt: data.paintedAt.present ? data.paintedAt.value : this.paintedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaintedSegment(')
          ..write('segmentId: $segmentId, ')
          ..write('mountainGroup: $mountainGroup, ')
          ..write('hikeId: $hikeId, ')
          ..write('paintedAt: $paintedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(segmentId, mountainGroup, hikeId, paintedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaintedSegment &&
          other.segmentId == this.segmentId &&
          other.mountainGroup == this.mountainGroup &&
          other.hikeId == this.hikeId &&
          other.paintedAt == this.paintedAt);
}

class PaintedSegmentsCompanion extends UpdateCompanion<PaintedSegment> {
  final Value<String> segmentId;
  final Value<String> mountainGroup;
  final Value<String> hikeId;
  final Value<DateTime> paintedAt;
  final Value<int> rowid;
  const PaintedSegmentsCompanion({
    this.segmentId = const Value.absent(),
    this.mountainGroup = const Value.absent(),
    this.hikeId = const Value.absent(),
    this.paintedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaintedSegmentsCompanion.insert({
    required String segmentId,
    required String mountainGroup,
    required String hikeId,
    required DateTime paintedAt,
    this.rowid = const Value.absent(),
  }) : segmentId = Value(segmentId),
       mountainGroup = Value(mountainGroup),
       hikeId = Value(hikeId),
       paintedAt = Value(paintedAt);
  static Insertable<PaintedSegment> custom({
    Expression<String>? segmentId,
    Expression<String>? mountainGroup,
    Expression<String>? hikeId,
    Expression<DateTime>? paintedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (segmentId != null) 'segment_id': segmentId,
      if (mountainGroup != null) 'mountain_group': mountainGroup,
      if (hikeId != null) 'hike_id': hikeId,
      if (paintedAt != null) 'painted_at': paintedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaintedSegmentsCompanion copyWith({
    Value<String>? segmentId,
    Value<String>? mountainGroup,
    Value<String>? hikeId,
    Value<DateTime>? paintedAt,
    Value<int>? rowid,
  }) {
    return PaintedSegmentsCompanion(
      segmentId: segmentId ?? this.segmentId,
      mountainGroup: mountainGroup ?? this.mountainGroup,
      hikeId: hikeId ?? this.hikeId,
      paintedAt: paintedAt ?? this.paintedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (mountainGroup.present) {
      map['mountain_group'] = Variable<String>(mountainGroup.value);
    }
    if (hikeId.present) {
      map['hike_id'] = Variable<String>(hikeId.value);
    }
    if (paintedAt.present) {
      map['painted_at'] = Variable<DateTime>(paintedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaintedSegmentsCompanion(')
          ..write('segmentId: $segmentId, ')
          ..write('mountainGroup: $mountainGroup, ')
          ..write('hikeId: $hikeId, ')
          ..write('paintedAt: $paintedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiscoveredCoursesTable extends DiscoveredCourses
    with TableInfo<$DiscoveredCoursesTable, DiscoveredCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscoveredCoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hikeIdMeta = const VerificationMeta('hikeId');
  @override
  late final GeneratedColumn<String> hikeId = GeneratedColumn<String>(
    'hike_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discoveredAtMeta = const VerificationMeta(
    'discoveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> discoveredAt = GeneratedColumn<DateTime>(
    'discovered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [courseId, hikeId, discoveredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discovered_courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiscoveredCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('hike_id')) {
      context.handle(
        _hikeIdMeta,
        hikeId.isAcceptableOrUnknown(data['hike_id']!, _hikeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hikeIdMeta);
    }
    if (data.containsKey('discovered_at')) {
      context.handle(
        _discoveredAtMeta,
        discoveredAt.isAcceptableOrUnknown(
          data['discovered_at']!,
          _discoveredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discoveredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseId};
  @override
  DiscoveredCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiscoveredCourse(
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      hikeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hike_id'],
      )!,
      discoveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discovered_at'],
      )!,
    );
  }

  @override
  $DiscoveredCoursesTable createAlias(String alias) {
    return $DiscoveredCoursesTable(attachedDatabase, alias);
  }
}

class DiscoveredCourse extends DataClass
    implements Insertable<DiscoveredCourse> {
  final String courseId;
  final String hikeId;
  final DateTime discoveredAt;
  const DiscoveredCourse({
    required this.courseId,
    required this.hikeId,
    required this.discoveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_id'] = Variable<String>(courseId);
    map['hike_id'] = Variable<String>(hikeId);
    map['discovered_at'] = Variable<DateTime>(discoveredAt);
    return map;
  }

  DiscoveredCoursesCompanion toCompanion(bool nullToAbsent) {
    return DiscoveredCoursesCompanion(
      courseId: Value(courseId),
      hikeId: Value(hikeId),
      discoveredAt: Value(discoveredAt),
    );
  }

  factory DiscoveredCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiscoveredCourse(
      courseId: serializer.fromJson<String>(json['courseId']),
      hikeId: serializer.fromJson<String>(json['hikeId']),
      discoveredAt: serializer.fromJson<DateTime>(json['discoveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseId': serializer.toJson<String>(courseId),
      'hikeId': serializer.toJson<String>(hikeId),
      'discoveredAt': serializer.toJson<DateTime>(discoveredAt),
    };
  }

  DiscoveredCourse copyWith({
    String? courseId,
    String? hikeId,
    DateTime? discoveredAt,
  }) => DiscoveredCourse(
    courseId: courseId ?? this.courseId,
    hikeId: hikeId ?? this.hikeId,
    discoveredAt: discoveredAt ?? this.discoveredAt,
  );
  DiscoveredCourse copyWithCompanion(DiscoveredCoursesCompanion data) {
    return DiscoveredCourse(
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      hikeId: data.hikeId.present ? data.hikeId.value : this.hikeId,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiscoveredCourse(')
          ..write('courseId: $courseId, ')
          ..write('hikeId: $hikeId, ')
          ..write('discoveredAt: $discoveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(courseId, hikeId, discoveredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiscoveredCourse &&
          other.courseId == this.courseId &&
          other.hikeId == this.hikeId &&
          other.discoveredAt == this.discoveredAt);
}

class DiscoveredCoursesCompanion extends UpdateCompanion<DiscoveredCourse> {
  final Value<String> courseId;
  final Value<String> hikeId;
  final Value<DateTime> discoveredAt;
  final Value<int> rowid;
  const DiscoveredCoursesCompanion({
    this.courseId = const Value.absent(),
    this.hikeId = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiscoveredCoursesCompanion.insert({
    required String courseId,
    required String hikeId,
    required DateTime discoveredAt,
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       hikeId = Value(hikeId),
       discoveredAt = Value(discoveredAt);
  static Insertable<DiscoveredCourse> custom({
    Expression<String>? courseId,
    Expression<String>? hikeId,
    Expression<DateTime>? discoveredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseId != null) 'course_id': courseId,
      if (hikeId != null) 'hike_id': hikeId,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiscoveredCoursesCompanion copyWith({
    Value<String>? courseId,
    Value<String>? hikeId,
    Value<DateTime>? discoveredAt,
    Value<int>? rowid,
  }) {
    return DiscoveredCoursesCompanion(
      courseId: courseId ?? this.courseId,
      hikeId: hikeId ?? this.hikeId,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (hikeId.present) {
      map['hike_id'] = Variable<String>(hikeId.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<DateTime>(discoveredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscoveredCoursesCompanion(')
          ..write('courseId: $courseId, ')
          ..write('hikeId: $hikeId, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HikesTable hikes = $HikesTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $PaintedSegmentsTable paintedSegments = $PaintedSegmentsTable(
    this,
  );
  late final $DiscoveredCoursesTable discoveredCourses =
      $DiscoveredCoursesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    hikes,
    trackPoints,
    paintedSegments,
    discoveredCourses,
  ];
}

typedef $$HikesTableCreateCompanionBuilder = HikesCompanion Function({
  required String id,
  Value<String?> courseId,
  Value<String?> courseName,
  Value<String?> mountainGroup,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<String> status,
  Value<double> distanceKm,
  Value<double?> coverage,
  Value<int> pausedSec,
  Value<int> movingSec,
  Value<int?> batteryStart,
  Value<int?> batteryEnd,
  Value<DateTime?> syncedAt,
  Value<String?> visitId,
  Value<int> rowid,
});
typedef $$HikesTableUpdateCompanionBuilder = HikesCompanion Function({
  Value<String> id,
  Value<String?> courseId,
  Value<String?> courseName,
  Value<String?> mountainGroup,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String> status,
  Value<double> distanceKm,
  Value<double?> coverage,
  Value<int> pausedSec,
  Value<int> movingSec,
  Value<int?> batteryStart,
  Value<int?> batteryEnd,
  Value<DateTime?> syncedAt,
  Value<String?> visitId,
  Value<int> rowid,
});

final class $$HikesTableReferences
    extends BaseReferences<_$AppDatabase, $HikesTable, Hike> {
  $$HikesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPoint>>
  _trackPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackPoints,
    aliasName: 'hikes__id__track_points__hike_id',
  );

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager(
      $_db,
      $_db.trackPoints,
    ).filter((f) => f.hikeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HikesTableFilterComposer extends Composer<_$AppDatabase, $HikesTable> {
  $$HikesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mountainGroup => $composableBuilder(
    column: $table.mountainGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coverage => $composableBuilder(
    column: $table.coverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedSec => $composableBuilder(
    column: $table.pausedSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingSec => $composableBuilder(
    column: $table.movingSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryStart => $composableBuilder(
    column: $table.batteryStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryEnd => $composableBuilder(
    column: $table.batteryEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackPointsRefs(
    Expression<bool> Function($$TrackPointsTableFilterComposer f) f,
  ) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.hikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HikesTableOrderingComposer
    extends Composer<_$AppDatabase, $HikesTable> {
  $$HikesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mountainGroup => $composableBuilder(
    column: $table.mountainGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coverage => $composableBuilder(
    column: $table.coverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedSec => $composableBuilder(
    column: $table.pausedSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingSec => $composableBuilder(
    column: $table.movingSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryStart => $composableBuilder(
    column: $table.batteryStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryEnd => $composableBuilder(
    column: $table.batteryEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitId => $composableBuilder(
    column: $table.visitId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HikesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HikesTable> {
  $$HikesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mountainGroup => $composableBuilder(
    column: $table.mountainGroup,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get coverage =>
      $composableBuilder(column: $table.coverage, builder: (column) => column);

  GeneratedColumn<int> get pausedSec =>
      $composableBuilder(column: $table.pausedSec, builder: (column) => column);

  GeneratedColumn<int> get movingSec =>
      $composableBuilder(column: $table.movingSec, builder: (column) => column);

  GeneratedColumn<int> get batteryStart => $composableBuilder(
    column: $table.batteryStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get batteryEnd => $composableBuilder(
    column: $table.batteryEnd,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get visitId =>
      $composableBuilder(column: $table.visitId, builder: (column) => column);

  Expression<T> trackPointsRefs<T extends Object>(
    Expression<T> Function($$TrackPointsTableAnnotationComposer a) f,
  ) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.hikeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HikesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HikesTable,
          Hike,
          $$HikesTableFilterComposer,
          $$HikesTableOrderingComposer,
          $$HikesTableAnnotationComposer,
          $$HikesTableCreateCompanionBuilder,
          $$HikesTableUpdateCompanionBuilder,
          (Hike, $$HikesTableReferences),
          Hike,
          PrefetchHooks Function({bool trackPointsRefs})
        > {
  $$HikesTableTableManager(_$AppDatabase db, $HikesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HikesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HikesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HikesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> courseId = const Value.absent(),
                Value<String?> courseName = const Value.absent(),
                Value<String?> mountainGroup = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<double?> coverage = const Value.absent(),
                Value<int> pausedSec = const Value.absent(),
                Value<int> movingSec = const Value.absent(),
                Value<int?> batteryStart = const Value.absent(),
                Value<int?> batteryEnd = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HikesCompanion(
                id: id,
                courseId: courseId,
                courseName: courseName,
                mountainGroup: mountainGroup,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                distanceKm: distanceKm,
                coverage: coverage,
                pausedSec: pausedSec,
                movingSec: movingSec,
                batteryStart: batteryStart,
                batteryEnd: batteryEnd,
                syncedAt: syncedAt,
                visitId: visitId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> courseId = const Value.absent(),
                Value<String?> courseName = const Value.absent(),
                Value<String?> mountainGroup = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<double?> coverage = const Value.absent(),
                Value<int> pausedSec = const Value.absent(),
                Value<int> movingSec = const Value.absent(),
                Value<int?> batteryStart = const Value.absent(),
                Value<int?> batteryEnd = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HikesCompanion.insert(
                id: id,
                courseId: courseId,
                courseName: courseName,
                mountainGroup: mountainGroup,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                distanceKm: distanceKm,
                coverage: coverage,
                pausedSec: pausedSec,
                movingSec: movingSec,
                batteryStart: batteryStart,
                batteryEnd: batteryEnd,
                syncedAt: syncedAt,
                visitId: visitId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HikesTable, Hike>(table),
                  $$HikesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackPointsRefs) db.trackPoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackPointsRefs)
                    await $_getPrefetchedData<Hike, $HikesTable, TrackPoint>(
                      currentTable: table,
                      referencedTable: $$HikesTableReferences
                          ._trackPointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HikesTableReferences(db, table, p0).trackPointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.hikeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HikesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HikesTable,
      Hike,
      $$HikesTableFilterComposer,
      $$HikesTableOrderingComposer,
      $$HikesTableAnnotationComposer,
      $$HikesTableCreateCompanionBuilder,
      $$HikesTableUpdateCompanionBuilder,
      (Hike, $$HikesTableReferences),
      Hike,
      PrefetchHooks Function({bool trackPointsRefs})
    >;
typedef $$TrackPointsTableCreateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> seq,
      required String hikeId,
      required DateTime recordedAt,
      required double lat,
      required double lon,
      Value<double?> accuracyM,
      Value<double?> altitudeM,
    });
typedef $$TrackPointsTableUpdateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> seq,
      Value<String> hikeId,
      Value<DateTime> recordedAt,
      Value<double> lat,
      Value<double> lon,
      Value<double?> accuracyM,
      Value<double?> altitudeM,
    });

final class $$TrackPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackPointsTable, TrackPoint> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HikesTable _hikeIdTable(_$AppDatabase db) =>
      db.hikes.createAlias('track_points__hike_id__hikes__id');

  $$HikesTableProcessedTableManager get hikeId {
    final $_column = $_itemColumn<String>('hike_id')!;

    final manager = $$HikesTableTableManager(
      $_db,
      $_db.hikes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_hikeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  $$HikesTableFilterComposer get hikeId {
    final $$HikesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.hikeId,
      referencedTable: $db.hikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HikesTableFilterComposer(
            $db: $db,
            $table: $db.hikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  $$HikesTableOrderingComposer get hikeId {
    final $$HikesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.hikeId,
      referencedTable: $db.hikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HikesTableOrderingComposer(
            $db: $db,
            $table: $db.hikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  $$HikesTableAnnotationComposer get hikeId {
    final $$HikesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.hikeId,
      referencedTable: $db.hikes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HikesTableAnnotationComposer(
            $db: $db,
            $table: $db.hikes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackPointsTable,
          TrackPoint,
          $$TrackPointsTableFilterComposer,
          $$TrackPointsTableOrderingComposer,
          $$TrackPointsTableAnnotationComposer,
          $$TrackPointsTableCreateCompanionBuilder,
          $$TrackPointsTableUpdateCompanionBuilder,
          (TrackPoint, $$TrackPointsTableReferences),
          TrackPoint,
          PrefetchHooks Function({bool hikeId})
        > {
  $$TrackPointsTableTableManager(_$AppDatabase db, $TrackPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> hikeId = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
              }) => TrackPointsCompanion(
                seq: seq,
                hikeId: hikeId,
                recordedAt: recordedAt,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String hikeId,
                required DateTime recordedAt,
                required double lat,
                required double lon,
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
              }) => TrackPointsCompanion.insert(
                seq: seq,
                hikeId: hikeId,
                recordedAt: recordedAt,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackPointsTable, TrackPoint>(table),
                  $$TrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({hikeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (hikeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.hikeId,
                        referencedTable: $$TrackPointsTableReferences
                            ._hikeIdTable(db),
                        referencedColumn: $$TrackPointsTableReferences
                            ._hikeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackPointsTable,
      TrackPoint,
      $$TrackPointsTableFilterComposer,
      $$TrackPointsTableOrderingComposer,
      $$TrackPointsTableAnnotationComposer,
      $$TrackPointsTableCreateCompanionBuilder,
      $$TrackPointsTableUpdateCompanionBuilder,
      (TrackPoint, $$TrackPointsTableReferences),
      TrackPoint,
      PrefetchHooks Function({bool hikeId})
    >;
typedef $$PaintedSegmentsTableCreateCompanionBuilder =
    PaintedSegmentsCompanion Function({
      required String segmentId,
      required String mountainGroup,
      required String hikeId,
      required DateTime paintedAt,
      Value<int> rowid,
    });
typedef $$PaintedSegmentsTableUpdateCompanionBuilder =
    PaintedSegmentsCompanion Function({
      Value<String> segmentId,
      Value<String> mountainGroup,
      Value<String> hikeId,
      Value<DateTime> paintedAt,
      Value<int> rowid,
    });

class $$PaintedSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaintedSegmentsTable> {
  $$PaintedSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mountainGroup => $composableBuilder(
    column: $table.mountainGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hikeId => $composableBuilder(
    column: $table.hikeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paintedAt => $composableBuilder(
    column: $table.paintedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaintedSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaintedSegmentsTable> {
  $$PaintedSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mountainGroup => $composableBuilder(
    column: $table.mountainGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hikeId => $composableBuilder(
    column: $table.hikeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paintedAt => $composableBuilder(
    column: $table.paintedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaintedSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaintedSegmentsTable> {
  $$PaintedSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<String> get mountainGroup => $composableBuilder(
    column: $table.mountainGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hikeId =>
      $composableBuilder(column: $table.hikeId, builder: (column) => column);

  GeneratedColumn<DateTime> get paintedAt =>
      $composableBuilder(column: $table.paintedAt, builder: (column) => column);
}

class $$PaintedSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaintedSegmentsTable,
          PaintedSegment,
          $$PaintedSegmentsTableFilterComposer,
          $$PaintedSegmentsTableOrderingComposer,
          $$PaintedSegmentsTableAnnotationComposer,
          $$PaintedSegmentsTableCreateCompanionBuilder,
          $$PaintedSegmentsTableUpdateCompanionBuilder,
          (
            PaintedSegment,
            BaseReferences<
              _$AppDatabase,
              $PaintedSegmentsTable,
              PaintedSegment
            >,
          ),
          PaintedSegment,
          PrefetchHooks Function()
        > {
  $$PaintedSegmentsTableTableManager(
    _$AppDatabase db,
    $PaintedSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaintedSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaintedSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaintedSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> segmentId = const Value.absent(),
                Value<String> mountainGroup = const Value.absent(),
                Value<String> hikeId = const Value.absent(),
                Value<DateTime> paintedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaintedSegmentsCompanion(
                segmentId: segmentId,
                mountainGroup: mountainGroup,
                hikeId: hikeId,
                paintedAt: paintedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String segmentId,
                required String mountainGroup,
                required String hikeId,
                required DateTime paintedAt,
                Value<int> rowid = const Value.absent(),
              }) => PaintedSegmentsCompanion.insert(
                segmentId: segmentId,
                mountainGroup: mountainGroup,
                hikeId: hikeId,
                paintedAt: paintedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaintedSegmentsTable, PaintedSegment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PaintedSegmentsTable,
                    PaintedSegment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaintedSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaintedSegmentsTable,
      PaintedSegment,
      $$PaintedSegmentsTableFilterComposer,
      $$PaintedSegmentsTableOrderingComposer,
      $$PaintedSegmentsTableAnnotationComposer,
      $$PaintedSegmentsTableCreateCompanionBuilder,
      $$PaintedSegmentsTableUpdateCompanionBuilder,
      (
        PaintedSegment,
        BaseReferences<_$AppDatabase, $PaintedSegmentsTable, PaintedSegment>,
      ),
      PaintedSegment,
      PrefetchHooks Function()
    >;
typedef $$DiscoveredCoursesTableCreateCompanionBuilder =
    DiscoveredCoursesCompanion Function({
      required String courseId,
      required String hikeId,
      required DateTime discoveredAt,
      Value<int> rowid,
    });
typedef $$DiscoveredCoursesTableUpdateCompanionBuilder =
    DiscoveredCoursesCompanion Function({
      Value<String> courseId,
      Value<String> hikeId,
      Value<DateTime> discoveredAt,
      Value<int> rowid,
    });

class $$DiscoveredCoursesTableFilterComposer
    extends Composer<_$AppDatabase, $DiscoveredCoursesTable> {
  $$DiscoveredCoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hikeId => $composableBuilder(
    column: $table.hikeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DiscoveredCoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscoveredCoursesTable> {
  $$DiscoveredCoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hikeId => $composableBuilder(
    column: $table.hikeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiscoveredCoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscoveredCoursesTable> {
  $$DiscoveredCoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get hikeId =>
      $composableBuilder(column: $table.hikeId, builder: (column) => column);

  GeneratedColumn<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => column,
  );
}

class $$DiscoveredCoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiscoveredCoursesTable,
          DiscoveredCourse,
          $$DiscoveredCoursesTableFilterComposer,
          $$DiscoveredCoursesTableOrderingComposer,
          $$DiscoveredCoursesTableAnnotationComposer,
          $$DiscoveredCoursesTableCreateCompanionBuilder,
          $$DiscoveredCoursesTableUpdateCompanionBuilder,
          (
            DiscoveredCourse,
            BaseReferences<
              _$AppDatabase,
              $DiscoveredCoursesTable,
              DiscoveredCourse
            >,
          ),
          DiscoveredCourse,
          PrefetchHooks Function()
        > {
  $$DiscoveredCoursesTableTableManager(
    _$AppDatabase db,
    $DiscoveredCoursesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscoveredCoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscoveredCoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscoveredCoursesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> courseId = const Value.absent(),
                Value<String> hikeId = const Value.absent(),
                Value<DateTime> discoveredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiscoveredCoursesCompanion(
                courseId: courseId,
                hikeId: hikeId,
                discoveredAt: discoveredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String courseId,
                required String hikeId,
                required DateTime discoveredAt,
                Value<int> rowid = const Value.absent(),
              }) => DiscoveredCoursesCompanion.insert(
                courseId: courseId,
                hikeId: hikeId,
                discoveredAt: discoveredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiscoveredCoursesTable, DiscoveredCourse>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DiscoveredCoursesTable,
                    DiscoveredCourse
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiscoveredCoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiscoveredCoursesTable,
      DiscoveredCourse,
      $$DiscoveredCoursesTableFilterComposer,
      $$DiscoveredCoursesTableOrderingComposer,
      $$DiscoveredCoursesTableAnnotationComposer,
      $$DiscoveredCoursesTableCreateCompanionBuilder,
      $$DiscoveredCoursesTableUpdateCompanionBuilder,
      (
        DiscoveredCourse,
        BaseReferences<
          _$AppDatabase,
          $DiscoveredCoursesTable,
          DiscoveredCourse
        >,
      ),
      DiscoveredCourse,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HikesTableTableManager get hikes =>
      $$HikesTableTableManager(_db, _db.hikes);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$PaintedSegmentsTableTableManager get paintedSegments =>
      $$PaintedSegmentsTableTableManager(_db, _db.paintedSegments);
  $$DiscoveredCoursesTableTableManager get discoveredCourses =>
      $$DiscoveredCoursesTableTableManager(_db, _db.discoveredCourses);
}
