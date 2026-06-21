import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
  retrying,
  offline
}

class SyncStatusData {
  final SyncStatus status;
  final int queueSize;
  final int successfulSyncs;
  final int failedSyncs;
  final DateTime lastSyncAttempt;
  final String? lastError;
  final Map<String, int> dataTypeCounts;

  SyncStatusData({
    required this.status,
    required this.queueSize,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.lastSyncAttempt,
    this.lastError,
    required this.dataTypeCounts,
  });

  double get successRate {
    final total = successfulSyncs + failedSyncs;
    return total > 0 ? successfulSyncs / total : 1.0;
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'queue_size': queueSize,
    'successful_syncs': successfulSyncs,
    'failed_syncs': failedSyncs,
    'last_sync_attempt': lastSyncAttempt.toIso8601String(),
    'last_error': lastError,
    'data_type_counts': dataTypeCounts,
    'success_rate': successRate,
  };
}

class SyncStatusMonitor {
  static final SyncStatusMonitor _instance = SyncStatusMonitor._internal();
  factory SyncStatusMonitor() => _instance;
  SyncStatusMonitor._internal();

  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  final ConnectivityService _connectivityService = locator<ConnectivityService>();

  Timer? _monitoringTimer;
  final StreamController<SyncStatusData> _statusController = StreamController<SyncStatusData>.broadcast();
  
  SyncStatus _currentStatus = SyncStatus.idle;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  DateTime _lastSyncAttempt = DateTime.now();
  String? _lastError;
  final Map<String, int> _dataTypeCounts = {};

  Stream<SyncStatusData> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;

  Future<void> initialize() async {
    await _loadStoredStats();
    _startMonitoring();
    debugPrint('SyncStatusMonitor initialized');
  }

  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateStatus());
    
    // Initial status update
    _updateStatus();
  }

  Future<void> _updateStatus() async {
    try {
      // Check connectivity
      final networkStatus = await _connectivityService.checkConnectivity();
      if (networkStatus == NetworkStatus.offline) {
        _updateCurrentStatus(SyncStatus.offline);
        return;
      }

      // Get queue status from database
      final pendingItems = await _databaseService.getPendingSyncItems(limit: 1000);
      final queueSize = pendingItems.length;

      // Count data types
      _dataTypeCounts.clear();
      for (final item in pendingItems) {
        _dataTypeCounts[item.type] = (_dataTypeCounts[item.type] ?? 0) + 1;
      }

      // Determine current status
      if (queueSize == 0) {
        _updateCurrentStatus(SyncStatus.idle);
      } else if (_currentStatus == SyncStatus.syncing) {
        // Keep syncing status if actively syncing
      } else {
        _updateCurrentStatus(SyncStatus.completed);
      }

      // Emit status update
      final statusData = SyncStatusData(
        status: _currentStatus,
        queueSize: queueSize,
        successfulSyncs: _successfulSyncs,
        failedSyncs: _failedSyncs,
        lastSyncAttempt: _lastSyncAttempt,
        lastError: _lastError,
        dataTypeCounts: Map.from(_dataTypeCounts),
      );

      _statusController.add(statusData);

      // Send status to server via WebSocket
      if (_webSocketService.isConnected) {
        _webSocketService.sendStatusUpdate(
          batteryLevel: 100, // Will be updated by battery service
          isCharging: false,  // Will be updated by battery service
          securityStatus: {
            'sync_status': statusData.toJson(),
          },
        );
      }

      // Store stats periodically
      await _storeStats();

    } catch (e) {
      debugPrint('Error updating sync status: $e');
      _updateCurrentStatus(SyncStatus.failed, error: e.toString());
    }
  }

  void _updateCurrentStatus(SyncStatus status, {String? error}) {
    _currentStatus = status;
    _lastSyncAttempt = DateTime.now();
    
    if (error != null) {
      _lastError = error;
    }

    debugPrint('Sync status updated: ${status.name}');
  }

  // Called by DataCollectorService when sync starts
  void onSyncStarted() {
    _updateCurrentStatus(SyncStatus.syncing);
    _updateStatus();
  }

  // Called by DataCollectorService when sync completes successfully
  void onSyncCompleted(int itemCount, String dataType) {
    _successfulSyncs += itemCount;
    _updateCurrentStatus(SyncStatus.completed);
    _updateStatus();
    
    debugPrint('Sync completed: $itemCount $dataType items');
  }

  // Called by DataCollectorService when sync fails
  void onSyncFailed(String dataType, String error) {
    _failedSyncs++;
    _updateCurrentStatus(SyncStatus.failed, error: error);
    _updateStatus();
    
    debugPrint('Sync failed for $dataType: $error');
  }

  // Called by DataCollectorService when retrying
  void onSyncRetry(String dataType) {
    _updateCurrentStatus(SyncStatus.retrying);
    _updateStatus();
    
    debugPrint('Retrying sync for $dataType');
  }

  Future<void> _loadStoredStats() async {
    try {
      final statsJson = _storageService.getString('sync_stats');
      if (statsJson != null) {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        _successfulSyncs = stats['successful_syncs'] ?? 0;
        _failedSyncs = stats['failed_syncs'] ?? 0;
        
        final lastAttemptStr = stats['last_sync_attempt'] as String?;
        if (lastAttemptStr != null) {
          _lastSyncAttempt = DateTime.parse(lastAttemptStr);
        }
        
        _lastError = stats['last_error'] as String?;
      }
    } catch (e) {
      debugPrint('Error loading sync stats: $e');
    }
  }

  Future<void> _storeStats() async {
    try {
      final stats = {
        'successful_syncs': _successfulSyncs,
        'failed_syncs': _failedSyncs,
        'last_sync_attempt': _lastSyncAttempt.toIso8601String(),
        'last_error': _lastError,
      };
      
      await _storageService.setString('sync_stats', jsonEncode(stats));
    } catch (e) {
      debugPrint('Error storing sync stats: $e');
    }
  }

  // Get detailed sync report
  Future<Map<String, dynamic>> getSyncReport() async {
    try {
      final pendingItems = await _databaseService.getPendingSyncItems(limit: 1000);
      final totalPending = pendingItems.length;
      
      // Group by data type
      final pendingByType = <String, int>{};
      for (final item in pendingItems) {
        pendingByType[item.type] = (pendingByType[item.type] ?? 0) + 1;
      }

      // Calculate health metrics
      final total = _successfulSyncs + _failedSyncs;
      final successRate = total > 0 ? _successfulSyncs / total : 1.0;
      final isHealthy = successRate >= 0.8 && totalPending < 100;

      return {
        'status': _currentStatus.name,
        'is_healthy': isHealthy,
        'total_pending': totalPending,
        'pending_by_type': pendingByType,
        'successful_syncs': _successfulSyncs,
        'failed_syncs': _failedSyncs,
        'success_rate': successRate,
        'last_sync_attempt': _lastSyncAttempt.toIso8601String(),
        'last_error': _lastError,
        'monitoring_active': _monitoringTimer?.isActive ?? false,
      };
    } catch (e) {
      debugPrint('Error generating sync report: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Reset statistics (for testing/maintenance)
  Future<void> resetStats() async {
    _successfulSyncs = 0;
    _failedSyncs = 0;
    _lastError = null;
    _lastSyncAttempt = DateTime.now();
    _dataTypeCounts.clear();
    
    await _storeStats();
    await _updateStatus();
    
    debugPrint('Sync statistics reset');
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _statusController.close();
    debugPrint('SyncStatusMonitor disposed');
  }
}