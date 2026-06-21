import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/core/services/rasp_service.dart';
import 'package:monitored_app/core/services/notification_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

enum SecurityThreatLevel { none, low, medium, high, critical }

enum ThreatCategory {
  rootAccess,
  debugging,
  tampering,
  reverseEngineering,
  networkAnomaly,
  locationSpoofing,
  injectionAttempt,
  privilegeEscalation,
  dataExfiltration,
  maliciousApp
}

class SecurityThreat {
  final String id;
  final ThreatCategory category;
  final SecurityThreatLevel level;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;
  final List<String> indicators;
  final String source;
  final bool isHandled;

  SecurityThreat({
    required this.id,
    required this.category,
    required this.level,
    required this.description,
    required this.detectedAt,
    required this.metadata,
    required this.indicators,
    required this.source,
    this.isHandled = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'level': level.name,
        'description': description,
        'detected_at': detectedAt.toIso8601String(),
        'metadata': metadata,
        'indicators': indicators,
        'source': source,
        'is_handled': isHandled,
      };
}

class SecurityBaseline {
  final String deviceId;
  final Map<String, dynamic> systemProfile;
  final List<String> installedApps;
  final Map<String, dynamic> networkProfile;
  final Map<String, dynamic> behaviorProfile;
  final DateTime createdAt;

  SecurityBaseline({
    required this.deviceId,
    required this.systemProfile,
    required this.installedApps,
    required this.networkProfile,
    required this.behaviorProfile,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'system_profile': systemProfile,
        'installed_apps': installedApps,
        'network_profile': networkProfile,
        'behavior_profile': behaviorProfile,
        'created_at': createdAt.toIso8601String(),
      };
}

class SecurityMonitoringService {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/security');

  final DatabaseService _databaseService = locator<DatabaseService>();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  final SecurityService _securityService = locator<SecurityService>();
  final RASPService _raspService = locator<RASPService>();
  final NotificationService _notificationService =
      locator<NotificationService>();

  final List<SecurityThreat> _activeThreats = [];
  final List<StreamSubscription> _subscriptions = [];
  Timer? _monitoringTimer;
  Timer? _baselineUpdateTimer;

  bool _isInitialized = false;
  bool _isMonitoring = false;
  SecurityBaseline? _currentBaseline;

  // Threat detection algorithms
  final Map<String, double> _anomalyThresholds = {
    'cpu_usage': 80.0,
    'memory_usage': 85.0,
    'network_connections': 50.0,
    'file_access_rate': 100.0,
    'permission_requests': 10.0,
  };

  // ML-like behavior analysis
  final Map<String, List<double>> _behaviorHistory = {};
  final int _maxHistorySize = 100;

  static final SecurityMonitoringService _instance =
      SecurityMonitoringService._internal();
  factory SecurityMonitoringService() => _instance;
  SecurityMonitoringService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing Security Monitoring service...');

      // Initialize security baseline
      await _createSecurityBaseline();

      // Start monitoring systems
      await startMonitoring();

      // Schedule baseline updates
      _scheduleBaselineUpdates();

      _isInitialized = true;
      debugPrint('Security Monitoring service initialized');

      await _logSecurityEvent(
        'SECURITY_MONITORING_INIT',
        'Security monitoring service initialized successfully',
        SecurityThreatLevel.none,
      );
    } catch (e) {
      debugPrint('Error initializing Security Monitoring service: $e');
      await _logSecurityEvent(
        'MONITORING_INIT_FAILED',
        'Failed to initialize security monitoring: $e',
        SecurityThreatLevel.high,
      );
    }
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      _isMonitoring = true;

      // Start real-time monitoring
      await _startRealTimeMonitoring();

      // Subscribe to system events
      _subscribeToSecurityEvents();

      // Start periodic threat scanning
      _startPeriodicScans();

      debugPrint('Security monitoring started');
    } catch (e) {
      debugPrint('Error starting security monitoring: $e');
      _isMonitoring = false;
    }
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      _isMonitoring = false;

