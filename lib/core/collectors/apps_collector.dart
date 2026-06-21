import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/collectors/base_collector.dart';

class AppsCollector extends BaseCollector {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/apps');

  Timer? _usageTimer;
  DateTime _lastUsageCheckTime = DateTime.now();

  // Database service reference
  final DatabaseService _databaseService = locator<DatabaseService>();

  @override
  String get collectorName => 'Apps';

  @override
  String get dataType => 'app_usage';

  @override
  List<Permission> get requiredPermissions => [Permission.systemAlertWindow];

  @override
  Future<void> initializeSpecific() async {
    try {
      // Setup specific configurations if needed
      debugPrint('Apps collector specific initialization completed');
    } catch (e) {
      debugPrint('Error initializing apps collector specific: $e');
    }
  }

  @override
  Future<bool> checkSpecificPermissions() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkUsageStatsPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking usage stats permissions: $e');
      return false;
    }
  }

  @override
  Future<void> requestSpecificPermissions() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermissions');
    } catch (e) {
      debugPrint('Error requesting usage stats permissions: $e');
    }
  }

  @override
  Future<void> startSpecificCollection() async {
    try {
      // Start periodic app usage check (every hour)
      _usageTimer = Timer.periodic(const Duration(hours: 1), (_) {
        _checkAppUsage();
      });

      // Collect installed apps immediately
      _collectInstalledApps();

      // Initial app usage check
      _checkAppUsage();

      debugPrint('Apps specific collection started');
    } catch (e) {
      debugPrint('Error starting apps specific collection: $e');
    }
  }

  @override
  Future<void> stopSpecificCollection() async {
    try {
      // Stop periodic check
      _usageTimer?.cancel();
      _usageTimer = null;

      debugPrint('Apps specific collection stopped');
    } catch (e) {
      debugPrint('Error stopping apps specific collection: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> collectData() async {
    try {
      // Collect app usage data
      final usageData = await _channel.invokeMethod<List<dynamic>>(
        'getAppUsage',
        {'since': _lastUsageCheckTime.millisecondsSinceEpoch},
      );

      if (usageData != null && usageData.isNotEmpty) {
        final processedUsage = <Map<String, dynamic>>[];

        for (final usage in usageData) {
          final usageRecord =
              await _convertUsageData(usage as Map<dynamic, dynamic>);
          if (usageRecord != null) {
            processedUsage.add(usageRecord);
          }
        }

        // Update last check time
        _lastUsageCheckTime = DateTime.now();

        return processedUsage;
      }

      return [];
    } catch (e) {
      debugPrint('Error collecting app usage data: $e');
      return [];
    }
  }

  Future<void> _collectInstalledApps() async {
    try {
      final appsList =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps');

      if (appsList != null && appsList.isNotEmpty) {
        var processedAppsCount = 0;

        for (final app in appsList) {
          final appRecord = await _convertAppData(app as Map<dynamic, dynamic>);
          if (appRecord != null) {
            processedAppsCount++;
          }
        }

        debugPrint('Collected and stored $processedAppsCount installed apps');
      }
    } catch (e) {
      debugPrint('Error collecting installed apps: $e');
    }
  }

  Future<void> _checkAppUsage() async {
    try {
      // Use the collectData method for consistency
      final usageData = await collectData();
      if (usageData.isNotEmpty) {
        await processData(usageData);
        debugPrint(
            'App usage periodic check complete: ${usageData.length} new records');
      }
    } catch (e) {
      debugPrint('Error checking app usage: $e');
    }
  }

  Future<Map<String, dynamic>?> _convertUsageData(
      Map<dynamic, dynamic> usageData) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final packageName = usageData['package_name'] as String;
      final appName = usageData['app_name'] as String?;
      final startTime =
          DateTime.fromMillisecondsSinceEpoch(usageData['start_time'] as int);
      final endTime =
          DateTime.fromMillisecondsSinceEpoch(usageData['end_time'] as int);
      final duration = usageData['duration'] as int;
      final date = startTime.toIso8601String().split('T')[0];

      // Store in database using database service
      await _databaseService.insertAppUsageData(
        deviceId: deviceId,
        packageName: packageName,
        appName: appName,
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        date: date,
      );

      // Return processed usage data for sync
      return {
        'package_name': packageName,
        'app_name': appName,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'recorded_at': startTime.toUtc().toIso8601String(),
        'duration': duration,
        'duration_seconds': duration,
        'date': date,
        'launch_count': usageData['launch_count'] ?? 1,
        'category': usageData['category'] ?? 'UNKNOWN',
      };
    } catch (e) {
      debugPrint('Error converting usage data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _convertAppData(
      Map<dynamic, dynamic> appData) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final packageName = appData['package_name'] as String;
      final appName = appData['app_name'] as String;
      final versionName = appData['version_name'] as String?;
      final versionCode = appData['version_code'] as int?;
      final firstInstallTime = DateTime.fromMillisecondsSinceEpoch(
          appData['first_install_time'] as int);
      final lastUpdateTime = appData['last_update_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              appData['last_update_time'] as int)
          : null;
      final category = appData['category'] as String?;
      final isSystemApp = appData['is_system_app'] == true;

      // Store in database using database service
      await _databaseService.insertAppData(
        deviceId: deviceId,
        packageName: packageName,
        appName: appName,
        versionName: versionName,
        versionCode: versionCode,
        firstInstallTime: firstInstallTime,
        lastUpdateTime: lastUpdateTime,
        appCategory: category,
        isSystemApp: isSystemApp,
      );

      // Return processed app data for sync
      return {
        'package_name': packageName,
        'app_name': appName,
        'version_name': versionName,
        'version_code': versionCode,
        'first_install_time': firstInstallTime.toUtc().toIso8601String(),
        'last_update_time': lastUpdateTime?.toUtc().toIso8601String(),
        'app_category': category,
        'is_system_app': isSystemApp,
      };
    } catch (e) {
      debugPrint('Error converting app data: $e');
      return null;
    }
  }
}
