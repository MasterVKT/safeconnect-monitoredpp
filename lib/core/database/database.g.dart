// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
      'payload', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAttemptMeta =
      const VerificationMeta('lastAttempt');
  @override
  late final GeneratedColumn<DateTime> lastAttempt = GeneratedColumn<DateTime>(
      'last_attempt', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _batchIdMeta =
      const VerificationMeta('batchId');
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
      'batch_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _payloadSizeMeta =
      const VerificationMeta('payloadSize');
  @override
  late final GeneratedColumn<int> payloadSize = GeneratedColumn<int>(
      'payload_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        priority,
        payload,
        createdAt,
        retryCount,
        lastAttempt,
        status,
        batchId,
        payloadSize
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
          _lastAttemptMeta,
          lastAttempt.isAcceptableOrUnknown(
              data['last_attempt']!, _lastAttemptMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('batch_id')) {
      context.handle(_batchIdMeta,
          batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta));
    }
    if (data.containsKey('payload_size')) {
      context.handle(
          _payloadSizeMeta,
          payloadSize.isAcceptableOrUnknown(
              data['payload_size']!, _payloadSizeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastAttempt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_attempt']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      batchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_id']),
      payloadSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payload_size'])!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String type;
  final int priority;
  final Uint8List payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttempt;
  final String status;
  final String? batchId;
  final int payloadSize;
  const SyncQueueTableData(
      {required this.id,
      required this.type,
      required this.priority,
      required this.payload,
      required this.createdAt,
      required this.retryCount,
      this.lastAttempt,
      required this.status,
      this.batchId,
      required this.payloadSize});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['priority'] = Variable<int>(priority);
    map['payload'] = Variable<Uint8List>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    map['payload_size'] = Variable<int>(payloadSize);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      type: Value(type),
      priority: Value(priority),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      status: Value(status),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      payloadSize: Value(payloadSize),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      priority: serializer.fromJson<int>(json['priority']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastAttempt: serializer.fromJson<DateTime?>(json['lastAttempt']),
      status: serializer.fromJson<String>(json['status']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      payloadSize: serializer.fromJson<int>(json['payloadSize']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'priority': serializer.toJson<int>(priority),
      'payload': serializer.toJson<Uint8List>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastAttempt': serializer.toJson<DateTime?>(lastAttempt),
      'status': serializer.toJson<String>(status),
      'batchId': serializer.toJson<String?>(batchId),
      'payloadSize': serializer.toJson<int>(payloadSize),
    };
  }

  SyncQueueTableData copyWith(
          {int? id,
          String? type,
          int? priority,
          Uint8List? payload,
          DateTime? createdAt,
          int? retryCount,
          Value<DateTime?> lastAttempt = const Value.absent(),
          String? status,
          Value<String?> batchId = const Value.absent(),
          int? payloadSize}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
        status: status ?? this.status,
        batchId: batchId.present ? batchId.value : this.batchId,
        payloadSize: payloadSize ?? this.payloadSize,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      priority: data.priority.present ? data.priority.value : this.priority,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastAttempt:
          data.lastAttempt.present ? data.lastAttempt.value : this.lastAttempt,
      status: data.status.present ? data.status.value : this.status,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      payloadSize:
          data.payloadSize.present ? data.payloadSize.value : this.payloadSize,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('status: $status, ')
          ..write('batchId: $batchId, ')
          ..write('payloadSize: $payloadSize')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      priority,
      $driftBlobEquality.hash(payload),
      createdAt,
      retryCount,
      lastAttempt,
      status,
      batchId,
      payloadSize);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.type == this.type &&
          other.priority == this.priority &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastAttempt == this.lastAttempt &&
          other.status == this.status &&
          other.batchId == this.batchId &&
          other.payloadSize == this.payloadSize);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> priority;
  final Value<Uint8List> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastAttempt;
  final Value<String> status;
  final Value<String?> batchId;
  final Value<int> payloadSize;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.priority = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.status = const Value.absent(),
    this.batchId = const Value.absent(),
    this.payloadSize = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.priority = const Value.absent(),
    required Uint8List payload,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.status = const Value.absent(),
    this.batchId = const Value.absent(),
    this.payloadSize = const Value.absent(),
  })  : type = Value(type),
        payload = Value(payload);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? priority,
    Expression<Uint8List>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastAttempt,
    Expression<String>? status,
    Expression<String>? batchId,
    Expression<int>? payloadSize,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (priority != null) 'priority': priority,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (status != null) 'status': status,
      if (batchId != null) 'batch_id': batchId,
      if (payloadSize != null) 'payload_size': payloadSize,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<int>? priority,
      Value<Uint8List>? payload,
      Value<DateTime>? createdAt,
      Value<int>? retryCount,
      Value<DateTime?>? lastAttempt,
      Value<String>? status,
      Value<String?>? batchId,
      Value<int>? payloadSize}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      status: status ?? this.status,
      batchId: batchId ?? this.batchId,
      payloadSize: payloadSize ?? this.payloadSize,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (payloadSize.present) {
      map['payload_size'] = Variable<int>(payloadSize.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('priority: $priority, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('status: $status, ')
          ..write('batchId: $batchId, ')
          ..write('payloadSize: $payloadSize')
          ..write(')'))
        .toString();
  }
}

class $CollectionLeaseTableTable extends CollectionLeaseTable
    with TableInfo<$CollectionLeaseTableTable, CollectionLeaseTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionLeaseTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
      'owner', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _acquiredAtMsMeta =
      const VerificationMeta('acquiredAtMs');
  @override
  late final GeneratedColumn<int> acquiredAtMs = GeneratedColumn<int>(
      'acquired_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, owner, acquiredAtMs, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_lease_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CollectionLeaseTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner')) {
      context.handle(
          _ownerMeta, owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta));
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('acquired_at_ms')) {
      context.handle(
          _acquiredAtMsMeta,
          acquiredAtMs.isAcceptableOrUnknown(
              data['acquired_at_ms']!, _acquiredAtMsMeta));
    } else if (isInserting) {
      context.missing(_acquiredAtMsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionLeaseTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionLeaseTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      owner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner'])!,
      acquiredAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acquired_at_ms'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CollectionLeaseTableTable createAlias(String alias) {
    return $CollectionLeaseTableTable(attachedDatabase, alias);
  }
}

