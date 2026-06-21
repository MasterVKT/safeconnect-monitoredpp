import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  SyncQueueTable,
  CollectionLeaseTable,
  SmsDataTable,
  CallDataTable,
  LocationDataTable,
  AppUsageDataTable,
  AppDataTable,
  MediaDataTable,
  ConfigurationTable,
  SecurityAuditTable,
  EmergencyEventsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(collectionLeaseTable);
          }
        },
      );

  // Sync Queue operations
  Future<List<SyncQueueTableData>> getPendingSyncItems() {
    return (select(syncQueueTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<int> insertSyncItem(SyncQueueTableCompanion item) {
    return into(syncQueueTable).insert(item);
  }

  Future<bool> updateSyncItemStatus(int id, String status) {
    return (update(syncQueueTable)..where((t) => t.id.equals(id)))
        .write(SyncQueueTableCompanion(
          status: Value(status),
          lastAttempt: Value(DateTime.now()),
        ))
        .then((count) => count > 0);
  }

  Future<void> deleteSyncItem(int id) {
    return (delete(syncQueueTable)..where((t) => t.id.equals(id))).go();
  }

  // Collection lease operations
  Future<CollectionLeaseTableData?> getCollectionLease() {
    return (select(collectionLeaseTable)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<bool> tryAcquireCollectionLease(
    String owner,
    int acquiredAtMs,
    int ttlMs,
  ) async {
    await customStatement(
      '''
      INSERT INTO collection_lease_table (id, owner, acquired_at_ms, updated_at)
      VALUES (1, ?, ?, CURRENT_TIMESTAMP)
      ON CONFLICT(id) DO UPDATE SET
        owner = excluded.owner,
        acquired_at_ms = excluded.acquired_at_ms,
        updated_at = CURRENT_TIMESTAMP
      WHERE collection_lease_table.owner = excluded.owner
        OR (? - collection_lease_table.acquired_at_ms) > ?
      ''',
      [
        owner,
        acquiredAtMs,
        acquiredAtMs,
        ttlMs,
      ],
    );

    final result =
        await customSelect('SELECT changes() AS affected_rows').getSingle();
    return result.read<int>('affected_rows') > 0;
  }

  Future<void> upsertCollectionLease(String owner, int acquiredAtMs) {
    return into(collectionLeaseTable).insertOnConflictUpdate(
      CollectionLeaseTableCompanion(
        id: const Value(1),
        owner: Value(owner),
        acquiredAtMs: Value(acquiredAtMs),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> touchCollectionLeaseIfOwner(String owner, int acquiredAtMs) {
    return (update(collectionLeaseTable)
          ..where((t) => t.id.equals(1) & t.owner.equals(owner)))
        .write(
          CollectionLeaseTableCompanion(
            acquiredAtMs: Value(acquiredAtMs),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((count) => count > 0);
  }

  Future<bool> clearCollectionLeaseIfOwner(String owner) {
    return (delete(collectionLeaseTable)
          ..where((t) => t.id.equals(1) & t.owner.equals(owner)))
        .go()
        .then((count) => count > 0);
  }

  // SMS operations
  Future<int> insertSmsData(SmsDataTableCompanion sms) {
    return into(smsDataTable).insert(sms, mode: InsertMode.insertOrIgnore);
  }

  Future<List<SmsDataTableData>> getUnsynedSms() {
    return (select(smsDataTable)..where((t) => t.synced.equals(false))).get();
  }

  Future<void> markSmsAsSynced(List<int> ids) {
    return batch((batch) {
      for (final id in ids) {
        batch.update(
          smsDataTable,
          SmsDataTableCompanion(synced: const Value(true)),
          where: (t) => t.id.equals(id),
        );
      }
    });
  }

  // Call operations
  Future<int> insertCallData(CallDataTableCompanion call) {
    return into(callDataTable).insert(call, mode: InsertMode.insertOrIgnore);
  }

  Future<List<CallDataTableData>> getUnsynedCalls() {
    return (select(callDataTable)..where((t) => t.synced.equals(false))).get();
  }

  Future<void> markCallsAsSynced(List<int> ids) {
    return batch((batch) {
      for (final id in ids) {
        batch.update(
          callDataTable,
          CallDataTableCompanion(synced: const Value(true)),
          where: (t) => t.id.equals(id),
        );
      }
    });
  }

  // Location operations
  Future<int> insertLocationData(LocationDataTableCompanion location) {
    return into(locationDataTable)
        .insert(location, mode: InsertMode.insertOrIgnore);
  }

  Future<List<LocationDataTableData>> getUnsynedLocations() {
    return (select(locationDataTable)..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> markLocationsAsSynced(List<int> ids) {
    return batch((batch) {
      for (final id in ids) {
        batch.update(
          locationDataTable,
          LocationDataTableCompanion(synced: const Value(true)),
          where: (t) => t.id.equals(id),
        );
      }
    });
  }

  // App Usage operations
  Future<int> insertAppUsageData(AppUsageDataTableCompanion appUsage) {
    return into(appUsageDataTable)
        .insert(appUsage, mode: InsertMode.insertOrIgnore);
  }

  Future<List<AppUsageDataTableData>> getUnsynedAppUsage() {
    return (select(appUsageDataTable)..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> markAppUsageAsSynced(List<int> ids) {
    return batch((batch) {
      for (final id in ids) {
        batch.update(
          appUsageDataTable,
          AppUsageDataTableCompanion(synced: const Value(true)),
          where: (t) => t.id.equals(id),
        );
      }
    });
  }

  // Media operations
  Future<int> insertMediaData(MediaDataTableCompanion media) {
    return into(mediaDataTable).insert(media, mode: InsertMode.insertOrIgnore);
  }

  Future<List<MediaDataTableData>> getUnsynedMedia() {
    return (select(mediaDataTable)..where((t) => t.synced.equals(false))).get();
  }

  Future<void> markMediaAsSynced(List<int> ids) {
    return batch((batch) {
      for (final id in ids) {
        batch.update(
          mediaDataTable,
          MediaDataTableCompanion(synced: const Value(true)),
          where: (t) => t.id.equals(id),
        );
      }
    });
  }

  // Configuration operations
  Future<void> updateConfiguration(String key, String value) {
    return into(configurationTable).insertOnConflictUpdate(
      ConfigurationTableCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String?> getConfiguration(String key) async {
    final result = await (select(configurationTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  // Security Audit operations
  Future<int> insertSecurityAuditLog(SecurityAuditTableCompanion audit) {
    return into(securityAuditTable).insert(audit);
  }

  Future<List<SecurityAuditTableData>> getRecentAuditLogs({int limit = 100}) {
    return (select(securityAuditTable)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  // Database maintenance
  Future<void> cleanupOldData() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    // Clean up synced data older than 7 days
    await (delete(smsDataTable)
          ..where((t) =>
              t.synced.equals(true) &
              t.recordedAt.isSmallerThanValue(cutoffDate)))
        .go();

    await (delete(callDataTable)
          ..where((t) =>
              t.synced.equals(true) &
              t.recordedAt.isSmallerThanValue(cutoffDate)))
        .go();

    await (delete(locationDataTable)
          ..where((t) =>
              t.synced.equals(true) &
              t.recordedAt.isSmallerThanValue(cutoffDate)))
        .go();

    await (delete(appUsageDataTable)
          ..where((t) =>
              t.synced.equals(true) &
              t.recordedAt.isSmallerThanValue(cutoffDate)))
        .go();

    // Clean up audit logs older than 30 days
    final auditCutoff = DateTime.now().subtract(const Duration(days: 30));
    await (delete(securityAuditTable)
          ..where((t) => t.timestamp.isSmallerThanValue(auditCutoff)))
        .go();
  }

  Future<Map<String, int>> getDatabaseStatistics() async {
    final smsCount = await (selectOnly(smsDataTable)
          ..addColumns([smsDataTable.id.count()]))
        .getSingle();
    final callsCount = await (selectOnly(callDataTable)
          ..addColumns([callDataTable.id.count()]))
        .getSingle();
    final locationsCount = await (selectOnly(locationDataTable)
          ..addColumns([locationDataTable.id.count()]))
        .getSingle();
    final appUsageCount = await (selectOnly(appUsageDataTable)
          ..addColumns([appUsageDataTable.id.count()]))
        .getSingle();
    final mediaCount = await (selectOnly(mediaDataTable)
          ..addColumns([mediaDataTable.id.count()]))
        .getSingle();
    final pendingSyncCount = await (selectOnly(syncQueueTable)
          ..addColumns([syncQueueTable.id.count()])
          ..where(syncQueueTable.status.equals('pending')))
        .getSingle();

    return {
      'sms': smsCount.read(smsDataTable.id.count()) ?? 0,
      'calls': callsCount.read(callDataTable.id.count()) ?? 0,
      'locations': locationsCount.read(locationDataTable.id.count()) ?? 0,
      'app_usage': appUsageCount.read(appUsageDataTable.id.count()) ?? 0,
      'media': mediaCount.read(mediaDataTable.id.count()) ?? 0,
      'pending_sync': pendingSyncCount.read(syncQueueTable.id.count()) ?? 0,
    };
  }

  // Get sync queue statistics
  Future<Map<String, dynamic>> getSyncQueueStatistics() async {
    final pendingCount = await (selectOnly(syncQueueTable)
          ..addColumns([syncQueueTable.id.count()])
          ..where(syncQueueTable.status.equals('pending')))
        .getSingle();

    final failedCount = await (selectOnly(syncQueueTable)
          ..addColumns([syncQueueTable.id.count()])
          ..where(syncQueueTable.status.equals('failed')))
        .getSingle();

    final processingCount = await (selectOnly(syncQueueTable)
          ..addColumns([syncQueueTable.id.count()])
          ..where(syncQueueTable.status.equals('processing')))
        .getSingle();

    final totalSize = await (selectOnly(syncQueueTable)
          ..addColumns([syncQueueTable.payloadSize.sum()])
          ..where(syncQueueTable.status.equals('pending')))
        .getSingle();

    return {
      'pending_items': pendingCount.read(syncQueueTable.id.count()) ?? 0,
      'failed_items': failedCount.read(syncQueueTable.id.count()) ?? 0,
      'processing_items': processingCount.read(syncQueueTable.id.count()) ?? 0,
      'total_pending_size_bytes':
          totalSize.read(syncQueueTable.payloadSize.sum()) ?? 0,
    };
  }

  // Clean up old sync items
  Future<int> cleanupOldSyncItems({int olderThanDays = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

    return await (delete(syncQueueTable)
          ..where((t) =>
              t.status.equals('completed') &
              t.createdAt.isSmallerThanValue(cutoffDate)))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Redirect sqlite3 to use libsqlcipher.so (provided by sqlcipher_flutter_libs)
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      open.overrideFor(OperatingSystem.android, () {
        return DynamicLibrary.open('libsqlcipher.so');
      });
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dbFolder.path,
          kDebugMode ? 'monitored_app_debug.db' : 'monitored_app.db'),
    );

    if (kDebugMode) {
      return NativeDatabase(
        file,
        setup: (database) {
          database.execute('PRAGMA foreign_keys=ON');
          database.execute('PRAGMA journal_mode=WAL');
          database.execute('PRAGMA synchronous=NORMAL');
          database.execute('PRAGMA cache_size=10000');
          database.execute('PRAGMA temp_store=MEMORY');
        },
      );
    }

    // Generate encryption key from device-specific data
    final encryptionKey = await _generateEncryptionKey();

    return NativeDatabase(
      file,
      setup: (database) {
        // Enable SQLCipher encryption for non-debug builds.
        database.execute('PRAGMA key="$encryptionKey"');
        database.execute('PRAGMA cipher_page_size=4096');
        database.execute('PRAGMA kdf_iter=64000');
        database.execute('PRAGMA cipher_hmac_algorithm=HMAC_SHA512');
        database.execute('PRAGMA cipher_kdf_algorithm=PBKDF2_HMAC_SHA512');

        // Performance optimizations
        database.execute('PRAGMA foreign_keys=ON');
        database.execute('PRAGMA journal_mode=WAL');
        database.execute('PRAGMA synchronous=NORMAL');
        database.execute('PRAGMA cache_size=10000');
        database.execute('PRAGMA temp_store=MEMORY');
      },
    );
  });
}

Future<File> getMonitoredAppDatabaseFile() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final name = kDebugMode ? 'monitored_app_debug.db' : 'monitored_app.db';
  return File(p.join(dbFolder.path, name));
}

Future<void> resetMonitoredAppDatabaseFile() async {
  final file = await getMonitoredAppDatabaseFile();
  final walFile = File('${file.path}-wal');
  final shmFile = File('${file.path}-shm');

  if (await file.exists()) {
    await file.delete();
  }
  if (await walFile.exists()) {
    await walFile.delete();
  }
  if (await shmFile.exists()) {
    await shmFile.delete();
  }
}

Future<String> _generateEncryptionKey() async {
  try {
    // Use Android Keystore for secure key generation
    final result =
        await MethodChannel('com.xpsafeconnect.monitored_app/keystore')
            .invokeMethod<String>('getMasterKey');

    if (result != null && result.isNotEmpty) {
      return result;
    }

    // Fallback to device-specific key if keystore fails
    return await _generateFallbackKey();
  } catch (e) {
    debugPrint('Error getting keystore key, using fallback: $e');
    return await _generateFallbackKey();
  }
}

Future<String> _generateFallbackKey() async {
  final deviceId = await _getSecureDeviceId();
  const appId = 'monitored_app_v1';
  final combined = '$deviceId:$appId';

  // Use PBKDF2 for key derivation
  final salt = utf8.encode('monitored_app_salt_2024');
  final bytes = utf8.encode(combined);

  // Simple PBKDF2 implementation
  var derived = bytes;
  for (int i = 0; i < 10000; i++) {
    final combined = derived + salt;
    derived = Uint8List.fromList(sha256.convert(combined).bytes);
  }

  return base64.encode(derived);
}

Future<String> _getSecureDeviceId() async {
  try {
    // Try to get device ID from secure storage first
    const storage = FlutterSecureStorage();
    var deviceId = await storage.read(key: 'secure_device_id');

    if (deviceId == null) {
      // Generate and store new secure device ID
      final deviceInfo = DeviceInfoPlugin();
      final random = Random.secure();
      final androidInfo = await deviceInfo.androidInfo;

      final components = [
        androidInfo.id,
        androidInfo.model,
        androidInfo.fingerprint,
        random.nextInt(1000000).toString(),
      ];

      final combined = components.join(':');
      final hash = sha256.convert(utf8.encode(combined));
      deviceId = hash.toString();

      await storage.write(key: 'secure_device_id', value: deviceId);
    }

    return deviceId;
  } catch (e) {
    debugPrint('Error getting secure device ID: $e');
    // Ultimate fallback
    return 'fallback_device_id_${Random().nextInt(999999)}';
  }
}
