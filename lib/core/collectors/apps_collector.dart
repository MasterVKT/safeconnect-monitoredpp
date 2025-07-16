import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

class AppsCollector {
  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/apps');
  final DataCollectorService _dataCollectorService = locator<DataCollectorService>();
  
  bool _isCollecting = false;
  Timer? _usageTimer;
  DateTime _lastUsageCheckTime = DateTime.now();
  
  Future<void> initialize() async {
    try {
      // Check if usage stats permissions are granted
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('Usage stats permissions not granted');
      }
    } catch (e) {
      debugPrint('Error initializing apps collector: $e');
    }
  }
  
  Future<bool> _checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsageStatsPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking usage stats permissions: $e');
      return false;
    }
  }
  
  Future<bool> _requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestUsageStatsPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting usage stats permissions: $e');
      return false;
    }
  }
  
  Future<void> startCollecting() async {
    if (_isCollecting) return;
    
    try {
      // Check permissions first
      var hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        hasPermissions = await _requestPermissions();
        if (!hasPermissions) {
          debugPrint('Cannot start apps collection: permissions not granted');
          return;
        }
      }
      
      // Start periodic app usage check (every hour)
      _usageTimer = Timer.periodic(const Duration(hours: 1), (_) {
        _checkAppUsage();
      });
      
      // Collect installed apps immediately
      _collectInstalledApps();
      
      // Initial app usage check
      _checkAppUsage();
      
      _isCollecting = true;
      debugPrint('Apps collector started');
    } catch (e) {
      debugPrint('Error starting apps collector: $e');
    }
  }
  
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    try {
      // Stop periodic check
      _usageTimer?.cancel();
      _usageTimer = null;
      
      _isCollecting = false;
      debugPrint('Apps collector stopped');
    } catch (e) {
      debugPrint('Error stopping apps collector: $e');
    }
  }
  
  Future<void> _collectInstalledApps() async {
    try {
      final appsList = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      
      if (appsList != null && appsList.isNotEmpty) {
        final deviceId = await DeviceUtils.getDeviceIdentifier();
        final processedApps = appsList.map((app) {
          final appData = app as Map<dynamic, dynamic>;
          
          return {
            'device_id': deviceId,
            'package_name': appData['package_name'],
            'app_name': appData['app_name'],
            'version_name': appData['version_name'],
            'version_code': appData['version_code'],
            'first_install_time': DateTime.fromMillisecondsSinceEpoch(
              appData['first_install_time'] as int
            ).toIso8601String(),
            'last_update_time': appData['last_update_time'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    appData['last_update_time'] as int
                  ).toIso8601String()
                : null,
            'app_category': appData['category'],
            'is_system_app': appData['is_system_app'] == true,
            'recorded_at': DateTime.now().toIso8601String(),
          };
        }).toList();
        
        // Queue for sync
        _dataCollectorService.queueForSync('installed_apps', processedApps);
        
        debugPrint('Collected ${processedApps.length} installed apps');
      }
    } catch (e) {
      debugPrint('Error collecting installed apps: $e');
    }
  }
  
  Future<void> _checkAppUsage() async {
    try {
      // Get current time
      final now = DateTime.now();
      
      // Get app usage since last check
      final usageData = await _channel.invokeMethod<List<dynamic>>(
        'getAppUsage',
        {'since': _lastUsageCheckTime.millisecondsSinceEpoch},
      );
      
      if (usageData != null && usageData.isNotEmpty) {
        final deviceId = await DeviceUtils.getDeviceIdentifier();
        final processedUsage = usageData.map((usage) {
          final usageData = usage as Map<dynamic, dynamic>;
          final startTime = DateTime.fromMillisecondsSinceEpoch(usageData['start_time'] as int);
          final endTime = DateTime.fromMillisecondsSinceEpoch(usageData['end_time'] as int);
          
          return {
            'device_id': deviceId,
            'package_name': usageData['package_name'],
            'app_name': usageData['app_name'],
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'duration': usageData['duration'] as int, // in seconds
            'date': startTime.toIso8601String().split('T')[0], // YYYY-MM-DD
            'recorded_at': DateTime.now().toIso8601String(),
          };
        }).toList();
        
        // Queue for sync
        _dataCollectorService.queueForSync('app_usage', processedUsage);
        
        debugPrint('Collected ${processedUsage.length} app usage records');
      }
      
      // Update last check time
      _lastUsageCheckTime = now;
    } catch (e) {
      debugPrint('Error checking app usage: $e');
    }
  }
}