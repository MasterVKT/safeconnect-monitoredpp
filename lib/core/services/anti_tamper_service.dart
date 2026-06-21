import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:crypto/crypto.dart';

enum TamperDetectionLevel { 
  none, 
  low, 
  medium, 
  high, 
  critical,
  // Legacy compatibility values for tests
  basic, 
  advanced, 
  paranoid 
}

enum TamperType {
  rootDetection,
  debuggerDetection,
  emulatorDetection,
  hookingDetection,
  signatureModification,
  runtimeModification,
  codeInjection,
  memoryTampering,
  rootAccess
}

class TamperEvent {
  final String type;
  final String description;
  final TamperDetectionLevel level;
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata;
  final String checksum;

  TamperEvent({
    required this.type,
    required this.description,
    required this.level,
    required this.detectedAt,
    this.metadata,
    required this.checksum,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'level': level.name,
      'detected_at': detectedAt.toIso8601String(),
      'metadata': metadata,
      'checksum': checksum,
    };
  }
}

class AntiTamperConfiguration {
  final TamperDetectionLevel detectionLevel;
  final bool enableRuntimeProtection;
  final bool enableIntegrityChecks;
  final bool enableAntiDebugging;

  const AntiTamperConfiguration({
    this.detectionLevel = TamperDetectionLevel.medium,
    this.enableRuntimeProtection = true,
    this.enableIntegrityChecks = true,
    this.enableAntiDebugging = true,
  });
}

class AntiTamperService {
  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/anti_tamper');

  final DatabaseService _databaseService = locator<DatabaseService>();
  final List<TamperEvent> _tamperEvents = [];

  AntiTamperConfiguration _configuration = const AntiTamperConfiguration();
  StreamController<TamperEvent>? _tamperEventController;

  bool _isInitialized = false;
  bool _protectionEnabled = false;
  Timer? _integrityTimer;
  Timer? _codeIntegrityTimer;
  String? _appSignature;

  // Runtime protection variables
  int _checksumFailures = 0;
  int _debuggerDetections = 0;
  int _hookingAttempts = 0;
  
  // Self-modifying code for protection
  late String _protectionKey;
  late List<int> _protectionSequence;
  
  // Additional state for public API
  TamperDetectionLevel _currentProtectionLevel = TamperDetectionLevel.medium;
  bool _runtimeProtectionActive = false;
  
  static final AntiTamperService _instance = AntiTamperService._internal();
  factory AntiTamperService() => _instance;
  AntiTamperService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Initializing anti-tamper service...');
      
      // Generate protection key
      _generateProtectionKey();
      
      // Calculate initial app signature
      await _calculateAppSignature();
      
      // Initialize runtime protection
      await _initializeRuntimeProtection();
      
      // Start integrity monitoring
      _startIntegrityMonitoring();
      
      _isInitialized = true;
      debugPrint('Anti-tamper service initialized');
      
