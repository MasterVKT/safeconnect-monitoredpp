import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/types/app_types.dart';
import 'package:monitored_app/app/locator.dart';

class SystemMetrics {
  final double cpuUsage;
  final double memoryUsagePercent;
  final int memoryUsedMB;
  final int memoryTotalMB;
  final double batteryLevel;
  final bool isCharging;
  final int storageUsedMB;
  final int storageTotalMB;
  final double networkUpload;
  final double networkDownload;
  final DateTime timestamp;

  SystemMetrics({
    required this.cpuUsage,
    required this.memoryUsagePercent,
    required this.memoryUsedMB,
    required this.memoryTotalMB,
    required this.batteryLevel,
    required this.isCharging,
    required this.storageUsedMB,
    required this.storageTotalMB,
    required this.networkUpload,
    required this.networkDownload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'cpu_usage_percent': cpuUsage,
      'memory_usage_percent': memoryUsagePercent,
      'memory_used_mb': memoryUsedMB,
      'memory_total_mb': memoryTotalMB,
      'battery_level': batteryLevel,
      'is_charging': isCharging,
      'storage_used_mb': storageUsedMB,
      'storage_total_mb': storageTotalMB,
      'network_upload_kbps': networkUpload,
      'network_download_kbps': networkDownload,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PerformanceReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, double> averageLatencies;
  final Map<String, int> operationCounts;
  final Map<String, double> errorRates;
  final SystemMetrics averageSystemMetrics;
  final List<String> performanceIssues;
  final Map<String, dynamic> recommendations;

  PerformanceReport({
    required this.periodStart,
    required this.periodEnd,
    required this.averageLatencies,
    required this.operationCounts,
    required this.errorRates,
    required this.averageSystemMetrics,
    required this.performanceIssues,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'average_latencies': averageLatencies,
      'operation_counts': operationCounts,
      'error_rates': errorRates,
      'average_system_metrics': averageSystemMetrics.toJson(),
      'performance_issues': performanceIssues,
      'recommendations': recommendations,
    };
  }
}

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final DatabaseService _databaseService = locator<DatabaseService>();
  final Battery _battery = Battery();

  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/performance');

  // Metrics collection
  final List<PerformanceMetric> _metricsBuffer = [];
  final Map<String, Stopwatch> _activeOperations = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, int> _errorCounts = {};

  // System monitoring
  Timer? _systemMetricsTimer;
  SystemMetrics? _lastSystemMetrics;
  final List<SystemMetrics> _systemMetricsHistory = [];

  // Performance thresholds
  static const double _highLatencyThreshold = 1000.0; // ms
  static const double _highMemoryUsageThreshold = 80.0; // %
  static const double _highCpuUsageThreshold = 70.0; // %
  static const double _lowBatteryThreshold = 20.0; // %

  bool _isMonitoring = false;

  Future<void> initialize() async {
    await _loadConfiguration();
    _startSystemMonitoring();
    _scheduleMetricsFlush();
    _isMonitoring = true;
    
    debugPrint('PerformanceMonitor initialized');
  }

  Future<void> _loadConfiguration() async {
    // Load performance monitoring configuration
    // This could include custom thresholds, sampling rates, etc.
  }

  /// Tracks the performance of an operation
  void trackOperation(String operation, Function() action) {
    if (!_isMonitoring) {
      action();
      return;
    }

    final stopwatch = Stopwatch()..start();

    try {
      action();
      
      stopwatch.stop();
      _recordLatencyMetric(operation, stopwatch.elapsedMilliseconds.toDouble());
      _incrementOperationCount(operation);
      
    } catch (e) {
      stopwatch.stop();
      _recordLatencyMetric(operation, stopwatch.elapsedMilliseconds.toDouble());
      _incrementErrorCount(operation);
      
      debugPrint('Operation failed: $operation - $e');
      rethrow;
    }
  }

  /// Tracks an async operation
  Future<T> trackAsyncOperation<T>(String operation, Future<T> Function() action) async {
    if (!_isMonitoring) {
      return await action();
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await action();
      
      stopwatch.stop();
      _recordLatencyMetric(operation, stopwatch.elapsedMilliseconds.toDouble());
      _incrementOperationCount(operation);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordLatencyMetric(operation, stopwatch.elapsedMilliseconds.toDouble());
      _incrementErrorCount(operation);
      
      debugPrint('Async operation failed: $operation - $e');
      rethrow;
    }
  }

  /// Starts tracking a long-running operation
  void startOperation(String operation) {
    if (!_isMonitoring) return;
    
    final stopwatch = Stopwatch()..start();
    _activeOperations[operation] = stopwatch;
  }

  /// Ends tracking of a long-running operation
  void endOperation(String operation, {bool success = true}) {
    if (!_isMonitoring) return;
    
    final stopwatch = _activeOperations.remove(operation);
    if (stopwatch == null) return;
    
    stopwatch.stop();
    _recordLatencyMetric(operation, stopwatch.elapsedMilliseconds.toDouble());
    
    if (success) {
      _incrementOperationCount(operation);
    } else {
      _incrementErrorCount(operation);
    }
  }

  /// Records a custom metric
  void recordMetric(String operation, MetricType type, double value, String unit, {Map<String, dynamic>? metadata}) {
    if (!_isMonitoring) return;
    
    final metric = PerformanceMetric(
      id: _generateMetricId(),
      operation: operation,
      type: type,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _metricsBuffer.add(metric);
    
    // Check for performance issues
    _checkPerformanceThresholds(metric);
  }

  void _recordLatencyMetric(String operation, double latencyMs) {
    recordMetric(operation, MetricType.latency, latencyMs, 'ms');
  }

  void _incrementOperationCount(String operation) {
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
  }

  void _incrementErrorCount(String operation) {
    _errorCounts[operation] = (_errorCounts[operation] ?? 0) + 1;
  }

  /// Starts system metrics monitoring
  void _startSystemMonitoring() {
    _systemMetricsTimer = Timer.periodic(const Duration(minutes: 1), (_) => _collectSystemMetrics());
    
    // Collect initial metrics
    _collectSystemMetrics();
  }

  Future<void> _collectSystemMetrics() async {
    try {
      final cpuUsage = await _getCpuUsage();
      final memoryInfo = await _getMemoryInfo();
      final batteryLevel = await _battery.batteryLevel;
      final isCharging = await _getBatteryChargingStatus();
      final storageInfo = await _getStorageInfo();
      final networkInfo = await _getNetworkInfo();
      
      final metrics = SystemMetrics(
        cpuUsage: cpuUsage,
        memoryUsagePercent: memoryInfo['usage_percent'],
        memoryUsedMB: memoryInfo['used_mb'],
        memoryTotalMB: memoryInfo['total_mb'],
        batteryLevel: batteryLevel.toDouble(),
        isCharging: isCharging,
        storageUsedMB: storageInfo['used_mb'],
        storageTotalMB: storageInfo['total_mb'],
        networkUpload: networkInfo['upload_kbps'],
        networkDownload: networkInfo['download_kbps'],
        timestamp: DateTime.now(),
      );
      
      _lastSystemMetrics = metrics;
      _systemMetricsHistory.add(metrics);
      
      // Keep only last 24 hours of metrics
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      _systemMetricsHistory.removeWhere((m) => m.timestamp.isBefore(cutoff));
      
      // Check system performance thresholds
      _checkSystemThresholds(metrics);
      
    } catch (e) {
      debugPrint('Error collecting system metrics: $e');
    }
  }

  Future<double> _getCpuUsage() async {
    try {
      final result = await _channel.invokeMethod<double>('getCpuUsage');
      return result ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getMemoryInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getMemoryInfo');
      return {
        'usage_percent': result?['usage_percent'] ?? 0.0,
        'used_mb': result?['used_mb'] ?? 0,
        'total_mb': result?['total_mb'] ?? 0,
      };
    } catch (e) {
      return {'usage_percent': 0.0, 'used_mb': 0, 'total_mb': 0};
    }
  }

  Future<bool> _getBatteryChargingStatus() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getStorageInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStorageInfo');
      return {
        'used_mb': result?['used_mb'] ?? 0,
        'total_mb': result?['total_mb'] ?? 0,
      };
    } catch (e) {
      return {'used_mb': 0, 'total_mb': 0};
    }
  }

