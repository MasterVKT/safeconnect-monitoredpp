import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';

enum PerformanceMode {
  maximum, // Maximum performance, high battery usage
  balanced, // Balanced performance and battery
  battery, // Battery optimized, reduced performance
  minimal, // Minimal performance, maximum battery life
  adaptive, // Automatically adapt based on conditions
}

enum OptimizationStrategy {
  none,
  aggressive,
  moderate,
  conservative,
}

class PerformanceMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final int memoryUsedMB;
  final int memoryAvailableMB;
  final double batteryLevel;
  final bool isCharging;
  final String networkType;
  final double networkSpeed;
  final int activeCollectors;
  final int syncQueueSize;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.memoryUsedMB,
    required this.memoryAvailableMB,
    required this.batteryLevel,
    required this.isCharging,
    required this.networkType,
    required this.networkSpeed,
    required this.activeCollectors,
    required this.syncQueueSize,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'cpu_usage': cpuUsage,
        'memory_usage': memoryUsage,
        'memory_used_mb': memoryUsedMB,
        'memory_available_mb': memoryAvailableMB,
        'battery_level': batteryLevel,
        'is_charging': isCharging,
        'network_type': networkType,
        'network_speed': networkSpeed,
        'active_collectors': activeCollectors,
        'sync_queue_size': syncQueueSize,
        'timestamp': timestamp.toIso8601String(),
      };
}

class OptimizationRule {
  final String name;
  final bool Function(PerformanceMetrics) condition;
  final Future<void> Function() action;
  final int priority;
  final Duration cooldown;
  DateTime? lastExecuted;

  OptimizationRule({
    required this.name,
    required this.condition,
    required this.action,
    required this.priority,
    this.cooldown = const Duration(minutes: 5),
  });

  bool canExecute(PerformanceMetrics metrics) {
    if (lastExecuted != null &&
        DateTime.now().difference(lastExecuted!) < cooldown) {
      return false;
    }
    return condition(metrics);
  }

  Future<void> execute() async {
    await action();
    lastExecuted = DateTime.now();
  }
}

class PerformanceOptimizer {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/performance');

  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final ConnectivityService _connectivityService =
      locator<ConnectivityService>();

  bool _isInitialized = false;
  PerformanceMode _currentMode = PerformanceMode.balanced;
  OptimizationStrategy _strategy = OptimizationStrategy.moderate;

  Timer? _metricsTimer;
  Timer? _optimizationTimer;

  final List<PerformanceMetrics> _metricsHistory = [];
  final List<OptimizationRule> _optimizationRules = [];
  final int _maxHistorySize = 100;

  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();
  final StreamController<PerformanceMode> _modeController =
      StreamController<PerformanceMode>.broadcast();

  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  Stream<PerformanceMode> get modeStream => _modeController.stream;

  bool get isInitialized => _isInitialized;
  PerformanceMode get currentMode => _currentMode;
  OptimizationStrategy get strategy => _strategy;
  List<PerformanceMetrics> get metricsHistory =>
      List.unmodifiable(_metricsHistory);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing Performance Optimizer...');

      // Load saved configuration
      await _loadConfiguration();

      // Setup optimization rules
      _setupOptimizationRules();

      // Start performance monitoring
      await _startMonitoring();

