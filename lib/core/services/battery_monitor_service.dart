import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/monitoring/performance_optimizer.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

enum BatteryProfileType {
  normal, // Normal usage patterns
  heavy, // Heavy usage with high drain
  light, // Light usage with low drain
  charging, // Device is charging
  critical, // Battery critically low
  optimized, // Battery optimization mode active
}

class BatteryProfile {
  final BatteryProfileType type;
  final int averageLevel;
  final double drainRate; // %/hour
  final Duration screenOnTime;
  final int cycleCount;
  final List<String> topDrainingApps;
  final DateTime profiledAt;
  final Map<String, dynamic> metadata;

  const BatteryProfile({
    required this.type,
    required this.averageLevel,
    required this.drainRate,
    required this.screenOnTime,
    required this.cycleCount,
    required this.topDrainingApps,
    required this.profiledAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'average_level': averageLevel,
        'drain_rate': drainRate,
        'screen_on_time_minutes': screenOnTime.inMinutes,
        'cycle_count': cycleCount,
        'top_draining_apps': topDrainingApps,
        'profiled_at': profiledAt.toIso8601String(),
        'metadata': metadata,
      };
}

class BatteryMonitorService {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/battery_monitor');

  final Battery _battery = Battery();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();

  Timer? _monitorTimer;
  Timer? _profilingTimer;
  StreamSubscription? _batteryStateSubscription;

  int _lastReportedLevel = -1;
  BatteryState _lastReportedState = BatteryState.unknown;

  // Battery profiling
  final List<Map<String, dynamic>> _batteryHistory = [];
  final int _maxHistorySize = 1000;
  bool _isProfilingEnabled = true;
  BatteryProfile? _currentProfile;

  // Performance integration
  bool _adaptiveOptimizationEnabled = true;

  // Stream controllers
  final StreamController<BatteryProfile> _profileController =
      StreamController<BatteryProfile>.broadcast();
  final StreamController<Map<String, dynamic>> _batteryDataController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<BatteryProfile> get profileStream => _profileController.stream;
  Stream<Map<String, dynamic>> get batteryDataStream =>
      _batteryDataController.stream;

  // Singleton pattern
  static final BatteryMonitorService _instance =
      BatteryMonitorService._internal();

  factory BatteryMonitorService() {
    return _instance;
  }

  BatteryMonitorService._internal();

  Future<void> initialize() async {
    try {
      await _loadConfiguration();
      debugPrint('BatteryMonitorService initialized');
    } catch (e) {
      debugPrint('Error initializing BatteryMonitorService: $e');
    }
  }

  PerformanceOptimizer? _getPerformanceOptimizerOrNull() {
    if (!locator.isRegistered<PerformanceOptimizer>()) {
      return null;
    }
    return locator<PerformanceOptimizer>();
  }

  Future<void> _loadConfiguration() async {
    try {
      _isProfilingEnabled =
          _storageService.getBool('battery_profiling_enabled') ?? true;
      _adaptiveOptimizationEnabled =
          _storageService.getBool('adaptive_battery_optimization') ?? true;
    } catch (e) {
      debugPrint('Error loading battery configuration: $e');
    }
  }

  Future<void> startMonitoring() async {
    await stopMonitoring();

    try {
      // Enhanced battery monitoring every 2 minutes
      _monitorTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
        await _collectBatteryData();
      });

      // Battery profiling every 15 minutes
      if (_isProfilingEnabled) {
        _profilingTimer =
            Timer.periodic(const Duration(minutes: 15), (timer) async {
          await _generateBatteryProfile();
        });
      }

      // Monitor battery state changes
      _batteryStateSubscription =
          _battery.onBatteryStateChanged.listen((state) async {
        await _handleBatteryStateChange(state);
      });

      // Initial data collection
      await _collectBatteryData();

