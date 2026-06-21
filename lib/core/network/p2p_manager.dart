import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/network/p2p_communication_service.dart';
import 'package:monitored_app/core/network/p2p_signaling_service.dart';
import 'package:monitored_app/core/network/p2p_command_handler.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

enum P2PManagerState {
  uninitialized,
  initializing,
  ready,
  connecting,
  connected,
  disconnected,
  error
}

class P2PConnectionInfo {
  final String peerId;
  final String deviceId;
  final String deviceName;
  final DateTime connectedAt;
  final Map<String, dynamic> metadata;

  P2PConnectionInfo({
    required this.peerId,
    required this.deviceId,
    required this.deviceName,
    required this.connectedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'peer_id': peerId,
    'device_id': deviceId,
    'device_name': deviceName,
    'connected_at': connectedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory P2PConnectionInfo.fromJson(Map<String, dynamic> json) => P2PConnectionInfo(
    peerId: json['peer_id'],
    deviceId: json['device_id'],
    deviceName: json['device_name'],
    connectedAt: DateTime.parse(json['connected_at']),
    metadata: json['metadata'] ?? {},
  );
}

class P2PDataTransfer {
  final String id;
  final String type; // 'file', 'media', 'data'
  final String fromPeerId;
  final String? toPeerId;
  final int totalSize;
  final int transferredSize;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status; // 'pending', 'active', 'completed', 'failed', 'cancelled'
  final Map<String, dynamic> metadata;

  P2PDataTransfer({
    required this.id,
    required this.type,
    required this.fromPeerId,
    this.toPeerId,
    required this.totalSize,
    required this.transferredSize,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.metadata = const {},
  });

  double get progress => totalSize > 0 ? (transferredSize / totalSize) : 0.0;
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isActive => status == 'active';
}

class P2PManager {
  static final P2PManager _instance = P2PManager._internal();
  factory P2PManager() => _instance;
  P2PManager._internal();

  late P2PCommunicationService _communicationService;
  late P2PSignalingService _signalingService;
  late P2PCommandHandler _commandHandler;
  late StorageService _storageService;
  late DatabaseService _databaseService;

  final StreamController<P2PManagerState> _stateController = StreamController<P2PManagerState>.broadcast();
  final StreamController<P2PConnectionInfo> _connectionController = StreamController<P2PConnectionInfo>.broadcast();
  final StreamController<P2PMessage> _messageController = StreamController<P2PMessage>.broadcast();
  final StreamController<P2PDataTransfer> _transferController = StreamController<P2PDataTransfer>.broadcast();

  final Map<String, P2PConnectionInfo> _activeConnections = {};
  final Map<String, P2PDataTransfer> _activeTransfers = {};
  final List<String> _trustedDevices = [];
  final List<String> _blockedDevices = [];

  P2PManagerState _state = P2PManagerState.uninitialized;
  Timer? _connectionHealthTimer;
  bool _autoAcceptConnections = false;
  bool _encryptCommunications = true;

  // Public API
  P2PManagerState get state => _state;
  Stream<P2PManagerState> get stateStream => _stateController.stream;
  Stream<P2PConnectionInfo> get connectionStream => _connectionController.stream;
  Stream<P2PMessage> get messageStream => _messageController.stream;
  Stream<P2PDataTransfer> get transferStream => _transferController.stream;
  
  List<P2PConnectionInfo> get activeConnections => _activeConnections.values.toList();
  List<P2PDataTransfer> get activeTransfers => _activeTransfers.values.toList();
  bool get hasActiveConnections => _activeConnections.isNotEmpty;
  int get connectionCount => _activeConnections.length;

  Future<void> initialize() async {
    if (_state != P2PManagerState.uninitialized) return;

    _updateState(P2PManagerState.initializing);

    try {
      _communicationService = locator<P2PCommunicationService>();
      _signalingService = locator<P2PSignalingService>();
      _commandHandler = locator<P2PCommandHandler>();
      _storageService = locator<StorageService>();
      _databaseService = locator<DatabaseService>();

      await _loadConfiguration();
      await _loadTrustedDevices();
      _setupEventHandlers();
      _startConnectionHealthMonitoring();

      _updateState(P2PManagerState.ready);
      debugPrint('P2P Manager initialized successfully');
    } catch (e) {
      debugPrint('P2P Manager initialization failed: $e');
      _updateState(P2PManagerState.error);
      rethrow;
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await _storageService.read('p2p_config');
      if (config != null) {
        final configData = jsonDecode(config);
        _autoAcceptConnections = configData['auto_accept_connections'] ?? false;
        _encryptCommunications = configData['encrypt_communications'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading P2P configuration: $e');
    }
  }

  Future<void> _loadTrustedDevices() async {
    try {
      final trustedDevicesData = await _storageService.read('trusted_devices');
      if (trustedDevicesData != null) {
        final List<dynamic> devices = jsonDecode(trustedDevicesData);
        _trustedDevices.clear();
        _trustedDevices.addAll(devices.cast<String>());
      }

      final blockedDevicesData = await _storageService.read('blocked_devices');
      if (blockedDevicesData != null) {
        final List<dynamic> devices = jsonDecode(blockedDevicesData);
        _blockedDevices.clear();
        _blockedDevices.addAll(devices.cast<String>());
      }
    } catch (e) {
      debugPrint('Error loading trusted/blocked devices: $e');
    }
  }

  void _setupEventHandlers() {
    // Listen for signaling messages
    _signalingService.signalingStream.listen((message) {
      _handleSignalingMessage(message);
    });

    // Listen for peer messages
    _communicationService.globalMessageStream.listen((message) {
      _messageController.add(message);
      _handleIncomingMessage(message);
    });

    // Listen for signaling events
    _signalingService.signalingStream.listen((signalingMessage) {
      _handleSignalingEvent(signalingMessage);
    });
  }


  void _handlePeerDisconnection(String peerId) {
    final connectionInfo = _activeConnections.remove(peerId);
    if (connectionInfo != null) {
      debugPrint('P2P connection lost: $peerId');
      _logConnectionEvent('peer_disconnected', peerId);
    }
  }

  void _handleIncomingMessage(P2PMessage message) {
    // Handle special message types
    switch (message.type) {
      case 'file_transfer_request':
        _handleFileTransferRequest(message);
        break;
      case 'file_chunk':
        _handleFileChunk(message);
        break;
      case 'transfer_status':
        _handleTransferStatus(message);
        break;
    }
  }

  void _handleSignalingEvent(SignalingMessage signalingMessage) {
    debugPrint('Signaling event: ${signalingMessage.type} from ${signalingMessage.fromDeviceId}');
  }

  void _startConnectionHealthMonitoring() {
    _connectionHealthTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkConnectionHealth();
    });
  }

  void _checkConnectionHealth() {
    for (final peerId in _activeConnections.keys.toList()) {
      final peer = _signalingService.getPeer(peerId);
      if (peer == null || peer.state != P2PConnectionState.connected) {
        _handlePeerDisconnection(peerId);
      }
    }
  }

  // Connection Management API
  Future<bool> connectToDevice(String deviceId, {Map<String, dynamic>? metadata}) async {
    if (_state != P2PManagerState.ready) {
      debugPrint('P2P Manager not ready for connections');
      return false;
    }

    if (_blockedDevices.contains(deviceId)) {
      debugPrint('Device is blocked: $deviceId');
      return false;
    }

    _updateState(P2PManagerState.connecting);

    try {
      final success = await _signalingService.connectToPeer(deviceId);
      
      if (success) {
        _updateState(P2PManagerState.connected);
        await _addTrustedDevice(deviceId);
        _logConnectionEvent('connection_initiated', deviceId);
        return true;
      } else {
        _updateState(P2PManagerState.ready);
        return false;
      }
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      _updateState(P2PManagerState.error);
      return false;
    }
  }

  Future<bool> disconnectFromDevice(String deviceId) async {
    try {
      final success = await _signalingService.disconnectFromPeer(deviceId);
      _logConnectionEvent('connection_terminated', deviceId);
      return success;
    } catch (e) {
      debugPrint('Error disconnecting from device: $e');
      return false;
    }
  }

  Future<void> disconnectAll() async {
    try {
      await _signalingService.disconnectFromAllPeers();
      _activeConnections.clear();
      _updateState(P2PManagerState.ready);
      debugPrint('Disconnected from all peers');
    } catch (e) {
      debugPrint('Error disconnecting from all peers: $e');
    }
  }

  // Communication API
  Future<bool> sendMessage(String deviceId, String type, Map<String, dynamic> data) async {
    if (!_activeConnections.containsKey(deviceId)) {
      debugPrint('Device not connected: $deviceId');
      return false;
    }

    try {
      return await _communicationService.sendSecureMessage(
        deviceId,
        'command_main',
        type,
        data,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendCommand(String deviceId, String command, Map<String, dynamic> parameters) async {
    if (!_activeConnections.containsKey(deviceId)) {
      debugPrint('Device not connected: $deviceId');
      return null;
    }

    try {
      return await _commandHandler.sendCommand(command, parameters);
    } catch (e) {
      debugPrint('Error sending command: $e');
      return null;
    }
  }

  // File Transfer API
  Future<String?> sendFile(String deviceId, String filePath, {Function(double)? onProgress}) async {
    if (!_activeConnections.containsKey(deviceId)) {
      debugPrint('Device not connected: $deviceId');
      return null;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File not found: $filePath');
        return null;
      }

      final fileSize = await file.length();
      final transferId = _generateTransferId();
      
      final transfer = P2PDataTransfer(
        id: transferId,
        type: 'file',
        fromPeerId: await DeviceUtils.getDeviceIdentifier(),
        toPeerId: deviceId,
        totalSize: fileSize,
        transferredSize: 0,
        startedAt: DateTime.now(),
        status: 'pending',
        metadata: {
          'file_name': filePath.split('/').last,
          'file_path': filePath,
        },
      );

      _activeTransfers[transferId] = transfer;
      _transferController.add(transfer);

      // Start file transfer
      final success = await _communicationService.sendFile(
        deviceId,
        filePath,
        onProgress: (progress) {
          final updatedTransfer = P2PDataTransfer(
            id: transferId,
            type: transfer.type,
            fromPeerId: transfer.fromPeerId,
            toPeerId: transfer.toPeerId,
            totalSize: transfer.totalSize,
            transferredSize: (transfer.totalSize * progress).round(),
            startedAt: transfer.startedAt,
            completedAt: progress >= 1.0 ? DateTime.now() : null,
            status: progress >= 1.0 ? 'completed' : 'active',
            metadata: transfer.metadata,
          );
          
          _activeTransfers[transferId] = updatedTransfer;
          _transferController.add(updatedTransfer);
          onProgress?.call(progress);
        },
      );

      if (success) {
        return transferId;
      } else {
        _activeTransfers.remove(transferId);
        return null;
      }
    } catch (e) {
      debugPrint('Error sending file: $e');
      return null;
    }
  }

  void cancelTransfer(String transferId) {
    final transfer = _activeTransfers[transferId];
    if (transfer != null && transfer.isActive) {
      final cancelledTransfer = P2PDataTransfer(
        id: transfer.id,
        type: transfer.type,
        fromPeerId: transfer.fromPeerId,
        toPeerId: transfer.toPeerId,
        totalSize: transfer.totalSize,
        transferredSize: transfer.transferredSize,
        startedAt: transfer.startedAt,
        completedAt: DateTime.now(),
        status: 'cancelled',
        metadata: transfer.metadata,
      );
      
      _activeTransfers[transferId] = cancelledTransfer;
      _transferController.add(cancelledTransfer);
      
      debugPrint('Transfer cancelled: $transferId');
    }
  }

  // Device Management API
  Future<void> addTrustedDevice(String deviceId) async {
    await _addTrustedDevice(deviceId);
  }

  Future<void> _addTrustedDevice(String deviceId) async {
    if (!_trustedDevices.contains(deviceId)) {
      _trustedDevices.add(deviceId);
      await _saveTrustedDevices();
      debugPrint('Added trusted device: $deviceId');
    }
  }

  Future<void> removeTrustedDevice(String deviceId) async {
    _trustedDevices.remove(deviceId);
    await _saveTrustedDevices();
    debugPrint('Removed trusted device: $deviceId');
  }

  Future<void> blockDevice(String deviceId) async {
    if (!_blockedDevices.contains(deviceId)) {
      _blockedDevices.add(deviceId);
      await _saveBlockedDevices();
      
      // Disconnect if currently connected
      await disconnectFromDevice(deviceId);
      
      debugPrint('Blocked device: $deviceId');
    }
  }

  Future<void> unblockDevice(String deviceId) async {
    _blockedDevices.remove(deviceId);
    await _saveBlockedDevices();
    debugPrint('Unblocked device: $deviceId');
  }

  bool isTrustedDevice(String deviceId) => _trustedDevices.contains(deviceId);
  bool isBlockedDevice(String deviceId) => _blockedDevices.contains(deviceId);
  List<String> get trustedDevices => List.unmodifiable(_trustedDevices);
  List<String> get blockedDevices => List.unmodifiable(_blockedDevices);

  // Configuration API
  Future<void> setAutoAcceptConnections(bool enabled) async {
    _autoAcceptConnections = enabled;
    await _saveConfiguration();
  }

  Future<void> setEncryptCommunications(bool enabled) async {
    _encryptCommunications = enabled;
    await _saveConfiguration();
  }

  bool get autoAcceptConnections => _autoAcceptConnections;
  bool get encryptCommunications => _encryptCommunications;

  // Helper methods
  void _handleFileTransferRequest(P2PMessage message) {
    // Handle incoming file transfer requests
    debugPrint('File transfer request received from ${message.id}');
  }

  void _handleFileChunk(P2PMessage message) {
    // Handle incoming file chunks
  }

  void _handleTransferStatus(P2PMessage message) {
    // Handle transfer status updates
  }

  Future<void> _saveConfiguration() async {
    final config = {
      'auto_accept_connections': _autoAcceptConnections,
      'encrypt_communications': _encryptCommunications,
    };
    await _storageService.write('p2p_config', jsonEncode(config));
  }

  Future<void> _saveTrustedDevices() async {
    await _storageService.write('trusted_devices', jsonEncode(_trustedDevices));
  }

  Future<void> _saveBlockedDevices() async {
    await _storageService.write('blocked_devices', jsonEncode(_blockedDevices));
  }

  void _updateState(P2PManagerState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
      debugPrint('P2P Manager state changed to: $newState');
    }
  }

  Future<void> _logConnectionEvent(String eventType, String deviceId) async {
    try {
      await _databaseService.insertSecurityAuditEvent(
        eventType: eventType,
        description: 'P2P connection event for device: $deviceId',
        severity: 'INFO',
        metadata: {
          'device_id': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
          'active_connections': _activeConnections.length,
        },
      );
    } catch (e) {
      debugPrint('Error logging connection event: $e');
    }
  }

  String _generateTransferId() {
    return 'transfer_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  void _handleSignalingMessage(SignalingMessage message) {
    // Handle incoming signaling messages for WebRTC connection establishment
    debugPrint('Received signaling message: ${message.type} from ${message.fromDeviceId}');
    
    // Forward to communication service for processing
    // This is a simplified implementation - in a full WebRTC setup,
    // this would handle offer/answer/ice-candidate exchanges
  }

  // Cleanup and disposal
  void dispose() {
    _connectionHealthTimer?.cancel();
    disconnectAll();
    _stateController.close();
    _connectionController.close();
    _messageController.close();
    _transferController.close();
    _activeConnections.clear();
    _activeTransfers.clear();
    debugPrint('P2P Manager disposed');
  }
}