  Future<Map<String, dynamic>> _getNetworkInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getNetworkInfo');
      return {
        'upload_kbps': result?['upload_kbps'] ?? 0.0,
        'download_kbps': result?['download_kbps'] ?? 0.0,
      };
    } catch (e) {
      return {'upload_kbps': 0.0, 'download_kbps': 0.0};
    }
  }

  void _checkPerformanceThresholds(PerformanceMetric metric) {
    if (metric.type == MetricType.latency && metric.value > _highLatencyThreshold) {
      _reportPerformanceIssue('High latency detected', 
        'Operation ${metric.operation} took ${metric.value}ms (threshold: ${_highLatencyThreshold}ms)');
    }
  }

  void _checkSystemThresholds(SystemMetrics metrics) {
    if (metrics.memoryUsagePercent > _highMemoryUsageThreshold) {
      _reportPerformanceIssue('High memory usage', 
        'Memory usage at ${metrics.memoryUsagePercent.toStringAsFixed(1)}% (threshold: $_highMemoryUsageThreshold%)');
    }
    
    if (metrics.cpuUsage > _highCpuUsageThreshold) {
      _reportPerformanceIssue('High CPU usage', 
        'CPU usage at ${metrics.cpuUsage.toStringAsFixed(1)}% (threshold: $_highCpuUsageThreshold%)');
    }
    
    if (metrics.batteryLevel < _lowBatteryThreshold && !metrics.isCharging) {
      _reportPerformanceIssue('Low battery', 
        'Battery level at ${metrics.batteryLevel.toStringAsFixed(1)}% (threshold: $_lowBatteryThreshold%)');
    }
  }

  void _reportPerformanceIssue(String title, String description) {
    debugPrint('Performance Issue: $title - $description');
    
    // Store performance issue for reporting
    recordMetric('performance_issue', MetricType.operationCount, 1, 'count', metadata: {
      'title': title,
      'description': description,
    });
  }

  /// Schedules periodic metrics flushing to database
  void _scheduleMetricsFlush() {
    Timer.periodic(const Duration(minutes: 5), (_) => _flushMetrics());
  }

  Future<void> _flushMetrics() async {
    if (_metricsBuffer.isEmpty) return;
    
    try {
      await _databaseService.insertPerformanceMetrics(_metricsBuffer);
      debugPrint('Flushed ${_metricsBuffer.length} performance metrics');
      _metricsBuffer.clear();
    } catch (e) {
      debugPrint('Error flushing metrics: $e');
    }
  }

  /// Generates a comprehensive performance report
  Future<PerformanceReport> generatePerformanceReport(DateTime start, DateTime end) async {
    final metricsData = await _databaseService.getPerformanceMetrics(start, end);
    final metrics = metricsData.map((data) => PerformanceMetric.fromJson(data)).toList();
    
    // Calculate average latencies
    final latencyMetrics = metrics.where((m) => m.type == MetricType.latency).toList();
    final averageLatencies = <String, double>{};
    
    for (final group in _groupBy(latencyMetrics, (m) => m.operation).entries) {
      final average = group.value.map((m) => m.value).reduce((a, b) => a + b) / group.value.length;
      averageLatencies[group.key] = average;
    }
    
    // Calculate operation counts
    final operationCounts = Map<String, int>.from(_operationCounts);
    
    // Calculate error rates
    final errorRates = <String, double>{};
    for (final operation in _operationCounts.keys) {
      final totalOps = _operationCounts[operation] ?? 0;
      final errors = _errorCounts[operation] ?? 0;
      errorRates[operation] = totalOps > 0 ? (errors / totalOps) * 100 : 0.0;
    }
    
    // Calculate average system metrics
    final systemMetricsInPeriod = _systemMetricsHistory
        .where((m) => m.timestamp.isAfter(start) && m.timestamp.isBefore(end))
        .toList();
    
    final averageSystemMetrics = _calculateAverageSystemMetrics(systemMetricsInPeriod);
    
    // Identify performance issues
    final performanceIssues = _identifyPerformanceIssues(averageLatencies, errorRates, averageSystemMetrics);
    
    // Generate recommendations
    final recommendations = _generateRecommendations(performanceIssues, averageSystemMetrics);
    
    return PerformanceReport(
      periodStart: start,
      periodEnd: end,
      averageLatencies: averageLatencies,
      operationCounts: operationCounts,
      errorRates: errorRates,
      averageSystemMetrics: averageSystemMetrics,
      performanceIssues: performanceIssues,
      recommendations: recommendations,
    );
  }

  SystemMetrics _calculateAverageSystemMetrics(List<SystemMetrics> metrics) {
    if (metrics.isEmpty) {
      return SystemMetrics(
        cpuUsage: 0, memoryUsagePercent: 0, memoryUsedMB: 0, memoryTotalMB: 0,
        batteryLevel: 0, isCharging: false, storageUsedMB: 0, storageTotalMB: 0,
        networkUpload: 0, networkDownload: 0, timestamp: DateTime.now(),
      );
    }
    
    final count = metrics.length;
    return SystemMetrics(
      cpuUsage: metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) / count,
      memoryUsagePercent: metrics.map((m) => m.memoryUsagePercent).reduce((a, b) => a + b) / count,
      memoryUsedMB: (metrics.map((m) => m.memoryUsedMB).reduce((a, b) => a + b) / count).round(),
      memoryTotalMB: metrics.first.memoryTotalMB,
      batteryLevel: metrics.map((m) => m.batteryLevel).reduce((a, b) => a + b) / count,
      isCharging: metrics.any((m) => m.isCharging),
      storageUsedMB: (metrics.map((m) => m.storageUsedMB).reduce((a, b) => a + b) / count).round(),
      storageTotalMB: metrics.first.storageTotalMB,
      networkUpload: metrics.map((m) => m.networkUpload).reduce((a, b) => a + b) / count,
      networkDownload: metrics.map((m) => m.networkDownload).reduce((a, b) => a + b) / count,
      timestamp: DateTime.now(),
    );
  }

  List<String> _identifyPerformanceIssues(Map<String, double> latencies, Map<String, double> errorRates, SystemMetrics systemMetrics) {
    final issues = <String>[];
    
    // Check high latency operations
    for (final entry in latencies.entries) {
      if (entry.value > _highLatencyThreshold) {
        issues.add('High latency in ${entry.key}: ${entry.value.toStringAsFixed(1)}ms');
      }
    }
    
    // Check high error rates
    for (final entry in errorRates.entries) {
      if (entry.value > 5.0) {
        issues.add('High error rate in ${entry.key}: ${entry.value.toStringAsFixed(1)}%');
      }
    }
    
    // Check system resource usage
    if (systemMetrics.memoryUsagePercent > _highMemoryUsageThreshold) {
      issues.add('High memory usage: ${systemMetrics.memoryUsagePercent.toStringAsFixed(1)}%');
    }
    
    if (systemMetrics.cpuUsage > _highCpuUsageThreshold) {
      issues.add('High CPU usage: ${systemMetrics.cpuUsage.toStringAsFixed(1)}%');
    }
    
    return issues;
  }

  Map<String, dynamic> _generateRecommendations(List<String> issues, SystemMetrics systemMetrics) {
    final recommendations = <String, dynamic>{};
    
    if (systemMetrics.memoryUsagePercent > _highMemoryUsageThreshold) {
      recommendations['memory'] = [
        'Consider reducing data collection frequency',
        'Implement more aggressive data compression',
        'Clear cached data more frequently',
      ];
    }
    
    if (systemMetrics.cpuUsage > _highCpuUsageThreshold) {
      recommendations['cpu'] = [
        'Reduce background processing frequency',
        'Optimize data processing algorithms',
        'Consider moving heavy operations to isolates',
      ];
    }
    
    if (systemMetrics.batteryLevel < _lowBatteryThreshold) {
      recommendations['battery'] = [
        'Enable aggressive power saving mode',
        'Reduce sync frequency',
        'Disable non-essential monitoring features',
      ];
    }
    
    return recommendations;
  }

  Map<K, List<T>> _groupBy<T, K>(Iterable<T> list, K Function(T) keyFunc) {
    final map = <K, List<T>>{};
    for (final item in list) {
      final key = keyFunc(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  String _generateMetricId() {
    return 'metric_${DateTime.now().millisecondsSinceEpoch}_${Object().hashCode}';
  }

  /// Gets current system metrics
  SystemMetrics? getCurrentSystemMetrics() {
    return _lastSystemMetrics;
  }

  /// Gets recent performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'operation_counts': Map.from(_operationCounts),
      'error_counts': Map.from(_errorCounts),
      'active_operations': _activeOperations.keys.toList(),
      'metrics_buffer_size': _metricsBuffer.length,
      'system_metrics_history_size': _systemMetricsHistory.length,
      'is_monitoring': _isMonitoring,
    };
  }

  /// Enables or disables performance monitoring
  void setMonitoringEnabled(bool enabled) {
    _isMonitoring = enabled;
    debugPrint('Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> dispose() async {
    _systemMetricsTimer?.cancel();
    await _flushMetrics();
    debugPrint('PerformanceMonitor disposed');
  }
}