class CollectionLeaseTableData extends DataClass
    implements Insertable<CollectionLeaseTableData> {
  final int id;
  final String owner;
  final int acquiredAtMs;
  final DateTime updatedAt;
  const CollectionLeaseTableData(
      {required this.id,
      required this.owner,
      required this.acquiredAtMs,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner'] = Variable<String>(owner);
    map['acquired_at_ms'] = Variable<int>(acquiredAtMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionLeaseTableCompanion toCompanion(bool nullToAbsent) {
    return CollectionLeaseTableCompanion(
      id: Value(id),
      owner: Value(owner),
      acquiredAtMs: Value(acquiredAtMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory CollectionLeaseTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionLeaseTableData(
      id: serializer.fromJson<int>(json['id']),
      owner: serializer.fromJson<String>(json['owner']),
      acquiredAtMs: serializer.fromJson<int>(json['acquiredAtMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'owner': serializer.toJson<String>(owner),
      'acquiredAtMs': serializer.toJson<int>(acquiredAtMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CollectionLeaseTableData copyWith(
          {int? id, String? owner, int? acquiredAtMs, DateTime? updatedAt}) =>
      CollectionLeaseTableData(
        id: id ?? this.id,
        owner: owner ?? this.owner,
        acquiredAtMs: acquiredAtMs ?? this.acquiredAtMs,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CollectionLeaseTableData copyWithCompanion(
      CollectionLeaseTableCompanion data) {
    return CollectionLeaseTableData(
      id: data.id.present ? data.id.value : this.id,
      owner: data.owner.present ? data.owner.value : this.owner,
      acquiredAtMs: data.acquiredAtMs.present
          ? data.acquiredAtMs.value
          : this.acquiredAtMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionLeaseTableData(')
          ..write('id: $id, ')
          ..write('owner: $owner, ')
          ..write('acquiredAtMs: $acquiredAtMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, owner, acquiredAtMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionLeaseTableData &&
          other.id == this.id &&
          other.owner == this.owner &&
          other.acquiredAtMs == this.acquiredAtMs &&
          other.updatedAt == this.updatedAt);
}

class CollectionLeaseTableCompanion
    extends UpdateCompanion<CollectionLeaseTableData> {
  final Value<int> id;
  final Value<String> owner;
  final Value<int> acquiredAtMs;
  final Value<DateTime> updatedAt;
  const CollectionLeaseTableCompanion({
    this.id = const Value.absent(),
    this.owner = const Value.absent(),
    this.acquiredAtMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CollectionLeaseTableCompanion.insert({
    this.id = const Value.absent(),
    required String owner,
    required int acquiredAtMs,
    this.updatedAt = const Value.absent(),
  })  : owner = Value(owner),
        acquiredAtMs = Value(acquiredAtMs);
  static Insertable<CollectionLeaseTableData> custom({
    Expression<int>? id,
    Expression<String>? owner,
    Expression<int>? acquiredAtMs,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (owner != null) 'owner': owner,
      if (acquiredAtMs != null) 'acquired_at_ms': acquiredAtMs,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CollectionLeaseTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? owner,
      Value<int>? acquiredAtMs,
      Value<DateTime>? updatedAt}) {
    return CollectionLeaseTableCompanion(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      acquiredAtMs: acquiredAtMs ?? this.acquiredAtMs,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (acquiredAtMs.present) {
      map['acquired_at_ms'] = Variable<int>(acquiredAtMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionLeaseTableCompanion(')
          ..write('id: $id, ')
          ..write('owner: $owner, ')
          ..write('acquiredAtMs: $acquiredAtMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SmsDataTableTable extends SmsDataTable
    with TableInfo<$SmsDataTableTable, SmsDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _messageTypeMeta =
      const VerificationMeta('messageType');
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
      'message_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _senderNameMeta =
      const VerificationMeta('senderName');
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
      'sender_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hasAttachmentMeta =
      const VerificationMeta('hasAttachment');
  @override
  late final GeneratedColumn<bool> hasAttachment = GeneratedColumn<bool>(
      'has_attachment', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_attachment" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        messageType,
        direction,
        sender,
        senderName,
        body,
        sentAt,
        recordedAt,
        conversationId,
        hasAttachment,
        synced,
        hash
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_data_table';
  @override
  VerificationContext validateIntegrity(Insertable<SmsDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
          _messageTypeMeta,
          messageType.isAcceptableOrUnknown(
              data['message_type']!, _messageTypeMeta));
    } else if (isInserting) {
      context.missing(_messageTypeMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
          _senderNameMeta,
          senderName.isAcceptableOrUnknown(
              data['sender_name']!, _senderNameMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    }
    if (data.containsKey('has_attachment')) {
      context.handle(
          _hasAttachmentMeta,
          hasAttachment.isAcceptableOrUnknown(
              data['has_attachment']!, _hasAttachmentMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      messageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_type'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      senderName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_name']),
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      conversationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conversation_id']),
      hasAttachment: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_attachment'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash'])!,
    );
  }

  @override
  $SmsDataTableTable createAlias(String alias) {
    return $SmsDataTableTable(attachedDatabase, alias);
  }
}

class SmsDataTableData extends DataClass
    implements Insertable<SmsDataTableData> {
  final int id;
  final String deviceId;
  final String messageType;
  final String direction;
  final String sender;
  final String? senderName;
  final String body;
  final DateTime sentAt;
  final DateTime recordedAt;
  final String? conversationId;
  final bool hasAttachment;
  final bool synced;
  final String hash;
  const SmsDataTableData(
      {required this.id,
      required this.deviceId,
      required this.messageType,
      required this.direction,
      required this.sender,
      this.senderName,
      required this.body,
      required this.sentAt,
      required this.recordedAt,
      this.conversationId,
      required this.hasAttachment,
      required this.synced,
      required this.hash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['message_type'] = Variable<String>(messageType);
    map['direction'] = Variable<String>(direction);
    map['sender'] = Variable<String>(sender);
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    map['body'] = Variable<String>(body);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    map['has_attachment'] = Variable<bool>(hasAttachment);
    map['synced'] = Variable<bool>(synced);
    map['hash'] = Variable<String>(hash);
    return map;
  }

  SmsDataTableCompanion toCompanion(bool nullToAbsent) {
    return SmsDataTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      messageType: Value(messageType),
      direction: Value(direction),
      sender: Value(sender),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      body: Value(body),
      sentAt: Value(sentAt),
      recordedAt: Value(recordedAt),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      hasAttachment: Value(hasAttachment),
      synced: Value(synced),
      hash: Value(hash),
    );
  }

  factory SmsDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsDataTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      messageType: serializer.fromJson<String>(json['messageType']),
      direction: serializer.fromJson<String>(json['direction']),
      sender: serializer.fromJson<String>(json['sender']),
      senderName: serializer.fromJson<String?>(json['senderName']),
      body: serializer.fromJson<String>(json['body']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      conversationId: serializer.fromJson<String?>(json['conversationId']),
      hasAttachment: serializer.fromJson<bool>(json['hasAttachment']),
      synced: serializer.fromJson<bool>(json['synced']),
      hash: serializer.fromJson<String>(json['hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'messageType': serializer.toJson<String>(messageType),
      'direction': serializer.toJson<String>(direction),
      'sender': serializer.toJson<String>(sender),
      'senderName': serializer.toJson<String?>(senderName),
      'body': serializer.toJson<String>(body),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'conversationId': serializer.toJson<String?>(conversationId),
      'hasAttachment': serializer.toJson<bool>(hasAttachment),
      'synced': serializer.toJson<bool>(synced),
      'hash': serializer.toJson<String>(hash),
    };
  }

  SmsDataTableData copyWith(
          {int? id,
          String? deviceId,
          String? messageType,
          String? direction,
          String? sender,
          Value<String?> senderName = const Value.absent(),
          String? body,
          DateTime? sentAt,
          DateTime? recordedAt,
          Value<String?> conversationId = const Value.absent(),
          bool? hasAttachment,
          bool? synced,
          String? hash}) =>
      SmsDataTableData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        messageType: messageType ?? this.messageType,
        direction: direction ?? this.direction,
        sender: sender ?? this.sender,
        senderName: senderName.present ? senderName.value : this.senderName,
        body: body ?? this.body,
        sentAt: sentAt ?? this.sentAt,
        recordedAt: recordedAt ?? this.recordedAt,
        conversationId:
            conversationId.present ? conversationId.value : this.conversationId,
        hasAttachment: hasAttachment ?? this.hasAttachment,
        synced: synced ?? this.synced,
        hash: hash ?? this.hash,
      );
  SmsDataTableData copyWithCompanion(SmsDataTableCompanion data) {
    return SmsDataTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      direction: data.direction.present ? data.direction.value : this.direction,
      sender: data.sender.present ? data.sender.value : this.sender,
      senderName:
          data.senderName.present ? data.senderName.value : this.senderName,
      body: data.body.present ? data.body.value : this.body,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      hasAttachment: data.hasAttachment.present
          ? data.hasAttachment.value
          : this.hasAttachment,
      synced: data.synced.present ? data.synced.value : this.synced,
      hash: data.hash.present ? data.hash.value : this.hash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsDataTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('messageType: $messageType, ')
          ..write('direction: $direction, ')
          ..write('sender: $sender, ')
          ..write('senderName: $senderName, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('hasAttachment: $hasAttachment, ')
          ..write('synced: $synced, ')
          ..write('hash: $hash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      messageType,
      direction,
      sender,
      senderName,
      body,
      sentAt,
      recordedAt,
      conversationId,
      hasAttachment,
      synced,
      hash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsDataTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.messageType == this.messageType &&
          other.direction == this.direction &&
          other.sender == this.sender &&
          other.senderName == this.senderName &&
          other.body == this.body &&
          other.sentAt == this.sentAt &&
          other.recordedAt == this.recordedAt &&
          other.conversationId == this.conversationId &&
          other.hasAttachment == this.hasAttachment &&
          other.synced == this.synced &&
          other.hash == this.hash);
}

class SmsDataTableCompanion extends UpdateCompanion<SmsDataTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> messageType;
  final Value<String> direction;
  final Value<String> sender;
  final Value<String?> senderName;
  final Value<String> body;
  final Value<DateTime> sentAt;
  final Value<DateTime> recordedAt;
  final Value<String?> conversationId;
  final Value<bool> hasAttachment;
  final Value<bool> synced;
  final Value<String> hash;
  const SmsDataTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.messageType = const Value.absent(),
    this.direction = const Value.absent(),
    this.sender = const Value.absent(),
    this.senderName = const Value.absent(),
    this.body = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.hasAttachment = const Value.absent(),
    this.synced = const Value.absent(),
    this.hash = const Value.absent(),
  });
  SmsDataTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String messageType,
    required String direction,
    required String sender,
    this.senderName = const Value.absent(),
    required String body,
    required DateTime sentAt,
    this.recordedAt = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.hasAttachment = const Value.absent(),
    this.synced = const Value.absent(),
    required String hash,
  })  : deviceId = Value(deviceId),
        messageType = Value(messageType),
        direction = Value(direction),
        sender = Value(sender),
        body = Value(body),
        sentAt = Value(sentAt),
        hash = Value(hash);
  static Insertable<SmsDataTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? messageType,
    Expression<String>? direction,
    Expression<String>? sender,
    Expression<String>? senderName,
    Expression<String>? body,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? recordedAt,
    Expression<String>? conversationId,
    Expression<bool>? hasAttachment,
    Expression<bool>? synced,
    Expression<String>? hash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (messageType != null) 'message_type': messageType,
      if (direction != null) 'direction': direction,
      if (sender != null) 'sender': sender,
      if (senderName != null) 'sender_name': senderName,
      if (body != null) 'body': body,
      if (sentAt != null) 'sent_at': sentAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (conversationId != null) 'conversation_id': conversationId,
      if (hasAttachment != null) 'has_attachment': hasAttachment,
      if (synced != null) 'synced': synced,
      if (hash != null) 'hash': hash,
    });
  }

  SmsDataTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<String>? messageType,
      Value<String>? direction,
      Value<String>? sender,
      Value<String?>? senderName,
      Value<String>? body,
      Value<DateTime>? sentAt,
      Value<DateTime>? recordedAt,
      Value<String?>? conversationId,
      Value<bool>? hasAttachment,
      Value<bool>? synced,
      Value<String>? hash}) {
    return SmsDataTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      messageType: messageType ?? this.messageType,
      direction: direction ?? this.direction,
      sender: sender ?? this.sender,
      senderName: senderName ?? this.senderName,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      recordedAt: recordedAt ?? this.recordedAt,
      conversationId: conversationId ?? this.conversationId,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      synced: synced ?? this.synced,
      hash: hash ?? this.hash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (hasAttachment.present) {
      map['has_attachment'] = Variable<bool>(hasAttachment.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsDataTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('messageType: $messageType, ')
          ..write('direction: $direction, ')
          ..write('sender: $sender, ')
          ..write('senderName: $senderName, ')
          ..write('body: $body, ')
          ..write('sentAt: $sentAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('conversationId: $conversationId, ')
          ..write('hasAttachment: $hasAttachment, ')
          ..write('synced: $synced, ')
          ..write('hash: $hash')
          ..write(')'))
        .toString();
  }
}

class $CallDataTableTable extends CallDataTable
    with TableInfo<$CallDataTableTable, CallDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CallDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _callTypeMeta =
      const VerificationMeta('callType');
  @override
  late final GeneratedColumn<String> callType = GeneratedColumn<String>(
      'call_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _contactNameMeta =
      const VerificationMeta('contactName');
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
      'contact_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isVideoCallMeta =
      const VerificationMeta('isVideoCall');
  @override
  late final GeneratedColumn<bool> isVideoCall = GeneratedColumn<bool>(
      'is_video_call', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_video_call" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _simSlotMeta =
      const VerificationMeta('simSlot');
  @override
  late final GeneratedColumn<int> simSlot = GeneratedColumn<int>(
      'sim_slot', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isConferenceMeta =
      const VerificationMeta('isConference');
  @override
  late final GeneratedColumn<bool> isConference = GeneratedColumn<bool>(
      'is_conference', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_conference" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        callType,
        phoneNumber,
        contactName,
        startTime,
        endTime,
        duration,
        recordedAt,
        isVideoCall,
        synced,
        hash,
        simSlot,
        isConference
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'call_data_table';
  @override
  VerificationContext validateIntegrity(Insertable<CallDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('call_type')) {
      context.handle(_callTypeMeta,
          callType.isAcceptableOrUnknown(data['call_type']!, _callTypeMeta));
    } else if (isInserting) {
      context.missing(_callTypeMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('contact_name')) {
      context.handle(
          _contactNameMeta,
          contactName.isAcceptableOrUnknown(
              data['contact_name']!, _contactNameMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('is_video_call')) {
      context.handle(
          _isVideoCallMeta,
          isVideoCall.isAcceptableOrUnknown(
              data['is_video_call']!, _isVideoCallMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('sim_slot')) {
      context.handle(_simSlotMeta,
          simSlot.isAcceptableOrUnknown(data['sim_slot']!, _simSlotMeta));
    }
    if (data.containsKey('is_conference')) {
      context.handle(
          _isConferenceMeta,
          isConference.isAcceptableOrUnknown(
              data['is_conference']!, _isConferenceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CallDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CallDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      callType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}call_type'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      contactName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_name']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      isVideoCall: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_video_call'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash'])!,
      simSlot: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sim_slot']),
      isConference: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_conference'])!,
    );
  }

  @override
  $CallDataTableTable createAlias(String alias) {
    return $CallDataTableTable(attachedDatabase, alias);
  }
}

class CallDataTableData extends DataClass
    implements Insertable<CallDataTableData> {
  final int id;
  final String deviceId;
  final String callType;
  final String phoneNumber;
  final String? contactName;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration;
  final DateTime recordedAt;
  final bool isVideoCall;
  final bool synced;
  final String hash;
  final int? simSlot;
  final bool isConference;
  const CallDataTableData(
      {required this.id,
      required this.deviceId,
      required this.callType,
      required this.phoneNumber,
      this.contactName,
      required this.startTime,
      this.endTime,
      required this.duration,
      required this.recordedAt,
      required this.isVideoCall,
      required this.synced,
      required this.hash,
      this.simSlot,
      required this.isConference});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['call_type'] = Variable<String>(callType);
    map['phone_number'] = Variable<String>(phoneNumber);
    if (!nullToAbsent || contactName != null) {
      map['contact_name'] = Variable<String>(contactName);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration'] = Variable<int>(duration);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['is_video_call'] = Variable<bool>(isVideoCall);
    map['synced'] = Variable<bool>(synced);
    map['hash'] = Variable<String>(hash);
    if (!nullToAbsent || simSlot != null) {
      map['sim_slot'] = Variable<int>(simSlot);
    }
    map['is_conference'] = Variable<bool>(isConference);
    return map;
  }

  CallDataTableCompanion toCompanion(bool nullToAbsent) {
    return CallDataTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      callType: Value(callType),
      phoneNumber: Value(phoneNumber),
      contactName: contactName == null && nullToAbsent
          ? const Value.absent()
          : Value(contactName),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      duration: Value(duration),
      recordedAt: Value(recordedAt),
      isVideoCall: Value(isVideoCall),
      synced: Value(synced),
      hash: Value(hash),
      simSlot: simSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(simSlot),
      isConference: Value(isConference),
    );
  }

  factory CallDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CallDataTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      callType: serializer.fromJson<String>(json['callType']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      contactName: serializer.fromJson<String?>(json['contactName']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      duration: serializer.fromJson<int>(json['duration']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      isVideoCall: serializer.fromJson<bool>(json['isVideoCall']),
      synced: serializer.fromJson<bool>(json['synced']),
      hash: serializer.fromJson<String>(json['hash']),
      simSlot: serializer.fromJson<int?>(json['simSlot']),
      isConference: serializer.fromJson<bool>(json['isConference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'callType': serializer.toJson<String>(callType),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'contactName': serializer.toJson<String?>(contactName),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'duration': serializer.toJson<int>(duration),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'isVideoCall': serializer.toJson<bool>(isVideoCall),
      'synced': serializer.toJson<bool>(synced),
      'hash': serializer.toJson<String>(hash),
      'simSlot': serializer.toJson<int?>(simSlot),
      'isConference': serializer.toJson<bool>(isConference),
    };
  }

  CallDataTableData copyWith(
          {int? id,
          String? deviceId,
          String? callType,
          String? phoneNumber,
          Value<String?> contactName = const Value.absent(),
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          int? duration,
          DateTime? recordedAt,
          bool? isVideoCall,
          bool? synced,
          String? hash,
          Value<int?> simSlot = const Value.absent(),
          bool? isConference}) =>
      CallDataTableData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        callType: callType ?? this.callType,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        contactName: contactName.present ? contactName.value : this.contactName,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        duration: duration ?? this.duration,
        recordedAt: recordedAt ?? this.recordedAt,
        isVideoCall: isVideoCall ?? this.isVideoCall,
        synced: synced ?? this.synced,
        hash: hash ?? this.hash,
        simSlot: simSlot.present ? simSlot.value : this.simSlot,
        isConference: isConference ?? this.isConference,
      );
  CallDataTableData copyWithCompanion(CallDataTableCompanion data) {
    return CallDataTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      callType: data.callType.present ? data.callType.value : this.callType,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      contactName:
          data.contactName.present ? data.contactName.value : this.contactName,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      duration: data.duration.present ? data.duration.value : this.duration,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      isVideoCall:
          data.isVideoCall.present ? data.isVideoCall.value : this.isVideoCall,
      synced: data.synced.present ? data.synced.value : this.synced,
      hash: data.hash.present ? data.hash.value : this.hash,
      simSlot: data.simSlot.present ? data.simSlot.value : this.simSlot,
      isConference: data.isConference.present
          ? data.isConference.value
          : this.isConference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CallDataTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('callType: $callType, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('contactName: $contactName, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('duration: $duration, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('isVideoCall: $isVideoCall, ')
          ..write('synced: $synced, ')
          ..write('hash: $hash, ')
          ..write('simSlot: $simSlot, ')
          ..write('isConference: $isConference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      callType,
      phoneNumber,
      contactName,
      startTime,
      endTime,
      duration,
      recordedAt,
      isVideoCall,
      synced,
      hash,
      simSlot,
      isConference);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CallDataTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.callType == this.callType &&
          other.phoneNumber == this.phoneNumber &&
          other.contactName == this.contactName &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.duration == this.duration &&
          other.recordedAt == this.recordedAt &&
          other.isVideoCall == this.isVideoCall &&
          other.synced == this.synced &&
          other.hash == this.hash &&
          other.simSlot == this.simSlot &&
          other.isConference == this.isConference);
}

class CallDataTableCompanion extends UpdateCompanion<CallDataTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> callType;
  final Value<String> phoneNumber;
  final Value<String?> contactName;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> duration;
  final Value<DateTime> recordedAt;
  final Value<bool> isVideoCall;
  final Value<bool> synced;
  final Value<String> hash;
  final Value<int?> simSlot;
  final Value<bool> isConference;
  const CallDataTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.callType = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.contactName = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.duration = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.isVideoCall = const Value.absent(),
    this.synced = const Value.absent(),
    this.hash = const Value.absent(),
    this.simSlot = const Value.absent(),
    this.isConference = const Value.absent(),
  });
  CallDataTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String callType,
    required String phoneNumber,
    this.contactName = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.duration = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.isVideoCall = const Value.absent(),
    this.synced = const Value.absent(),
    required String hash,
    this.simSlot = const Value.absent(),
    this.isConference = const Value.absent(),
  })  : deviceId = Value(deviceId),
        callType = Value(callType),
        phoneNumber = Value(phoneNumber),
        startTime = Value(startTime),
        hash = Value(hash);
  static Insertable<CallDataTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? callType,
    Expression<String>? phoneNumber,
    Expression<String>? contactName,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? duration,
    Expression<DateTime>? recordedAt,
    Expression<bool>? isVideoCall,
    Expression<bool>? synced,
    Expression<String>? hash,
    Expression<int>? simSlot,
    Expression<bool>? isConference,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (callType != null) 'call_type': callType,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (contactName != null) 'contact_name': contactName,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (duration != null) 'duration': duration,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (isVideoCall != null) 'is_video_call': isVideoCall,
      if (synced != null) 'synced': synced,
      if (hash != null) 'hash': hash,
      if (simSlot != null) 'sim_slot': simSlot,
      if (isConference != null) 'is_conference': isConference,
    });
  }

  CallDataTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<String>? callType,
      Value<String>? phoneNumber,
      Value<String?>? contactName,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int>? duration,
      Value<DateTime>? recordedAt,
      Value<bool>? isVideoCall,
      Value<bool>? synced,
      Value<String>? hash,
      Value<int?>? simSlot,
      Value<bool>? isConference}) {
    return CallDataTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      callType: callType ?? this.callType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      recordedAt: recordedAt ?? this.recordedAt,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      synced: synced ?? this.synced,
      hash: hash ?? this.hash,
      simSlot: simSlot ?? this.simSlot,
      isConference: isConference ?? this.isConference,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (callType.present) {
      map['call_type'] = Variable<String>(callType.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (isVideoCall.present) {
      map['is_video_call'] = Variable<bool>(isVideoCall.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (simSlot.present) {
      map['sim_slot'] = Variable<int>(simSlot.value);
    }
    if (isConference.present) {
      map['is_conference'] = Variable<bool>(isConference.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CallDataTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('callType: $callType, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('contactName: $contactName, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('duration: $duration, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('isVideoCall: $isVideoCall, ')
          ..write('synced: $synced, ')
          ..write('hash: $hash, ')
          ..write('simSlot: $simSlot, ')
          ..write('isConference: $isConference')
          ..write(')'))
        .toString();
  }
}

class $LocationDataTableTable extends LocationDataTable
    with TableInfo<$LocationDataTableTable, LocationDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _altitudeMeta =
      const VerificationMeta('altitude');
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
      'altitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bearingMeta =
      const VerificationMeta('bearing');
  @override
  late final GeneratedColumn<double> bearing = GeneratedColumn<double>(
      'bearing', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _activityTypeMeta =
      const VerificationMeta('activityType');
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
      'activity_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _batteryLevelMeta =
      const VerificationMeta('batteryLevel');
  @override
  late final GeneratedColumn<int> batteryLevel = GeneratedColumn<int>(
      'battery_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        bearing,
        recordedAt,
        provider,
        activityType,
        synced,
        batteryLevel
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_data_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocationDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(_altitudeMeta,
          altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('bearing')) {
      context.handle(_bearingMeta,
          bearing.isAcceptableOrUnknown(data['bearing']!, _bearingMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('activity_type')) {
      context.handle(
          _activityTypeMeta,
          activityType.isAcceptableOrUnknown(
              data['activity_type']!, _activityTypeMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('battery_level')) {
      context.handle(
          _batteryLevelMeta,
          batteryLevel.isAcceptableOrUnknown(
              data['battery_level']!, _batteryLevelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy'])!,
      altitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}altitude']),
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed']),
      bearing: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bearing']),
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      activityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_type']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      batteryLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}battery_level']),
    );
  }

  @override
  $LocationDataTableTable createAlias(String alias) {
    return $LocationDataTableTable(attachedDatabase, alias);
  }
}

class LocationDataTableData extends DataClass
    implements Insertable<LocationDataTableData> {
  final int id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? speed;
  final double? bearing;
  final DateTime recordedAt;
  final String provider;
  final String? activityType;
  final bool synced;
  final int? batteryLevel;
  const LocationDataTableData(
      {required this.id,
      required this.deviceId,
      required this.latitude,
      required this.longitude,
      required this.accuracy,
      this.altitude,
      this.speed,
      this.bearing,
      required this.recordedAt,
      required this.provider,
      this.activityType,
      required this.synced,
      this.batteryLevel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['accuracy'] = Variable<double>(accuracy);
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || bearing != null) {
      map['bearing'] = Variable<double>(bearing);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || activityType != null) {
      map['activity_type'] = Variable<String>(activityType);
    }
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || batteryLevel != null) {
      map['battery_level'] = Variable<int>(batteryLevel);
    }
    return map;
  }

  LocationDataTableCompanion toCompanion(bool nullToAbsent) {
    return LocationDataTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: Value(accuracy),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      speed:
          speed == null && nullToAbsent ? const Value.absent() : Value(speed),
      bearing: bearing == null && nullToAbsent
          ? const Value.absent()
          : Value(bearing),
      recordedAt: Value(recordedAt),
      provider: Value(provider),
      activityType: activityType == null && nullToAbsent
          ? const Value.absent()
          : Value(activityType),
      synced: Value(synced),
      batteryLevel: batteryLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryLevel),
    );
  }

  factory LocationDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationDataTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      speed: serializer.fromJson<double?>(json['speed']),
      bearing: serializer.fromJson<double?>(json['bearing']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      provider: serializer.fromJson<String>(json['provider']),
      activityType: serializer.fromJson<String?>(json['activityType']),
      synced: serializer.fromJson<bool>(json['synced']),
      batteryLevel: serializer.fromJson<int?>(json['batteryLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double>(accuracy),
      'altitude': serializer.toJson<double?>(altitude),
      'speed': serializer.toJson<double?>(speed),
      'bearing': serializer.toJson<double?>(bearing),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'provider': serializer.toJson<String>(provider),
      'activityType': serializer.toJson<String?>(activityType),
      'synced': serializer.toJson<bool>(synced),
      'batteryLevel': serializer.toJson<int?>(batteryLevel),
    };
  }

  LocationDataTableData copyWith(
          {int? id,
          String? deviceId,
          double? latitude,
          double? longitude,
          double? accuracy,
          Value<double?> altitude = const Value.absent(),
          Value<double?> speed = const Value.absent(),
          Value<double?> bearing = const Value.absent(),
          DateTime? recordedAt,
          String? provider,
          Value<String?> activityType = const Value.absent(),
          bool? synced,
          Value<int?> batteryLevel = const Value.absent()}) =>
      LocationDataTableData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracy: accuracy ?? this.accuracy,
        altitude: altitude.present ? altitude.value : this.altitude,
        speed: speed.present ? speed.value : this.speed,
        bearing: bearing.present ? bearing.value : this.bearing,
        recordedAt: recordedAt ?? this.recordedAt,
        provider: provider ?? this.provider,
        activityType:
            activityType.present ? activityType.value : this.activityType,
        synced: synced ?? this.synced,
        batteryLevel:
            batteryLevel.present ? batteryLevel.value : this.batteryLevel,
      );
  LocationDataTableData copyWithCompanion(LocationDataTableCompanion data) {
    return LocationDataTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      speed: data.speed.present ? data.speed.value : this.speed,
      bearing: data.bearing.present ? data.bearing.value : this.bearing,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      provider: data.provider.present ? data.provider.value : this.provider,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      synced: data.synced.present ? data.synced.value : this.synced,
      batteryLevel: data.batteryLevel.present
          ? data.batteryLevel.value
          : this.batteryLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationDataTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('bearing: $bearing, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('provider: $provider, ')
          ..write('activityType: $activityType, ')
          ..write('synced: $synced, ')
          ..write('batteryLevel: $batteryLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      latitude,
      longitude,
      accuracy,
      altitude,
      speed,
      bearing,
      recordedAt,
      provider,
      activityType,
      synced,
      batteryLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationDataTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.altitude == this.altitude &&
          other.speed == this.speed &&
          other.bearing == this.bearing &&
          other.recordedAt == this.recordedAt &&
          other.provider == this.provider &&
          other.activityType == this.activityType &&
          other.synced == this.synced &&
          other.batteryLevel == this.batteryLevel);
}

class LocationDataTableCompanion
    extends UpdateCompanion<LocationDataTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracy;
  final Value<double?> altitude;
  final Value<double?> speed;
  final Value<double?> bearing;
  final Value<DateTime> recordedAt;
  final Value<String> provider;
  final Value<String?> activityType;
  final Value<bool> synced;
  final Value<int?> batteryLevel;
  const LocationDataTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.bearing = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.provider = const Value.absent(),
    this.activityType = const Value.absent(),
    this.synced = const Value.absent(),
    this.batteryLevel = const Value.absent(),
  });
  LocationDataTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required double latitude,
    required double longitude,
    required double accuracy,
    this.altitude = const Value.absent(),
    this.speed = const Value.absent(),
    this.bearing = const Value.absent(),
    this.recordedAt = const Value.absent(),
    required String provider,
    this.activityType = const Value.absent(),
    this.synced = const Value.absent(),
    this.batteryLevel = const Value.absent(),
  })  : deviceId = Value(deviceId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        accuracy = Value(accuracy),
        provider = Value(provider);
  static Insertable<LocationDataTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<double>? altitude,
    Expression<double>? speed,
    Expression<double>? bearing,
    Expression<DateTime>? recordedAt,
    Expression<String>? provider,
    Expression<String>? activityType,
    Expression<bool>? synced,
    Expression<int>? batteryLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      if (bearing != null) 'bearing': bearing,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (provider != null) 'provider': provider,
      if (activityType != null) 'activity_type': activityType,
      if (synced != null) 'synced': synced,
      if (batteryLevel != null) 'battery_level': batteryLevel,
    });
  }

  LocationDataTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double>? accuracy,
      Value<double?>? altitude,
      Value<double?>? speed,
      Value<double?>? bearing,
      Value<DateTime>? recordedAt,
      Value<String>? provider,
      Value<String?>? activityType,
      Value<bool>? synced,
      Value<int?>? batteryLevel}) {
    return LocationDataTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      recordedAt: recordedAt ?? this.recordedAt,
      provider: provider ?? this.provider,
      activityType: activityType ?? this.activityType,
      synced: synced ?? this.synced,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (bearing.present) {
      map['bearing'] = Variable<double>(bearing.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (batteryLevel.present) {
      map['battery_level'] = Variable<int>(batteryLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationDataTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('speed: $speed, ')
          ..write('bearing: $bearing, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('provider: $provider, ')
          ..write('activityType: $activityType, ')
          ..write('synced: $synced, ')
          ..write('batteryLevel: $batteryLevel')
          ..write(')'))
        .toString();
  }
}

class $AppUsageDataTableTable extends AppUsageDataTable
    with TableInfo<$AppUsageDataTableTable, AppUsageDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsageDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _appNameMeta =
      const VerificationMeta('appName');
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
      'app_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _launchCountMeta =
      const VerificationMeta('launchCount');
  @override
  late final GeneratedColumn<int> launchCount = GeneratedColumn<int>(
      'launch_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 10, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        packageName,
        appName,
        category,
        startTime,
        endTime,
        durationSeconds,
        launchCount,
        recordedAt,
        synced,
        date
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_usage_data_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AppUsageDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(_appNameMeta,
          appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta));
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('launch_count')) {
      context.handle(
          _launchCountMeta,
          launchCount.isAcceptableOrUnknown(
              data['launch_count']!, _launchCountMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppUsageDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUsageDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name'])!,
      appName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      launchCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}launch_count'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $AppUsageDataTableTable createAlias(String alias) {
    return $AppUsageDataTableTable(attachedDatabase, alias);
  }
}

class AppUsageDataTableData extends DataClass
    implements Insertable<AppUsageDataTableData> {
  final int id;
  final String deviceId;
  final String packageName;
  final String appName;
  final String? category;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int launchCount;
  final DateTime recordedAt;
  final bool synced;
  final String date;
  const AppUsageDataTableData(
      {required this.id,
      required this.deviceId,
      required this.packageName,
      required this.appName,
      this.category,
      required this.startTime,
      this.endTime,
      required this.durationSeconds,
      required this.launchCount,
      required this.recordedAt,
      required this.synced,
      required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['launch_count'] = Variable<int>(launchCount);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced'] = Variable<bool>(synced);
    map['date'] = Variable<String>(date);
    return map;
  }

  AppUsageDataTableCompanion toCompanion(bool nullToAbsent) {
    return AppUsageDataTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      packageName: Value(packageName),
      appName: Value(appName),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationSeconds: Value(durationSeconds),
      launchCount: Value(launchCount),
      recordedAt: Value(recordedAt),
      synced: Value(synced),
      date: Value(date),
    );
  }

  factory AppUsageDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUsageDataTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      category: serializer.fromJson<String?>(json['category']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      launchCount: serializer.fromJson<int>(json['launchCount']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'category': serializer.toJson<String?>(category),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'launchCount': serializer.toJson<int>(launchCount),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'synced': serializer.toJson<bool>(synced),
      'date': serializer.toJson<String>(date),
    };
  }

  AppUsageDataTableData copyWith(
          {int? id,
          String? deviceId,
          String? packageName,
          String? appName,
          Value<String?> category = const Value.absent(),
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          int? durationSeconds,
          int? launchCount,
          DateTime? recordedAt,
          bool? synced,
          String? date}) =>
      AppUsageDataTableData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        packageName: packageName ?? this.packageName,
        appName: appName ?? this.appName,
        category: category.present ? category.value : this.category,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        launchCount: launchCount ?? this.launchCount,
        recordedAt: recordedAt ?? this.recordedAt,
        synced: synced ?? this.synced,
        date: date ?? this.date,
      );
  AppUsageDataTableData copyWithCompanion(AppUsageDataTableCompanion data) {
    return AppUsageDataTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      category: data.category.present ? data.category.value : this.category,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      launchCount:
          data.launchCount.present ? data.launchCount.value : this.launchCount,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageDataTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('category: $category, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('launchCount: $launchCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      packageName,
      appName,
      category,
      startTime,
      endTime,
      durationSeconds,
      launchCount,
      recordedAt,
      synced,
      date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUsageDataTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.category == this.category &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.launchCount == this.launchCount &&
          other.recordedAt == this.recordedAt &&
          other.synced == this.synced &&
          other.date == this.date);
}

class AppUsageDataTableCompanion
    extends UpdateCompanion<AppUsageDataTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<String?> category;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int> durationSeconds;
  final Value<int> launchCount;
  final Value<DateTime> recordedAt;
  final Value<bool> synced;
  final Value<String> date;
  const AppUsageDataTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.category = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.launchCount = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.date = const Value.absent(),
  });
  AppUsageDataTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String packageName,
    required String appName,
    this.category = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.launchCount = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
    required String date,
  })  : deviceId = Value(deviceId),
        packageName = Value(packageName),
        appName = Value(appName),
        startTime = Value(startTime),
        date = Value(date);
  static Insertable<AppUsageDataTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<String>? category,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationSeconds,
    Expression<int>? launchCount,
    Expression<DateTime>? recordedAt,
    Expression<bool>? synced,
    Expression<String>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (category != null) 'category': category,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (launchCount != null) 'launch_count': launchCount,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (synced != null) 'synced': synced,
      if (date != null) 'date': date,
    });
  }

  AppUsageDataTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<String>? packageName,
      Value<String>? appName,
      Value<String?>? category,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<int>? durationSeconds,
      Value<int>? launchCount,
      Value<DateTime>? recordedAt,
      Value<bool>? synced,
      Value<String>? date}) {
    return AppUsageDataTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      launchCount: launchCount ?? this.launchCount,
      recordedAt: recordedAt ?? this.recordedAt,
      synced: synced ?? this.synced,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (launchCount.present) {
      map['launch_count'] = Variable<int>(launchCount.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageDataTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('category: $category, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('launchCount: $launchCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $AppDataTableTable extends AppDataTable
    with TableInfo<$AppDataTableTable, AppDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _appNameMeta =
      const VerificationMeta('appName');
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
      'app_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _versionNameMeta =
      const VerificationMeta('versionName');
  @override
  late final GeneratedColumn<String> versionName = GeneratedColumn<String>(
      'version_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionCodeMeta =
      const VerificationMeta('versionCode');
  @override
  late final GeneratedColumn<int> versionCode = GeneratedColumn<int>(
      'version_code', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _firstInstallTimeMeta =
      const VerificationMeta('firstInstallTime');
  @override
  late final GeneratedColumn<DateTime> firstInstallTime =
      GeneratedColumn<DateTime>('first_install_time', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastUpdateTimeMeta =
      const VerificationMeta('lastUpdateTime');
  @override
  late final GeneratedColumn<DateTime> lastUpdateTime =
      GeneratedColumn<DateTime>('last_update_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _appCategoryMeta =
      const VerificationMeta('appCategory');
  @override
  late final GeneratedColumn<String> appCategory = GeneratedColumn<String>(
      'app_category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSystemAppMeta =
      const VerificationMeta('isSystemApp');
  @override
  late final GeneratedColumn<bool> isSystemApp = GeneratedColumn<bool>(
      'is_system_app', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_system_app" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        packageName,
        appName,
        versionName,
        versionCode,
        firstInstallTime,
        lastUpdateTime,
        appCategory,
        isSystemApp,
        recordedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_data_table';
  @override
  VerificationContext validateIntegrity(Insertable<AppDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(_appNameMeta,
          appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta));
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('version_name')) {
      context.handle(
          _versionNameMeta,
          versionName.isAcceptableOrUnknown(
              data['version_name']!, _versionNameMeta));
    }
    if (data.containsKey('version_code')) {
      context.handle(
          _versionCodeMeta,
          versionCode.isAcceptableOrUnknown(
              data['version_code']!, _versionCodeMeta));
    }
    if (data.containsKey('first_install_time')) {
      context.handle(
          _firstInstallTimeMeta,
          firstInstallTime.isAcceptableOrUnknown(
              data['first_install_time']!, _firstInstallTimeMeta));
    } else if (isInserting) {
      context.missing(_firstInstallTimeMeta);
    }
    if (data.containsKey('last_update_time')) {
      context.handle(
          _lastUpdateTimeMeta,
          lastUpdateTime.isAcceptableOrUnknown(
              data['last_update_time']!, _lastUpdateTimeMeta));
    }
    if (data.containsKey('app_category')) {
      context.handle(
          _appCategoryMeta,
          appCategory.isAcceptableOrUnknown(
              data['app_category']!, _appCategoryMeta));
    }
    if (data.containsKey('is_system_app')) {
      context.handle(
          _isSystemAppMeta,
          isSystemApp.isAcceptableOrUnknown(
              data['is_system_app']!, _isSystemAppMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name'])!,
      appName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_name'])!,
      versionName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version_name']),
      versionCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version_code']),
      firstInstallTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}first_install_time'])!,
      lastUpdateTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_update_time']),
      appCategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_category']),
      isSystemApp: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system_app'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $AppDataTableTable createAlias(String alias) {
    return $AppDataTableTable(attachedDatabase, alias);
  }
}

class AppDataTableData extends DataClass
    implements Insertable<AppDataTableData> {
  final int id;
  final String deviceId;
  final String packageName;
  final String appName;
  final String? versionName;
  final int? versionCode;
  final DateTime firstInstallTime;
  final DateTime? lastUpdateTime;
  final String? appCategory;
  final bool isSystemApp;
  final DateTime recordedAt;
  final bool synced;
  const AppDataTableData(
      {required this.id,
      required this.deviceId,
      required this.packageName,
      required this.appName,
      this.versionName,
      this.versionCode,
      required this.firstInstallTime,
      this.lastUpdateTime,
      this.appCategory,
      required this.isSystemApp,
      required this.recordedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    if (!nullToAbsent || versionName != null) {
      map['version_name'] = Variable<String>(versionName);
    }
    if (!nullToAbsent || versionCode != null) {
      map['version_code'] = Variable<int>(versionCode);
    }
    map['first_install_time'] = Variable<DateTime>(firstInstallTime);
    if (!nullToAbsent || lastUpdateTime != null) {
      map['last_update_time'] = Variable<DateTime>(lastUpdateTime);
    }
    if (!nullToAbsent || appCategory != null) {
      map['app_category'] = Variable<String>(appCategory);
    }
    map['is_system_app'] = Variable<bool>(isSystemApp);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AppDataTableCompanion toCompanion(bool nullToAbsent) {
    return AppDataTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      packageName: Value(packageName),
      appName: Value(appName),
      versionName: versionName == null && nullToAbsent
          ? const Value.absent()
          : Value(versionName),
      versionCode: versionCode == null && nullToAbsent
          ? const Value.absent()
          : Value(versionCode),
      firstInstallTime: Value(firstInstallTime),
      lastUpdateTime: lastUpdateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdateTime),
      appCategory: appCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(appCategory),
      isSystemApp: Value(isSystemApp),
      recordedAt: Value(recordedAt),
      synced: Value(synced),
    );
  }

  factory AppDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppDataTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      versionName: serializer.fromJson<String?>(json['versionName']),
      versionCode: serializer.fromJson<int?>(json['versionCode']),
      firstInstallTime: serializer.fromJson<DateTime>(json['firstInstallTime']),
      lastUpdateTime: serializer.fromJson<DateTime?>(json['lastUpdateTime']),
      appCategory: serializer.fromJson<String?>(json['appCategory']),
      isSystemApp: serializer.fromJson<bool>(json['isSystemApp']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'versionName': serializer.toJson<String?>(versionName),
      'versionCode': serializer.toJson<int?>(versionCode),
      'firstInstallTime': serializer.toJson<DateTime>(firstInstallTime),
      'lastUpdateTime': serializer.toJson<DateTime?>(lastUpdateTime),
      'appCategory': serializer.toJson<String?>(appCategory),
      'isSystemApp': serializer.toJson<bool>(isSystemApp),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AppDataTableData copyWith(
          {int? id,
          String? deviceId,
          String? packageName,
          String? appName,
          Value<String?> versionName = const Value.absent(),
          Value<int?> versionCode = const Value.absent(),
          DateTime? firstInstallTime,
          Value<DateTime?> lastUpdateTime = const Value.absent(),
          Value<String?> appCategory = const Value.absent(),
          bool? isSystemApp,
          DateTime? recordedAt,
          bool? synced}) =>
      AppDataTableData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        packageName: packageName ?? this.packageName,
        appName: appName ?? this.appName,
        versionName: versionName.present ? versionName.value : this.versionName,
        versionCode: versionCode.present ? versionCode.value : this.versionCode,
        firstInstallTime: firstInstallTime ?? this.firstInstallTime,
        lastUpdateTime:
            lastUpdateTime.present ? lastUpdateTime.value : this.lastUpdateTime,
        appCategory: appCategory.present ? appCategory.value : this.appCategory,
        isSystemApp: isSystemApp ?? this.isSystemApp,
        recordedAt: recordedAt ?? this.recordedAt,
        synced: synced ?? this.synced,
      );
  AppDataTableData copyWithCompanion(AppDataTableCompanion data) {
    return AppDataTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      versionName:
          data.versionName.present ? data.versionName.value : this.versionName,
      versionCode:
          data.versionCode.present ? data.versionCode.value : this.versionCode,
      firstInstallTime: data.firstInstallTime.present
          ? data.firstInstallTime.value
          : this.firstInstallTime,
      lastUpdateTime: data.lastUpdateTime.present
          ? data.lastUpdateTime.value
          : this.lastUpdateTime,
      appCategory:
          data.appCategory.present ? data.appCategory.value : this.appCategory,
      isSystemApp:
          data.isSystemApp.present ? data.isSystemApp.value : this.isSystemApp,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppDataTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('versionName: $versionName, ')
          ..write('versionCode: $versionCode, ')
          ..write('firstInstallTime: $firstInstallTime, ')
          ..write('lastUpdateTime: $lastUpdateTime, ')
          ..write('appCategory: $appCategory, ')
          ..write('isSystemApp: $isSystemApp, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      packageName,
      appName,
      versionName,
      versionCode,
      firstInstallTime,
      lastUpdateTime,
      appCategory,
      isSystemApp,
      recordedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppDataTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.versionName == this.versionName &&
          other.versionCode == this.versionCode &&
          other.firstInstallTime == this.firstInstallTime &&
          other.lastUpdateTime == this.lastUpdateTime &&
          other.appCategory == this.appCategory &&
          other.isSystemApp == this.isSystemApp &&
          other.recordedAt == this.recordedAt &&
          other.synced == this.synced);
}

class AppDataTableCompanion extends UpdateCompanion<AppDataTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<String?> versionName;
  final Value<int?> versionCode;
  final Value<DateTime> firstInstallTime;
  final Value<DateTime?> lastUpdateTime;
  final Value<String?> appCategory;
  final Value<bool> isSystemApp;
  final Value<DateTime> recordedAt;
  final Value<bool> synced;
  const AppDataTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.versionName = const Value.absent(),
    this.versionCode = const Value.absent(),
    this.firstInstallTime = const Value.absent(),
    this.lastUpdateTime = const Value.absent(),
    this.appCategory = const Value.absent(),
    this.isSystemApp = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  AppDataTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String packageName,
    required String appName,
    this.versionName = const Value.absent(),
    this.versionCode = const Value.absent(),
    required DateTime firstInstallTime,
    this.lastUpdateTime = const Value.absent(),
    this.appCategory = const Value.absent(),
    this.isSystemApp = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
  })  : deviceId = Value(deviceId),
        packageName = Value(packageName),
        appName = Value(appName),
        firstInstallTime = Value(firstInstallTime);
  static Insertable<AppDataTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<String>? versionName,
    Expression<int>? versionCode,
    Expression<DateTime>? firstInstallTime,
    Expression<DateTime>? lastUpdateTime,
    Expression<String>? appCategory,
    Expression<bool>? isSystemApp,
    Expression<DateTime>? recordedAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (versionName != null) 'version_name': versionName,
      if (versionCode != null) 'version_code': versionCode,
      if (firstInstallTime != null) 'first_install_time': firstInstallTime,
      if (lastUpdateTime != null) 'last_update_time': lastUpdateTime,
      if (appCategory != null) 'app_category': appCategory,
      if (isSystemApp != null) 'is_system_app': isSystemApp,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (synced != null) 'synced': synced,
    });
  }

  AppDataTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<String>? packageName,
      Value<String>? appName,
      Value<String?>? versionName,
      Value<int?>? versionCode,
      Value<DateTime>? firstInstallTime,
      Value<DateTime?>? lastUpdateTime,
      Value<String?>? appCategory,
      Value<bool>? isSystemApp,
      Value<DateTime>? recordedAt,
      Value<bool>? synced}) {
    return AppDataTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      firstInstallTime: firstInstallTime ?? this.firstInstallTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      appCategory: appCategory ?? this.appCategory,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      recordedAt: recordedAt ?? this.recordedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (versionName.present) {
      map['version_name'] = Variable<String>(versionName.value);
    }
    if (versionCode.present) {
      map['version_code'] = Variable<int>(versionCode.value);
    }
    if (firstInstallTime.present) {
      map['first_install_time'] = Variable<DateTime>(firstInstallTime.value);
    }
    if (lastUpdateTime.present) {
      map['last_update_time'] = Variable<DateTime>(lastUpdateTime.value);
    }
    if (appCategory.present) {
      map['app_category'] = Variable<String>(appCategory.value);
    }
    if (isSystemApp.present) {
      map['is_system_app'] = Variable<bool>(isSystemApp.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppDataTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('versionName: $versionName, ')
          ..write('versionCode: $versionCode, ')
          ..write('firstInstallTime: $firstInstallTime, ')
          ..write('lastUpdateTime: $lastUpdateTime, ')
          ..write('appCategory: $appCategory, ')
          ..write('isSystemApp: $isSystemApp, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $MediaDataTableTable extends MediaDataTable
    with TableInfo<$MediaDataTableTable, MediaDataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _captureMethodMeta =
      const VerificationMeta('captureMethod');
  @override
  late final GeneratedColumn<String> captureMethod = GeneratedColumn<String>(
      'capture_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cameraTypeMeta =
      const VerificationMeta('cameraType');
  @override
  late final GeneratedColumn<String> cameraType = GeneratedColumn<String>(
      'camera_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailMeta =
      const VerificationMeta('thumbnail');
  @override
  late final GeneratedColumn<Uint8List> thumbnail = GeneratedColumn<Uint8List>(
      'thumbnail', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceId,
        mediaId,
        mediaType,
        fileName,
        filePath,
        mimeType,
        fileSize,
        width,
        height,
        createdAt,
        modifiedAt,
        recordedAt,
        synced,
        captureMethod,
        cameraType,
        duration,
        thumbnail
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_data_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaDataTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    if (data.containsKey('capture_method')) {
      context.handle(
          _captureMethodMeta,
          captureMethod.isAcceptableOrUnknown(
              data['capture_method']!, _captureMethodMeta));
    }
    if (data.containsKey('camera_type')) {
      context.handle(
          _cameraTypeMeta,
          cameraType.isAcceptableOrUnknown(
              data['camera_type']!, _cameraTypeMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('thumbnail')) {
      context.handle(_thumbnailMeta,
          thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaDataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaDataTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      captureMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}capture_method']),
      cameraType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}camera_type']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      thumbnail: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}thumbnail']),
    );
  }

  @override
  $MediaDataTableTable createAlias(String alias) {
    return $MediaDataTableTable(attachedDatabase, alias);
  }
}

class MediaDataTableData extends DataClass
    implements Insertable<MediaDataTableData> {
  final int id;
  final String deviceId;
  final String mediaId;
  final String mediaType;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final int? width;
  final int? height;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime recordedAt;
  final bool synced;
  final String? captureMethod;
  final String? cameraType;
  final int? duration;
  final Uint8List? thumbnail;
  const MediaDataTableData(
      {required this.id,
      required this.deviceId,
      required this.mediaId,
      required this.mediaType,
      required this.fileName,
      required this.filePath,
      required this.mimeType,
      required this.fileSize,
      this.width,
      this.height,
      required this.createdAt,
      required this.modifiedAt,
      required this.recordedAt,
      required this.synced,
      this.captureMethod,
      this.cameraType,
      this.duration,
      this.thumbnail});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['media_id'] = Variable<String>(mediaId);
    map['media_type'] = Variable<String>(mediaType);
    map['file_name'] = Variable<String>(fileName);
    map['file_path'] = Variable<String>(filePath);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || captureMethod != null) {
      map['capture_method'] = Variable<String>(captureMethod);
    }
    if (!nullToAbsent || cameraType != null) {
      map['camera_type'] = Variable<String>(cameraType);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail);
    }
    return map;
  }

  MediaDataTableCompanion toCompanion(bool nullToAbsent) {
    return MediaDataTableCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      fileName: Value(fileName),
      filePath: Value(filePath),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      recordedAt: Value(recordedAt),
      synced: Value(synced),
      captureMethod: captureMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(captureMethod),
      cameraType: cameraType == null && nullToAbsent
          ? const Value.absent()
          : Value(cameraType),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
    );
  }

  factory MediaDataTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaDataTableData(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      captureMethod: serializer.fromJson<String?>(json['captureMethod']),
      cameraType: serializer.fromJson<String?>(json['cameraType']),
      duration: serializer.fromJson<int?>(json['duration']),
      thumbnail: serializer.fromJson<Uint8List?>(json['thumbnail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'mediaId': serializer.toJson<String>(mediaId),
      'mediaType': serializer.toJson<String>(mediaType),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String>(filePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'synced': serializer.toJson<bool>(synced),
      'captureMethod': serializer.toJson<String?>(captureMethod),
      'cameraType': serializer.toJson<String?>(cameraType),
      'duration': serializer.toJson<int?>(duration),
      'thumbnail': serializer.toJson<Uint8List?>(thumbnail),
    };
  }

  MediaDataTableData copyWith(
          {int? id,
          String? deviceId,
          String? mediaId,
          String? mediaType,
          String? fileName,
          String? filePath,
          String? mimeType,
          int? fileSize,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          DateTime? createdAt,
          DateTime? modifiedAt,
          DateTime? recordedAt,
          bool? synced,
          Value<String?> captureMethod = const Value.absent(),
          Value<String?> cameraType = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<Uint8List?> thumbnail = const Value.absent()}) =>
      MediaDataTableData(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        mediaId: mediaId ?? this.mediaId,
        mediaType: mediaType ?? this.mediaType,
        fileName: fileName ?? this.fileName,
        filePath: filePath ?? this.filePath,
        mimeType: mimeType ?? this.mimeType,
        fileSize: fileSize ?? this.fileSize,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        createdAt: createdAt ?? this.createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        recordedAt: recordedAt ?? this.recordedAt,
        synced: synced ?? this.synced,
        captureMethod:
            captureMethod.present ? captureMethod.value : this.captureMethod,
        cameraType: cameraType.present ? cameraType.value : this.cameraType,
        duration: duration.present ? duration.value : this.duration,
        thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
      );
  MediaDataTableData copyWithCompanion(MediaDataTableCompanion data) {
    return MediaDataTableData(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      captureMethod: data.captureMethod.present
          ? data.captureMethod.value
          : this.captureMethod,
      cameraType:
          data.cameraType.present ? data.cameraType.value : this.cameraType,
      duration: data.duration.present ? data.duration.value : this.duration,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaDataTableData(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced, ')
          ..write('captureMethod: $captureMethod, ')
          ..write('cameraType: $cameraType, ')
          ..write('duration: $duration, ')
          ..write('thumbnail: $thumbnail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceId,
      mediaId,
      mediaType,
      fileName,
      filePath,
      mimeType,
      fileSize,
      width,
      height,
      createdAt,
      modifiedAt,
      recordedAt,
      synced,
      captureMethod,
      cameraType,
      duration,
      $driftBlobEquality.hash(thumbnail));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaDataTableData &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.recordedAt == this.recordedAt &&
          other.synced == this.synced &&
          other.captureMethod == this.captureMethod &&
          other.cameraType == this.cameraType &&
          other.duration == this.duration &&
          $driftBlobEquality.equals(other.thumbnail, this.thumbnail));
}

class MediaDataTableCompanion extends UpdateCompanion<MediaDataTableData> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<String> mediaId;
  final Value<String> mediaType;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<int?> width;
  final Value<int?> height;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<DateTime> recordedAt;
  final Value<bool> synced;
  final Value<String?> captureMethod;
  final Value<String?> cameraType;
  final Value<int?> duration;
  final Value<Uint8List?> thumbnail;
  const MediaDataTableCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.captureMethod = const Value.absent(),
    this.cameraType = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumbnail = const Value.absent(),
  });
  MediaDataTableCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required String mediaId,
    required String mediaType,
    required String fileName,
    required String filePath,
    required String mimeType,
    required int fileSize,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.recordedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.captureMethod = const Value.absent(),
    this.cameraType = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumbnail = const Value.absent(),
  })  : deviceId = Value(deviceId),
        mediaId = Value(mediaId),
        mediaType = Value(mediaType),
        fileName = Value(fileName),
        filePath = Value(filePath),
        mimeType = Value(mimeType),
        fileSize = Value(fileSize),
        createdAt = Value(createdAt),
        modifiedAt = Value(modifiedAt);
  static Insertable<MediaDataTableData> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<String>? mediaId,
    Expression<String>? mediaType,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? recordedAt,
    Expression<bool>? synced,
    Expression<String>? captureMethod,
    Expression<String>? cameraType,
    Expression<int>? duration,
    Expression<Uint8List>? thumbnail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (synced != null) 'synced': synced,
      if (captureMethod != null) 'capture_method': captureMethod,
      if (cameraType != null) 'camera_type': cameraType,
      if (duration != null) 'duration': duration,
      if (thumbnail != null) 'thumbnail': thumbnail,
    });
  }

  MediaDataTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<String>? mediaId,
      Value<String>? mediaType,
      Value<String>? fileName,
      Value<String>? filePath,
      Value<String>? mimeType,
      Value<int>? fileSize,
      Value<int?>? width,
      Value<int?>? height,
      Value<DateTime>? createdAt,
      Value<DateTime>? modifiedAt,
      Value<DateTime>? recordedAt,
      Value<bool>? synced,
      Value<String?>? captureMethod,
      Value<String?>? cameraType,
      Value<int?>? duration,
      Value<Uint8List?>? thumbnail}) {
    return MediaDataTableCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      recordedAt: recordedAt ?? this.recordedAt,
      synced: synced ?? this.synced,
      captureMethod: captureMethod ?? this.captureMethod,
      cameraType: cameraType ?? this.cameraType,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (captureMethod.present) {
      map['capture_method'] = Variable<String>(captureMethod.value);
    }
    if (cameraType.present) {
      map['camera_type'] = Variable<String>(cameraType.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaDataTableCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('synced: $synced, ')
          ..write('captureMethod: $captureMethod, ')
          ..write('cameraType: $cameraType, ')
          ..write('duration: $duration, ')
          ..write('thumbnail: $thumbnail')
          ..write(')'))
        .toString();
  }
}

class $ConfigurationTableTable extends ConfigurationTable
    with TableInfo<$ConfigurationTableTable, ConfigurationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigurationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configuration_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConfigurationTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ConfigurationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigurationTableData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ConfigurationTableTable createAlias(String alias) {
    return $ConfigurationTableTable(attachedDatabase, alias);
  }
}

class ConfigurationTableData extends DataClass
    implements Insertable<ConfigurationTableData> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const ConfigurationTableData(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConfigurationTableCompanion toCompanion(bool nullToAbsent) {
    return ConfigurationTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConfigurationTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigurationTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConfigurationTableData copyWith(
          {String? key, String? value, DateTime? updatedAt}) =>
      ConfigurationTableData(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ConfigurationTableData copyWithCompanion(ConfigurationTableCompanion data) {
    return ConfigurationTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationTableData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigurationTableData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class ConfigurationTableCompanion
    extends UpdateCompanion<ConfigurationTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConfigurationTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigurationTableCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<ConfigurationTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigurationTableCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ConfigurationTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecurityAuditTableTable extends SecurityAuditTable
    with TableInfo<$SecurityAuditTableTable, SecurityAuditTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecurityAuditTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        eventType,
        description,
        severity,
        timestamp,
        deviceId,
        metadata,
        hash
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'security_audit_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<SecurityAuditTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecurityAuditTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecurityAuditTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash'])!,
    );
  }

  @override
  $SecurityAuditTableTable createAlias(String alias) {
    return $SecurityAuditTableTable(attachedDatabase, alias);
  }
}

class SecurityAuditTableData extends DataClass
    implements Insertable<SecurityAuditTableData> {
  final int id;
  final String eventType;
  final String description;
  final String severity;
  final DateTime timestamp;
  final String deviceId;
  final String? metadata;
  final String hash;
  const SecurityAuditTableData(
      {required this.id,
      required this.eventType,
      required this.description,
      required this.severity,
      required this.timestamp,
      required this.deviceId,
      this.metadata,
      required this.hash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_type'] = Variable<String>(eventType);
    map['description'] = Variable<String>(description);
    map['severity'] = Variable<String>(severity);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['hash'] = Variable<String>(hash);
    return map;
  }

  SecurityAuditTableCompanion toCompanion(bool nullToAbsent) {
    return SecurityAuditTableCompanion(
      id: Value(id),
      eventType: Value(eventType),
      description: Value(description),
      severity: Value(severity),
      timestamp: Value(timestamp),
      deviceId: Value(deviceId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      hash: Value(hash),
    );
  }

  factory SecurityAuditTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecurityAuditTableData(
      id: serializer.fromJson<int>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      description: serializer.fromJson<String>(json['description']),
      severity: serializer.fromJson<String>(json['severity']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      hash: serializer.fromJson<String>(json['hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventType': serializer.toJson<String>(eventType),
      'description': serializer.toJson<String>(description),
      'severity': serializer.toJson<String>(severity),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'deviceId': serializer.toJson<String>(deviceId),
      'metadata': serializer.toJson<String?>(metadata),
      'hash': serializer.toJson<String>(hash),
    };
  }

  SecurityAuditTableData copyWith(
          {int? id,
          String? eventType,
          String? description,
          String? severity,
          DateTime? timestamp,
          String? deviceId,
          Value<String?> metadata = const Value.absent(),
          String? hash}) =>
      SecurityAuditTableData(
        id: id ?? this.id,
        eventType: eventType ?? this.eventType,
        description: description ?? this.description,
        severity: severity ?? this.severity,
        timestamp: timestamp ?? this.timestamp,
        deviceId: deviceId ?? this.deviceId,
        metadata: metadata.present ? metadata.value : this.metadata,
        hash: hash ?? this.hash,
      );
  SecurityAuditTableData copyWithCompanion(SecurityAuditTableCompanion data) {
    return SecurityAuditTableData(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      description:
          data.description.present ? data.description.value : this.description,
      severity: data.severity.present ? data.severity.value : this.severity,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      hash: data.hash.present ? data.hash.value : this.hash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecurityAuditTableData(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('description: $description, ')
          ..write('severity: $severity, ')
          ..write('timestamp: $timestamp, ')
          ..write('deviceId: $deviceId, ')
          ..write('metadata: $metadata, ')
          ..write('hash: $hash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eventType, description, severity,
      timestamp, deviceId, metadata, hash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecurityAuditTableData &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.description == this.description &&
          other.severity == this.severity &&
          other.timestamp == this.timestamp &&
          other.deviceId == this.deviceId &&
          other.metadata == this.metadata &&
          other.hash == this.hash);
}

class SecurityAuditTableCompanion
    extends UpdateCompanion<SecurityAuditTableData> {
  final Value<int> id;
  final Value<String> eventType;
  final Value<String> description;
  final Value<String> severity;
  final Value<DateTime> timestamp;
  final Value<String> deviceId;
  final Value<String?> metadata;
  final Value<String> hash;
  const SecurityAuditTableCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.description = const Value.absent(),
    this.severity = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.hash = const Value.absent(),
  });
  SecurityAuditTableCompanion.insert({
    this.id = const Value.absent(),
    required String eventType,
    required String description,
    required String severity,
    this.timestamp = const Value.absent(),
    required String deviceId,
    this.metadata = const Value.absent(),
    required String hash,
  })  : eventType = Value(eventType),
        description = Value(description),
        severity = Value(severity),
        deviceId = Value(deviceId),
        hash = Value(hash);
  static Insertable<SecurityAuditTableData> custom({
    Expression<int>? id,
    Expression<String>? eventType,
    Expression<String>? description,
    Expression<String>? severity,
    Expression<DateTime>? timestamp,
    Expression<String>? deviceId,
    Expression<String>? metadata,
    Expression<String>? hash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (description != null) 'description': description,
      if (severity != null) 'severity': severity,
      if (timestamp != null) 'timestamp': timestamp,
      if (deviceId != null) 'device_id': deviceId,
      if (metadata != null) 'metadata': metadata,
      if (hash != null) 'hash': hash,
    });
  }

  SecurityAuditTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? eventType,
      Value<String>? description,
      Value<String>? severity,
      Value<DateTime>? timestamp,
      Value<String>? deviceId,
      Value<String?>? metadata,
      Value<String>? hash}) {
    return SecurityAuditTableCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      metadata: metadata ?? this.metadata,
      hash: hash ?? this.hash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecurityAuditTableCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('description: $description, ')
          ..write('severity: $severity, ')
          ..write('timestamp: $timestamp, ')
          ..write('deviceId: $deviceId, ')
          ..write('metadata: $metadata, ')
          ..write('hash: $hash')
          ..write(')'))
        .toString();
  }
}

class $EmergencyEventsTableTable extends EmergencyEventsTable
    with TableInfo<$EmergencyEventsTableTable, EmergencyEventsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergencyEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _emergencyIdMeta =
      const VerificationMeta('emergencyId');
  @override
  late final GeneratedColumn<String> emergencyId = GeneratedColumn<String>(
      'emergency_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _triggerTypeMeta =
      const VerificationMeta('triggerType');
  @override
  late final GeneratedColumn<String> triggerType = GeneratedColumn<String>(
      'trigger_type', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _activatedAtMeta =
      const VerificationMeta('activatedAt');
  @override
  late final GeneratedColumn<DateTime> activatedAt = GeneratedColumn<DateTime>(
      'activated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deactivatedAtMeta =
      const VerificationMeta('deactivatedAt');
  @override
  late final GeneratedColumn<DateTime> deactivatedAt =
      GeneratedColumn<DateTime>('deactivated_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _triggerDataMeta =
      const VerificationMeta('triggerData');
  @override
  late final GeneratedColumn<String> triggerData = GeneratedColumn<String>(
      'trigger_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionsPerformedMeta =
      const VerificationMeta('actionsPerformed');
  @override
  late final GeneratedColumn<String> actionsPerformed = GeneratedColumn<String>(
      'actions_performed', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        emergencyId,
        triggerType,
        activatedAt,
        deactivatedAt,
        deviceId,
        triggerData,
        actionsPerformed,
        metadata,
        createdAt,
        updatedAt,
        synced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_events_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<EmergencyEventsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('emergency_id')) {
      context.handle(
          _emergencyIdMeta,
          emergencyId.isAcceptableOrUnknown(
              data['emergency_id']!, _emergencyIdMeta));
    } else if (isInserting) {
      context.missing(_emergencyIdMeta);
    }
    if (data.containsKey('trigger_type')) {
      context.handle(
          _triggerTypeMeta,
          triggerType.isAcceptableOrUnknown(
              data['trigger_type']!, _triggerTypeMeta));
    } else if (isInserting) {
      context.missing(_triggerTypeMeta);
    }
    if (data.containsKey('activated_at')) {
      context.handle(
          _activatedAtMeta,
          activatedAt.isAcceptableOrUnknown(
              data['activated_at']!, _activatedAtMeta));
    } else if (isInserting) {
      context.missing(_activatedAtMeta);
    }
    if (data.containsKey('deactivated_at')) {
      context.handle(
          _deactivatedAtMeta,
          deactivatedAt.isAcceptableOrUnknown(
              data['deactivated_at']!, _deactivatedAtMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('trigger_data')) {
      context.handle(
          _triggerDataMeta,
          triggerData.isAcceptableOrUnknown(
              data['trigger_data']!, _triggerDataMeta));
    } else if (isInserting) {
      context.missing(_triggerDataMeta);
    }
    if (data.containsKey('actions_performed')) {
      context.handle(
          _actionsPerformedMeta,
          actionsPerformed.isAcceptableOrUnknown(
              data['actions_performed']!, _actionsPerformedMeta));
    } else if (isInserting) {
      context.missing(_actionsPerformedMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    } else if (isInserting) {
      context.missing(_metadataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyEventsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyEventsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      emergencyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emergency_id'])!,
      triggerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trigger_type'])!,
      activatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}activated_at'])!,
      deactivatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}deactivated_at']),
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      triggerData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trigger_data'])!,
      actionsPerformed: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}actions_performed'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $EmergencyEventsTableTable createAlias(String alias) {
    return $EmergencyEventsTableTable(attachedDatabase, alias);
  }
}

class EmergencyEventsTableData extends DataClass
    implements Insertable<EmergencyEventsTableData> {
  final int id;
  final String emergencyId;
  final String triggerType;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;
  final String deviceId;
  final String triggerData;
  final String actionsPerformed;
  final String metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;
  const EmergencyEventsTableData(
      {required this.id,
      required this.emergencyId,
      required this.triggerType,
      required this.activatedAt,
      this.deactivatedAt,
      required this.deviceId,
      required this.triggerData,
      required this.actionsPerformed,
      required this.metadata,
      required this.createdAt,
      required this.updatedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['emergency_id'] = Variable<String>(emergencyId);
    map['trigger_type'] = Variable<String>(triggerType);
    map['activated_at'] = Variable<DateTime>(activatedAt);
    if (!nullToAbsent || deactivatedAt != null) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['trigger_data'] = Variable<String>(triggerData);
    map['actions_performed'] = Variable<String>(actionsPerformed);
    map['metadata'] = Variable<String>(metadata);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  EmergencyEventsTableCompanion toCompanion(bool nullToAbsent) {
    return EmergencyEventsTableCompanion(
      id: Value(id),
      emergencyId: Value(emergencyId),
      triggerType: Value(triggerType),
      activatedAt: Value(activatedAt),
      deactivatedAt: deactivatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deactivatedAt),
      deviceId: Value(deviceId),
      triggerData: Value(triggerData),
      actionsPerformed: Value(actionsPerformed),
      metadata: Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      synced: Value(synced),
    );
  }

  factory EmergencyEventsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyEventsTableData(
      id: serializer.fromJson<int>(json['id']),
      emergencyId: serializer.fromJson<String>(json['emergencyId']),
      triggerType: serializer.fromJson<String>(json['triggerType']),
      activatedAt: serializer.fromJson<DateTime>(json['activatedAt']),
      deactivatedAt: serializer.fromJson<DateTime?>(json['deactivatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      triggerData: serializer.fromJson<String>(json['triggerData']),
      actionsPerformed: serializer.fromJson<String>(json['actionsPerformed']),
      metadata: serializer.fromJson<String>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'emergencyId': serializer.toJson<String>(emergencyId),
      'triggerType': serializer.toJson<String>(triggerType),
      'activatedAt': serializer.toJson<DateTime>(activatedAt),
      'deactivatedAt': serializer.toJson<DateTime?>(deactivatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'triggerData': serializer.toJson<String>(triggerData),
      'actionsPerformed': serializer.toJson<String>(actionsPerformed),
      'metadata': serializer.toJson<String>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  EmergencyEventsTableData copyWith(
          {int? id,
          String? emergencyId,
          String? triggerType,
          DateTime? activatedAt,
          Value<DateTime?> deactivatedAt = const Value.absent(),
          String? deviceId,
          String? triggerData,
          String? actionsPerformed,
          String? metadata,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? synced}) =>
      EmergencyEventsTableData(
        id: id ?? this.id,
        emergencyId: emergencyId ?? this.emergencyId,
        triggerType: triggerType ?? this.triggerType,
        activatedAt: activatedAt ?? this.activatedAt,
        deactivatedAt:
            deactivatedAt.present ? deactivatedAt.value : this.deactivatedAt,
        deviceId: deviceId ?? this.deviceId,
        triggerData: triggerData ?? this.triggerData,
        actionsPerformed: actionsPerformed ?? this.actionsPerformed,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        synced: synced ?? this.synced,
      );
  EmergencyEventsTableData copyWithCompanion(
      EmergencyEventsTableCompanion data) {
    return EmergencyEventsTableData(
      id: data.id.present ? data.id.value : this.id,
      emergencyId:
          data.emergencyId.present ? data.emergencyId.value : this.emergencyId,
      triggerType:
          data.triggerType.present ? data.triggerType.value : this.triggerType,
      activatedAt:
          data.activatedAt.present ? data.activatedAt.value : this.activatedAt,
      deactivatedAt: data.deactivatedAt.present
          ? data.deactivatedAt.value
          : this.deactivatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      triggerData:
          data.triggerData.present ? data.triggerData.value : this.triggerData,
      actionsPerformed: data.actionsPerformed.present
          ? data.actionsPerformed.value
          : this.actionsPerformed,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyEventsTableData(')
          ..write('id: $id, ')
          ..write('emergencyId: $emergencyId, ')
          ..write('triggerType: $triggerType, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('triggerData: $triggerData, ')
          ..write('actionsPerformed: $actionsPerformed, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      emergencyId,
      triggerType,
      activatedAt,
      deactivatedAt,
      deviceId,
      triggerData,
      actionsPerformed,
      metadata,
      createdAt,
      updatedAt,
      synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyEventsTableData &&
          other.id == this.id &&
          other.emergencyId == this.emergencyId &&
          other.triggerType == this.triggerType &&
          other.activatedAt == this.activatedAt &&
          other.deactivatedAt == this.deactivatedAt &&
          other.deviceId == this.deviceId &&
          other.triggerData == this.triggerData &&
          other.actionsPerformed == this.actionsPerformed &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.synced == this.synced);
}

class EmergencyEventsTableCompanion
    extends UpdateCompanion<EmergencyEventsTableData> {
  final Value<int> id;
  final Value<String> emergencyId;
  final Value<String> triggerType;
  final Value<DateTime> activatedAt;
  final Value<DateTime?> deactivatedAt;
  final Value<String> deviceId;
  final Value<String> triggerData;
  final Value<String> actionsPerformed;
  final Value<String> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> synced;
  const EmergencyEventsTableCompanion({
    this.id = const Value.absent(),
    this.emergencyId = const Value.absent(),
    this.triggerType = const Value.absent(),
    this.activatedAt = const Value.absent(),
    this.deactivatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.triggerData = const Value.absent(),
    this.actionsPerformed = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  EmergencyEventsTableCompanion.insert({
    this.id = const Value.absent(),
    required String emergencyId,
    required String triggerType,
    required DateTime activatedAt,
    this.deactivatedAt = const Value.absent(),
    required String deviceId,
    required String triggerData,
    required String actionsPerformed,
    required String metadata,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.synced = const Value.absent(),
  })  : emergencyId = Value(emergencyId),
        triggerType = Value(triggerType),
        activatedAt = Value(activatedAt),
        deviceId = Value(deviceId),
        triggerData = Value(triggerData),
        actionsPerformed = Value(actionsPerformed),
        metadata = Value(metadata);
  static Insertable<EmergencyEventsTableData> custom({
    Expression<int>? id,
    Expression<String>? emergencyId,
    Expression<String>? triggerType,
    Expression<DateTime>? activatedAt,
    Expression<DateTime>? deactivatedAt,
    Expression<String>? deviceId,
    Expression<String>? triggerData,
    Expression<String>? actionsPerformed,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (emergencyId != null) 'emergency_id': emergencyId,
      if (triggerType != null) 'trigger_type': triggerType,
      if (activatedAt != null) 'activated_at': activatedAt,
      if (deactivatedAt != null) 'deactivated_at': deactivatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (triggerData != null) 'trigger_data': triggerData,
      if (actionsPerformed != null) 'actions_performed': actionsPerformed,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (synced != null) 'synced': synced,
    });
  }

  EmergencyEventsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? emergencyId,
      Value<String>? triggerType,
      Value<DateTime>? activatedAt,
      Value<DateTime?>? deactivatedAt,
      Value<String>? deviceId,
      Value<String>? triggerData,
      Value<String>? actionsPerformed,
      Value<String>? metadata,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? synced}) {
    return EmergencyEventsTableCompanion(
      id: id ?? this.id,
      emergencyId: emergencyId ?? this.emergencyId,
      triggerType: triggerType ?? this.triggerType,
      activatedAt: activatedAt ?? this.activatedAt,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      deviceId: deviceId ?? this.deviceId,
      triggerData: triggerData ?? this.triggerData,
      actionsPerformed: actionsPerformed ?? this.actionsPerformed,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (emergencyId.present) {
      map['emergency_id'] = Variable<String>(emergencyId.value);
    }
    if (triggerType.present) {
      map['trigger_type'] = Variable<String>(triggerType.value);
    }
    if (activatedAt.present) {
      map['activated_at'] = Variable<DateTime>(activatedAt.value);
    }
    if (deactivatedAt.present) {
      map['deactivated_at'] = Variable<DateTime>(deactivatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (triggerData.present) {
      map['trigger_data'] = Variable<String>(triggerData.value);
    }
    if (actionsPerformed.present) {
      map['actions_performed'] = Variable<String>(actionsPerformed.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('emergencyId: $emergencyId, ')
          ..write('triggerType: $triggerType, ')
          ..write('activatedAt: $activatedAt, ')
          ..write('deactivatedAt: $deactivatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('triggerData: $triggerData, ')
          ..write('actionsPerformed: $actionsPerformed, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  late final $CollectionLeaseTableTable collectionLeaseTable =
      $CollectionLeaseTableTable(this);
  late final $SmsDataTableTable smsDataTable = $SmsDataTableTable(this);
  late final $CallDataTableTable callDataTable = $CallDataTableTable(this);
  late final $LocationDataTableTable locationDataTable =
      $LocationDataTableTable(this);
  late final $AppUsageDataTableTable appUsageDataTable =
      $AppUsageDataTableTable(this);
  late final $AppDataTableTable appDataTable = $AppDataTableTable(this);
  late final $MediaDataTableTable mediaDataTable = $MediaDataTableTable(this);
  late final $ConfigurationTableTable configurationTable =
      $ConfigurationTableTable(this);
  late final $SecurityAuditTableTable securityAuditTable =
      $SecurityAuditTableTable(this);
  late final $EmergencyEventsTableTable emergencyEventsTable =
      $EmergencyEventsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        syncQueueTable,
        collectionLeaseTable,
        smsDataTable,
        callDataTable,
        locationDataTable,
        appUsageDataTable,
        appDataTable,
        mediaDataTable,
        configurationTable,
        securityAuditTable,
        emergencyEventsTable
      ];
}

typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String type,
  Value<int> priority,
  required Uint8List payload,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<DateTime?> lastAttempt,
  Value<String> status,
  Value<String?> batchId,
  Value<int> payloadSize,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<int> priority,
  Value<Uint8List> payload,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<DateTime?> lastAttempt,
  Value<String> status,
  Value<String?> batchId,
  Value<int> payloadSize,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get batchId => $composableBuilder(
      column: $table.batchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get payloadSize => $composableBuilder(
      column: $table.payloadSize, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get batchId => $composableBuilder(
      column: $table.batchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get payloadSize => $composableBuilder(
      column: $table.payloadSize, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttempt => $composableBuilder(
      column: $table.lastAttempt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<int> get payloadSize => $composableBuilder(
      column: $table.payloadSize, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(
      _$AppDatabase db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<Uint8List> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastAttempt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> batchId = const Value.absent(),
            Value<int> payloadSize = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            type: type,
            priority: priority,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            lastAttempt: lastAttempt,
            status: status,
            batchId: batchId,
            payloadSize: payloadSize,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            Value<int> priority = const Value.absent(),
            required Uint8List payload,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastAttempt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> batchId = const Value.absent(),
            Value<int> payloadSize = const Value.absent(),
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            type: type,
            priority: priority,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            lastAttempt: lastAttempt,
            status: status,
            batchId: batchId,
            payloadSize: payloadSize,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$AppDatabase, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;
typedef $$CollectionLeaseTableTableCreateCompanionBuilder
    = CollectionLeaseTableCompanion Function({
  Value<int> id,
  required String owner,
  required int acquiredAtMs,
  Value<DateTime> updatedAt,
});
typedef $$CollectionLeaseTableTableUpdateCompanionBuilder
    = CollectionLeaseTableCompanion Function({
  Value<int> id,
  Value<String> owner,
  Value<int> acquiredAtMs,
  Value<DateTime> updatedAt,
});

class $$CollectionLeaseTableTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionLeaseTableTable> {
  $$CollectionLeaseTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acquiredAtMs => $composableBuilder(
      column: $table.acquiredAtMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CollectionLeaseTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionLeaseTableTable> {
  $$CollectionLeaseTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get owner => $composableBuilder(
      column: $table.owner, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acquiredAtMs => $composableBuilder(
      column: $table.acquiredAtMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CollectionLeaseTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionLeaseTableTable> {
  $$CollectionLeaseTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<int> get acquiredAtMs => $composableBuilder(
      column: $table.acquiredAtMs, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CollectionLeaseTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CollectionLeaseTableTable,
    CollectionLeaseTableData,
    $$CollectionLeaseTableTableFilterComposer,
    $$CollectionLeaseTableTableOrderingComposer,
    $$CollectionLeaseTableTableAnnotationComposer,
    $$CollectionLeaseTableTableCreateCompanionBuilder,
    $$CollectionLeaseTableTableUpdateCompanionBuilder,
    (
      CollectionLeaseTableData,
      BaseReferences<_$AppDatabase, $CollectionLeaseTableTable,
          CollectionLeaseTableData>
    ),
    CollectionLeaseTableData,
    PrefetchHooks Function()> {
  $$CollectionLeaseTableTableTableManager(
      _$AppDatabase db, $CollectionLeaseTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionLeaseTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionLeaseTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionLeaseTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> owner = const Value.absent(),
            Value<int> acquiredAtMs = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CollectionLeaseTableCompanion(
            id: id,
            owner: owner,
            acquiredAtMs: acquiredAtMs,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String owner,
            required int acquiredAtMs,
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CollectionLeaseTableCompanion.insert(
            id: id,
            owner: owner,
            acquiredAtMs: acquiredAtMs,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CollectionLeaseTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CollectionLeaseTableTable,
        CollectionLeaseTableData,
        $$CollectionLeaseTableTableFilterComposer,
        $$CollectionLeaseTableTableOrderingComposer,
        $$CollectionLeaseTableTableAnnotationComposer,
        $$CollectionLeaseTableTableCreateCompanionBuilder,
        $$CollectionLeaseTableTableUpdateCompanionBuilder,
        (
          CollectionLeaseTableData,
          BaseReferences<_$AppDatabase, $CollectionLeaseTableTable,
              CollectionLeaseTableData>
        ),
        CollectionLeaseTableData,
        PrefetchHooks Function()>;
typedef $$SmsDataTableTableCreateCompanionBuilder = SmsDataTableCompanion
    Function({
  Value<int> id,
  required String deviceId,
  required String messageType,
  required String direction,
  required String sender,
  Value<String?> senderName,
  required String body,
  required DateTime sentAt,
  Value<DateTime> recordedAt,
  Value<String?> conversationId,
  Value<bool> hasAttachment,
  Value<bool> synced,
  required String hash,
});
typedef $$SmsDataTableTableUpdateCompanionBuilder = SmsDataTableCompanion
    Function({
  Value<int> id,
  Value<String> deviceId,
  Value<String> messageType,
  Value<String> direction,
  Value<String> sender,
  Value<String?> senderName,
  Value<String> body,
  Value<DateTime> sentAt,
  Value<DateTime> recordedAt,
  Value<String?> conversationId,
  Value<bool> hasAttachment,
  Value<bool> synced,
  Value<String> hash,
});

class $$SmsDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $SmsDataTableTable> {
  $$SmsDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageType => $composableBuilder(
      column: $table.messageType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasAttachment => $composableBuilder(
      column: $table.hasAttachment, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));
}

class $$SmsDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsDataTableTable> {
  $$SmsDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageType => $composableBuilder(
      column: $table.messageType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conversationId => $composableBuilder(
      column: $table.conversationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasAttachment => $composableBuilder(
      column: $table.hasAttachment,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));
}

class $$SmsDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsDataTableTable> {
  $$SmsDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get messageType => $composableBuilder(
      column: $table.messageType, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
      column: $table.senderName, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
      column: $table.conversationId, builder: (column) => column);

  GeneratedColumn<bool> get hasAttachment => $composableBuilder(
      column: $table.hasAttachment, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);
}

class $$SmsDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SmsDataTableTable,
    SmsDataTableData,
    $$SmsDataTableTableFilterComposer,
    $$SmsDataTableTableOrderingComposer,
    $$SmsDataTableTableAnnotationComposer,
    $$SmsDataTableTableCreateCompanionBuilder,
    $$SmsDataTableTableUpdateCompanionBuilder,
    (
      SmsDataTableData,
      BaseReferences<_$AppDatabase, $SmsDataTableTable, SmsDataTableData>
    ),
    SmsDataTableData,
    PrefetchHooks Function()> {
  $$SmsDataTableTableTableManager(_$AppDatabase db, $SmsDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String> sender = const Value.absent(),
            Value<String?> senderName = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> sentAt = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String?> conversationId = const Value.absent(),
            Value<bool> hasAttachment = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String> hash = const Value.absent(),
          }) =>
              SmsDataTableCompanion(
            id: id,
            deviceId: deviceId,
            messageType: messageType,
            direction: direction,
            sender: sender,
            senderName: senderName,
            body: body,
            sentAt: sentAt,
            recordedAt: recordedAt,
            conversationId: conversationId,
            hasAttachment: hasAttachment,
            synced: synced,
            hash: hash,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required String messageType,
            required String direction,
            required String sender,
            Value<String?> senderName = const Value.absent(),
            required String body,
            required DateTime sentAt,
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String?> conversationId = const Value.absent(),
            Value<bool> hasAttachment = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            required String hash,
          }) =>
              SmsDataTableCompanion.insert(
            id: id,
            deviceId: deviceId,
            messageType: messageType,
            direction: direction,
            sender: sender,
            senderName: senderName,
            body: body,
            sentAt: sentAt,
            recordedAt: recordedAt,
            conversationId: conversationId,
            hasAttachment: hasAttachment,
            synced: synced,
            hash: hash,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SmsDataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SmsDataTableTable,
    SmsDataTableData,
    $$SmsDataTableTableFilterComposer,
    $$SmsDataTableTableOrderingComposer,
    $$SmsDataTableTableAnnotationComposer,
    $$SmsDataTableTableCreateCompanionBuilder,
    $$SmsDataTableTableUpdateCompanionBuilder,
    (
      SmsDataTableData,
      BaseReferences<_$AppDatabase, $SmsDataTableTable, SmsDataTableData>
    ),
    SmsDataTableData,
    PrefetchHooks Function()>;
typedef $$CallDataTableTableCreateCompanionBuilder = CallDataTableCompanion
    Function({
  Value<int> id,
  required String deviceId,
  required String callType,
  required String phoneNumber,
  Value<String?> contactName,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int> duration,
  Value<DateTime> recordedAt,
  Value<bool> isVideoCall,
  Value<bool> synced,
  required String hash,
  Value<int?> simSlot,
  Value<bool> isConference,
});
typedef $$CallDataTableTableUpdateCompanionBuilder = CallDataTableCompanion
    Function({
  Value<int> id,
  Value<String> deviceId,
  Value<String> callType,
  Value<String> phoneNumber,
  Value<String?> contactName,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int> duration,
  Value<DateTime> recordedAt,
  Value<bool> isVideoCall,
  Value<bool> synced,
  Value<String> hash,
  Value<int?> simSlot,
  Value<bool> isConference,
});

class $$CallDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $CallDataTableTable> {
  $$CallDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get callType => $composableBuilder(
      column: $table.callType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactName => $composableBuilder(
      column: $table.contactName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isVideoCall => $composableBuilder(
      column: $table.isVideoCall, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get simSlot => $composableBuilder(
      column: $table.simSlot, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isConference => $composableBuilder(
      column: $table.isConference, builder: (column) => ColumnFilters(column));
}

class $$CallDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CallDataTableTable> {
  $$CallDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get callType => $composableBuilder(
      column: $table.callType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactName => $composableBuilder(
      column: $table.contactName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isVideoCall => $composableBuilder(
      column: $table.isVideoCall, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get simSlot => $composableBuilder(
      column: $table.simSlot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isConference => $composableBuilder(
      column: $table.isConference,
      builder: (column) => ColumnOrderings(column));
}

class $$CallDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CallDataTableTable> {
  $$CallDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get callType =>
      $composableBuilder(column: $table.callType, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get contactName => $composableBuilder(
      column: $table.contactName, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<bool> get isVideoCall => $composableBuilder(
      column: $table.isVideoCall, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<int> get simSlot =>
      $composableBuilder(column: $table.simSlot, builder: (column) => column);

  GeneratedColumn<bool> get isConference => $composableBuilder(
      column: $table.isConference, builder: (column) => column);
}

class $$CallDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CallDataTableTable,
    CallDataTableData,
    $$CallDataTableTableFilterComposer,
    $$CallDataTableTableOrderingComposer,
    $$CallDataTableTableAnnotationComposer,
    $$CallDataTableTableCreateCompanionBuilder,
    $$CallDataTableTableUpdateCompanionBuilder,
    (
      CallDataTableData,
      BaseReferences<_$AppDatabase, $CallDataTableTable, CallDataTableData>
    ),
    CallDataTableData,
    PrefetchHooks Function()> {
  $$CallDataTableTableTableManager(_$AppDatabase db, $CallDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CallDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CallDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CallDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> callType = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<String?> contactName = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> isVideoCall = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String> hash = const Value.absent(),
            Value<int?> simSlot = const Value.absent(),
            Value<bool> isConference = const Value.absent(),
          }) =>
              CallDataTableCompanion(
            id: id,
            deviceId: deviceId,
            callType: callType,
            phoneNumber: phoneNumber,
            contactName: contactName,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            recordedAt: recordedAt,
            isVideoCall: isVideoCall,
            synced: synced,
            hash: hash,
            simSlot: simSlot,
            isConference: isConference,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required String callType,
            required String phoneNumber,
            Value<String?> contactName = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> isVideoCall = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            required String hash,
            Value<int?> simSlot = const Value.absent(),
            Value<bool> isConference = const Value.absent(),
          }) =>
              CallDataTableCompanion.insert(
            id: id,
            deviceId: deviceId,
            callType: callType,
            phoneNumber: phoneNumber,
            contactName: contactName,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            recordedAt: recordedAt,
            isVideoCall: isVideoCall,
            synced: synced,
            hash: hash,
            simSlot: simSlot,
            isConference: isConference,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CallDataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CallDataTableTable,
    CallDataTableData,
    $$CallDataTableTableFilterComposer,
    $$CallDataTableTableOrderingComposer,
    $$CallDataTableTableAnnotationComposer,
    $$CallDataTableTableCreateCompanionBuilder,
    $$CallDataTableTableUpdateCompanionBuilder,
    (
      CallDataTableData,
      BaseReferences<_$AppDatabase, $CallDataTableTable, CallDataTableData>
    ),
    CallDataTableData,
    PrefetchHooks Function()>;
typedef $$LocationDataTableTableCreateCompanionBuilder
    = LocationDataTableCompanion Function({
  Value<int> id,
  required String deviceId,
  required double latitude,
  required double longitude,
  required double accuracy,
  Value<double?> altitude,
  Value<double?> speed,
  Value<double?> bearing,
  Value<DateTime> recordedAt,
  required String provider,
  Value<String?> activityType,
  Value<bool> synced,
  Value<int?> batteryLevel,
});
typedef $$LocationDataTableTableUpdateCompanionBuilder
    = LocationDataTableCompanion Function({
  Value<int> id,
  Value<String> deviceId,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> accuracy,
  Value<double?> altitude,
  Value<double?> speed,
  Value<double?> bearing,
  Value<DateTime> recordedAt,
  Value<String> provider,
  Value<String?> activityType,
  Value<bool> synced,
  Value<int?> batteryLevel,
});

class $$LocationDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocationDataTableTable> {
  $$LocationDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get altitude => $composableBuilder(
      column: $table.altitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bearing => $composableBuilder(
      column: $table.bearing, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityType => $composableBuilder(
      column: $table.activityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get batteryLevel => $composableBuilder(
      column: $table.batteryLevel, builder: (column) => ColumnFilters(column));
}

class $$LocationDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationDataTableTable> {
  $$LocationDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get altitude => $composableBuilder(
      column: $table.altitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bearing => $composableBuilder(
      column: $table.bearing, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityType => $composableBuilder(
      column: $table.activityType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get batteryLevel => $composableBuilder(
      column: $table.batteryLevel,
      builder: (column) => ColumnOrderings(column));
}

class $$LocationDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationDataTableTable> {
  $$LocationDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get bearing =>
      $composableBuilder(column: $table.bearing, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get activityType => $composableBuilder(
      column: $table.activityType, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get batteryLevel => $composableBuilder(
      column: $table.batteryLevel, builder: (column) => column);
}

class $$LocationDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocationDataTableTable,
    LocationDataTableData,
    $$LocationDataTableTableFilterComposer,
    $$LocationDataTableTableOrderingComposer,
    $$LocationDataTableTableAnnotationComposer,
    $$LocationDataTableTableCreateCompanionBuilder,
    $$LocationDataTableTableUpdateCompanionBuilder,
    (
      LocationDataTableData,
      BaseReferences<_$AppDatabase, $LocationDataTableTable,
          LocationDataTableData>
    ),
    LocationDataTableData,
    PrefetchHooks Function()> {
  $$LocationDataTableTableTableManager(
      _$AppDatabase db, $LocationDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationDataTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double> accuracy = const Value.absent(),
            Value<double?> altitude = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<double?> bearing = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String?> activityType = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int?> batteryLevel = const Value.absent(),
          }) =>
              LocationDataTableCompanion(
            id: id,
            deviceId: deviceId,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            altitude: altitude,
            speed: speed,
            bearing: bearing,
            recordedAt: recordedAt,
            provider: provider,
            activityType: activityType,
            synced: synced,
            batteryLevel: batteryLevel,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required double latitude,
            required double longitude,
            required double accuracy,
            Value<double?> altitude = const Value.absent(),
            Value<double?> speed = const Value.absent(),
            Value<double?> bearing = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            required String provider,
            Value<String?> activityType = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<int?> batteryLevel = const Value.absent(),
          }) =>
              LocationDataTableCompanion.insert(
            id: id,
            deviceId: deviceId,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            altitude: altitude,
            speed: speed,
            bearing: bearing,
            recordedAt: recordedAt,
            provider: provider,
            activityType: activityType,
            synced: synced,
            batteryLevel: batteryLevel,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocationDataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocationDataTableTable,
    LocationDataTableData,
    $$LocationDataTableTableFilterComposer,
    $$LocationDataTableTableOrderingComposer,
    $$LocationDataTableTableAnnotationComposer,
    $$LocationDataTableTableCreateCompanionBuilder,
    $$LocationDataTableTableUpdateCompanionBuilder,
    (
      LocationDataTableData,
      BaseReferences<_$AppDatabase, $LocationDataTableTable,
          LocationDataTableData>
    ),
    LocationDataTableData,
    PrefetchHooks Function()>;
typedef $$AppUsageDataTableTableCreateCompanionBuilder
    = AppUsageDataTableCompanion Function({
  Value<int> id,
  required String deviceId,
  required String packageName,
  required String appName,
  Value<String?> category,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<int> launchCount,
  Value<DateTime> recordedAt,
  Value<bool> synced,
  required String date,
});
typedef $$AppUsageDataTableTableUpdateCompanionBuilder
    = AppUsageDataTableCompanion Function({
  Value<int> id,
  Value<String> deviceId,
  Value<String> packageName,
  Value<String> appName,
  Value<String?> category,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<int> durationSeconds,
  Value<int> launchCount,
  Value<DateTime> recordedAt,
  Value<bool> synced,
  Value<String> date,
});

class $$AppUsageDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppUsageDataTableTable> {
  $$AppUsageDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appName => $composableBuilder(
      column: $table.appName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get launchCount => $composableBuilder(
      column: $table.launchCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));
}

class $$AppUsageDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppUsageDataTableTable> {
  $$AppUsageDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appName => $composableBuilder(
      column: $table.appName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get launchCount => $composableBuilder(
      column: $table.launchCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));
}

class $$AppUsageDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppUsageDataTableTable> {
  $$AppUsageDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get launchCount => $composableBuilder(
      column: $table.launchCount, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$AppUsageDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppUsageDataTableTable,
    AppUsageDataTableData,
    $$AppUsageDataTableTableFilterComposer,
    $$AppUsageDataTableTableOrderingComposer,
    $$AppUsageDataTableTableAnnotationComposer,
    $$AppUsageDataTableTableCreateCompanionBuilder,
    $$AppUsageDataTableTableUpdateCompanionBuilder,
    (
      AppUsageDataTableData,
      BaseReferences<_$AppDatabase, $AppUsageDataTableTable,
          AppUsageDataTableData>
    ),
    AppUsageDataTableData,
    PrefetchHooks Function()> {
  $$AppUsageDataTableTableTableManager(
      _$AppDatabase db, $AppUsageDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsageDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsageDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsageDataTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> packageName = const Value.absent(),
            Value<String> appName = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> launchCount = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String> date = const Value.absent(),
          }) =>
              AppUsageDataTableCompanion(
            id: id,
            deviceId: deviceId,
            packageName: packageName,
            appName: appName,
            category: category,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            launchCount: launchCount,
            recordedAt: recordedAt,
            synced: synced,
            date: date,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required String packageName,
            required String appName,
            Value<String?> category = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> launchCount = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            required String date,
          }) =>
              AppUsageDataTableCompanion.insert(
            id: id,
            deviceId: deviceId,
            packageName: packageName,
            appName: appName,
            category: category,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            launchCount: launchCount,
            recordedAt: recordedAt,
            synced: synced,
            date: date,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppUsageDataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppUsageDataTableTable,
    AppUsageDataTableData,
    $$AppUsageDataTableTableFilterComposer,
    $$AppUsageDataTableTableOrderingComposer,
    $$AppUsageDataTableTableAnnotationComposer,
    $$AppUsageDataTableTableCreateCompanionBuilder,
    $$AppUsageDataTableTableUpdateCompanionBuilder,
    (
      AppUsageDataTableData,
      BaseReferences<_$AppDatabase, $AppUsageDataTableTable,
          AppUsageDataTableData>
    ),
    AppUsageDataTableData,
    PrefetchHooks Function()>;
typedef $$AppDataTableTableCreateCompanionBuilder = AppDataTableCompanion
    Function({
  Value<int> id,
  required String deviceId,
  required String packageName,
  required String appName,
  Value<String?> versionName,
  Value<int?> versionCode,
  required DateTime firstInstallTime,
  Value<DateTime?> lastUpdateTime,
  Value<String?> appCategory,
  Value<bool> isSystemApp,
  Value<DateTime> recordedAt,
  Value<bool> synced,
});
typedef $$AppDataTableTableUpdateCompanionBuilder = AppDataTableCompanion
    Function({
  Value<int> id,
  Value<String> deviceId,
  Value<String> packageName,
  Value<String> appName,
  Value<String?> versionName,
  Value<int?> versionCode,
  Value<DateTime> firstInstallTime,
  Value<DateTime?> lastUpdateTime,
  Value<String?> appCategory,
  Value<bool> isSystemApp,
  Value<DateTime> recordedAt,
  Value<bool> synced,
});

class $$AppDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppDataTableTable> {
  $$AppDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appName => $composableBuilder(
      column: $table.appName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionName => $composableBuilder(
      column: $table.versionName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get versionCode => $composableBuilder(
      column: $table.versionCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstInstallTime => $composableBuilder(
      column: $table.firstInstallTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUpdateTime => $composableBuilder(
      column: $table.lastUpdateTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appCategory => $composableBuilder(
      column: $table.appCategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystemApp => $composableBuilder(
      column: $table.isSystemApp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$AppDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppDataTableTable> {
  $$AppDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appName => $composableBuilder(
      column: $table.appName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionName => $composableBuilder(
      column: $table.versionName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get versionCode => $composableBuilder(
      column: $table.versionCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstInstallTime => $composableBuilder(
      column: $table.firstInstallTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUpdateTime => $composableBuilder(
      column: $table.lastUpdateTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appCategory => $composableBuilder(
      column: $table.appCategory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystemApp => $composableBuilder(
      column: $table.isSystemApp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$AppDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppDataTableTable> {
  $$AppDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
      column: $table.packageName, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get versionName => $composableBuilder(
      column: $table.versionName, builder: (column) => column);

  GeneratedColumn<int> get versionCode => $composableBuilder(
      column: $table.versionCode, builder: (column) => column);

  GeneratedColumn<DateTime> get firstInstallTime => $composableBuilder(
      column: $table.firstInstallTime, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdateTime => $composableBuilder(
      column: $table.lastUpdateTime, builder: (column) => column);

  GeneratedColumn<String> get appCategory => $composableBuilder(
      column: $table.appCategory, builder: (column) => column);

  GeneratedColumn<bool> get isSystemApp => $composableBuilder(
      column: $table.isSystemApp, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AppDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppDataTableTable,
    AppDataTableData,
    $$AppDataTableTableFilterComposer,
    $$AppDataTableTableOrderingComposer,
    $$AppDataTableTableAnnotationComposer,
    $$AppDataTableTableCreateCompanionBuilder,
    $$AppDataTableTableUpdateCompanionBuilder,
    (
      AppDataTableData,
      BaseReferences<_$AppDatabase, $AppDataTableTable, AppDataTableData>
    ),
    AppDataTableData,
    PrefetchHooks Function()> {
  $$AppDataTableTableTableManager(_$AppDatabase db, $AppDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> packageName = const Value.absent(),
            Value<String> appName = const Value.absent(),
            Value<String?> versionName = const Value.absent(),
            Value<int?> versionCode = const Value.absent(),
            Value<DateTime> firstInstallTime = const Value.absent(),
            Value<DateTime?> lastUpdateTime = const Value.absent(),
            Value<String?> appCategory = const Value.absent(),
            Value<bool> isSystemApp = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              AppDataTableCompanion(
            id: id,
            deviceId: deviceId,
            packageName: packageName,
            appName: appName,
            versionName: versionName,
            versionCode: versionCode,
            firstInstallTime: firstInstallTime,
            lastUpdateTime: lastUpdateTime,
            appCategory: appCategory,
            isSystemApp: isSystemApp,
            recordedAt: recordedAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required String packageName,
            required String appName,
            Value<String?> versionName = const Value.absent(),
            Value<int?> versionCode = const Value.absent(),
            required DateTime firstInstallTime,
            Value<DateTime?> lastUpdateTime = const Value.absent(),
            Value<String?> appCategory = const Value.absent(),
            Value<bool> isSystemApp = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              AppDataTableCompanion.insert(
            id: id,
            deviceId: deviceId,
            packageName: packageName,
            appName: appName,
            versionName: versionName,
            versionCode: versionCode,
            firstInstallTime: firstInstallTime,
            lastUpdateTime: lastUpdateTime,
            appCategory: appCategory,
            isSystemApp: isSystemApp,
            recordedAt: recordedAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppDataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppDataTableTable,
    AppDataTableData,
    $$AppDataTableTableFilterComposer,
    $$AppDataTableTableOrderingComposer,
    $$AppDataTableTableAnnotationComposer,
    $$AppDataTableTableCreateCompanionBuilder,
    $$AppDataTableTableUpdateCompanionBuilder,
    (
      AppDataTableData,
      BaseReferences<_$AppDatabase, $AppDataTableTable, AppDataTableData>
    ),
    AppDataTableData,
    PrefetchHooks Function()>;
typedef $$MediaDataTableTableCreateCompanionBuilder = MediaDataTableCompanion
    Function({
  Value<int> id,
  required String deviceId,
  required String mediaId,
  required String mediaType,
  required String fileName,
  required String filePath,
  required String mimeType,
  required int fileSize,
  Value<int?> width,
  Value<int?> height,
  required DateTime createdAt,
  required DateTime modifiedAt,
  Value<DateTime> recordedAt,
  Value<bool> synced,
  Value<String?> captureMethod,
  Value<String?> cameraType,
  Value<int?> duration,
  Value<Uint8List?> thumbnail,
});
typedef $$MediaDataTableTableUpdateCompanionBuilder = MediaDataTableCompanion
    Function({
  Value<int> id,
  Value<String> deviceId,
  Value<String> mediaId,
  Value<String> mediaType,
  Value<String> fileName,
  Value<String> filePath,
  Value<String> mimeType,
  Value<int> fileSize,
  Value<int?> width,
  Value<int?> height,
  Value<DateTime> createdAt,
  Value<DateTime> modifiedAt,
  Value<DateTime> recordedAt,
  Value<bool> synced,
  Value<String?> captureMethod,
  Value<String?> cameraType,
  Value<int?> duration,
  Value<Uint8List?> thumbnail,
});

class $$MediaDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaDataTableTable> {
  $$MediaDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get captureMethod => $composableBuilder(
      column: $table.captureMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cameraType => $composableBuilder(
      column: $table.cameraType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get thumbnail => $composableBuilder(
      column: $table.thumbnail, builder: (column) => ColumnFilters(column));
}

class $$MediaDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaDataTableTable> {
  $$MediaDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get captureMethod => $composableBuilder(
      column: $table.captureMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cameraType => $composableBuilder(
      column: $table.cameraType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get thumbnail => $composableBuilder(
      column: $table.thumbnail, builder: (column) => ColumnOrderings(column));
}

class $$MediaDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaDataTableTable> {
  $$MediaDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get captureMethod => $composableBuilder(
      column: $table.captureMethod, builder: (column) => column);

  GeneratedColumn<String> get cameraType => $composableBuilder(
      column: $table.cameraType, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<Uint8List> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);
}

class $$MediaDataTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaDataTableTable,
    MediaDataTableData,
    $$MediaDataTableTableFilterComposer,
    $$MediaDataTableTableOrderingComposer,
    $$MediaDataTableTableAnnotationComposer,
    $$MediaDataTableTableCreateCompanionBuilder,
    $$MediaDataTableTableUpdateCompanionBuilder,
    (
      MediaDataTableData,
      BaseReferences<_$AppDatabase, $MediaDataTableTable, MediaDataTableData>
    ),
    MediaDataTableData,
    PrefetchHooks Function()> {
  $$MediaDataTableTableTableManager(
      _$AppDatabase db, $MediaDataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> mediaId = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> modifiedAt = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String?> captureMethod = const Value.absent(),
            Value<String?> cameraType = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<Uint8List?> thumbnail = const Value.absent(),
          }) =>
              MediaDataTableCompanion(
            id: id,
            deviceId: deviceId,
            mediaId: mediaId,
            mediaType: mediaType,
            fileName: fileName,
            filePath: filePath,
            mimeType: mimeType,
            fileSize: fileSize,
            width: width,
            height: height,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            recordedAt: recordedAt,
            synced: synced,
            captureMethod: captureMethod,
            cameraType: cameraType,
            duration: duration,
            thumbnail: thumbnail,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required String mediaId,
            required String mediaType,
            required String fileName,
            required String filePath,
            required String mimeType,
            required int fileSize,
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            required DateTime createdAt,
            required DateTime modifiedAt,
            Value<DateTime> recordedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<String?> captureMethod = const Value.absent(),
            Value<String?> cameraType = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<Uint8List?> thumbnail = const Value.absent(),
          }) =>
              MediaDataTableCompanion.insert(
            id: id,
            deviceId: deviceId,
            mediaId: mediaId,
            mediaType: mediaType,
            fileName: fileName,
            filePath: filePath,
            mimeType: mimeType,
            fileSize: fileSize,
            width: width,
            height: height,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            recordedAt: recordedAt,
            synced: synced,
            captureMethod: captureMethod,
            cameraType: cameraType,
            duration: duration,
            thumbnail: thumbnail,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaDataTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaDataTableTable,
    MediaDataTableData,
    $$MediaDataTableTableFilterComposer,
    $$MediaDataTableTableOrderingComposer,
    $$MediaDataTableTableAnnotationComposer,
    $$MediaDataTableTableCreateCompanionBuilder,
    $$MediaDataTableTableUpdateCompanionBuilder,
    (
      MediaDataTableData,
      BaseReferences<_$AppDatabase, $MediaDataTableTable, MediaDataTableData>
    ),
    MediaDataTableData,
    PrefetchHooks Function()>;
typedef $$ConfigurationTableTableCreateCompanionBuilder
    = ConfigurationTableCompanion Function({
  required String key,
  required String value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ConfigurationTableTableUpdateCompanionBuilder
    = ConfigurationTableCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ConfigurationTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigurationTableTable> {
  $$ConfigurationTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ConfigurationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigurationTableTable> {
  $$ConfigurationTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConfigurationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigurationTableTable> {
  $$ConfigurationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConfigurationTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConfigurationTableTable,
    ConfigurationTableData,
    $$ConfigurationTableTableFilterComposer,
    $$ConfigurationTableTableOrderingComposer,
    $$ConfigurationTableTableAnnotationComposer,
    $$ConfigurationTableTableCreateCompanionBuilder,
    $$ConfigurationTableTableUpdateCompanionBuilder,
    (
      ConfigurationTableData,
      BaseReferences<_$AppDatabase, $ConfigurationTableTable,
          ConfigurationTableData>
    ),
    ConfigurationTableData,
    PrefetchHooks Function()> {
  $$ConfigurationTableTableTableManager(
      _$AppDatabase db, $ConfigurationTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigurationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigurationTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigurationTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConfigurationTableCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConfigurationTableCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConfigurationTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConfigurationTableTable,
    ConfigurationTableData,
    $$ConfigurationTableTableFilterComposer,
    $$ConfigurationTableTableOrderingComposer,
    $$ConfigurationTableTableAnnotationComposer,
    $$ConfigurationTableTableCreateCompanionBuilder,
    $$ConfigurationTableTableUpdateCompanionBuilder,
    (
      ConfigurationTableData,
      BaseReferences<_$AppDatabase, $ConfigurationTableTable,
          ConfigurationTableData>
    ),
    ConfigurationTableData,
    PrefetchHooks Function()>;
typedef $$SecurityAuditTableTableCreateCompanionBuilder
    = SecurityAuditTableCompanion Function({
  Value<int> id,
  required String eventType,
  required String description,
  required String severity,
  Value<DateTime> timestamp,
  required String deviceId,
  Value<String?> metadata,
  required String hash,
});
typedef $$SecurityAuditTableTableUpdateCompanionBuilder
    = SecurityAuditTableCompanion Function({
  Value<int> id,
  Value<String> eventType,
  Value<String> description,
  Value<String> severity,
  Value<DateTime> timestamp,
  Value<String> deviceId,
  Value<String?> metadata,
  Value<String> hash,
});

class $$SecurityAuditTableTableFilterComposer
    extends Composer<_$AppDatabase, $SecurityAuditTableTable> {
  $$SecurityAuditTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));
}

class $$SecurityAuditTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SecurityAuditTableTable> {
  $$SecurityAuditTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));
}

class $$SecurityAuditTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecurityAuditTableTable> {
  $$SecurityAuditTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);
}

class $$SecurityAuditTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SecurityAuditTableTable,
    SecurityAuditTableData,
    $$SecurityAuditTableTableFilterComposer,
    $$SecurityAuditTableTableOrderingComposer,
    $$SecurityAuditTableTableAnnotationComposer,
    $$SecurityAuditTableTableCreateCompanionBuilder,
    $$SecurityAuditTableTableUpdateCompanionBuilder,
    (
      SecurityAuditTableData,
      BaseReferences<_$AppDatabase, $SecurityAuditTableTable,
          SecurityAuditTableData>
    ),
    SecurityAuditTableData,
    PrefetchHooks Function()> {
  $$SecurityAuditTableTableTableManager(
      _$AppDatabase db, $SecurityAuditTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecurityAuditTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecurityAuditTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecurityAuditTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<String> hash = const Value.absent(),
          }) =>
              SecurityAuditTableCompanion(
            id: id,
            eventType: eventType,
            description: description,
            severity: severity,
            timestamp: timestamp,
            deviceId: deviceId,
            metadata: metadata,
            hash: hash,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String eventType,
            required String description,
            required String severity,
            Value<DateTime> timestamp = const Value.absent(),
            required String deviceId,
            Value<String?> metadata = const Value.absent(),
            required String hash,
          }) =>
              SecurityAuditTableCompanion.insert(
            id: id,
            eventType: eventType,
            description: description,
            severity: severity,
            timestamp: timestamp,
            deviceId: deviceId,
            metadata: metadata,
            hash: hash,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SecurityAuditTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SecurityAuditTableTable,
    SecurityAuditTableData,
    $$SecurityAuditTableTableFilterComposer,
    $$SecurityAuditTableTableOrderingComposer,
    $$SecurityAuditTableTableAnnotationComposer,
    $$SecurityAuditTableTableCreateCompanionBuilder,
    $$SecurityAuditTableTableUpdateCompanionBuilder,
    (
      SecurityAuditTableData,
      BaseReferences<_$AppDatabase, $SecurityAuditTableTable,
          SecurityAuditTableData>
    ),
    SecurityAuditTableData,
    PrefetchHooks Function()>;
typedef $$EmergencyEventsTableTableCreateCompanionBuilder
    = EmergencyEventsTableCompanion Function({
  Value<int> id,
  required String emergencyId,
  required String triggerType,
  required DateTime activatedAt,
  Value<DateTime?> deactivatedAt,
  required String deviceId,
  required String triggerData,
  required String actionsPerformed,
  required String metadata,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
});
typedef $$EmergencyEventsTableTableUpdateCompanionBuilder
    = EmergencyEventsTableCompanion Function({
  Value<int> id,
  Value<String> emergencyId,
  Value<String> triggerType,
  Value<DateTime> activatedAt,
  Value<DateTime?> deactivatedAt,
  Value<String> deviceId,
  Value<String> triggerData,
  Value<String> actionsPerformed,
  Value<String> metadata,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> synced,
});

class $$EmergencyEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $EmergencyEventsTableTable> {
  $$EmergencyEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emergencyId => $composableBuilder(
      column: $table.emergencyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get triggerType => $composableBuilder(
      column: $table.triggerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get activatedAt => $composableBuilder(
      column: $table.activatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deactivatedAt => $composableBuilder(
      column: $table.deactivatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get triggerData => $composableBuilder(
      column: $table.triggerData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionsPerformed => $composableBuilder(
      column: $table.actionsPerformed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$EmergencyEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EmergencyEventsTableTable> {
  $$EmergencyEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emergencyId => $composableBuilder(
      column: $table.emergencyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get triggerType => $composableBuilder(
      column: $table.triggerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get activatedAt => $composableBuilder(
      column: $table.activatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deactivatedAt => $composableBuilder(
      column: $table.deactivatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get triggerData => $composableBuilder(
      column: $table.triggerData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionsPerformed => $composableBuilder(
      column: $table.actionsPerformed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$EmergencyEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmergencyEventsTableTable> {
  $$EmergencyEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get emergencyId => $composableBuilder(
      column: $table.emergencyId, builder: (column) => column);

  GeneratedColumn<String> get triggerType => $composableBuilder(
      column: $table.triggerType, builder: (column) => column);

  GeneratedColumn<DateTime> get activatedAt => $composableBuilder(
      column: $table.activatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deactivatedAt => $composableBuilder(
      column: $table.deactivatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get triggerData => $composableBuilder(
      column: $table.triggerData, builder: (column) => column);

  GeneratedColumn<String> get actionsPerformed => $composableBuilder(
      column: $table.actionsPerformed, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$EmergencyEventsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmergencyEventsTableTable,
    EmergencyEventsTableData,
    $$EmergencyEventsTableTableFilterComposer,
    $$EmergencyEventsTableTableOrderingComposer,
    $$EmergencyEventsTableTableAnnotationComposer,
    $$EmergencyEventsTableTableCreateCompanionBuilder,
    $$EmergencyEventsTableTableUpdateCompanionBuilder,
    (
      EmergencyEventsTableData,
      BaseReferences<_$AppDatabase, $EmergencyEventsTableTable,
          EmergencyEventsTableData>
    ),
    EmergencyEventsTableData,
    PrefetchHooks Function()> {
  $$EmergencyEventsTableTableTableManager(
      _$AppDatabase db, $EmergencyEventsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmergencyEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmergencyEventsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmergencyEventsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> emergencyId = const Value.absent(),
            Value<String> triggerType = const Value.absent(),
            Value<DateTime> activatedAt = const Value.absent(),
            Value<DateTime?> deactivatedAt = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> triggerData = const Value.absent(),
            Value<String> actionsPerformed = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              EmergencyEventsTableCompanion(
            id: id,
            emergencyId: emergencyId,
            triggerType: triggerType,
            activatedAt: activatedAt,
            deactivatedAt: deactivatedAt,
            deviceId: deviceId,
            triggerData: triggerData,
            actionsPerformed: actionsPerformed,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String emergencyId,
            required String triggerType,
            required DateTime activatedAt,
            Value<DateTime?> deactivatedAt = const Value.absent(),
            required String deviceId,
            required String triggerData,
            required String actionsPerformed,
            required String metadata,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              EmergencyEventsTableCompanion.insert(
            id: id,
            emergencyId: emergencyId,
            triggerType: triggerType,
            activatedAt: activatedAt,
            deactivatedAt: deactivatedAt,
            deviceId: deviceId,
            triggerData: triggerData,
            actionsPerformed: actionsPerformed,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmergencyEventsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $EmergencyEventsTableTable,
        EmergencyEventsTableData,
        $$EmergencyEventsTableTableFilterComposer,
        $$EmergencyEventsTableTableOrderingComposer,
        $$EmergencyEventsTableTableAnnotationComposer,
        $$EmergencyEventsTableTableCreateCompanionBuilder,
        $$EmergencyEventsTableTableUpdateCompanionBuilder,
        (
          EmergencyEventsTableData,
          BaseReferences<_$AppDatabase, $EmergencyEventsTableTable,
              EmergencyEventsTableData>
        ),
        EmergencyEventsTableData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
  $$CollectionLeaseTableTableTableManager get collectionLeaseTable =>
      $$CollectionLeaseTableTableTableManager(_db, _db.collectionLeaseTable);
  $$SmsDataTableTableTableManager get smsDataTable =>
      $$SmsDataTableTableTableManager(_db, _db.smsDataTable);
  $$CallDataTableTableTableManager get callDataTable =>
      $$CallDataTableTableTableManager(_db, _db.callDataTable);
  $$LocationDataTableTableTableManager get locationDataTable =>
      $$LocationDataTableTableTableManager(_db, _db.locationDataTable);
  $$AppUsageDataTableTableTableManager get appUsageDataTable =>
      $$AppUsageDataTableTableTableManager(_db, _db.appUsageDataTable);
  $$AppDataTableTableTableManager get appDataTable =>
      $$AppDataTableTableTableManager(_db, _db.appDataTable);
  $$MediaDataTableTableTableManager get mediaDataTable =>
      $$MediaDataTableTableTableManager(_db, _db.mediaDataTable);
  $$ConfigurationTableTableTableManager get configurationTable =>
      $$ConfigurationTableTableTableManager(_db, _db.configurationTable);
  $$SecurityAuditTableTableTableManager get securityAuditTable =>
      $$SecurityAuditTableTableTableManager(_db, _db.securityAuditTable);
  $$EmergencyEventsTableTableTableManager get emergencyEventsTable =>
      $$EmergencyEventsTableTableTableManager(_db, _db.emergencyEventsTable);
}