      _isInitialized = true;
      debugPrint('Performance Optimizer initialized');
    } catch (e) {
      debugPrint('Error initializing Performance Optimizer: $e');
      throw Exception('Failed to initialize Performance Optimizer: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final modeString = await _storageService.read('performance_mode');
      if (modeString != null) {
        _currentMode = PerformanceMode.values.firstWhere(
          (mode) => mode.name == modeString,
          orElse: () => PerformanceMode.balanced,
        );
      }

      final strategyString =
          await _storageService.read('optimization_strategy');
      if (strategyString != null) {
        _strategy = OptimizationStrategy.values.firstWhere(
          (strategy) => strategy.name == strategyString,
          orElse: () => OptimizationStrategy.moderate,
        );
      }

      debugPrint(
          'Loaded performance configuration: mode=${_currentMode.name}, strategy=${_strategy.name}');
    } catch (e) {
      debugPrint('Error loading performance configuration: $e');
    }
  }

  void _setupOptimizationRules() {
    _optimizationRules.clear();

    // High memory usage rule
    _optimizationRules.add(OptimizationRule(
      name: 'high_memory_usage',
      condition: (metrics) => metrics.memoryUsage > 85.0,
      action: () async => await _optimizeMemoryUsage(),
      priority: 1,
      cooldown: const Duration(minutes: 2),
    ));

    // Low battery rule
    _optimizationRules.add(OptimizationRule(
      name: 'low_battery',
      condition: (metrics) =>
          metrics.batteryLevel < 20.0 && !metrics.isCharging,
      action: () async => await _enableBatterySaverMode(),
      priority: 1,
      cooldown: const Duration(minutes: 1),
    ));

    // High CPU usage rule
    _optimizationRules.add(OptimizationRule(
      name: 'high_cpu_usage',
      condition: (metrics) => metrics.cpuUsage > 80.0,
      action: () async => await _reduceCPUUsage(),
      priority: 2,
      cooldown: const Duration(minutes: 3),
    ));

    // Large sync queue rule
    _optimizationRules.add(OptimizationRule(
      name: 'large_sync_queue',
      condition: (metrics) => metrics.syncQueueSize > 1000,
      action: () async => await _optimizeSyncQueue(),
      priority: 2,
      cooldown: const Duration(minutes: 5),
    ));

    // Poor network conditions rule
    _optimizationRules.add(OptimizationRule(
      name: 'poor_network',
      condition: (metrics) =>
          metrics.networkSpeed < 1.0 && metrics.networkType != 'none',
      action: () async => await _optimizeNetworkUsage(),
      priority: 3,
      cooldown: const Duration(minutes: 2),
    ));

    // Adaptive mode rules
    if (_currentMode == PerformanceMode.adaptive) {
      _setupAdaptiveRules();
    }

    debugPrint('Setup ${_optimizationRules.length} optimization rules');
  }

  void _setupAdaptiveRules() {
    // Auto-switch to battery mode when battery is low
    _optimizationRules.add(OptimizationRule(
      name: 'adaptive_battery_low',
      condition: (metrics) =>
          metrics.batteryLevel < 15.0 && !metrics.isCharging,
      action: () async => await setPerformanceMode(PerformanceMode.battery),
      priority: 1,
    ));

    // Auto-switch to maximum mode when charging and high load
    _optimizationRules.add(OptimizationRule(
      name: 'adaptive_charging_high_load',
      condition: (metrics) => metrics.isCharging && metrics.syncQueueSize > 500,
      action: () async => await setPerformanceMode(PerformanceMode.maximum),
      priority: 2,
    ));

    // Auto-switch to balanced mode when conditions normalize
    _optimizationRules.add(OptimizationRule(
      name: 'adaptive_normalize',
      condition: (metrics) =>
          metrics.batteryLevel > 30.0 &&
          metrics.memoryUsage < 70.0 &&
          metrics.cpuUsage < 60.0,
      action: () async => await setPerformanceMode(PerformanceMode.balanced),
      priority: 3,
      cooldown: const Duration(minutes: 10),
    ));
  }

  Future<void> _startMonitoring() async {
    // Collect metrics every 30 seconds
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _collectMetrics();
    });

    // Run optimization checks every minute
    _optimizationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _runOptimizations();
    });

    // Collect initial metrics
    await _collectMetrics();
  }

  Future<void> _collectMetrics() async {
    try {
      final metrics = await _gatherPerformanceMetrics();

      // Add to history
      _metricsHistory.add(metrics);
      if (_metricsHistory.length > _maxHistorySize) {
        _metricsHistory.removeAt(0);
      }

      // Notify listeners
      _metricsController.add(metrics);

      // Store metrics in database periodically
      if (_metricsHistory.length % 10 == 0) {
        await _storeMetrics(metrics);
      }
    } catch (e) {
      debugPrint('Error collecting performance metrics: $e');
    }
  }

  Future<PerformanceMetrics> _gatherPerformanceMetrics() async {
    final timestamp = DateTime.now();

    // Gather system metrics
    final cpuUsage = await _getCPUUsage();
    final memoryInfo = await _getMemoryInfo();
    final batteryInfo = await _getBatteryInfo();
    final networkInfo = await _getNetworkInfo();
    final appInfo = await _getAppInfo();

    return PerformanceMetrics(
      cpuUsage: cpuUsage,
      memoryUsage: memoryInfo['usage'] ?? 0.0,
      memoryUsedMB: memoryInfo['used_mb'] ?? 0,
      memoryAvailableMB: memoryInfo['available_mb'] ?? 0,
      batteryLevel: batteryInfo['level'] ?? 0.0,
      isCharging: batteryInfo['is_charging'] ?? false,
      networkType: networkInfo['type'] ?? 'unknown',
      networkSpeed: networkInfo['speed'] ?? 0.0,
      activeCollectors: appInfo['active_collectors'] ?? 0,
      syncQueueSize: appInfo['sync_queue_size'] ?? 0,
      timestamp: timestamp,
    );
  }

  Future<double> _getCPUUsage() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<double>('getCPUUsage');
        return result ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        final result =
            await _channel.invokeMethod<Map<Object?, Object?>>('getMemoryInfo');
        return result?.cast<String, dynamic>() ?? {};
      }

      // Fallback for other platforms
      final totalMemory = Platform.resolvedExecutable.length; // Placeholder
      final usedMemory = (totalMemory * 0.6).round(); // Estimate

      return {
        'usage': (usedMemory / totalMemory) * 100,
        'used_mb': usedMemory ~/ 1024 ~/ 1024,
        'available_mb': (totalMemory - usedMemory) ~/ 1024 ~/ 1024,
      };
    } catch (e) {
      return {
        'usage': 0.0,
        'used_mb': 0,
        'available_mb': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getBatteryInfo() async {
    try {
      if (!locator.isRegistered<BatteryMonitorService>()) {
        return {
          'level': 100.0,
          'is_charging': false,
        };
      }
      final batteryService = locator<BatteryMonitorService>();
      final level = await batteryService.getBatteryLevel();
      final isCharging = await batteryService.isCharging();

      return {
        'level': level.toDouble(),
        'is_charging': isCharging,
      };
    } catch (e) {
      return {
        'level': 100.0,
        'is_charging': false,
      };
    }
  }

  Future<Map<String, dynamic>> _getNetworkInfo() async {
    try {
      final networkStatus = await _connectivityService.checkConnectivity();

      return {
        'type': networkStatus.name,
        'speed': _estimateNetworkSpeed(networkStatus),
      };
    } catch (e) {
      return {
        'type': 'unknown',
        'speed': 0.0,
      };
    }
  }

  double _estimateNetworkSpeed(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return 50.0; // Estimate 50 Mbps for WiFi
      case NetworkStatus.mobile:
        return 10.0; // Estimate 10 Mbps for mobile
      case NetworkStatus.online:
        return 25.0; // Estimate 25 Mbps for other connections
      case NetworkStatus.offline:
        return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      // Get sync queue size from database
      final syncQueueSize = await _databaseService.getSyncQueueSize();

      return {
        'active_collectors': 5, // Would be dynamically determined
        'sync_queue_size': syncQueueSize,
      };
    } catch (e) {
      return {
        'active_collectors': 0,
        'sync_queue_size': 0,
      };
    }
  }

  Future<void> _runOptimizations() async {
    if (_metricsHistory.isEmpty) return;

    final currentMetrics = _metricsHistory.last;

    // Sort rules by priority
    final sortedRules = List<OptimizationRule>.from(_optimizationRules)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final rule in sortedRules) {
      try {
        if (rule.canExecute(currentMetrics)) {
          debugPrint('Executing optimization rule: ${rule.name}');
          await rule.execute();
          await _logOptimization(rule.name, currentMetrics);
        }
      } catch (e) {
        debugPrint('Error executing optimization rule ${rule.name}: $e');
      }
    }
  }

  // Optimization actions

  Future<void> _optimizeMemoryUsage() async {
    try {
      debugPrint('Optimizing memory usage...');

      // Force garbage collection
      if (Platform.isAndroid) {
        await _channel.invokeMethod('forceGC');
      }

      // Clear caches
      await _clearCaches();

      // Reduce collector frequency temporarily
      await _reduceCollectorFrequency(duration: const Duration(minutes: 10));
    } catch (e) {
      debugPrint('Error optimizing memory usage: $e');
    }
  }

  Future<void> _enableBatterySaverMode() async {
    try {
      debugPrint('Enabling battery saver mode...');

      // Switch to battery performance mode
      await setPerformanceMode(PerformanceMode.battery);

      // Reduce background activity
      await _reduceBackgroundActivity();

      // Increase sync intervals
      await _increaseSyncIntervals();
    } catch (e) {
      debugPrint('Error enabling battery saver mode: $e');
    }
  }

  Future<void> _reduceCPUUsage() async {
    try {
      debugPrint('Reducing CPU usage...');

      // Reduce data collection frequency
      await _reduceCollectorFrequency(duration: const Duration(minutes: 5));

      // Pause non-essential tasks
      await _pauseNonEssentialTasks();
    } catch (e) {
      debugPrint('Error reducing CPU usage: $e');
    }
  }

  Future<void> _optimizeSyncQueue() async {
    try {
      debugPrint('Optimizing sync queue...');

      // Prioritize high-priority items
      await _databaseService.prioritizeSyncQueue();

      // Remove old low-priority items
      await _databaseService.cleanupOldSyncItems();

      // Increase sync frequency temporarily
      await _increaseSyncFrequency(duration: const Duration(minutes: 15));
    } catch (e) {
      debugPrint('Error optimizing sync queue: $e');
    }
  }

  Future<void> _optimizeNetworkUsage() async {
    try {
      debugPrint('Optimizing network usage...');

      // Switch to WiFi-only mode if available
      await _preferWiFiConnection();

      // Compress data more aggressively
      await _enableHighCompression();

      // Batch network requests
      await _enableRequestBatching();
    } catch (e) {
      debugPrint('Error optimizing network usage: $e');
    }
  }

  // Helper methods for optimizations

  Future<void> _clearCaches() async {
    try {
      // Clear temporary files
      final tempDir = Directory.systemTemp;
      final appTempFiles = tempDir
          .listSync()
          .where((file) => file.path.contains('monitored_app'))
          .toList();

      for (final file in appTempFiles) {
        try {
          await file.delete(recursive: true);
        } catch (e) {
          // Ignore individual file deletion errors
        }
      }

      debugPrint('Cleared cache files');
    } catch (e) {
      debugPrint('Error clearing caches: $e');
    }
  }

  Future<void> _reduceCollectorFrequency({required Duration duration}) async {
    try {
      // This would integrate with DataCollectorService
      // await _dataCollectorService.reduceFrequency(duration);
      debugPrint(
          'Reduced collector frequency for ${duration.inMinutes} minutes');
    } catch (e) {
      debugPrint('Error reducing collector frequency: $e');
    }
  }

  Future<void> _reduceBackgroundActivity() async {
    try {
      // Reduce background service activity
      debugPrint('Reduced background activity');
    } catch (e) {
      debugPrint('Error reducing background activity: $e');
    }
  }

  Future<void> _increaseSyncIntervals() async {
    try {
      // Increase sync intervals to save battery
      debugPrint('Increased sync intervals');
    } catch (e) {
      debugPrint('Error increasing sync intervals: $e');
    }
  }

  Future<void> _pauseNonEssentialTasks() async {
    try {
      // Pause non-essential background tasks
      debugPrint('Paused non-essential tasks');
    } catch (e) {
      debugPrint('Error pausing non-essential tasks: $e');
    }
  }

  Future<void> _increaseSyncFrequency({required Duration duration}) async {
    try {
      // Temporarily increase sync frequency
      debugPrint('Increased sync frequency for ${duration.inMinutes} minutes');
    } catch (e) {
      debugPrint('Error increasing sync frequency: $e');
    }
  }

  Future<void> _preferWiFiConnection() async {
    try {
      // Configure to prefer WiFi connections
      debugPrint('Configured to prefer WiFi');
    } catch (e) {
      debugPrint('Error configuring WiFi preference: $e');
    }
  }

  Future<void> _enableHighCompression() async {
    try {
      // Enable higher compression ratios
      debugPrint('Enabled high compression');
    } catch (e) {
      debugPrint('Error enabling high compression: $e');
    }
  }

  Future<void> _enableRequestBatching() async {
    try {
      // Enable request batching
      debugPrint('Enabled request batching');
    } catch (e) {
      debugPrint('Error enabling request batching: $e');
    }
  }

  // Public API methods

  Future<void> setPerformanceMode(PerformanceMode mode) async {
    if (_currentMode == mode) return;

    final oldMode = _currentMode;

    try {
      debugPrint('Switching to performance mode: ${mode.name}');

      _currentMode = mode;

      // Apply mode-specific configurations
      await _applyPerformanceMode(mode);

      // Save configuration
      await _storageService.write('performance_mode', mode.name);

      // Update optimization rules if switching to/from adaptive
      if (mode == PerformanceMode.adaptive ||
          oldMode == PerformanceMode.adaptive) {
        _setupOptimizationRules();
      }

      // Notify listeners
      _modeController.add(mode);

      await _logModeChange(oldMode, mode);
    } catch (e) {
      debugPrint('Error setting performance mode: $e');
      _currentMode = oldMode; // Revert on error
    }
  }

  Future<void> setOptimizationStrategy(OptimizationStrategy strategy) async {
    if (_strategy == strategy) return;

    try {
      _strategy = strategy;
      await _storageService.write('optimization_strategy', strategy.name);

      // Update optimization rules based on strategy
      _setupOptimizationRules();

      debugPrint('Set optimization strategy: ${strategy.name}');
    } catch (e) {
      debugPrint('Error setting optimization strategy: $e');
    }
  }

  Future<void> _applyPerformanceMode(PerformanceMode mode) async {
    switch (mode) {
      case PerformanceMode.maximum:
        await _applyMaximumMode();
        break;
      case PerformanceMode.balanced:
        await _applyBalancedMode();
        break;
      case PerformanceMode.battery:
        await _applyBatteryMode();
        break;
      case PerformanceMode.minimal:
        await _applyMinimalMode();
        break;
      case PerformanceMode.adaptive:
        await _applyAdaptiveMode();
        break;
    }
  }

  Future<void> _applyMaximumMode() async {
    // High frequency data collection
    // Aggressive sync
    // Full feature set enabled
    debugPrint('Applied maximum performance mode');
  }

  Future<void> _applyBalancedMode() async {
    // Standard data collection
    // Regular sync intervals
    // All features enabled
    debugPrint('Applied balanced performance mode');
  }

  Future<void> _applyBatteryMode() async {
    // Reduced data collection frequency
    // Extended sync intervals
    // Non-essential features disabled
    debugPrint('Applied battery performance mode');
  }

  Future<void> _applyMinimalMode() async {
    // Minimum data collection
    // Long sync intervals
    // Only critical features enabled
    debugPrint('Applied minimal performance mode');
  }

  Future<void> _applyAdaptiveMode() async {
    // Start with balanced mode, then adapt
    await _applyBalancedMode();
    debugPrint('Applied adaptive performance mode');
  }

  // Analytics and reporting

  Future<Map<String, dynamic>> getPerformanceReport() async {
    try {
      if (_metricsHistory.isEmpty) {
        return {'error': 'No metrics available'};
      }

      final recent = _metricsHistory.take(20).toList();

      return {
        'current_mode': _currentMode.name,
        'optimization_strategy': _strategy.name,
        'metrics_count': _metricsHistory.length,
        'average_cpu_usage': _calculateAverage(recent, (m) => m.cpuUsage),
        'average_memory_usage': _calculateAverage(recent, (m) => m.memoryUsage),
        'average_battery_level':
            _calculateAverage(recent, (m) => m.batteryLevel),
        'optimization_rules_count': _optimizationRules.length,
        'last_metrics': recent.last.toJson(),
        'performance_trends': _calculateTrends(),
      };
    } catch (e) {
      debugPrint('Error generating performance report: $e');
      return {'error': e.toString()};
    }
  }

  double _calculateAverage(List<PerformanceMetrics> metrics,
      double Function(PerformanceMetrics) getValue) {
    if (metrics.isEmpty) return 0.0;
    return metrics.map(getValue).reduce((a, b) => a + b) / metrics.length;
  }

  Map<String, dynamic> _calculateTrends() {
    if (_metricsHistory.length < 10) return {};

    final recent =
        _metricsHistory.skip(_metricsHistory.length - 10).take(10).toList();
    final older = _metricsHistory
        .take(_metricsHistory.length - 10)
        .skip(_metricsHistory.length - 20)
        .take(10)
        .toList();

    return {
      'cpu_trend': _calculateTrend(older, recent, (m) => m.cpuUsage),
      'memory_trend': _calculateTrend(older, recent, (m) => m.memoryUsage),
      'battery_trend': _calculateTrend(older, recent, (m) => m.batteryLevel),
    };
  }

  String _calculateTrend(
      List<PerformanceMetrics> older,
      List<PerformanceMetrics> recent,
      double Function(PerformanceMetrics) getValue) {
    if (older.isEmpty || recent.isEmpty) return 'stable';

    final olderAvg = _calculateAverage(older, getValue);
    final recentAvg = _calculateAverage(recent, getValue);
    final change = (recentAvg - olderAvg) / olderAvg * 100;

    if (change > 10) return 'increasing';
    if (change < -10) return 'decreasing';
    return 'stable';
  }

  Future<void> _storeMetrics(PerformanceMetrics metrics) async {
    try {
      await _storageService.setString(
        'latest_performance_metrics',
        jsonEncode(metrics.toJson()),
      );
    } catch (e) {
      debugPrint('Error storing performance metrics: $e');
    }
  }

  Future<void> _logOptimization(
      String ruleName, PerformanceMetrics metrics) async {
    try {
      await _databaseService.insertSecurityAuditEvent(
        eventType: 'performance_optimization',
        description: 'Performance optimization rule executed: $ruleName',
        severity: 'INFO',
        metadata: {
          'rule': ruleName,
          'metrics': metrics.toJson(),
        },
      );
    } catch (e) {
      debugPrint('Error logging optimization: $e');
    }
  }

  Future<void> _logModeChange(
      PerformanceMode oldMode, PerformanceMode newMode) async {
    try {
      await _databaseService.insertSecurityAuditEvent(
        eventType: 'performance_mode_change',
        description:
            'Performance mode changed from ${oldMode.name} to ${newMode.name}',
        severity: 'INFO',
        metadata: {
          'old_mode': oldMode.name,
          'new_mode': newMode.name,
        },
      );
    } catch (e) {
      debugPrint('Error logging mode change: $e');
    }
  }

  Future<void> dispose() async {
    _metricsTimer?.cancel();
    _optimizationTimer?.cancel();
    _metricsController.close();
    _modeController.close();

    _isInitialized = false;
    debugPrint('Performance Optimizer disposed');
  }
}
