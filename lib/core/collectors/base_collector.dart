import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/device_service.dart';
import 'package:monitored_app/core/utils/retry_mechanism.dart';

/// Abstract base class for all data collectors
/// Provides common functionality for:
/// - Data collection management
/// - Error handling and retry logic
/// - Battery optimization
/// - Data compression and caching
/// - Permissions management
abstract class BaseCollector {
  // Core services
  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final BatteryMonitorService _batteryMonitorService = locator<BatteryMonitorService>();

  // Collection state
  bool _isCollecting = false;
  bool _isInitialized = false;
  Timer? _collectionTimer;
  Timer? _batteryCheckTimer;
  
  // Configuration
  int _collectionIntervalSeconds = 900; // Default: 15 minutes
  
  // Cache and retry management
  List<Map<String, dynamic>> _dataCache = [];
  final RetryMechanism _retryMechanism = RetryMechanism();
  
  // Abstract properties that must be implemented by subclasses
  String get collectorName;
  String get dataType;
  List<Permission> get requiredPermissions;
  
  // Abstract methods that must be implemented by subclasses
  Future<void> initializeSpecific();
  Future<bool> checkSpecificPermissions();
  Future<void> requestSpecificPermissions();
  Future<void> startSpecificCollection();
  Future<void> stopSpecificCollection();
  Future<List<Map<String, dynamic>>> collectData();
  
  // Common initialization
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing $collectorName collector');
      
      // Load configuration from storage
      await _loadConfiguration();
      