      debugPrint('Enhanced battery monitoring started');
    } catch (e) {
      debugPrint('Error starting battery monitoring: $e');
    }
  }

  Future<void> stopMonitoring() async {
    _monitorTimer?.cancel();
    _monitorTimer = null;

    _profilingTimer?.cancel();
    _profilingTimer = null;

    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;

    debugPrint('Battery monitoring stopped');
  }

  Future<void> _collectBatteryData() async {
    try {
      final batteryData = await _gatherComprehensiveBatteryData();

      // Store in history
      _batteryHistory.add(batteryData);
      if (_batteryHistory.length > _maxHistorySize) {
        _batteryHistory.removeAt(0);
      }

      // Stream the data
      _batteryDataController.add(batteryData);

      // Check if we should report changes
      final level = batteryData['level'] as int;
      final state = batteryData['state'] as String;
      final batteryState = _parseBatteryState(state);

      if (_shouldReportChange(level, batteryState)) {
        await _reportBatteryStatus(level, batteryState, batteryData);
      }

      // Integrate with performance optimizer
      if (_adaptiveOptimizationEnabled) {
        await _integrateWithPerformanceOptimizer(batteryData);
      }
    } catch (e) {
      debugPrint('Error collecting battery data: $e');
    }
  }

  Future<void> _handleBatteryStateChange(BatteryState state) async {
    try {
      final batteryData = await _gatherComprehensiveBatteryData();
      final level = batteryData['level'] as int;

      // Immediate report on state change
      if (state != _lastReportedState) {
        await _reportBatteryStatus(level, state, batteryData);

        // Handle critical state changes
        await _handleCriticalBatteryStates(level, state, batteryData);
      }
    } catch (e) {
      debugPrint('Error handling battery state change: $e');
    }
  }

  bool _shouldReportChange(int level, BatteryState state) {
    // Rapport si:
    // - Premier rapport (-1 signifie que c'est le premier)
    // - Le niveau a changé de plus de 5%
    // - L'état de chargement a changé
    return _lastReportedLevel == -1 ||
        (level - _lastReportedLevel).abs() >= 5 ||
        state != _lastReportedState;
  }

  Future<void> _reportBatteryStatus(
      int level, BatteryState state, Map<String, dynamic> batteryData) async {
    _lastReportedLevel = level;
    _lastReportedState = state;

    final isCharging =
        state == BatteryState.charging || state == BatteryState.full;

    // Enhanced battery report
    final reportData = {
      'battery_level': level,
      'is_charging': isCharging,
      'battery_state': state.toString(),
      'battery_health': batteryData['health'],
      'temperature': batteryData['temperature'],
      'voltage': batteryData['voltage'],
      'technology': batteryData['technology'],
      'capacity': batteryData['capacity'],
      'charge_counter': batteryData['charge_counter'],
      'current_average': batteryData['current_average'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Send via WebSocket
    _webSocketService.sendStatusUpdate(
      batteryLevel: level,
      isCharging: isCharging,
      securityStatus: reportData,
    );

    debugPrint(
        'Enhanced battery status reported: $level%, charging: $isCharging, health: ${batteryData['health']}');
  }

  Future<int> getCurrentBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level;
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      return 100; // Valeur par défaut sécurisée
    }
  }

  Future<bool> isCharging() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging || state == BatteryState.full;
    } catch (e) {
      debugPrint('Error getting battery charging state: $e');
      return false; // Default to not charging
    }
  }

  Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      return await _gatherComprehensiveBatteryData();
    } catch (e) {
      debugPrint('Error getting battery info: $e');
      return {
        'level': 100,
        'is_charging': false,
        'state': 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _gatherComprehensiveBatteryData() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isChargingValue =
          state == BatteryState.charging || state == BatteryState.full;

      // Get advanced battery information from native
      Map<String, dynamic> advancedInfo = {};
      if (Platform.isAndroid) {
        try {
          final nativeData = await _channel
              .invokeMethod<Map<Object?, Object?>>('getBatteryInfo');
          advancedInfo = nativeData?.cast<String, dynamic>() ?? {};
        } catch (e) {
          debugPrint('Error getting native battery info: $e');
        }
      }

      return {
        'level': level,
        'is_charging': isChargingValue,
        'state': state.toString(),
        'health': advancedInfo['health'] ?? 'unknown',
        'temperature': advancedInfo['temperature'] ?? 0,
        'voltage': advancedInfo['voltage'] ?? 0,
        'technology': advancedInfo['technology'] ?? 'unknown',
        'capacity': advancedInfo['capacity'] ?? 0,
        'charge_counter': advancedInfo['charge_counter'] ?? 0,
        'current_average': advancedInfo['current_average'] ?? 0,
        'current_now': advancedInfo['current_now'] ?? 0,
        'energy_counter': advancedInfo['energy_counter'] ?? 0,
        'status': advancedInfo['status'] ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error gathering comprehensive battery data: $e');
      return {
        'level': 100,
        'is_charging': false,
        'state': 'unknown',
        'health': 'unknown',
        'temperature': 0,
        'voltage': 0,
        'technology': 'unknown',
        'capacity': 0,
        'charge_counter': 0,
        'current_average': 0,
        'current_now': 0,
        'energy_counter': 0,
        'status': 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  Future<void> _generateBatteryProfile() async {
    if (_batteryHistory.length < 10) return; // Need sufficient data

    try {
      final recentHistory =
          _batteryHistory.skip(_batteryHistory.length - 50).take(50).toList();

      // Calculate average level
      final averageLevel = recentHistory.fold<int>(
              0, (sum, data) => sum + (data['level'] as int)) ~/
          recentHistory.length;

      // Calculate drain rate
      final drainRate = _calculateDrainRate(recentHistory);

      // Determine profile type
      final profileType =
          _determineProfileType(averageLevel, drainRate, recentHistory);

      // Get screen on time (would need native implementation)
      final screenOnTime = await _getScreenOnTime();

      // Get top draining apps (would need native implementation)
      final topDrainingApps = await _getTopDrainingApps();

      // Get cycle count estimate
      final cycleCount = await _estimateBatteryCycleCount();

      // Create profile
      _currentProfile = BatteryProfile(
        type: profileType,
        averageLevel: averageLevel,
        drainRate: drainRate,
        screenOnTime: screenOnTime,
        cycleCount: cycleCount,
        topDrainingApps: topDrainingApps,
        profiledAt: DateTime.now(),
        metadata: {
          'data_points': recentHistory.length,
          'profile_version': '1.0',
          'device_info': await DeviceUtils.getDeviceInfo(),
        },
      );

      // Stream the profile
      _profileController.add(_currentProfile!);

      // Store in database
      await _databaseService.queueDataForSync(
          'battery_profile', _currentProfile!.toJson(),
          priority: 3);

      debugPrint(
          'Battery profile generated: ${_currentProfile!.type.name}, drain rate: ${_currentProfile!.drainRate.toStringAsFixed(2)}%/h');
    } catch (e) {
      debugPrint('Error generating battery profile: $e');
    }
  }

  double _calculateDrainRate(List<Map<String, dynamic>> history) {
    if (history.length < 2) return 0.0;

    try {
      final first = history.first;
      final last = history.last;

      final firstLevel = first['level'] as int;
      final lastLevel = last['level'] as int;

      final firstTime = DateTime.parse(first['timestamp'] as String);
      final lastTime = DateTime.parse(last['timestamp'] as String);

      final timeDiffHours = lastTime.difference(firstTime).inMinutes / 60.0;
      if (timeDiffHours <= 0) return 0.0;

      final levelDiff = firstLevel - lastLevel;
      return levelDiff / timeDiffHours;
    } catch (e) {
      debugPrint('Error calculating drain rate: $e');
      return 0.0;
    }
  }

  BatteryProfileType _determineProfileType(
      int averageLevel, double drainRate, List<Map<String, dynamic>> history) {
    final hasCharging = history.any((data) => data['is_charging'] == true);

    if (hasCharging) {
      return BatteryProfileType.charging;
    }

    if (averageLevel < 15) {
      return BatteryProfileType.critical;
    }

    if (drainRate > 15.0) {
      return BatteryProfileType.heavy;
    } else if (drainRate < 5.0) {
      return BatteryProfileType.light;
    } else {
      return BatteryProfileType.normal;
    }
  }

  Future<Duration> _getScreenOnTime() async {
    try {
      if (Platform.isAndroid) {
        final screenOnTimeMs =
            await _channel.invokeMethod<int>('getScreenOnTime');
        return Duration(milliseconds: screenOnTimeMs ?? 0);
      }
      return Duration.zero;
    } catch (e) {
      debugPrint('Error getting screen on time: $e');
      return Duration.zero;
    }
  }

  Future<List<String>> _getTopDrainingApps() async {
    try {
      if (Platform.isAndroid) {
        final apps =
            await _channel.invokeMethod<List<Object?>>('getTopDrainingApps');
        return apps?.cast<String>() ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error getting top draining apps: $e');
      return [];
    }
  }

  Future<int> _estimateBatteryCycleCount() async {
    try {
      if (Platform.isAndroid) {
        final cycleCount =
            await _channel.invokeMethod<int>('getBatteryCycleCount');
        return cycleCount ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error estimating battery cycle count: $e');
      return 0;
    }
  }

  Future<void> _integrateWithPerformanceOptimizer(
      Map<String, dynamic> batteryData) async {
    try {
      final optimizer = _getPerformanceOptimizerOrNull();
      if (optimizer == null) return;
      final level = batteryData['level'] as int;
      final isCharging = batteryData['is_charging'] as bool;

      // Trigger performance optimization based on battery state
      if (level < 20 && !isCharging) {
        await optimizer.setPerformanceMode(PerformanceMode.battery);
      } else if (level > 80 && isCharging) {
        await optimizer.setPerformanceMode(PerformanceMode.maximum);
      } else if (level > 50) {
        await optimizer.setPerformanceMode(PerformanceMode.balanced);
      }
    } catch (e) {
      debugPrint('Error integrating with performance optimizer: $e');
    }
  }

  Future<void> _handleCriticalBatteryStates(
      int level, BatteryState state, Map<String, dynamic> batteryData) async {
    try {
      if (level <= 5 && state != BatteryState.charging) {
        // Critical battery - trigger emergency power saving
        await _triggerEmergencyPowerSaving();
      } else if (level <= 15 && state != BatteryState.charging) {
        // Low battery - enable aggressive optimization
        await _enableAggressiveOptimization();
      }
    } catch (e) {
      debugPrint('Error handling critical battery states: $e');
    }
  }

  Future<void> _triggerEmergencyPowerSaving() async {
    try {
      final optimizer = _getPerformanceOptimizerOrNull();
      if (optimizer == null) return;
      debugPrint('Triggering emergency power saving mode');
      await optimizer.setPerformanceMode(PerformanceMode.minimal);

      // Additional emergency measures could be implemented here
      // Such as disabling non-essential services, reducing sync frequency, etc.
    } catch (e) {
      debugPrint('Error triggering emergency power saving: $e');
    }
  }

  Future<void> _enableAggressiveOptimization() async {
    try {
      final optimizer = _getPerformanceOptimizerOrNull();
      if (optimizer == null) return;
      debugPrint('Enabling aggressive battery optimization');
      await optimizer.setPerformanceMode(PerformanceMode.battery);
      await optimizer.setOptimizationStrategy(OptimizationStrategy.aggressive);
    } catch (e) {
      debugPrint('Error enabling aggressive optimization: $e');
    }
  }

  BatteryState _parseBatteryState(String stateString) {
    switch (stateString.toLowerCase()) {
      case 'charging':
        return BatteryState.charging;
      case 'discharging':
        return BatteryState.discharging;
      case 'full':
        return BatteryState.full;
      case 'unknown':
      default:
        return BatteryState.unknown;
    }
  }

  // Public API methods

  Future<BatteryProfile?> getCurrentProfile() async {
    return _currentProfile;
  }

  Future<List<Map<String, dynamic>>> getBatteryHistory({int? limit}) async {
    final historyLimit = limit ?? _batteryHistory.length;
    return _batteryHistory
        .skip(_batteryHistory.length - historyLimit)
        .take(historyLimit)
        .toList();
  }

  Future<Map<String, dynamic>> getBatteryAnalytics() async {
    if (_batteryHistory.isEmpty) {
      return {'error': 'No battery data available'};
    }

    try {
      final recentData =
          _batteryHistory.skip(_batteryHistory.length - 100).take(100).toList();

      return {
        'total_data_points': _batteryHistory.length,
        'average_level': recentData.fold<int>(
                0, (sum, data) => sum + (data['level'] as int)) ~/
            recentData.length,
        'current_profile': _currentProfile?.toJson(),
        'drain_rate_24h': _calculateDrainRate(recentData),
        'charging_sessions':
            recentData.where((data) => data['is_charging'] == true).length,
        'critical_events':
            recentData.where((data) => (data['level'] as int) <= 15).length,
        'health_status': recentData.last['health'],
        'last_updated': recentData.last['timestamp'],
      };
    } catch (e) {
      debugPrint('Error generating battery analytics: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> updateConfiguration({
    bool? profilingEnabled,
    bool? adaptiveOptimizationEnabled,
  }) async {
    if (profilingEnabled != null) {
      _isProfilingEnabled = profilingEnabled;
      await _storageService.setBool(
          'battery_profiling_enabled', profilingEnabled);
    }

    if (adaptiveOptimizationEnabled != null) {
      _adaptiveOptimizationEnabled = adaptiveOptimizationEnabled;
      await _storageService.setBool(
          'adaptive_battery_optimization', adaptiveOptimizationEnabled);
    }
  }

  void dispose() {
    stopMonitoring();
    _profileController.close();
    _batteryDataController.close();
  }

  // Getter methods - fix method references in PerformanceOptimizer
  Future<int> getBatteryLevel() async {
    return await getCurrentBatteryLevel();
  }
}
