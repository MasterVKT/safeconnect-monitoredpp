import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/app/locator.dart';

enum SecurityThreatLevel { none, low, medium, high, critical }

enum AuthMethod { none, pin, biometric, password }

class SecurityConfiguration {
  final bool appLockEnabled;
  final AuthMethod authMethod;
  final bool autoLockEnabled;
  final Duration autoLockTimeout;

  const SecurityConfiguration({
    this.appLockEnabled = false,
    this.authMethod = AuthMethod.none,
    this.autoLockEnabled = false,
    this.autoLockTimeout = const Duration(minutes: 5),
  });
}

enum SecurityEventType {
  authenticationSuccess,
  authenticationFailure,
  rootDetected,
  debuggerDetected,
  tamperDetected,
  unauthorizedAccess,
  securityBypass
}

class SecurityThreat {
  final String type;
  final String description;
  final SecurityThreatLevel level;
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata;

  SecurityThreat({
    required this.type,
    required this.description,
    required this.level,
    required this.detectedAt,
    this.metadata,
  });
}

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/security');

  final DatabaseService _databaseService = locator<DatabaseService>();
  final List<SecurityThreat> _detectedThreats = [];

  bool _isInitialized = false;
  bool _securityCompromised = false;

  // Authentication state
  bool _appLockEnabled = false;
  AuthMethod _authMethod = AuthMethod.none;
  String? _pinHash;

  // Auto-lock state
  bool _isAutoLockEnabled = false;
  Duration _autoLockTimeout = const Duration(minutes: 5);
  bool _isLocked = false;
  Timer? _autoLockTimer;

  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing security service...');

      // Perform initial security checks
      await _performSecurityScan();

      // Check device admin status
      await _checkDeviceAdminStatus();

      _isInitialized = true;
      debugPrint('Security service initialized');

      // Log initialization
      await _logSecurityEvent(
        'SECURITY_SERVICE_INIT',
        'Security service initialized successfully',
        'medium',
      );
    } catch (e) {
      debugPrint('Error initializing security service: $e');
      await _logSecurityEvent(
        'SECURITY_SERVICE_INIT_FAILED',
        'Failed to initialize security service: $e',
        'high',
      );
    }
  }

  Future<bool> isRootDetected() async {
    try {
      // Check for common root indicators
      final rootIndicators = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
      ];

      for (final path in rootIndicators) {
        if (await File(path).exists()) {
          await _reportThreat(
            'ROOT_DETECTED_FILE',
            'Root file detected: $path',
            SecurityThreatLevel.high,
            {'path': path},
          );
          return true;
        }
      }

      // Check for root apps
      final rootApps = [
        'com.noshufou.android.su',
        'com.noshufou.android.su.elite',
        'eu.chainfire.supersu',
        'com.koushikdutta.superuser',
        'com.thirdparty.superuser',
        'com.yellowes.su',
        'com.topjohnwu.magisk',
      ];

      for (final package in rootApps) {
        if (await _isPackageInstalled(package)) {
          await _reportThreat(
            'ROOT_DETECTED_APP',
            'Root app detected: $package',
            SecurityThreatLevel.high,
            {'package': package},
          );
          return true;
        }
      }

      // Test su command execution
      try {
        final result = await Process.run('which', ['su']);
        if (result.exitCode == 0) {
          await _reportThreat(
            'ROOT_DETECTED_SU',
            'su command available',
            SecurityThreatLevel.high,
          );
          return true;
        }
      } catch (e) {
        // Expected on non-rooted devices
      }

      return false;
    } catch (e) {
      debugPrint('Error checking root status: $e');
      return false;
    }
  }

  Future<bool> isDebuggerDetected() async {
    try {
      // Check if debugger is connected
      if (kDebugMode) {
        await _reportThreat(
          'DEBUG_MODE_DETECTED',
          'Application running in debug mode',
          SecurityThreatLevel.medium,
        );
        return true;
      }

      // Check application flags
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.buildSignature.isEmpty) {
        await _reportThreat(
          'DEBUG_BUILD_DETECTED',
          'Debug build signature detected',
          SecurityThreatLevel.medium,
        );
        return true;
      }

      // Check for debugging tools via native code
      try {
        final isDebugging =
            await _channel.invokeMethod<bool>('isDebuggingDetected') ?? false;
        if (isDebugging) {
          await _reportThreat(
            'DEBUGGER_DETECTED_NATIVE',
            'Native debugger detection triggered',
            SecurityThreatLevel.high,
          );
          return true;
        }
      } catch (e) {
        debugPrint('Native debugging check failed: $e');
      }

      return false;
    } catch (e) {
      debugPrint('Error checking debugger status: $e');
      return false;
    }
  }

  Future<bool> isEmulatorDetected() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Check for emulator indicators
        final emulatorIndicators = [
          androidInfo.brand.toLowerCase().contains('generic'),
          androidInfo.device.toLowerCase().contains('generic'),
          androidInfo.model.toLowerCase().contains('emulator'),
          androidInfo.model.toLowerCase().contains('sdk'),
          androidInfo.product.toLowerCase().contains('sdk'),
          androidInfo.hardware.toLowerCase().contains('goldfish'),
          androidInfo.hardware.toLowerCase().contains('ranchu'),
          androidInfo.fingerprint.toLowerCase().contains('generic'),
        ];

        if (emulatorIndicators.any((indicator) => indicator)) {
          await _reportThreat(
            'EMULATOR_DETECTED',
            'Android emulator environment detected',
            SecurityThreatLevel.medium,
            {
              'brand': androidInfo.brand,
              'device': androidInfo.device,
              'model': androidInfo.model,
              'product': androidInfo.product,
              'hardware': androidInfo.hardware,
            },
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking emulator status: $e');
      return false;
    }
  }

  Future<bool> requestDeviceAdmin() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestDeviceAdmin') ?? false;

      if (result) {
        await _logSecurityEvent(
          'DEVICE_ADMIN_REQUESTED',
          'Device admin privileges requested successfully',
          'medium',
        );
      } else {
        await _logSecurityEvent(
          'DEVICE_ADMIN_REQUEST_FAILED',
          'Failed to request device admin privileges',
          'high',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Error requesting device admin: $e');
      await _logSecurityEvent(
        'DEVICE_ADMIN_REQUEST_ERROR',
        'Error requesting device admin: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> isDeviceAdminActive() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;
    } catch (e) {
      debugPrint('Error checking device admin status: $e');
      return false;
    }
  }

  Future<bool> verifyAppIntegrity() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // Check signature
      if (packageInfo.buildSignature.isEmpty) {
        await _reportThreat(
          'INTEGRITY_NO_SIGNATURE',
          'Application signature missing',
          SecurityThreatLevel.critical,
        );
        return false;
      }

      // Verify expected signature (in production, compare with known good signature)
      // For now, just check that signature exists
      debugPrint(
          'App signature verified: ${packageInfo.buildSignature.substring(0, 10)}...');

      return true;
    } catch (e) {
      debugPrint('Error verifying app integrity: $e');
      await _reportThreat(
        'INTEGRITY_CHECK_FAILED',
        'App integrity verification failed: $e',
        SecurityThreatLevel.high,
      );
      return false;
    }
  }

  Future<void> enableAntiTampering() async {
    try {
      // Enable various anti-tampering measures
      await _enableRuntimeProtection();
      await _enableIntegrityChecks();

      await _logSecurityEvent(
        'ANTI_TAMPERING_ENABLED',
        'Anti-tampering measures activated',
        'medium',
      );
    } catch (e) {
      debugPrint('Error enabling anti-tampering: $e');
      await _logSecurityEvent(
        'ANTI_TAMPERING_FAILED',
        'Failed to enable anti-tampering: $e',
        'high',
      );
    }
  }

  Future<SecurityThreatLevel> getCurrentThreatLevel() async {
    if (_detectedThreats.isEmpty) {
      return SecurityThreatLevel.none;
    }

    // Return highest threat level found
    return _detectedThreats
        .map((threat) => threat.level)
        .reduce((a, b) => a.index > b.index ? a : b);
  }

  List<SecurityThreat> getDetectedThreats() {
    return List.unmodifiable(_detectedThreats);
  }

  Future<void> performSecurityScan() async {
    try {
      await _performSecurityScan();
    } catch (e) {
      debugPrint('Error performing security scan: $e');
    }
  }

  bool get isSecurityCompromised => _securityCompromised;

  // Private methods

  Future<void> _performSecurityScan() async {
    debugPrint('Performing security scan...');

    final checks = [
      isRootDetected(),
      isDebuggerDetected(),
      isEmulatorDetected(),
      verifyAppIntegrity(),
    ];

    final results = await Future.wait(checks);

    // Update security compromised status
    _securityCompromised = results.any((result) => result == true);

    if (_securityCompromised) {
      await _logSecurityEvent(
        'SECURITY_COMPROMISED',
        'Security threats detected during scan',
        'critical',
      );
    }

    debugPrint(
        'Security scan completed. Threats detected: ${_detectedThreats.length}');
  }

  Future<void> _reportThreat(
    String type,
    String description,
    SecurityThreatLevel level, [
    Map<String, dynamic>? metadata,
  ]) async {
    final threat = SecurityThreat(
      type: type,
      description: description,
      level: level,
      detectedAt: DateTime.now(),
      metadata: metadata,
    );

    _detectedThreats.add(threat);

    await _logSecurityEvent(
      type,
      description,
      _threatLevelToString(level),
      metadata: metadata,
    );

    // Send security alert via WebSocket for high/critical threats
    if (level == SecurityThreatLevel.high ||
        level == SecurityThreatLevel.critical) {
      try {
        final webSocketService = locator<WebSocketService>();
        webSocketService.sendSecurityAlert(
          alertType: type,
          description: description,
          severity: _threatLevelToString(level),
          metadata: metadata,
        );
      } catch (e) {
        debugPrint('Error sending security alert via WebSocket: $e');
      }
    }

    debugPrint('Security threat detected: $type - $description');
  }

  Future<void> _logSecurityEvent(
    String eventType,
    String description,
    String severity, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _databaseService.logSecurityEvent(
        eventType: eventType,
        description: description,
        severity: severity,
        metadata: metadata?.toString(),
      );
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  Future<bool> _isPackageInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
          'isPackageInstalled', {'packageName': packageName});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _enableRuntimeProtection() async {
    try {
      await _channel.invokeMethod('enableRuntimeProtection');
    } catch (e) {
      debugPrint('Error enabling runtime protection: $e');
    }
  }

  Future<void> _enableIntegrityChecks() async {
    try {
      await _channel.invokeMethod('enableIntegrityChecks');
    } catch (e) {
      debugPrint('Error enabling integrity checks: $e');
    }
  }

  String _threatLevelToString(SecurityThreatLevel level) {
    switch (level) {
      case SecurityThreatLevel.none:
        return 'none';
      case SecurityThreatLevel.low:
        return 'low';
      case SecurityThreatLevel.medium:
        return 'medium';
      case SecurityThreatLevel.high:
        return 'high';
      case SecurityThreatLevel.critical:
        return 'critical';
    }
  }

  // Lock device functionality
  Future<bool> lockDevice({int durationMinutes = 60}) async {
    try {
      debugPrint('Locking device for $durationMinutes minutes');

      // Use native method channel to lock device
      final result = await _channel.invokeMethod<bool>('lockDevice', {
            'durationMinutes': durationMinutes,
          }) ??
          false;

      if (result) {
        await _logSecurityEvent(
          'DEVICE_LOCKED',
          'Device locked remotely for $durationMinutes minutes',
          'medium',
          metadata: {'duration_minutes': durationMinutes},
        );
      } else {
        await _logSecurityEvent(
          'DEVICE_LOCK_FAILED',
          'Failed to lock device remotely',
          'high',
        );
      }

      return result;
    } catch (e) {
      debugPrint('Error locking device: $e');
      await _logSecurityEvent(
        'DEVICE_LOCK_ERROR',
        'Error locking device: $e',
        'high',
      );
      return false;
    }
  }

  // Update disguise settings
  Future<bool> updateDisguiseSettings(Map<String, dynamic> settings) async {
    try {
      debugPrint('Updating disguise settings: ${settings.keys.join(', ')}');

      // Store disguise settings in database configuration
      for (final entry in settings.entries) {
        await _databaseService.setConfiguration(
            'disguise_${entry.key}', entry.value.toString());
      }

      // Apply settings via native channel if needed
      try {
        await _channel.invokeMethod('updateDisguiseSettings', settings);
      } catch (e) {
        debugPrint('Native disguise settings update failed: $e');
        // Continue with database-only update
      }

      await _logSecurityEvent(
        'DISGUISE_SETTINGS_UPDATED',
        'Disguise settings updated: ${settings.keys.join(', ')}',
        'low',
        metadata: settings,
      );

      return true;
    } catch (e) {
      debugPrint('Error updating disguise settings: $e');
      await _logSecurityEvent(
        'DISGUISE_SETTINGS_ERROR',
        'Error updating disguise settings: $e',
        'medium',
      );
      return false;
    }
  }

  // Configure protection settings
  Future<bool> configureProtection(Map<String, dynamic> config) async {
    try {
      debugPrint('Configuring protection: ${config.keys.join(', ')}');

      // Store protection configuration in database
      for (final entry in config.entries) {
        await _databaseService.setConfiguration(
            'protection_${entry.key}', entry.value.toString());
      }

      // Apply protection settings
      final antiTamperingEnabled = config['anti_tampering'] as bool? ?? false;
      final deviceAdminRequired = config['device_admin'] as bool? ?? false;
      final integrityChecksEnabled =
          config['integrity_checks'] as bool? ?? false;

      if (antiTamperingEnabled) {
        await enableAntiTampering();
      }

      if (deviceAdminRequired) {
        await requestDeviceAdmin();
      }

      if (integrityChecksEnabled) {
        await _enableIntegrityChecks();
      }

      // Apply settings via native channel
      try {
        await _channel.invokeMethod('configureProtection', config);
      } catch (e) {
        debugPrint('Native protection configuration failed: $e');
        // Continue with Dart-only configuration
      }

      await _logSecurityEvent(
        'PROTECTION_CONFIGURED',
        'Protection configuration updated: ${config.keys.join(', ')}',
        'medium',
        metadata: config,
      );

      return true;
    } catch (e) {
      debugPrint('Error configuring protection: $e');
      await _logSecurityEvent(
        'PROTECTION_CONFIG_ERROR',
        'Error configuring protection: $e',
        'high',
      );
      return false;
    }
  }

  // Get current protection status
  Future<Map<String, dynamic>> getProtectionStatus() async {
    try {
      final isDeviceAdmin = await isDeviceAdminActive();
      final threatLevel = await getCurrentThreatLevel();
      final threats = getDetectedThreats();

      return {
        'device_admin_active': isDeviceAdmin,
        'threat_level': _threatLevelToString(threatLevel),
        'threats_detected': threats.length,
        'security_compromised': _securityCompromised,
        'initialized': _isInitialized,
        'latest_threats': threats
            .take(5)
            .map((t) => {
                  'type': t.type,
                  'description': t.description,
                  'level': _threatLevelToString(t.level),
                  'detected_at': t.detectedAt.toIso8601String(),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('Error getting protection status: $e');
      return {
        'error': e.toString(),
        'initialized': _isInitialized,
      };
    }
  }

  // Additional methods for P2P command handler
  Future<bool> restartDevice() async {
    try {
      debugPrint('Attempting to restart device remotely');

      final result =
          await _channel.invokeMethod<bool>('restartDevice') ?? false;

      await _logSecurityEvent(
        'DEVICE_RESTART_REQUESTED',
        result ? 'Device restart initiated remotely' : 'Device restart failed',
        result ? 'medium' : 'high',
      );

      return result;
    } catch (e) {
      debugPrint('Error restarting device: $e');
      await _logSecurityEvent(
        'DEVICE_RESTART_ERROR',
        'Error restarting device: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> wipeDevice() async {
    try {
      debugPrint('Attempting to wipe device remotely - CRITICAL OPERATION');

      final result = await _channel.invokeMethod<bool>('wipeDevice') ?? false;

      await _logSecurityEvent(
        'DEVICE_WIPE_REQUESTED',
        result ? 'Device wipe initiated remotely' : 'Device wipe failed',
        'critical',
      );

      return result;
    } catch (e) {
      debugPrint('Error wiping device: $e');
      await _logSecurityEvent(
        'DEVICE_WIPE_ERROR',
        'Error wiping device: $e',
        'critical',
      );
      return false;
    }
  }

  Future<bool> enableStealthMode() async {
    try {
      await _databaseService.setConfiguration('stealth_mode_enabled', 'true');

      final result =
          await _channel.invokeMethod<bool>('enableStealthMode') ?? false;

      await _logSecurityEvent(
        'STEALTH_MODE_ENABLED',
        'Stealth mode activated',
        'medium',
      );

      return result;
    } catch (e) {
      debugPrint('Error enabling stealth mode: $e');
      return false;
    }
  }

  Future<bool> disableStealthMode() async {
    try {
      await _databaseService.setConfiguration('stealth_mode_enabled', 'false');

      final result =
          await _channel.invokeMethod<bool>('disableStealthMode') ?? false;

      await _logSecurityEvent(
        'STEALTH_MODE_DISABLED',
        'Stealth mode deactivated',
        'medium',
      );

      return result;
    } catch (e) {
      debugPrint('Error disabling stealth mode: $e');
      return false;
    }
  }

  Future<bool> enableDeviceAdmin() async {
    return await requestDeviceAdmin();
  }

  Future<bool> disableDeviceAdmin() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('disableDeviceAdmin') ?? false;

      await _logSecurityEvent(
        'DEVICE_ADMIN_DISABLED',
        result ? 'Device admin disabled' : 'Failed to disable device admin',
        result ? 'medium' : 'high',
      );

      return result;
    } catch (e) {
      debugPrint('Error disabling device admin: $e');
      return false;
    }
  }

  Future<bool> updateSecuritySettings(Map<String, dynamic> settings) async {
    try {
      for (final entry in settings.entries) {
        await _databaseService.setConfiguration(
            'security_${entry.key}', entry.value.toString());
      }

      await _logSecurityEvent(
        'SECURITY_SETTINGS_UPDATED',
        'Security settings updated: ${settings.keys.join(', ')}',
        'medium',
        metadata: settings,
      );

      return true;
    } catch (e) {
      debugPrint('Error updating security settings: $e');
      return false;
    }
  }

  Future<bool> isStealthModeActive() async {
    try {
      final stealthEnabled =
          await _databaseService.getConfiguration('stealth_mode_enabled');
      return stealthEnabled == 'true';
    } catch (e) {
      debugPrint('Error checking stealth mode status: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveThreats() async {
    try {
      return _detectedThreats
          .map((threat) => {
                'type': threat.type,
                'description': threat.description,
                'level': _threatLevelToString(threat.level),
                'detected_at': threat.detectedAt.toIso8601String(),
                'metadata': threat.metadata,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting active threats: $e');
      return [];
    }
  }

  // Encryption/Decryption methods for P2P
  Future<String> encryptData(String data) async {
    try {
      // Simple encryption implementation - in production use proper encryption
      final bytes = data.codeUnits;
      final encrypted = bytes.map((byte) => byte ^ 0xAA).toList();
      return base64Encode(encrypted);
    } catch (e) {
      debugPrint('Error encrypting data: $e');
      rethrow;
    }
  }

  Future<String> decryptData(String encryptedData) async {
    try {
      final encrypted = base64Decode(encryptedData);
      final decrypted = encrypted.map((byte) => byte ^ 0xAA).toList();
      return String.fromCharCodes(decrypted);
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      rethrow;
    }
  }

  // Authentication methods expected by tests
  bool get isAppLockEnabled => _appLockEnabled;
  AuthMethod get authMethod => _authMethod;
  bool get isAutoLockEnabled => _isAutoLockEnabled;
  Duration get autoLockTimeout => _autoLockTimeout;
  bool get isLocked => _isLocked;

  Future<void> enableAutoLock(Duration timeout) async {
    _isAutoLockEnabled = true;
    _autoLockTimeout = timeout;
    _startAutoLockTimer();
    await _logSecurityEvent('AUTO_LOCK_ENABLED', 'Auto-lock enabled with $timeout', 'medium');
  }

  Future<void> disableAutoLock() async {
    _isAutoLockEnabled = false;
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    await _logSecurityEvent('AUTO_LOCK_DISABLED', 'Auto-lock disabled', 'medium');
  }

  void updateLastActivity() {
    if (_isAutoLockEnabled) {
      _startAutoLockTimer();
    }
  }

  void _startAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(_autoLockTimeout, () {
      _isLocked = true;
      debugPrint('[Security] Auto-lock triggered');
    });
  }

  Future<void> updateConfiguration(SecurityConfiguration config) async {
    _appLockEnabled = config.appLockEnabled;
    _authMethod = config.authMethod;
    _isAutoLockEnabled = config.autoLockEnabled;
    _autoLockTimeout = config.autoLockTimeout;
    if (config.autoLockEnabled) {
      _startAutoLockTimer();
    }
    try {
      await _databaseService.setConfiguration(
        'security_config',
        jsonEncode({
          'appLockEnabled': config.appLockEnabled,
          'authMethod': config.authMethod.name,
          'autoLockEnabled': config.autoLockEnabled,
          'autoLockTimeoutMinutes': config.autoLockTimeout.inMinutes,
        }),
      );
    } catch (e) {
      debugPrint('Error saving security configuration: $e');
    }
  }

  Future<bool> setPIN(String pin) async {
    try {
      final pinHash = pin.hashCode.toString();
      _pinHash = pinHash;
      final storageService = locator<StorageService>();
      await storageService.setSecureData('security_pin', pinHash);
      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    }
  }

  Future<bool> changePIN(String currentPin, String newPin) async {
    final isValid = await authenticateWithPIN(currentPin);
    if (!isValid) return false;
    return setPIN(newPin);
  }

  Future<void> logSecurityEvent(SecurityEventType type, String description) async {
    await _logSecurityEvent(type.name, description, 'medium');
  }

  Future<Map<String, dynamic>> getDeviceSecurityStatus() async {
    final isRooted = await isRootDetected();
    final isDebugging = await isDebuggerDetected();
    final isEmulator = await isEmulatorDetected();
    return {
      'isRooted': isRooted,
      'isDebugging': isDebugging,
      'isEmulator': isEmulator,
      'biometricsAvailable': !isRooted && !isDebugging,
    };
  }

  Future<bool> isDeviceSecure() async {
    if (await isRootDetected()) return false;
    if (await isDebuggerDetected()) return false;
    if (await isEmulatorDetected()) return false;
    return true;
  }

  Future<List<Map<String, dynamic>>> getSecurityEventHistory({int days = 7}) async {
    try {
      return await _databaseService.getSecurityEvents(days);
    } catch (e) {
      debugPrint('Error getting security event history: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      // Simulate biometric authentication
      final result =
          await _channel.invokeMethod<bool>('authenticateWithBiometrics') ??
              false;

      if (result) {
        await _logSecurityEvent(
          'BIOMETRIC_AUTH_SUCCESS',
          'Biometric authentication successful',
          'medium',
        );
        return true;
      } else {
        await _logSecurityEvent(
          'BIOMETRIC_AUTH_FAILURE',
          'Biometric authentication failed',
          'medium',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      await _logSecurityEvent(
        'BIOMETRIC_AUTH_ERROR',
        'Biometric authentication error: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> authenticateWithPIN(String pin) async {
    try {
      if (_pinHash == null) return false;

      // Simple hash comparison - in production use proper hashing
      final pinHash = pin.hashCode.toString();
      final result = pinHash == _pinHash;

      if (result) {
        await _logSecurityEvent(
          'PIN_AUTH_SUCCESS',
          'PIN authentication successful',
          'medium',
        );
        return true;
      } else {
        await _logSecurityEvent(
          'PIN_AUTH_FAILURE',
          'PIN authentication failed',
          'medium',
        );
        return false;
      }
    } catch (e) {
      debugPrint('PIN authentication error: $e');
      return false;
    }
  }

  Future<void> enableAppLock(AuthMethod method, {String? pin}) async {
    try {
      _authMethod = method;

      if (method == AuthMethod.pin && pin != null) {
        _pinHash = pin.hashCode.toString();
      }

      _appLockEnabled = true;

      await _logSecurityEvent(
        'APP_LOCK_ENABLED',
        'App lock enabled with method: ${method.name}',
        'medium',
      );
    } catch (e) {
      debugPrint('Error enabling app lock: $e');
    }
  }

  Future<void> disableAppLock() async {
    try {
      _appLockEnabled = false;
      _authMethod = AuthMethod.none;
      _pinHash = null;

      await _logSecurityEvent(
        'APP_LOCK_DISABLED',
        'App lock disabled',
        'medium',
      );
    } catch (e) {
      debugPrint('Error disabling app lock: $e');
    }
  }

  Future<bool> requestDeviceAdminPrivileges() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestDeviceAdmin');

      if (result == true) {
        await _logSecurityEvent(
          'DEVICE_ADMIN_REQUESTED',
          'Device admin privileges requested',
          'medium',
        );
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting device admin: $e');
      await _logSecurityEvent(
        'DEVICE_ADMIN_REQUEST_FAILED',
        'Failed to request device admin: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> wipeDeviceData({bool includeExternal = false}) async {
    try {
      final result = await _channel.invokeMethod<bool>('wipeDeviceData', {
        'includeExternal': includeExternal,
      });

      if (result == true) {
        await _logSecurityEvent(
          'DEVICE_WIPE_INITIATED',
          'Device wipe initiated (includeExternal: $includeExternal)',
          'critical',
        );
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error wiping device: $e');
      await _logSecurityEvent(
        'DEVICE_WIPE_FAILED',
        'Failed to wipe device: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> setCameraDisabled(bool disabled) async {
    try {
      final result = await _channel.invokeMethod<bool>('disableCamera', {
        'disabled': disabled,
      });

      if (result == true) {
        await _logSecurityEvent(
          'CAMERA_POLICY_CHANGED',
          'Camera ${disabled ? "disabled" : "enabled"} by admin policy',
          'medium',
        );
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting camera policy: $e');
      return false;
    }
  }

  Future<bool> isCameraDisabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isCameraDisabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking camera policy: $e');
      return false;
    }
  }

  Future<bool> setPasswordPolicy({
    int minLength = 6,
    bool requireNumbers = true,
    bool requireSymbols = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('setPasswordPolicy', {
        'minLength': minLength,
        'requireNumbers': requireNumbers,
        'requireSymbols': requireSymbols,
      });

      if (result == true) {
        await _logSecurityEvent(
          'PASSWORD_POLICY_UPDATED',
          'Password policy updated: minLength=$minLength, numbers=$requireNumbers, symbols=$requireSymbols',
          'medium',
        );
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting password policy: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getSecurityStatus() async {
    try {
      final result = await _channel
          .invokeMethod<Map<Object?, Object?>>('getSecurityStatus');
      return result?.cast<String, dynamic>() ?? {};
    } catch (e) {
      debugPrint('Error getting security status: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> _checkDeviceAdminStatus() async {
    try {
      final isActive = await isDeviceAdminActive();

      if (!isActive) {
        await _logSecurityEvent(
          'DEVICE_ADMIN_INACTIVE',
          'Device admin protection is not active',
          'high',
        );

        await _addThreat(SecurityThreat(
          type: 'DEVICE_ADMIN_INACTIVE',
          description:
              'Device admin protection is not enabled, app may be vulnerable to uninstallation',
          level: SecurityThreatLevel.high,
          detectedAt: DateTime.now(),
          metadata: {'remediation': 'Enable device admin protection'},
        ));
      } else {
        await _logSecurityEvent(
          'DEVICE_ADMIN_ACTIVE',
          'Device admin protection is active',
          'low',
        );
      }
    } catch (e) {
      debugPrint('Error checking device admin status: $e');
    }
  }

  // Enhanced periodic monitoring with device admin checks
  Future<void> startPeriodicMonitoring() async {
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _performSecurityScan();
      await _checkDeviceAdminStatus();

      // Check for security policy violations
      final securityStatus = await getSecurityStatus();
      final securityLevel = securityStatus['securityLevel'] as String?;

      if (securityLevel == 'CRITICAL' || securityLevel == 'LOW') {
        await _logSecurityEvent(
          'SECURITY_LEVEL_WARNING',
          'Device security level is $securityLevel',
          'high',
        );

        // Send alert via WebSocket
        final webSocketService = locator<WebSocketService>();
        webSocketService.sendSecurityAlert(
          alertType: 'SECURITY_LEVEL_WARNING',
          description: 'Device security level degraded to $securityLevel',
          severity: 'high',
          metadata: securityStatus,
        );
      }
    });
  }

  Future<void> _addThreat(SecurityThreat threat) async {
    try {
      _detectedThreats.add(threat);

      await _logSecurityEvent(
        threat.type,
        threat.description,
        _threatLevelToString(threat.level),
        metadata: threat.metadata,
      );

      // Send security alert via WebSocket for high/critical threats
      if (threat.level == SecurityThreatLevel.high ||
          threat.level == SecurityThreatLevel.critical) {
        try {
          final webSocketService = locator<WebSocketService>();
          webSocketService.sendSecurityAlert(
            alertType: threat.type,
            description: threat.description,
            severity: _threatLevelToString(threat.level),
            metadata: threat.metadata,
          );
        } catch (e) {
          debugPrint('Error sending security alert via WebSocket: $e');
        }
      }

      debugPrint(
          'Security threat added: ${threat.type} - ${threat.description}');
    } catch (e) {
      debugPrint('Error adding security threat: $e');
    }
  }

  Future<void> dispose() async {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    _detectedThreats.clear();
    _isInitialized = false;
    _securityCompromised = false;
    _appLockEnabled = false;
    _authMethod = AuthMethod.none;
    _pinHash = null;
    _isAutoLockEnabled = false;
    _isLocked = false;
  }
}