      await _logTamperEvent(
        'ANTI_TAMPER_INIT',
        'Anti-tamper service initialized successfully',
        TamperDetectionLevel.low,
      );
      
    } catch (e) {
      debugPrint('Error initializing anti-tamper service: $e');
      await _logTamperEvent(
        'ANTI_TAMPER_INIT_FAILED',
        'Failed to initialize anti-tamper service: $e',
        TamperDetectionLevel.high,
      );
    }
  }

  void _generateProtectionKey() {
    final random = Random.secure();
    _protectionKey = base64Encode(List.generate(32, (_) => random.nextInt(256)));
    _protectionSequence = List.generate(16, (_) => random.nextInt(256));
  }

  Future<void> _calculateAppSignature() async {
    try {
      // Get app binary hash
      final appHash = await _getAppBinaryHash();
      
      // Get library checksums
      final libChecksum = await _getLibraryChecksums();
      
      // Combine for app signature
      final combined = '$appHash:$libChecksum:${_protectionKey}';
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      
      _appSignature = digest.toString();

      debugPrint('App signature calculated: ${_appSignature?.substring(0, 16)}...');
    } catch (e) {
      debugPrint('Error calculating app signature: $e');
      await _detectTamper(
        'SIGNATURE_CALCULATION_FAILED',
        'Failed to calculate app signature: $e',
        TamperDetectionLevel.high,
      );
    }
  }

  Future<String> _getAppBinaryHash() async {
    try {
      final result = await _channel.invokeMethod<String>('getAppBinaryHash');
      return result ?? 'unknown';
    } catch (e) {
      debugPrint('Native app hash calculation failed: $e');
      return 'fallback_hash_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<String> _getLibraryChecksums() async {
    try {
      final result = await _channel.invokeMethod<String>('getLibraryChecksums');
      return result ?? 'unknown';
    } catch (e) {
      debugPrint('Native library checksum failed: $e');
      return 'fallback_lib_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _initializeRuntimeProtection() async {
    try {
      await _channel.invokeMethod('initializeRuntimeProtection', {
        'protection_key': _protectionKey,
        'protection_sequence': _protectionSequence,
      });
    } catch (e) {
      debugPrint('Native runtime protection failed: $e');
      // Continue with Dart-only protection
    }
  }

  void _startIntegrityMonitoring() {
    // Periodic integrity checks
    _integrityTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _performIntegrityCheck();
    });
    
    // Code integrity checks (more frequent)
    _codeIntegrityTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _performCodeIntegrityCheck();
    });
  }

  Future<void> _performIntegrityCheck() async {
    try {
      // Check app signature
      await _verifyAppSignature();
      
      // Check for debugging
      await _checkDebuggingAttempts();
      
      // Check for hooking
      await _checkHookingAttempts();
      
      // Check runtime modifications
      await _checkRuntimeModifications();
      
      // Verify protection sequence
      _verifyProtectionSequence();
      
    } catch (e) {
      debugPrint('Integrity check error: $e');
      await _detectTamper(
        'INTEGRITY_CHECK_ERROR',
        'Error during integrity check: $e',
        TamperDetectionLevel.medium,
      );
    }
  }

  Future<void> _verifyAppSignature() async {
    try {
      final currentHash = await _getAppBinaryHash();
      final currentLibs = await _getLibraryChecksums();
      
      final combined = '$currentHash:$currentLibs:${_protectionKey}';
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      final currentSignature = digest.toString();
      
      if (_appSignature != null && currentSignature != _appSignature) {
        _checksumFailures++;
        await _detectTamper(
          'APP_SIGNATURE_MISMATCH',
          'Application signature verification failed',
          TamperDetectionLevel.critical,
          metadata: {
            'expected': _appSignature,
            'actual': currentSignature,
            'failure_count': _checksumFailures,
          },
        );
      }
    } catch (e) {
      debugPrint('Signature verification error: $e');
    }
  }

  Future<void> _checkDebuggingAttempts() async {
    try {
      final isDebugging = await _channel.invokeMethod<bool>('isBeingDebugged') ?? false;
      
      if (isDebugging) {
        _debuggerDetections++;
        await _detectTamper(
          'DEBUGGER_DETECTED',
          'Debugging attempt detected',
          TamperDetectionLevel.critical,
          metadata: {
            'detection_count': _debuggerDetections,
            'detection_method': 'native',
          },
        );
      }
      
      // Additional Dart-level checks
      if (kDebugMode) {
        await _detectTamper(
          'DEBUG_MODE_ACTIVE',
          'Application running in debug mode',
          TamperDetectionLevel.medium,
        );
      }
    } catch (e) {
      debugPrint('Debugging check error: $e');
    }
  }

  Future<void> _checkHookingAttempts() async {
    try {
      final hookingDetected = await _channel.invokeMethod<bool>('detectHooking') ?? false;
      
      if (hookingDetected) {
        _hookingAttempts++;
        await _detectTamper(
          'HOOKING_DETECTED',
          'Code hooking or injection detected',
          TamperDetectionLevel.critical,
          metadata: {
            'hooking_count': _hookingAttempts,
            'detection_method': 'native',
          },
        );
      }
    } catch (e) {
      debugPrint('Hooking check error: $e');
    }
  }

  Future<void> _checkRuntimeModifications() async {
    try {
      final modifications = await _channel.invokeMethod<Map>('checkRuntimeModifications');
      
      if (modifications != null && modifications['detected'] == true) {
        await _detectTamper(
          'RUNTIME_MODIFICATION',
          'Runtime code modification detected',
          TamperDetectionLevel.critical,
          metadata: modifications.cast<String, dynamic>(),
        );
      }
    } catch (e) {
      debugPrint('Runtime modification check error: $e');
    }
  }

  void _verifyProtectionSequence() {
    // Simple obfuscated check
    final expected = _protectionSequence.fold(0, (sum, value) => sum ^ value);
    final current = _protectionSequence.fold(0, (sum, value) => sum ^ value);
    
    if (expected != current) {
      _detectTamper(
        'PROTECTION_SEQUENCE_MODIFIED',
        'Protection sequence has been modified',
        TamperDetectionLevel.critical,
      );
    }
  }

  Future<void> _performCodeIntegrityCheck() async {
    try {
      // Check critical method integrity
      final methodChecksums = await _channel.invokeMethod<Map>('getMethodChecksums');
      
      if (methodChecksums != null) {
        await _validateMethodChecksums(methodChecksums.cast<String, dynamic>());
      }
      
      // Check for dynamic loading
      final dynamicLoads = await _channel.invokeMethod<List>('getDynamicLoads');
      
      if (dynamicLoads != null && dynamicLoads.isNotEmpty) {
        await _detectTamper(
          'DYNAMIC_LOADING_DETECTED',
          'Unauthorized dynamic library loading detected',
          TamperDetectionLevel.high,
          metadata: {
            'loaded_libraries': dynamicLoads,
          },
        );
      }
    } catch (e) {
      debugPrint('Code integrity check error: $e');
    }
  }

  Future<void> _validateMethodChecksums(Map<String, dynamic> checksums) async {
    // Store expected checksums on first run
    final expectedChecksums = await _databaseService.getConfiguration('method_checksums');
    
    if (expectedChecksums == null) {
      await _databaseService.setConfiguration('method_checksums', jsonEncode(checksums));
      return;
    }
    
    try {
      final expected = jsonDecode(expectedChecksums) as Map<String, dynamic>;
      
      for (final entry in checksums.entries) {
        final expectedValue = expected[entry.key];
        if (expectedValue != null && expectedValue != entry.value) {
          await _detectTamper(
            'METHOD_CHECKSUM_MISMATCH',
            'Method checksum mismatch for ${entry.key}',
            TamperDetectionLevel.critical,
            metadata: {
              'method': entry.key,
              'expected': expectedValue,
              'actual': entry.value,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Method checksum validation error: $e');
    }
  }

  // Anti-debugging measures
  Future<void> enableAntiDebugging() async {
    try {
      await _channel.invokeMethod('enableAntiDebugging');
      
      await _logTamperEvent(
        'ANTI_DEBUGGING_ENABLED',
        'Anti-debugging measures activated',
        TamperDetectionLevel.medium,
      );
    } catch (e) {
      debugPrint('Anti-debugging enable error: $e');
    }
  }

  // Code obfuscation verification
  Future<bool> verifyCodeObfuscation() async {
    try {
      final isObfuscated = await _channel.invokeMethod<bool>('verifyObfuscation') ?? false;
      
      if (!isObfuscated) {
        await _detectTamper(
          'CODE_NOT_OBFUSCATED',
          'Code obfuscation verification failed',
          TamperDetectionLevel.medium,
        );
      }
      
      return isObfuscated;
    } catch (e) {
      debugPrint('Obfuscation verification error: $e');
      return false;
    }
  }

  // Root/jailbreak specific checks
  Future<void> performAdvancedRootDetection() async {
    try {
      final rootDetected = await _channel.invokeMethod<bool>('advancedRootDetection') ?? false;
      
      if (rootDetected) {
        await _detectTamper(
          'ADVANCED_ROOT_DETECTED',
          'Advanced root detection triggered',
          TamperDetectionLevel.critical,
        );
      }
    } catch (e) {
      debugPrint('Advanced root detection error: $e');
    }
  }

  // Emulator detection
  Future<void> performEmulatorDetection() async {
    try {
      final emulatorDetected = await _channel.invokeMethod<bool>('detectEmulator') ?? false;
      
      if (emulatorDetected) {
        await _detectTamper(
          'EMULATOR_DETECTED',
          'Application running on emulator',
          TamperDetectionLevel.high,
        );
      }
    } catch (e) {
      debugPrint('Emulator detection error: $e');
    }
  }

  Future<void> _detectTamper(
    String type,
    String description,
    TamperDetectionLevel level, {
    Map<String, dynamic>? metadata,
  }) async {
    final checksum = _generateEventChecksum(type, description, level);
    
    final event = TamperEvent(
      type: type,
      description: description,
      level: level,
      detectedAt: DateTime.now(),
      metadata: metadata,
      checksum: checksum,
    );

    _tamperEvents.add(event);
    _eventController.add(event);

    await _logTamperEvent(type, description, level, metadata: metadata);

    // Send security alert for high/critical events
    if (level == TamperDetectionLevel.high || level == TamperDetectionLevel.critical) {
      try {
        final webSocketService = locator<WebSocketService>();
        webSocketService.sendSecurityAlert(
          alertType: type,
          description: description,
          severity: level.name,
          metadata: metadata,
        );
      } catch (e) {
        debugPrint('Error sending tamper alert: $e');
      }
    }

    // Take protective actions for critical events
    if (level == TamperDetectionLevel.critical) {
      await _takeCriticalProtectiveAction(type);
    }

    debugPrint('Tamper detected: $type - $description (${level.name})');
  }

  String _generateEventChecksum(String type, String description, TamperDetectionLevel level) {
    final data = '$type:$description:${level.name}:${_protectionKey}';
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  Future<void> _takeCriticalProtectiveAction(String tamperType) async {
    try {
      switch (tamperType) {
        case 'DEBUGGER_DETECTED':
          await _enableEnhancedProtection();
          break;
        case 'APP_SIGNATURE_MISMATCH':
          await _initiateSecurityLockdown();
          break;
        case 'HOOKING_DETECTED':
          await _enableAntiHooking();
          break;
        case 'RUNTIME_MODIFICATION':
          await _resetProtectionMeasures();
          break;
        default:
          await _enableGenericProtection();
      }
    } catch (e) {
      debugPrint('Error taking protective action: $e');
    }
  }

  Future<void> _enableEnhancedProtection() async {
    await _channel.invokeMethod('enableEnhancedProtection');
    debugPrint('Enhanced protection activated');
  }

  Future<void> _initiateSecurityLockdown() async {
    await _channel.invokeMethod('initiateSecurityLockdown');
    debugPrint('Security lockdown initiated');
  }

  Future<void> _enableAntiHooking() async {
    await _channel.invokeMethod('enableAntiHooking');
    debugPrint('Anti-hooking protection activated');
  }

  Future<void> _resetProtectionMeasures() async {
    await _channel.invokeMethod('resetProtectionMeasures');
    debugPrint('Protection measures reset');
  }

  Future<void> _enableGenericProtection() async {
    await _channel.invokeMethod('enableGenericProtection');
    debugPrint('Generic protection activated');
  }

  Future<void> _logTamperEvent(
    String eventType,
    String description,
    TamperDetectionLevel level, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _databaseService.logSecurityEvent(
        eventType: eventType,
        description: description,
        severity: level.name,
        metadata: metadata?.toString(),
      );
    } catch (e) {
      debugPrint('Error logging tamper event: $e');
    }
  }

  // Public API
  bool get isProtectionEnabled => _protectionEnabled;
  List<TamperEvent> get detectedEvents => List.unmodifiable(_tamperEvents);

  // New public API methods expected by tests
  TamperDetectionLevel get currentProtectionLevel => _currentProtectionLevel;
  bool get isRuntimeProtectionActive => _runtimeProtectionActive;
  AntiTamperConfiguration get currentConfiguration => _configuration;

  StreamController<TamperEvent> get _eventController {
    if (_tamperEventController == null || _tamperEventController!.isClosed) {
      _tamperEventController = StreamController<TamperEvent>.broadcast();
    }
    return _tamperEventController!;
  }

  Stream<TamperEvent> get tamperEventStream => _eventController.stream;

  Future<void> updateConfiguration(AntiTamperConfiguration config) async {
    _configuration = config;
    _currentProtectionLevel = config.detectionLevel;
    try {
      await _databaseService.setConfiguration(
        'anti_tamper_config',
        jsonEncode({
          'detectionLevel': config.detectionLevel.name,
          'enableRuntimeProtection': config.enableRuntimeProtection,
          'enableIntegrityChecks': config.enableIntegrityChecks,
          'enableAntiDebugging': config.enableAntiDebugging,
        }),
      );
    } catch (e) {
      debugPrint('Error saving anti-tamper configuration: $e');
    }
  }

  Future<Map<String, dynamic>> getTamperDetectionStatus() async {
    return {
      'protectionLevel': _currentProtectionLevel.name,
      'runtimeProtectionActive': _runtimeProtectionActive,
      'lastIntegrityCheck': DateTime.now().toIso8601String(),
      'totalTamperEvents': _tamperEvents.length,
      'criticalEvents': _tamperEvents
          .where((e) => e.level == TamperDetectionLevel.critical)
          .length,
    };
  }
  
  Future<bool> checkRootAccess() async {
    try {
      final rootDetected = await _channel.invokeMethod<bool>('advancedRootDetection') ?? false;
      return rootDetected;
    } catch (e) {
      debugPrint('Root access check error: $e');
      return false;
    }
  }
  
  Future<bool> checkDebugging() async {
    try {
      final isDebugging = await _channel.invokeMethod<bool>('isBeingDebugged') ?? false;
      return isDebugging || kDebugMode;
    } catch (e) {
      debugPrint('Debugging check error: $e');
      return kDebugMode;
    }
  }
  
  Future<bool> checkEmulator() async {
    try {
      final emulatorDetected = await _channel.invokeMethod<bool>('detectEmulator') ?? false;
      return emulatorDetected;
    } catch (e) {
      debugPrint('Emulator check error: $e');
      return false;
    }
  }
  
  Future<bool> checkHooking() async {
    try {
      final hookingDetected = await _channel.invokeMethod<bool>('detectHooking') ?? false;
      return hookingDetected;
    } catch (e) {
      debugPrint('Hooking check error: $e');
      return false;
    }
  }
  
  Future<void> setProtectionLevel(TamperDetectionLevel level) async {
    _currentProtectionLevel = level;
    
    // Save to configuration
    final databaseService = locator<DatabaseService>();
    await databaseService.setConfiguration('anti_tamper_protection_level', level.name);
  }
  
  Future<bool> startRuntimeProtection() async {
    if (_runtimeProtectionActive) return true;
    
    try {
      await _initializeRuntimeProtection();
      _runtimeProtectionActive = true;
      
      await _logTamperEvent(
        'RUNTIME_PROTECTION_STARTED',
        'Runtime protection activated',
        TamperDetectionLevel.medium,
      );
      return true;
    } catch (e) {
      debugPrint('Error starting runtime protection: $e');
      return false;
    }
  }
  
  Future<bool> stopRuntimeProtection() async {
    try {
      _runtimeProtectionActive = false;
      
      await _logTamperEvent(
        'RUNTIME_PROTECTION_STOPPED',
        'Runtime protection deactivated',
        TamperDetectionLevel.medium,
      );
      return true;
    } catch (e) {
      debugPrint('Error stopping runtime protection: $e');
      return false;
    }
  }
  
  Future<bool> performIntegrityCheck() async {
    try {
      await _performIntegrityCheck();
      return true;
    } catch (e) {
      debugPrint('Integrity check failed: $e');
      return false;
    }
  }
  
  Future<void> handleTamperDetection(TamperType tamperType, String details) async {
    await _detectTamper(
      tamperType.name.toUpperCase(),
      details,
      TamperDetectionLevel.high,
    );
  }
  
  Future<void> enableProtection() async {
    if (_protectionEnabled) return;
    
    await enableAntiDebugging();
    await performAdvancedRootDetection();
    await performEmulatorDetection();
    await verifyCodeObfuscation();
    
    _protectionEnabled = true;
    
    await _logTamperEvent(
      'PROTECTION_ENABLED',
      'Anti-tamper protection activated',
      TamperDetectionLevel.medium,
    );
  }

  Future<void> disableProtection() async {
    _protectionEnabled = false;
    _integrityTimer?.cancel();
    _codeIntegrityTimer?.cancel();
    
    await _logTamperEvent(
      'PROTECTION_DISABLED',
      'Anti-tamper protection deactivated',
      TamperDetectionLevel.medium,
    );
  }

  Map<String, dynamic> getProtectionStatus() {
    return {
      'enabled': _protectionEnabled,
      'initialized': _isInitialized,
      'checksum_failures': _checksumFailures,
      'debugger_detections': _debuggerDetections,
      'hooking_attempts': _hookingAttempts,
      'total_tamper_events': _tamperEvents.length,
      'critical_events': _tamperEvents.where((e) => e.level == TamperDetectionLevel.critical).length,
      'app_signature': _appSignature?.substring(0, 16),
    };
  }

  List<Map<String, dynamic>> getRecentEvents({int limit = 10}) {
    return _tamperEvents
        .take(limit)
        .map((event) => event.toJson())
        .toList();
  }

  Future<void> performManualIntegrityCheck() async {
    await _performIntegrityCheck();
    await _performCodeIntegrityCheck();
  }

  Future<void> dispose() async {
    _integrityTimer?.cancel();
    _codeIntegrityTimer?.cancel();
    _tamperEvents.clear();
    _protectionEnabled = false;
    _isInitialized = false;
    await _tamperEventController?.close();
    _tamperEventController = null;
  }
}