      // Cancel timers
      _monitoringTimer?.cancel();
      _baselineUpdateTimer?.cancel();

      // Cancel subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      debugPrint('Security monitoring stopped');
    } catch (e) {
      debugPrint('Error stopping security monitoring: $e');
    }
  }

  Future<void> _createSecurityBaseline() async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();

      // Collect system profile
      final systemProfile = await _collectSystemProfile();

      // Get installed apps
      final installedApps = await _getInstalledApps();

      // Collect network profile
      final networkProfile = await _collectNetworkProfile();

      // Initialize behavior profile
      final behaviorProfile = <String, dynamic>{
        'app_usage_patterns': {},
        'network_patterns': {},
        'system_calls': {},
        'file_access_patterns': {},
      };

      _currentBaseline = SecurityBaseline(
        deviceId: deviceId,
        systemProfile: systemProfile,
        installedApps: installedApps,
        networkProfile: networkProfile,
        behaviorProfile: behaviorProfile,
        createdAt: DateTime.now(),
      );

      // Store baseline
      await _storeBaseline(_currentBaseline!);

      debugPrint('Security baseline created');
    } catch (e) {
      debugPrint('Error creating security baseline: $e');
    }
  }

  Future<Map<String, dynamic>> _collectSystemProfile() async {
    try {
      final profile = await _channel
          .invokeMethod<Map<Object?, Object?>>('getSystemProfile');
      return profile?.cast<String, dynamic>() ?? {};
    } catch (e) {
      debugPrint('Error collecting system profile: $e');
      return {};
    }
  }

  Future<List<String>> _getInstalledApps() async {
    try {
      final apps =
          await _channel.invokeMethod<List<Object?>>('getInstalledApps');
      return apps?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _collectNetworkProfile() async {
    try {
      final profile = await _channel
          .invokeMethod<Map<Object?, Object?>>('getNetworkProfile');
      return profile?.cast<String, dynamic>() ?? {};
    } catch (e) {
      debugPrint('Error collecting network profile: $e');
      return {};
    }
  }

  Future<void> _startRealTimeMonitoring() async {
    try {
      await _channel.invokeMethod('startRealTimeMonitoring');
      debugPrint('Real-time monitoring started');
    } catch (e) {
      debugPrint('Error starting real-time monitoring: $e');
    }
  }

  void _subscribeToSecurityEvents() {
    // Subscribe to RASP violations (implementation via stream pending)
    _raspService.getViolations();

    // Subscribe to system security events
    _channel.setMethodCallHandler(_handleSecurityEvent);
  }

  Future<void> _handleSecurityEvent(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onSecurityThreat':
          final data = call.arguments as Map<Object?, Object?>;
          await _processThreatDetection(data.cast<String, dynamic>());
          break;
        case 'onAnomalyDetected':
          final data = call.arguments as Map<Object?, Object?>;
          await _processAnomalyDetection(data.cast<String, dynamic>());
          break;
        case 'onSystemEvent':
          final data = call.arguments as Map<Object?, Object?>;
          await _processSystemEvent(data.cast<String, dynamic>());
          break;
      }
    } catch (e) {
      debugPrint('Error handling security event: $e');
    }
  }

  void _startPeriodicScans() {
    _monitoringTimer?.cancel();

    // Comprehensive scan every 5 minutes
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _performComprehensiveScan();
    });
  }

  Future<void> _performComprehensiveScan() async {
    if (!_isMonitoring) return;

    try {
      // Check for new threats
      await _scanForNewThreats();

      // Analyze behavior patterns
      await _analyzeBehaviorPatterns();

      // Check baseline deviations
      await _checkBaselineDeviations();

      // Validate security controls
      await _validateSecurityControls();

      // Update threat intelligence
      await _updateThreatIntelligence();
    } catch (e) {
      debugPrint('Error during comprehensive scan: $e');
    }
  }

  Future<void> _scanForNewThreats() async {
    try {
      // Scan for root access attempts
      await _checkRootAccess();

      // Scan for debugging attempts
      await _checkDebugging();

      // Scan for tampering
      await _checkTampering();

      // Scan for malicious apps
      await _checkMaliciousApps();

      // Scan for network anomalies
      await _checkNetworkAnomalies();
    } catch (e) {
      debugPrint('Error scanning for threats: $e');
    }
  }

  Future<void> _checkRootAccess() async {
    try {
      final securityStatus = await _securityService.getSecurityStatus();

      if (securityStatus['isRootDetected'] == true) {
        await _createThreat(
          category: ThreatCategory.rootAccess,
          level: SecurityThreatLevel.critical,
          description: 'Root access detected on device',
          indicators: [
            'su_binary_found',
            'root_apps_installed',
            'system_partition_writable'
          ],
          source: 'security_service',
          metadata: securityStatus,
        );
      }
    } catch (e) {
      debugPrint('Error checking root access: $e');
    }
  }

  Future<void> _checkDebugging() async {
    try {
      final isDebugging =
          await _channel.invokeMethod<bool>('isDebuggingActive');

      if (isDebugging == true) {
        await _createThreat(
          category: ThreatCategory.debugging,
          level: SecurityThreatLevel.high,
          description: 'Active debugging session detected',
          indicators: ['debugger_attached', 'debug_mode_enabled'],
          source: 'rasp_system',
          metadata: {'detection_method': 'native_check'},
        );
      }
    } catch (e) {
      debugPrint('Error checking debugging: $e');
    }
  }

  Future<void> _checkTampering() async {
    try {
      final raspStatus = await _raspService.getRASPStatus();
      final checks = raspStatus['checks'] as Map<String, dynamic>?;

      if (checks != null) {
        for (final entry in checks.entries) {
          if (entry.value == false) {
            await _createThreat(
              category: ThreatCategory.tampering,
              level: SecurityThreatLevel.high,
              description: 'Application tampering detected: ${entry.key}',
              indicators: ['integrity_check_failed', entry.key],
              source: 'integrity_monitor',
              metadata: {'failed_check': entry.key, 'rasp_status': raspStatus},
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking tampering: $e');
    }
  }

  Future<void> _checkMaliciousApps() async {
    try {
      if (_currentBaseline == null) return;

      final currentApps = await _getInstalledApps();
      final baselineApps = _currentBaseline!.installedApps;

      // Check for new suspicious apps
      final newApps =
          currentApps.where((app) => !baselineApps.contains(app)).toList();

      for (final app in newApps) {
        final riskScore = await _calculateAppRiskScore(app);

        if (riskScore > 0.7) {
          await _createThreat(
            category: ThreatCategory.maliciousApp,
            level: SecurityThreatLevel.medium,
            description: 'Suspicious application installed: $app',
            indicators: ['new_app_high_risk', 'permissions_suspicious'],
            source: 'app_analyzer',
            metadata: {'app_name': app, 'risk_score': riskScore},
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking malicious apps: $e');
    }
  }

  Future<double> _calculateAppRiskScore(String appName) async {
    try {
      // Simple heuristic-based risk scoring
      double score = 0.0;

      final suspiciousKeywords = [
        'hack',
        'crack',
        'cheat',
        'mod',
        'xposed',
        'substrate',
        'frida',
        'root',
        'supersu',
        'magisk',
        'lucky',
        'game',
        'guardian'
      ];

      final lowerAppName = appName.toLowerCase();

      for (final keyword in suspiciousKeywords) {
        if (lowerAppName.contains(keyword)) {
          score += 0.3;
        }
      }

      // Check app permissions (would require native implementation)
      final permissions = await _getAppPermissions(appName);
      final dangerousPermissions = permissions
          .where((perm) =>
              perm.contains('SYSTEM') ||
              perm.contains('ROOT') ||
              perm.contains('ADMIN'))
          .length;

      score += dangerousPermissions * 0.2;

      return min(score, 1.0);
    } catch (e) {
      debugPrint('Error calculating app risk score: $e');
      return 0.0;
    }
  }

  Future<List<String>> _getAppPermissions(String appName) async {
    try {
      final permissions = await _channel.invokeMethod<List<Object?>>(
          'getAppPermissions', {'appName': appName});
      return permissions?.cast<String>() ?? [];
    } catch (e) {
      debugPrint('Error getting app permissions: $e');
      return [];
    }
  }

  Future<void> _checkNetworkAnomalies() async {
    try {
      final networkStats =
          await _channel.invokeMethod<Map<Object?, Object?>>('getNetworkStats');
      final stats = networkStats?.cast<String, dynamic>() ?? {};

      // Check for unusual network activity
      final activeConnections = stats['active_connections'] as int? ?? 0;

      if (activeConnections > _anomalyThresholds['network_connections']!) {
        await _createThreat(
          category: ThreatCategory.networkAnomaly,
          level: SecurityThreatLevel.medium,
          description: 'Excessive network connections detected',
          indicators: ['high_connection_count', 'potential_c2_communication'],
          source: 'network_monitor',
          metadata: {
            'active_connections': activeConnections,
            'threshold': _anomalyThresholds['network_connections']
          },
        );
      }

      // Check for data exfiltration patterns
      await _checkDataExfiltration(stats);
    } catch (e) {
      debugPrint('Error checking network anomalies: $e');
    }
  }

  Future<void> _checkDataExfiltration(Map<String, dynamic> networkStats) async {
    try {
      final uploadRate = networkStats['upload_rate'] as double? ?? 0.0;
      final downloadRate = networkStats['download_rate'] as double? ?? 0.0;

      // Detect unusual upload patterns (potential data exfiltration)
      if (uploadRate > downloadRate * 3 && uploadRate > 1024 * 1024) {
        // 1MB/s upload threshold
        await _createThreat(
          category: ThreatCategory.dataExfiltration,
          level: SecurityThreatLevel.high,
          description: 'Potential data exfiltration detected',
          indicators: ['high_upload_rate', 'upload_download_ratio_anomaly'],
          source: 'network_analyzer',
          metadata: {
            'upload_rate': uploadRate,
            'download_rate': downloadRate,
            'ratio': uploadRate / max(downloadRate, 1),
          },
        );
      }
    } catch (e) {
      debugPrint('Error checking data exfiltration: $e');
    }
  }

  Future<void> _analyzeBehaviorPatterns() async {
    try {
      // Collect current behavior metrics
      final currentMetrics = await _collectBehaviorMetrics();

      // Update behavior history
      _updateBehaviorHistory(currentMetrics);

      // Detect anomalies using statistical analysis
      await _detectBehaviorAnomalies(currentMetrics);
    } catch (e) {
      debugPrint('Error analyzing behavior patterns: $e');
    }
  }

  Future<Map<String, double>> _collectBehaviorMetrics() async {
    try {
      final metrics = await _channel
          .invokeMethod<Map<Object?, Object?>>('getBehaviorMetrics');
      return metrics?.cast<String, double>() ?? {};
    } catch (e) {
      debugPrint('Error collecting behavior metrics: $e');
      return {};
    }
  }

  void _updateBehaviorHistory(Map<String, double> metrics) {
    for (final entry in metrics.entries) {
      final key = entry.key;
      final value = entry.value;

      _behaviorHistory[key] ??= [];
      _behaviorHistory[key]!.add(value);

      // Keep only recent history
      if (_behaviorHistory[key]!.length > _maxHistorySize) {
        _behaviorHistory[key]!.removeAt(0);
      }
    }
  }

  Future<void> _detectBehaviorAnomalies(
      Map<String, double> currentMetrics) async {
    for (final entry in currentMetrics.entries) {
      final key = entry.key;
      final value = entry.value;

      final history = _behaviorHistory[key];
      if (history == null || history.length < 10) continue;

      // Calculate statistical measures
      final mean = history.reduce((a, b) => a + b) / history.length;
      final variance =
          history.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
              history.length;
      final stdDev = sqrt(variance);

      // Check for anomalies (values beyond 2 standard deviations)
      if ((value - mean).abs() > 2 * stdDev && stdDev > 0) {
        await _createThreat(
          category: ThreatCategory.reverseEngineering,
          level: SecurityThreatLevel.medium,
          description: 'Behavioral anomaly detected in $key',
          indicators: ['statistical_anomaly', 'behavior_deviation'],
          source: 'behavior_analyzer',
          metadata: {
            'metric': key,
            'current_value': value,
            'expected_mean': mean,
            'standard_deviation': stdDev,
            'deviation_factor': (value - mean).abs() / stdDev,
          },
        );
      }
    }
  }

  Future<void> _checkBaselineDeviations() async {
    if (_currentBaseline == null) return;

    try {
      // Check for system profile changes
      final currentSystemProfile = await _collectSystemProfile();
      await _compareSystemProfiles(
          _currentBaseline!.systemProfile, currentSystemProfile);

      // Check for app changes
      final currentApps = await _getInstalledApps();
      await _compareAppLists(_currentBaseline!.installedApps, currentApps);
    } catch (e) {
      debugPrint('Error checking baseline deviations: $e');
    }
  }

  Future<void> _compareSystemProfiles(
      Map<String, dynamic> baseline, Map<String, dynamic> current) async {
    final criticalKeys = [
      'build_fingerprint',
      'security_patch',
      'selinux_status',
      'dm_verity_status'
    ];

    for (final key in criticalKeys) {
      if (baseline[key] != current[key]) {
        await _createThreat(
          category: ThreatCategory.tampering,
          level: SecurityThreatLevel.high,
          description: 'Critical system property changed: $key',
          indicators: ['system_modification', 'baseline_deviation'],
          source: 'baseline_monitor',
          metadata: {
            'property': key,
            'baseline_value': baseline[key],
            'current_value': current[key],
          },
        );
      }
    }
  }

  Future<void> _compareAppLists(
      List<String> baseline, List<String> current) async {
    // Check for removed system apps (potential tampering)
    final removedApps = baseline
        .where((app) => !current.contains(app) && _isSystemApp(app))
        .toList();

    if (removedApps.isNotEmpty) {
      await _createThreat(
        category: ThreatCategory.tampering,
        level: SecurityThreatLevel.medium,
        description: 'System applications removed: ${removedApps.join(', ')}',
        indicators: ['system_app_removal', 'potential_tampering'],
        source: 'app_monitor',
        metadata: {'removed_apps': removedApps},
      );
    }
  }

  bool _isSystemApp(String appName) {
    final systemPackages = [
      'com.android.systemui',
      'com.android.settings',
      'com.google.android.gms',
      'com.android.vending',
    ];

    return systemPackages.any((pkg) => appName.contains(pkg));
  }

  Future<void> _validateSecurityControls() async {
    try {
      // Validate that all security services are running
      final securityStatus = await _securityService.getSecurityStatus();
      final raspStatus = await _raspService.getProtectionStatus();

      if (securityStatus['isSecurityServiceActive'] != true) {
        await _createThreat(
          category: ThreatCategory.tampering,
          level: SecurityThreatLevel.critical,
          description: 'Security service has been disabled',
          indicators: ['security_service_inactive', 'protection_bypass'],
          source: 'control_validator',
          metadata: securityStatus,
        );
      }

      if (raspStatus['is_monitoring'] != true) {
        await _createThreat(
          category: ThreatCategory.tampering,
          level: SecurityThreatLevel.high,
          description: 'RASP monitoring has been disabled',
          indicators: ['rasp_disabled', 'runtime_protection_bypass'],
          source: 'control_validator',
          metadata: raspStatus,
        );
      }
    } catch (e) {
      debugPrint('Error validating security controls: $e');
    }
  }

  Future<void> _updateThreatIntelligence() async {
    try {
      // In a real implementation, this would fetch updated threat intelligence
      // from a remote server and update local threat detection rules
      debugPrint('Updating threat intelligence...');
    } catch (e) {
      debugPrint('Error updating threat intelligence: $e');
    }
  }

  Future<void> _createThreat({
    required ThreatCategory category,
    required SecurityThreatLevel level,
    required String description,
    required List<String> indicators,
    required String source,
    required Map<String, dynamic> metadata,
  }) async {
    final threat = SecurityThreat(
      id: _generateThreatId(),
      category: category,
      level: level,
      description: description,
      detectedAt: DateTime.now(),
      metadata: metadata,
      indicators: indicators,
      source: source,
    );

    _activeThreats.add(threat);

    // Log the threat
    await _logThreat(threat);

    // Handle the threat
    await _handleThreat(threat);

    // Send real-time alert
    await _sendThreatAlert(threat);
  }

  String _generateThreatId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'THR_${timestamp}_$random';
  }

  Future<void> _logThreat(SecurityThreat threat) async {
    try {
      await _databaseService.insertEmergencyEvent({
        'event_type': 'THREAT_DETECTED',
        'description': threat.description,
        'severity': threat.level.name,
        'metadata': {
          ...threat.metadata,
          'threat_id': threat.id,
          'category': threat.category.name,
          'indicators': threat.indicators,
          'source': threat.source,
        },
      });
    } catch (e) {
      debugPrint('Error logging threat: $e');
    }
  }

  Future<void> _handleThreat(SecurityThreat threat) async {
    // Automated threat response based on level and category
    switch (threat.level) {
      case SecurityThreatLevel.critical:
        await _handleCriticalThreat(threat);
        break;
      case SecurityThreatLevel.high:
        await _handleHighThreat(threat);
        break;
      case SecurityThreatLevel.medium:
        await _handleMediumThreat(threat);
        break;
      case SecurityThreatLevel.low:
        await _handleLowThreat(threat);
        break;
      case SecurityThreatLevel.none:
        // Log only
        break;
    }
  }

  Future<void> _handleCriticalThreat(SecurityThreat threat) async {
    // Immediate response for critical threats
    await _notificationService.showEmergencyNotification(
      'Critical Security Threat',
      threat.description,
    );

    // Activate emergency protocols
    switch (threat.category) {
      case ThreatCategory.rootAccess:
        await _activateRootProtection();
        break;
      case ThreatCategory.tampering:
        await _activateAntiTamperMode();
        break;
      default:
        await _activateGeneralProtection();
    }
  }

  Future<void> _handleHighThreat(SecurityThreat threat) async {
    // Enhanced monitoring and protection
    await _increaseMonitoringFrequency();
    await _enableEnhancedProtection();
  }

  Future<void> _handleMediumThreat(SecurityThreat threat) async {
    // Standard response
    await _logSecurityEvent(
      'THREAT_RESPONSE',
      'Medium threat handled: ${threat.description}',
      SecurityThreatLevel.medium,
      threat.metadata,
    );
  }

  Future<void> _handleLowThreat(SecurityThreat threat) async {
    // Log and monitor
    await _logSecurityEvent(
      'THREAT_RESPONSE',
      'Low threat logged: ${threat.description}',
      SecurityThreatLevel.low,
      threat.metadata,
    );
  }

  Future<void> _activateRootProtection() async {
    // Implement root-specific protection measures
    debugPrint('Activating root protection measures');
  }

  Future<void> _activateAntiTamperMode() async {
    // Implement anti-tamper measures
    debugPrint('Activating anti-tamper mode');
  }

  Future<void> _activateGeneralProtection() async {
    // Implement general protection measures
    debugPrint('Activating general protection measures');
  }

  Future<void> _increaseMonitoringFrequency() async {
    // Increase scan frequency for enhanced monitoring
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _performComprehensiveScan();
    });
  }

  Future<void> _enableEnhancedProtection() async {
    // Enable additional protection layers
    debugPrint('Enhanced protection enabled');
  }

  Future<void> _sendThreatAlert(SecurityThreat threat) async {
    try {
      _webSocketService.sendSecurityAlert(
        alertType: 'THREAT_DETECTED',
        description: threat.description,
        severity: threat.level.name,
        metadata: {
          ...threat.metadata,
          'threat_id': threat.id,
          'category': threat.category.name,
          'indicators': threat.indicators,
          'source': threat.source,
        },
      );
    } catch (e) {
      debugPrint('Error sending threat alert: $e');
    }
  }

  Future<void> _processThreatDetection(Map<String, dynamic> data) async {
    // Process threat detection from native layer
    await _createThreat(
      category: ThreatCategory.values.firstWhere(
        (cat) => cat.name == data['category'],
        orElse: () => ThreatCategory.tampering,
      ),
      level: SecurityThreatLevel.values.firstWhere(
        (level) => level.name == data['level'],
        orElse: () => SecurityThreatLevel.medium,
      ),
      description: data['description'] ?? 'Unknown threat detected',
      indicators: List<String>.from(data['indicators'] ?? []),
      source: data['source'] ?? 'native_detection',
      metadata: data,
    );
  }

  Future<void> _processAnomalyDetection(Map<String, dynamic> data) async {
    // Process anomaly detection from native layer
    await _createThreat(
      category: ThreatCategory.reverseEngineering,
      level: SecurityThreatLevel.medium,
      description: 'System anomaly detected: ${data['type']}',
      indicators: ['anomaly_detected', data['type']],
      source: 'anomaly_detector',
      metadata: data,
    );
  }

  Future<void> _processSystemEvent(Map<String, dynamic> data) async {
    // Process system security events
    final eventType = data['event_type'] as String?;

    switch (eventType) {
      case 'permission_request':
        await _handlePermissionRequest(data);
        break;
      case 'network_event':
        await _handleNetworkEvent(data);
        break;
      case 'file_access':
        await _handleFileAccess(data);
        break;
    }
  }

  Future<void> _handlePermissionRequest(Map<String, dynamic> data) async {
    final permission = data['permission'] as String?;
    final requestingApp = data['app'] as String?;

    // Check for suspicious permission requests
    final dangerousPermissions = [
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
      'android.permission.READ_SMS',
      'android.permission.CALL_PHONE',
    ];

    if (permission != null && dangerousPermissions.contains(permission)) {
      await _createThreat(
        category: ThreatCategory.privilegeEscalation,
        level: SecurityThreatLevel.low,
        description:
            'Dangerous permission requested: $permission by $requestingApp',
        indicators: ['dangerous_permission', permission],
        source: 'permission_monitor',
        metadata: data,
      );
    }
  }

  Future<void> _handleNetworkEvent(Map<String, dynamic> data) async {
    // Handle network security events
    final eventType = data['type'] as String?;

    if (eventType == 'suspicious_connection') {
      await _createThreat(
        category: ThreatCategory.networkAnomaly,
        level: SecurityThreatLevel.medium,
        description: 'Suspicious network connection detected',
        indicators: ['suspicious_connection', 'unknown_endpoint'],
        source: 'network_monitor',
        metadata: data,
      );
    }
  }

  Future<void> _handleFileAccess(Map<String, dynamic> data) async {
    // Handle file access security events
    final filePath = data['file_path'] as String?;
    final accessType = data['access_type'] as String?;

    // Check for access to sensitive files
    final sensitiveFiles = ['/system/', '/data/data/', '/proc/', '/dev/'];

    if (filePath != null &&
        sensitiveFiles.any((path) => filePath.startsWith(path))) {
      await _createThreat(
        category: ThreatCategory.privilegeEscalation,
        level: SecurityThreatLevel.medium,
        description: 'Access to sensitive file: $filePath ($accessType)',
        indicators: ['sensitive_file_access', accessType ?? 'unknown'],
        source: 'file_monitor',
        metadata: data,
      );
    }
  }

  void _scheduleBaselineUpdates() {
    _baselineUpdateTimer?.cancel();

    // Update baseline daily
    _baselineUpdateTimer = Timer.periodic(const Duration(days: 1), (_) async {
      await _updateBaseline();
    });
  }

  Future<void> _updateBaseline() async {
    try {
      await _createSecurityBaseline();
      debugPrint('Security baseline updated');
    } catch (e) {
      debugPrint('Error updating baseline: $e');
    }
  }

  Future<void> _storeBaseline(SecurityBaseline baseline) async {
    try {
      await _databaseService.storeSecurityBaseline(baseline.toJson());
    } catch (e) {
      debugPrint('Error storing baseline: $e');
    }
  }

  Future<void> _logSecurityEvent(
    String eventType,
    String description,
    SecurityThreatLevel level, [
    Map<String, dynamic>? metadata,
  ]) async {
    try {
      await _databaseService.insertEmergencyEvent({
        'event_type': eventType,
        'description': description,
        'severity': level.name,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  // Public interface methods

  List<SecurityThreat> getActiveThreats() => List.unmodifiable(_activeThreats);

  List<SecurityThreat> getThreatsByCategory(ThreatCategory category) =>
      _activeThreats.where((threat) => threat.category == category).toList();

  List<SecurityThreat> getThreatsByLevel(SecurityThreatLevel level) =>
      _activeThreats.where((threat) => threat.level == level).toList();

  SecurityBaseline? getCurrentBaseline() => _currentBaseline;

  Map<String, dynamic> getMonitoringStatus() => {
        'is_initialized': _isInitialized,
        'is_monitoring': _isMonitoring,
        'active_threats': _activeThreats.length,
        'baseline_created': _currentBaseline != null,
        'last_scan': DateTime.now().toIso8601String(),
        'threat_categories': _getThreadCategoryStats(),
        'threat_levels': _getThreatLevelStats(),
      };

  Map<String, int> _getThreadCategoryStats() {
    final stats = <String, int>{};
    for (final category in ThreatCategory.values) {
      stats[category.name] = getThreatsByCategory(category).length;
    }
    return stats;
  }

  Map<String, int> _getThreatLevelStats() {
    final stats = <String, int>{};
    for (final level in SecurityThreatLevel.values) {
      stats[level.name] = getThreatsByLevel(level).length;
    }
    return stats;
  }

  Future<void> clearHandledThreats() async {
    _activeThreats.removeWhere((threat) => threat.isHandled);
    await _logSecurityEvent(
      'THREATS_CLEARED',
      'Handled threats cleared from active list',
      SecurityThreatLevel.none,
    );
  }

  Future<void> markThreatHandled(String threatId) async {
    final threatIndex =
        _activeThreats.indexWhere((threat) => threat.id == threatId);
    if (threatIndex != -1) {
      // Create a new threat with isHandled = true (since SecurityThreat is immutable)
      final oldThreat = _activeThreats[threatIndex];
      final handledThreat = SecurityThreat(
        id: oldThreat.id,
        category: oldThreat.category,
        level: oldThreat.level,
        description: oldThreat.description,
        detectedAt: oldThreat.detectedAt,
        metadata: oldThreat.metadata,
        indicators: oldThreat.indicators,
        source: oldThreat.source,
        isHandled: true,
      );

      _activeThreats[threatIndex] = handledThreat;

      await _logSecurityEvent(
        'THREAT_HANDLED',
        'Threat marked as handled: ${oldThreat.description}',
        SecurityThreatLevel.none,
        {'threat_id': threatId},
      );
    }
  }

  Future<void> dispose() async {
    await stopMonitoring();
    _activeThreats.clear();
    _behaviorHistory.clear();
    _currentBaseline = null;
    _isInitialized = false;
    debugPrint('Security Monitoring service disposed');
  }
}