      // Check permissions
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        debugPrint('$collectorName: Required permissions not granted');
      }
      
      // Initialize cache
      await _loadCachedData();
      
      // Initialize specific collector
      await initializeSpecific();
      
      _isInitialized = true;
      debugPrint('$collectorName collector initialized successfully');
    } catch (e) {
      debugPrint('Error initializing $collectorName collector: $e');
      await _logError('initialization_error', e.toString());
    }
  }
  
  // Start data collection
  Future<void> startCollecting() async {
    if (_isCollecting || !_isInitialized) {
      debugPrint('$collectorName: Cannot start collection - already collecting or not initialized');
      return;
    }
    
    try {
      // Check permissions again
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        debugPrint('$collectorName: Cannot start collection - permissions not granted');
        return;
      }
      
      // Check battery optimization settings
      final shouldStart = await _shouldStartBasedOnBattery();
      if (!shouldStart) {
        debugPrint('$collectorName: Delaying start due to battery optimization');
        _scheduleDelayedStart();
        return;
      }
      
      // Start specific collection
      await startSpecificCollection();
      
      // Start periodic collection timer
      _startPeriodicCollection();
      
      // Start battery monitoring for adaptive behavior
      _startBatteryMonitoring();
      
      _isCollecting = true;
      debugPrint('$collectorName collector started with interval: $_collectionIntervalSeconds seconds');
      
      // Log collection start
      await _logEvent('collection_started', {
        'interval_seconds': _collectionIntervalSeconds,
        'battery_level': await _batteryMonitorService.getCurrentBatteryLevel(),
      });
      
    } catch (e) {
      debugPrint('Error starting $collectorName collector: $e');
      await _logError('start_collection_error', e.toString());
    }
  }
  
  // Stop data collection
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    try {
      // Stop timers
      _collectionTimer?.cancel();
      _batteryCheckTimer?.cancel();
      
      // Stop specific collection
      await stopSpecificCollection();
      
      // Save cached data
      await _saveCachedData();
      
      _isCollecting = false;
      debugPrint('$collectorName collector stopped');
      
      // Log collection stop
      await _logEvent('collection_stopped', {
        'cached_items': _dataCache.length,
      });
      
    } catch (e) {
      debugPrint('Error stopping $collectorName collector: $e');
      await _logError('stop_collection_error', e.toString());
    }
  }
  
  // Common permission checking
  Future<bool> checkPermissions() async {
    try {
      return await checkSpecificPermissions();
    } catch (e) {
      debugPrint('Error checking permissions for $collectorName: $e');
      return false;
    }
  }
  
  // Request permissions
  Future<bool> requestPermissions() async {
    try {
      await requestSpecificPermissions();
      return await checkSpecificPermissions();
    } catch (e) {
      debugPrint('Error requesting permissions for $collectorName: $e');
      return false;
    }
  }
  
  // Process and cache collected data
  Future<void> processData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;
    
    try {
      final deviceService = locator<DeviceService>();
      final deviceId = await deviceService.getServerDeviceId();
      final timestamp = DateTime.now();
      
      // Add metadata to each item
      final processedData = data.map((item) {
        final enriched = <String, dynamic>{
          ...item,
          'collected_at': timestamp.toUtc().toIso8601String(),
          'collector': collectorName,
          'data_type': dataType,
        };

        if (deviceId != null && deviceId.isNotEmpty) {
          enriched['device_id'] = deviceId;
        }

        return enriched;
      }).toList();
      
      // Add to cache
      _dataCache.addAll(processedData);
      
      // Compress cache if it gets too large (>1000 items)
      if (_dataCache.length > 1000) {
        await _compressCache();
      }
      
      // Store in database for persistence
      await _storeInDatabase(processedData);
      
      debugPrint('$collectorName: Processed ${data.length} items');
      
    } catch (e) {
      debugPrint('Error processing data for $collectorName: $e');
      await _logError('data_processing_error', e.toString());
    }
  }
  
  // Update collection interval
  Future<void> updateCollectionInterval(int seconds) async {
    if (seconds < 60) seconds = 60; // Minimum 1 minute
    if (seconds > 3600) seconds = 3600; // Maximum 1 hour
    
    _collectionIntervalSeconds = seconds;
    await _storageService.setInt('${collectorName}_interval_seconds', seconds);
    
    // Restart collection if currently active
    if (_isCollecting) {
      await stopCollecting();
      await startCollecting();
    }
    
    debugPrint('$collectorName: Collection interval updated to $seconds seconds');
  }
  
  // Public getter for collection status
  bool get isCollecting => _isCollecting;

  // Get collector statistics
  Map<String, dynamic> getStatistics() {
    return {
      'collector_name': collectorName,
      'data_type': dataType,
      'is_collecting': _isCollecting,
      'is_initialized': _isInitialized,
      'collection_interval_seconds': _collectionIntervalSeconds,
      'cached_items': _dataCache.length,
      'retry_attempts': _retryMechanism.currentAttempt,
    };
  }
  
  // Clear cached data
  Future<void> clearCache() async {
    _dataCache.clear();
    await _storageService.remove('${collectorName}_cached_data');
    debugPrint('$collectorName: Cache cleared');
  }
  
  // === Private Methods ===
  
  Future<void> _startPeriodicCollection() async {
    _collectionTimer = Timer.periodic(
      Duration(seconds: _collectionIntervalSeconds),
      (_) => _performCollection(),
    );
    
    // Perform initial collection
    await _performCollection();
  }
  
  Future<void> _performCollection() async {
    try {
      // Check if we should collect based on battery level
      final shouldCollect = await _shouldCollectBasedOnBattery();
      if (!shouldCollect) {
        debugPrint('$collectorName: Skipping collection due to battery optimization');
        return;
      }
      
      // Collect data using subclass implementation
      final data = await collectData();
      
      if (data.isNotEmpty) {
        await processData(data);
      }
      
    } catch (e) {
      debugPrint('Error during $collectorName collection: $e');
      await _logError('collection_error', e.toString());
    }
  }
  
  Future<void> _startBatteryMonitoring() async {
    _batteryCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _adjustForBatteryLevel(),
    );
  }
  
  Future<void> _adjustForBatteryLevel() async {
    try {
      final batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
      
      // Adjust collection interval based on battery level
      int newInterval = _collectionIntervalSeconds;
      
      if (batteryLevel <= 20) {
        // Very low battery: reduce frequency significantly
        newInterval = (_collectionIntervalSeconds * 3).clamp(900, 3600);
      } else if (batteryLevel <= 40) {
        // Low battery: reduce frequency moderately
        newInterval = (_collectionIntervalSeconds * 2).clamp(600, 3600);
      } else if (batteryLevel >= 80) {
        // High battery: can increase frequency slightly
        newInterval = (_collectionIntervalSeconds * 0.8).round().clamp(300, 3600);
      }
      
      if (newInterval != _collectionIntervalSeconds) {
        await updateCollectionInterval(newInterval);
        debugPrint('$collectorName: Adjusted interval to $newInterval sec (battery: $batteryLevel%)');
      }
      
    } catch (e) {
      debugPrint('Error adjusting $collectorName for battery level: $e');
    }
  }
  
  Future<bool> _shouldStartBasedOnBattery() async {
    try {
      final batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
      
      // Don't start if battery is critically low (< 10%)
      if (batteryLevel < 10) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking battery for $collectorName start: $e');
      return true; // Default to true if we can't check
    }
  }
  
  Future<bool> _shouldCollectBasedOnBattery() async {
    try {
      final batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
      
      // Skip collection if battery is very low (< 5%)
      if (batteryLevel < 5) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking battery for $collectorName collection: $e');
      return true; // Default to true if we can't check
    }
  }
  
  Future<void> _scheduleDelayedStart() async {
    // Schedule a delayed start in 5 minutes
    Timer(const Duration(minutes: 5), () async {
      if (!_isCollecting) {
        await startCollecting();
      }
    });
  }
  
  Future<void> _loadConfiguration() async {
    try {
      final intervalSeconds = _storageService.getInt('${collectorName}_interval_seconds');
      if (intervalSeconds != null && intervalSeconds > 0) {
        _collectionIntervalSeconds = intervalSeconds;
      }
      
    } catch (e) {
      debugPrint('Error loading configuration for $collectorName: $e');
    }
  }
  
  Future<void> _loadCachedData() async {
    try {
      final cachedDataJson = _storageService.getString('${collectorName}_cached_data');
      if (cachedDataJson != null) {
        final cachedData = jsonDecode(cachedDataJson) as List<dynamic>;
        _dataCache = cachedData.map((item) => Map<String, dynamic>.from(item)).toList();
        debugPrint('$collectorName: Loaded ${_dataCache.length} cached items');
      }
    } catch (e) {
      debugPrint('Error loading cached data for $collectorName: $e');
    }
  }
  
  Future<void> _saveCachedData() async {
    try {
      if (_dataCache.isNotEmpty) {
        await _storageService.setString(
          '${collectorName}_cached_data',
          jsonEncode(_dataCache),
        );
        debugPrint('$collectorName: Saved ${_dataCache.length} items to cache');
      }
    } catch (e) {
      debugPrint('Error saving cached data for $collectorName: $e');
    }
  }
  
  Future<void> _compressCache() async {
    try {
      // Keep only the most recent 500 items
      if (_dataCache.length > 500) {
        _dataCache = _dataCache.sublist(_dataCache.length - 500);
        await _saveCachedData();
        debugPrint('$collectorName: Cache compressed to ${_dataCache.length} items');
      }
    } catch (e) {
      debugPrint('Error compressing cache for $collectorName: $e');
    }
  }
  
  Future<void> _storeInDatabase(List<Map<String, dynamic>> data) async {
    try {
      // Store each item in the database based on data type
      // This will be handled by the database service's appropriate insert methods
      for (final item in data) {
        await _databaseService.queueDataForSync(dataType, item);
      }
    } catch (e) {
      debugPrint('Error storing $collectorName data in database: $e');
    }
  }
  
  Future<void> _logEvent(String eventType, Map<String, dynamic> metadata) async {
    try {
      await _databaseService.insertSecurityAuditEvent(
        eventType: 'collector_$eventType',
        description: '$collectorName: $eventType',
        severity: 'INFO',
        metadata: {
          'collector': collectorName,
          'data_type': dataType,
          ...metadata,
        },
      );
    } catch (e) {
      debugPrint('Error logging event for $collectorName: $e');
    }
  }
  
  Future<void> _logError(String errorType, String errorMessage) async {
    try {
      await _databaseService.insertSecurityAuditEvent(
        eventType: 'collector_error',
        description: '$collectorName: $errorType - $errorMessage',
        severity: 'ERROR',
        metadata: {
          'collector': collectorName,
          'data_type': dataType,
          'error_type': errorType,
          'error_message': errorMessage,
        },
      );
    } catch (e) {
      debugPrint('Error logging error for $collectorName: $e');
    }
  }
}
