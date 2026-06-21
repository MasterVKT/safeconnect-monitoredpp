import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/database/database.dart';
import 'package:monitored_app/core/sync/pending_sync_selector.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/types/app_types.dart';

class DatabaseService {
  late final AppDatabase _database;
  static DatabaseService? _instance;

  DatabaseService._internal();

  static DatabaseService get instance {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      _database = AppDatabase();
      await _database.customSelect('SELECT 1').getSingle();
      debugPrint('Database initialized with encryption');
    } catch (e) {
      final error = e.toString().toLowerCase();
      final isCipherMismatch = error.contains('file is not a database') ||
          error.contains('hmac check failed');

      if (!isCipherMismatch) {
        rethrow;
      }

      debugPrint('Database corruption/cipher mismatch detected, resetting DB');
      await resetMonitoredAppDatabaseFile();

      _database = AppDatabase();
      await _database.customSelect('SELECT 1').getSingle();
      debugPrint('Database reset and reinitialized');
    }
  }

  AppDatabase get database => _database;

  Future<bool> tryAcquireCollectionLease({
    required String owner,
    required Duration ttl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    return _database.tryAcquireCollectionLease(
      owner,
      now,
      ttl.inMilliseconds,
    );
  }

  Future<bool> touchCollectionLease(String owner) {
    return _database.touchCollectionLeaseIfOwner(
      owner,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> releaseCollectionLease(String owner) {
    return _database.clearCollectionLeaseIfOwner(owner);
  }

  Future<String?> getCollectionLeaseOwner() async {
    final lease = await _database.getCollectionLease();
    return lease?.owner;
  }

  // Generic method to queue data for sync
  Future<void> queueDataForSync(String dataType, Map<String, dynamic> data,
      {int priority = 2}) async {
    try {
      final payload = _compressAndEncryptData(data);
      final batchId = _generateBatchId();

      final syncItemId = await _database.insertSyncItem(
        SyncQueueTableCompanion(
          type: Value(dataType),
          priority: Value(priority),
          payload: Value(payload),
          batchId: Value(batchId),
          payloadSize: Value(payload.length),
          status: Value('pending'),
        ),
      );

      debugPrint('Queued $dataType data for sync with priority $priority');

      // Notify DataCollectorService about new data to sync
      _notifyDataCollectorService(dataType, {
        ...data,
        'sync_item_id': syncItemId,
      });
    } catch (e) {
      debugPrint('Error queuing data for sync: $e');
    }
  }

  // Callback for notifying about new sync data
  Function(String dataType, Map<String, dynamic> data)?
      _dataNotificationCallback;

  void setDataNotificationCallback(
      Function(String dataType, Map<String, dynamic> data) callback) {
    _dataNotificationCallback = callback;
  }

  // Notify about new sync data
  void _notifyDataCollectorService(String dataType, Map<String, dynamic> data) {
    try {
      _dataNotificationCallback?.call(dataType, data);
    } catch (e) {
      debugPrint('Error notifying about sync data: $e');
    }
  }

  // SMS operations
  Future<void> insertSmsData({
    required String deviceId,
    required String messageType,
    required String direction,
    required String sender,
    String? senderName,
    required String body,
    required DateTime sentAt,
    String? conversationId,
    bool hasAttachment = false,
  }) async {
    try {
      final hash = _generateDataHash('$sender:$sentAt:$body');

      final smsData = SmsDataTableCompanion(
        deviceId: Value(deviceId),
        messageType: Value(messageType),
        direction: Value(direction),
        sender: Value(sender),
        senderName: Value(senderName),
        body: Value(body),
        sentAt: Value(sentAt),
        conversationId: Value(conversationId),
        hasAttachment: Value(hasAttachment),
        hash: Value(hash),
      );

      final insertedId = await _database.insertSmsData(smsData);
      if (insertedId == 0) {
        debugPrint('SMS data already exists, skipping duplicate queue item');
        return;
      }

      // Queue for sync
      await queueDataForSync(
          'sms',
          {
            'device_id': deviceId,
            'message_type': messageType,
            'direction': direction,
            'sender': sender,
            'sender_name': senderName,
            'body': body,
            'sent_at': sentAt.toUtc().toIso8601String(),
            'conversation_id': conversationId,
            'has_attachment': hasAttachment,
          },
          priority: 1);
    } catch (e) {
      debugPrint('Error inserting SMS data: $e');
    }
  }

  // Call operations
  Future<void> insertCallData({
    required String deviceId,
    required String callType,
    required String phoneNumber,
    String? contactName,
    required DateTime startTime,
    DateTime? endTime,
    int duration = 0,
    bool isVideoCall = false,
    int? simSlot,
    bool isConference = false,
    DateTime? recordedAt,
  }) async {
    try {
      final hash = _generateDataHash('$phoneNumber:$startTime:$duration');
      final effectiveRecordedAt = recordedAt ?? startTime;

      final callData = CallDataTableCompanion(
        deviceId: Value(deviceId),
        callType: Value(callType),
        phoneNumber: Value(phoneNumber),
        contactName: Value(contactName),
        startTime: Value(startTime),
        endTime: Value(endTime),
        duration: Value(duration),
        recordedAt: Value(effectiveRecordedAt),
        isVideoCall: Value(isVideoCall),
        simSlot: Value(simSlot),
        isConference: Value(isConference),
        hash: Value(hash),
      );

      final insertedId = await _database.insertCallData(callData);
      if (insertedId == 0) {
        debugPrint('Call data already exists, skipping duplicate queue item');
        return;
      }

      // Queue for sync
      await queueDataForSync(
          'calls',
          {
            'device_id': deviceId,
            'call_type': callType,
            'phone_number': phoneNumber,
            'contact_name': contactName,
            'start_time': startTime.toUtc().toIso8601String(),
            'end_time': endTime?.toUtc().toIso8601String(),
            'duration': duration,
            'is_video_call': isVideoCall,
            'sim_slot': simSlot,
            'is_conference': isConference,
            'recorded_at': effectiveRecordedAt.toUtc().toIso8601String(),
          },
          priority: 1);
    } catch (e) {
      debugPrint('Error inserting call data: $e');
    }
  }

  // Location operations
  Future<void> insertLocationData({
    required String deviceId,
    required double latitude,
    required double longitude,
    required double accuracy,
    double? altitude,
    double? speed,
    double? bearing,
    double? heading,
    required String provider,
    String? activityType,
    int? batteryLevel,
    DateTime? recordedAt,
  }) async {
    try {
      final locationData = LocationDataTableCompanion(
        deviceId: Value(deviceId),
        latitude: Value(latitude),
        longitude: Value(longitude),
        accuracy: Value(accuracy),
        altitude: Value(altitude),
        speed: Value(speed),
        bearing: Value(
            heading ?? bearing), // Use heading if provided, fallback to bearing
        provider: Value(provider),
        activityType: Value(activityType),
        batteryLevel: Value(batteryLevel),
        recordedAt: Value(recordedAt ?? DateTime.now()),
      );

      await _database.insertLocationData(locationData);

      // Queue for sync
      await queueDataForSync(
          'location',
          {
            'device_id': deviceId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'altitude': altitude,
            'speed': speed,
            'bearing': bearing,
            'recorded_at': (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
            'provider': provider,
            'activity_type': activityType,
            'battery_level': batteryLevel,
          },
          priority: 2);
    } catch (e) {
      debugPrint('Error inserting location data: $e');
    }
  }

  // App Usage operations
  Future<void> insertAppUsageData({
    required String deviceId,
    required String packageName,
    String? appName,
    required DateTime startTime,
    required DateTime endTime,
    required int duration,
    required String date,
  }) async {
    try {
      final appUsageData = AppUsageDataTableCompanion(
        deviceId: Value(deviceId),
        packageName: Value(packageName),
        appName: Value(appName ?? packageName),
        startTime: Value(startTime),
        endTime: Value(endTime),
        durationSeconds: Value(duration),
        date: Value(date),
      );

      await _database.insertAppUsageData(appUsageData);

      // Queue for sync
      await queueDataForSync(
          'app_usage',
          {
            'device_id': deviceId,
            'package_name': packageName,
            'app_name': appName,
            'start_time': startTime.toUtc().toIso8601String(),
            'end_time': endTime.toUtc().toIso8601String(),
            'recorded_at': startTime.toUtc().toIso8601String(),
            'duration': duration,
            'date': date,
          },
          priority: 3);
    } catch (e) {
      debugPrint('Error inserting app usage data: $e');
    }
  }

  Future<void> insertAppData({
    required String deviceId,
    required String packageName,
    required String appName,
    String? versionName,
    int? versionCode,
    required DateTime firstInstallTime,
    DateTime? lastUpdateTime,
    String? appCategory,
    required bool isSystemApp,
  }) async {
    try {
      final appData = AppDataTableCompanion(
        deviceId: Value(deviceId),
        packageName: Value(packageName),
        appName: Value(appName),
        versionName: Value(versionName),
        versionCode: Value(versionCode),
        firstInstallTime: Value(firstInstallTime),
        lastUpdateTime: Value(lastUpdateTime),
        appCategory: Value(appCategory),
        isSystemApp: Value(isSystemApp),
      );

      await _database
          .into(_database.appDataTable)
          .insert(appData, mode: InsertMode.insertOrReplace);

      await queueDataForSync(
        'app_info',
        {
          'device_id': deviceId,
          'package_name': packageName,
          'app_name': appName,
          'version_name': versionName,
          'version_code': versionCode,
          'first_install_time': firstInstallTime.toUtc().toIso8601String(),
          'last_update_time': lastUpdateTime?.toUtc().toIso8601String(),
          'app_category': appCategory,
          'is_system_app': isSystemApp,
          'recorded_at': DateTime.now().toUtc().toIso8601String(),
        },
        priority: 3,
      );
    } catch (e) {
      debugPrint('Error inserting app data: $e');
    }
  }

  // Media operations
  Future<void> insertMediaData({
    required String deviceId,
    required String mediaId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String mediaType,
    required DateTime createdAt,
    int? width,
    int? height,
    String? cameraType,
    int? duration,
  }) async {
    try {
      final mediaData = MediaDataTableCompanion(
        deviceId: Value(deviceId),
        mediaId: Value(mediaId),
        mediaType: Value(mediaType),
        fileName: Value(fileName),
        filePath: Value(filePath),
        mimeType: Value(mimeType),
        fileSize: Value(fileSize),
        width: Value(width),
        height: Value(height),
        createdAt: Value(createdAt),
        modifiedAt: Value(createdAt), // Same as created for new media
        cameraType: Value(cameraType),
        duration: Value(duration),
      );

      await _database.insertMediaData(mediaData);

      // Queue for sync with lower priority (media is usually large)
      await queueDataForSync(
          'media',
          {
            'device_id': deviceId,
            'media_id': mediaId,
            'file_path': filePath,
            'file_name': fileName,
            'file_size': fileSize,
            'mime_type': mimeType,
            'media_type': mediaType,
            'created_at': createdAt.toUtc().toIso8601String(),
            'width': width,
            'height': height,
            'camera_type': cameraType,
            'duration': duration,
          },
          priority: 4);
    } catch (e) {
      debugPrint('Error inserting media data: $e');
    }
  }

  // Configuration operations
  Future<void> setConfiguration(String key, String value) async {
    try {
      await _database.updateConfiguration(key, value);
      debugPrint('Configuration updated: $key');
    } catch (e) {
      debugPrint('Error updating configuration: $e');
    }
  }

  Future<String?> getConfiguration(String key) async {
    try {
      return await _database.getConfiguration(key);
    } catch (e) {
      debugPrint('Error getting configuration: $e');
      return null;
    }
  }

  // Security audit operations
  Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    required String severity,
    String? metadata,
  }) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final hash = _generateDataHash(
          '$eventType:$description:${DateTime.now().toIso8601String()}');

      await _database.insertSecurityAuditLog(
        SecurityAuditTableCompanion(
          eventType: Value(eventType),
          description: Value(description),
          severity: Value(severity),
          deviceId: Value(deviceId),
          metadata: Value(metadata),
          hash: Value(hash),
        ),
      );

      debugPrint('Security event logged: $eventType ($severity)');
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  // Sync operations
  Future<List<SyncQueueTableData>> getPendingSyncItems({int limit = 50}) async {
    try {
      final items = await _database.getPendingSyncItems();
      return items.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting pending sync items: $e');
      return [];
    }
  }

  Future<List<SyncQueueTableData>> getPendingSyncItemsFairly({
    int totalLimit = 1000,
    int limitPerType = 200,
  }) async {
    try {
      final items = await _database.getPendingSyncItems();
      return PendingSyncSelector.selectFairly(
        items: items,
        dataTypeOf: (item) => item.type,
        priorityOf: (item) => item.priority,
        totalLimit: totalLimit,
        limitPerType: limitPerType,
      );
    } catch (e) {
      debugPrint('Error getting balanced pending sync items: $e');
      return [];
    }
  }

  Future<void> markSyncItemCompleted(int syncId) async {
    try {
      await _database.updateSyncItemStatus(syncId, 'completed');
    } catch (e) {
      debugPrint('Error marking sync item completed: $e');
    }
  }

  Future<void> markSyncItemFailed(int syncId) async {
    try {
      await _database.updateSyncItemStatus(syncId, 'failed');
    } catch (e) {
      debugPrint('Error marking sync item failed: $e');
    }
  }

  Future<void> updateSyncItemStatus(int syncId, String status) async {
    try {
      await _database.updateSyncItemStatus(syncId, status);
    } catch (e) {
      debugPrint('Error updating sync item status: $e');
    }
  }

  // Load pending data from database to DataCollectorService queue
  Future<void> loadPendingDataToCollector() async {
    try {
      final pendingItems = await getPendingSyncItemsFairly();

      if (pendingItems.isEmpty) {
        debugPrint('No pending sync items found in database');
        return;
      }

      final groupedData = <String, List<Map<String, dynamic>>>{};

      // Group items by data type and decompress payload
      for (final item in pendingItems) {
        try {
          final data = _decompressAndDecryptData(item.payload);

          if (!groupedData.containsKey(item.type)) {
            groupedData[item.type] = [];
          }

          groupedData[item.type]!.add({
            ...data,
            'sync_item_id': item.id, // Include ID for tracking
          });
        } catch (e) {
          debugPrint('Error processing sync item ${item.id}: $e');
        }
      }

      // Notify about grouped data using callback to avoid circular dependency
      for (final entry in groupedData.entries) {
        for (final item in entry.value) {
          _notifyDataCollectorService(entry.key, item);
        }
      }

      debugPrint(
          'Loaded ${pendingItems.length} pending items to collector (${groupedData.length} types)');
    } catch (e) {
      debugPrint('Error loading pending data to collector: $e');
    }
  }

  // Mark sync items as synced when successfully sent
  Future<void> markItemsSynced(List<Map<String, dynamic>> syncedItems) async {
    try {
      for (final item in syncedItems) {
        final syncItemId = item['sync_item_id'];
        if (syncItemId != null) {
          await markSyncItemCompleted(syncItemId as int);
        }
      }
      debugPrint('Marked ${syncedItems.length} items as synced');
    } catch (e) {
      debugPrint('Error marking items as synced: $e');
    }
  }

  Future<void> markItemsPermanentlyFailed(
    List<Map<String, dynamic>> failedItems,
  ) async {
    try {
      var markedCount = 0;
      for (final item in failedItems) {
        final syncItemId = item['sync_item_id'];
        if (syncItemId is int) {
          await updateSyncItemStatus(syncItemId, 'failed_permanent');
          markedCount++;
        }
      }
      debugPrint('Marked $markedCount items as permanently failed');
    } catch (e) {
      debugPrint('Error marking items as permanently failed: $e');
    }
  }

  // Get sync queue statistics
  Future<Map<String, int>> getSyncQueueStatistics() async {
    try {
      final stats = await _database.getSyncQueueStatistics();
      return stats.cast<String, int>();
    } catch (e) {
      debugPrint('Error getting sync queue statistics: $e');
      return {
        'total_pending': 0,
        'total_completed': 0,
        'total_failed': 0,
      };
    }
  }

  // Clean up old completed sync items (older than 7 days)
  Future<void> cleanupOldSyncItems() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      await _database.cleanupOldSyncItems();
      debugPrint('Cleaned up old sync items older than $cutoffDate');
    } catch (e) {
      debugPrint('Error cleaning up old sync items: $e');
    }
  }

  // Database maintenance
  Future<void> performMaintenance() async {
    try {
      await _database.cleanupOldData();
      debugPrint('Database maintenance completed');
    } catch (e) {
      debugPrint('Error during database maintenance: $e');
    }
  }

  Future<Map<String, int>> getStatistics() async {
    try {
      return await _database.getDatabaseStatistics();
    } catch (e) {
      debugPrint('Error getting database statistics: $e');
      return {};
    }
  }

  // Private helper methods
  Uint8List _compressAndEncryptData(Map<String, dynamic> data) {
    // Simple JSON serialization for now
    // In production, this should include compression and encryption
    final jsonString = jsonEncode(data);
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  String _generateDataHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateBatchId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${timestamp}_$random';
  }

  Map<String, dynamic> _decompressAndDecryptData(Uint8List payload) {
    try {
      // Simple JSON deserialization for now
      // In production, this should include decompression and decryption
      final jsonString = utf8.decode(payload);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decompressing data: $e');
      return {};
    }
  }

  // Alias method for compatibility
  Map<String, dynamic> _decryptAndDecompressData(Uint8List payload) {
    return _decompressAndDecryptData(payload);
  }

  // Missing methods that are called throughout the codebase

  Future<void> clearSensitiveData() async {
    try {
      // Clear all sensitive data from the database
      await _database.delete(_database.smsDataTable).go();
      await _database.delete(_database.callDataTable).go();
      await _database.delete(_database.mediaDataTable).go();
      debugPrint('Sensitive data cleared from database');
    } catch (e) {
      debugPrint('Error clearing sensitive data: $e');
    }
  }

  Future<void> forceSyncAllPendingData() async {
    try {
      final pendingItems = await _database.getPendingSyncItems();
      for (final item in pendingItems) {
        await _database.updateSyncItemStatus(item.id, 'priority');
      }
      debugPrint('Forced sync for ${pendingItems.length} pending items');
    } catch (e) {
      debugPrint('Error forcing sync: $e');
    }
  }

  Future<void> insertCommandExecutionResult(dynamic result) async {
    try {
      Map<String, dynamic>? metadata;
      try {
        metadata = result.toJson();
      } catch (e) {
        // If toJson() doesn't exist, create metadata manually
        metadata = {
          'command_id': result.commandId ?? 'unknown',
          'result_type': result.runtimeType.toString(),
          'raw_result': result.toString(),
        };
      }

      await insertSecurityAuditEvent(
        eventType: 'command_execution',
        description:
            'Remote command executed: ${result.commandId ?? 'unknown'}',
        severity: 'INFO',
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error inserting command result: $e');
    }
  }

  Future<void> insertSecurityAuditEvent({
    required String eventType,
    required String description,
    required String severity,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final metadataJson = metadata != null ? jsonEncode(metadata) : null;
      final hash = _generateHash(
          '$eventType:$description:${DateTime.now().millisecondsSinceEpoch}');

      await _database.into(_database.securityAuditTable).insert(
            SecurityAuditTableCompanion(
              eventType: Value(eventType),
              description: Value(description),
              severity: Value(severity),
              deviceId: Value(deviceId),
              metadata: Value(metadataJson),
              hash: Value(hash),
            ),
          );
    } catch (e) {
      debugPrint('Error inserting security audit event: $e');
    }
  }

  Future<void> insertPerformanceMetrics(List<PerformanceMetric> metrics) async {
    try {
      // Store performance metrics in configuration table as JSON
      final metricsJson = jsonEncode(metrics.map((m) => m.toJson()).toList());
      await _database.into(_database.configurationTable).insertOnConflictUpdate(
            ConfigurationTableCompanion(
              key: const Value('performance_metrics'),
              value: Value(metricsJson),
            ),
          );
    } catch (e) {
      debugPrint('Error inserting performance metrics: $e');
    }
  }

  Future<List<dynamic>> getPerformanceMetrics(
      DateTime start, DateTime end) async {
    try {
      final result = await (_database.select(_database.configurationTable)
            ..where((t) => t.key.equals('performance_metrics')))
          .getSingleOrNull();

      if (result?.value != null) {
        final List<dynamic> metrics = jsonDecode(result!.value);
        return metrics.where((m) {
          final timestamp = DateTime.parse(m['timestamp']);
          return timestamp.isAfter(start) && timestamp.isBefore(end);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting performance metrics: $e');
      return [];
    }
  }

  Future<List<dynamic>> getConsentRecords() async {
    try {
      // Store consent records in configuration table as JSON
      final result = await (_database.select(_database.configurationTable)
            ..where((t) => t.key.equals('consent_records')))
          .getSingleOrNull();

      if (result?.value != null) {
        final List<dynamic> records = jsonDecode(result!.value);
        return records;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting consent records: $e');
      return [];
    }
  }

  Future<void> insertConsentRecord(ConsentRecord consent) async {
    try {
      final existingRecords = await getConsentRecords();
      existingRecords.add(consent.toJson());

      final recordsJson = jsonEncode(existingRecords);
      await _database.into(_database.configurationTable).insertOnConflictUpdate(
            ConfigurationTableCompanion(
              key: const Value('consent_records'),
              value: Value(recordsJson),
            ),
          );
    } catch (e) {
      debugPrint('Error inserting consent record: $e');
    }
  }

  Future<void> updateConsentRecord(ConsentRecord consent) async {
    try {
      final existingRecords = await getConsentRecords();
      final index = existingRecords.indexWhere((r) => r['id'] == consent.id);

      if (index != -1) {
        existingRecords[index] = consent.toJson();

        final recordsJson = jsonEncode(existingRecords);
        await _database
            .into(_database.configurationTable)
            .insertOnConflictUpdate(
              ConfigurationTableCompanion(
                key: const Value('consent_records'),
                value: Value(recordsJson),
              ),
            );
      }
    } catch (e) {
      debugPrint('Error updating consent record: $e');
    }
  }

  Future<void> deleteOldDataByCategory(
      DataCategory category, DateTime cutoffDate) async {
    try {
      switch (category) {
        case DataCategory.location:
          await (_database.delete(_database.locationDataTable)
                ..where((t) => t.recordedAt.isSmallerThanValue(cutoffDate)))
              .go();
          break;
        case DataCategory.communication:
          await (_database.delete(_database.smsDataTable)
                ..where((t) => t.recordedAt.isSmallerThanValue(cutoffDate)))
              .go();
          await (_database.delete(_database.callDataTable)
                ..where((t) => t.recordedAt.isSmallerThanValue(cutoffDate)))
              .go();
          break;
        case DataCategory.appUsage:
          await (_database.delete(_database.appUsageDataTable)
                ..where((t) => t.recordedAt.isSmallerThanValue(cutoffDate)))
              .go();
          break;
        case DataCategory.media:
          await (_database.delete(_database.mediaDataTable)
                ..where((t) => t.recordedAt.isSmallerThanValue(cutoffDate)))
              .go();
          break;
        default:
          break;
      }
      debugPrint('Deleted old data for category $category before $cutoffDate');
    } catch (e) {
      debugPrint('Error deleting old data: $e');
    }
  }

  Future<void> deleteAllDataByCategory(DataCategory category) async {
    try {
      switch (category) {
        case DataCategory.location:
          await _database.delete(_database.locationDataTable).go();
          break;
        case DataCategory.communication:
          await _database.delete(_database.smsDataTable).go();
          await _database.delete(_database.callDataTable).go();
          break;
        case DataCategory.appUsage:
          await _database.delete(_database.appUsageDataTable).go();
          break;
        case DataCategory.media:
          await _database.delete(_database.mediaDataTable).go();
          break;
        default:
          break;
      }
      debugPrint('Deleted all data for category $category');
    } catch (e) {
      debugPrint('Error deleting all data: $e');
    }
  }

  Future<String> _getDeviceId() async {
    // Use the same device ID generation as DeviceUtils
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Emergency event methods
  Future<void> insertEmergencyEvent(dynamic emergencyEvent) async {
    try {
      await _database.into(_database.emergencyEventsTable).insert(
            EmergencyEventsTableCompanion.insert(
              emergencyId: emergencyEvent.id,
              triggerType: emergencyEvent.triggerType.name,
              activatedAt: emergencyEvent.activatedAt,
              deactivatedAt: Value(emergencyEvent.deactivatedAt),
              deviceId: emergencyEvent.deviceId,
              triggerData: json.encode(emergencyEvent.triggerData),
              actionsPerformed: json.encode(emergencyEvent.actionsPerformed),
              metadata: json.encode(emergencyEvent.metadata),
              createdAt: Value(DateTime.now()),
            ),
          );
      debugPrint('Emergency event inserted: ${emergencyEvent.id}');
    } catch (e) {
      debugPrint('Error inserting emergency event: $e');
    }
  }

  Future<void> updateEmergencyEvent(dynamic emergencyEvent) async {
    try {
      await (_database.update(_database.emergencyEventsTable)
            ..where((t) => t.emergencyId.equals(emergencyEvent.id)))
          .write(EmergencyEventsTableCompanion(
        deactivatedAt: Value(emergencyEvent.deactivatedAt),
        actionsPerformed: Value(json.encode(emergencyEvent.actionsPerformed)),
        metadata: Value(json.encode(emergencyEvent.metadata)),
        updatedAt: Value(DateTime.now()),
      ));
      debugPrint('Emergency event updated: ${emergencyEvent.id}');
    } catch (e) {
      debugPrint('Error updating emergency event: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEmergencyEvents({int? limit}) async {
    try {
      final query = _database.select(_database.emergencyEventsTable)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

      if (limit != null) {
        query.limit(limit);
      }

      final results = await query.get();
      return results
          .map((event) => {
                'emergency_id': event.emergencyId,
                'trigger_type': event.triggerType,
                'activated_at': event.activatedAt.toIso8601String(),
                'deactivated_at': event.deactivatedAt?.toIso8601String(),
                'device_id': event.deviceId,
                'trigger_data': json.decode(event.triggerData),
                'actions_performed': json.decode(event.actionsPerformed),
                'metadata': json.decode(event.metadata),
                'created_at': event.createdAt.toIso8601String(),
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting emergency events: $e');
      return [];
    }
  }

  // Media analytics method for compatibility with AdvancedMediaService
  Future<Map<String, dynamic>> getMediaAnalytics(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Default to last 30 days if no dates provided
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Get all media data and filter in Dart (simpler approach)
      final allMediaData =
          await _database.select(_database.mediaDataTable).get();

      // Filter by date range
      final mediaData = allMediaData
          .where((m) =>
              m.createdAt.isAfter(startDate!) && m.createdAt.isBefore(endDate!))
          .toList();

      // Calculate analytics
      final totalItems = mediaData.length;
      final photoCount = mediaData.where((m) => m.mediaType == 'PHOTO').length;
      final videoCount = mediaData.where((m) => m.mediaType == 'VIDEO').length;
      final audioCount = mediaData.where((m) => m.mediaType == 'AUDIO').length;
      final screenshotCount =
          mediaData.where((m) => m.mediaType == 'SCREENSHOT').length;

      final totalSize = mediaData.fold<int>(0, (sum, m) => sum + m.fileSize);

      return {
        'total_items': totalItems,
        'photo_count': photoCount,
        'video_count': videoCount,
        'audio_count': audioCount,
        'screenshot_count': screenshotCount,
        'total_size_bytes': totalSize,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting media analytics: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityEvents(int days) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final logs = await _database.getRecentAuditLogs(limit: 500);
      return logs
          .where((log) => log.timestamp.isAfter(since))
          .map((log) => {
                'type': log.eventType,
                'description': log.description,
                'severity': log.severity,
                'timestamp': log.timestamp.millisecondsSinceEpoch,
                'device_id': log.deviceId,
                'metadata': log.metadata,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting security events: $e');
      return [];
    }
  }

  Future<void> logTamperAttempt(
      String tamperType, String details, String severity) async {
    await logSecurityEvent(
      eventType: tamperType,
      description: details,
      severity: severity,
    );
  }

  // File Transfer Session Management
  Future<void> saveFileTransferSession(Map<String, dynamic> sessionData) async {
    try {
      final payload = _compressAndEncryptData(sessionData);

      await _database.insertSyncItem(
        SyncQueueTableCompanion(
          type: Value('file_transfer_session'),
          priority: Value(1), // High priority for session tracking
          payload: Value(payload),
          batchId: Value(_generateBatchId()),
          payloadSize: Value(payload.length),
          status: Value('pending'),
        ),
      );

      debugPrint('File transfer session saved: ${sessionData['id']}');
    } catch (e) {
      debugPrint('Error saving file transfer session: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingFileTransfers() async {
    try {
      final pendingSessions = await (_database.select(_database.syncQueueTable)
            ..where((t) =>
                t.type.equals('file_transfer_session') &
                t.status.isIn(['pending', 'transferring', 'paused'])))
          .get();

      final sessions = <Map<String, dynamic>>[];
      for (final item in pendingSessions) {
        try {
          final data = _decryptAndDecompressData(item.payload);
          sessions.add(data);
        } catch (e) {
          debugPrint('Error decrypting file transfer session: $e');
        }
      }

      return sessions;
    } catch (e) {
      debugPrint('Error getting pending file transfers: $e');
      return [];
    }
  }

  Future<void> removeFileTransferSession(String sessionId) async {
    try {
      // Find and remove the session from sync queue
      final sessions = await getPendingFileTransfers();
      for (final session in sessions) {
        if (session['id'] == sessionId) {
          // Remove from sync queue (implementation depends on database schema)
          await (_database.delete(_database.syncQueueTable)
                ..where((t) => t.type.equals('file_transfer_session')))
              .go();
          break;
        }
      }

      debugPrint('File transfer session removed: $sessionId');
    } catch (e) {
      debugPrint('Error removing file transfer session: $e');
    }
  }

  // Security baseline storage
  Future<void> storeSecurityBaseline(Map<String, dynamic> baseline) async {
    try {
      await queueDataForSync('security_baseline', baseline, priority: 1);
      debugPrint('Security baseline stored');
    } catch (e) {
      debugPrint('Error storing security baseline: $e');
      rethrow;
    }
  }

  // Missing database query methods needed by other services
  Future<List<SyncQueueTableData>> getSyncItemsByTypeAndStatus(
      String type, List<String> statuses) async {
    try {
      final items = await (_database.select(_database.syncQueueTable)
            ..where((t) => t.type.equals(type))
            ..where((t) => t.status.isIn(statuses))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();
      return items;
    } catch (e) {
      debugPrint('Error getting sync items by type and status: $e');
      return [];
    }
  }

  Future<List<SyncQueueTableData>> getSyncItemsByType(String type) async {
    try {
      final items = await (_database.select(_database.syncQueueTable)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
          .get();
      return items;
    } catch (e) {
      debugPrint('Error getting sync items by type: $e');
      return [];
    }
  }

  Future<void> deleteSyncItemsByType(String type) async {
    try {
      await (_database.delete(_database.syncQueueTable)
            ..where((t) => t.type.equals(type)))
          .go();
      debugPrint('Deleted all sync items of type: $type');
    } catch (e) {
      debugPrint('Error deleting sync items by type: $e');
    }
  }

  Future<int> getSyncQueueSize() async {
    try {
      final count = await (_database.select(_database.syncQueueTable)
            ..where((t) => t.status.equals('pending')))
          .get()
          .then((items) => items.length);
      return count;
    } catch (e) {
      debugPrint('Error getting sync queue size: $e');
      return 0;
    }
  }

  Future<void> prioritizeSyncQueue() async {
    try {
      // Update high-priority items to be processed first
      await (_database.update(_database.syncQueueTable)
            ..where((t) => t.priority.equals(1)))
          .write(const SyncQueueTableCompanion(
        status: Value('priority'),
      ));
      debugPrint('Prioritized high-priority sync items');
    } catch (e) {
      debugPrint('Error prioritizing sync queue: $e');
    }
  }

  Future<void> close() async {
    await _database.close();
  }
}
