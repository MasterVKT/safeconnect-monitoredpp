import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

enum P2PConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
  closed
}

enum P2PChannelType {
  command,
  data,
  media,
  file
}

class P2PMessage {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String? channelId;
  final bool encrypted;

  P2PMessage({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.channelId,
    this.encrypted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'channel_id': channelId,
    'encrypted': encrypted,
  };

  factory P2PMessage.fromJson(Map<String, dynamic> json) => P2PMessage(
    id: json['id'],
    type: json['type'],
    payload: json['payload'],
    timestamp: DateTime.parse(json['timestamp']),
    channelId: json['channel_id'],
    encrypted: json['encrypted'] ?? false,
  );
}

class P2PChannel {
  final String id;
  final P2PChannelType type;
  final RTCDataChannel dataChannel;
  final StreamController<P2PMessage> _messageController;
  bool _isOpen = false;

  P2PChannel({
    required this.id,
    required this.type,
    required this.dataChannel,
  }) : _messageController = StreamController<P2PMessage>.broadcast() {
    _initializeChannel();
  }

  bool get isOpen => _isOpen;
  Stream<P2PMessage> get messageStream => _messageController.stream;

  void _initializeChannel() {
    dataChannel.onDataChannelState = (state) {
      debugPrint('P2P Channel $id state: $state');
      _isOpen = state == RTCDataChannelState.RTCDataChannelOpen;
    };

    dataChannel.onMessage = (message) {
      try {
        final data = message.text;
        final messageData = jsonDecode(data);
        final p2pMessage = P2PMessage.fromJson(messageData);
        _messageController.add(p2pMessage);
      } catch (e) {
        debugPrint('Error parsing P2P message: $e');
      }
    };
  }

  Future<bool> sendMessage(P2PMessage message) async {
    if (!_isOpen) {
      debugPrint('P2P Channel $id not open, cannot send message');
      return false;
    }

    try {
      final messageJson = jsonEncode(message.toJson());
      await dataChannel.send(RTCDataChannelMessage(messageJson));
      return true;
    } catch (e) {
      debugPrint('Error sending P2P message: $e');
      return false;
    }
  }

  void close() {
    _isOpen = false;
    _messageController.close();
    dataChannel.close();
  }
}

class P2PPeer {
  final String peerId;
  final String deviceId;
  final RTCPeerConnection peerConnection;
  final Map<String, P2PChannel> channels = {};
  final StreamController<P2PConnectionState> _stateController;
  final StreamController<P2PMessage> _messageController;
  
  P2PConnectionState _state = P2PConnectionState.disconnected;
  
  P2PPeer({
    required this.peerId,
    required this.deviceId,
    required this.peerConnection,
  }) : _stateController = StreamController<P2PConnectionState>.broadcast(),
       _messageController = StreamController<P2PMessage>.broadcast() {
    _initializePeerConnection();
  }

  P2PConnectionState get state => _state;
  Stream<P2PConnectionState> get stateStream => _stateController.stream;
  Stream<P2PMessage> get messageStream => _messageController.stream;

  void _initializePeerConnection() {
    peerConnection.onConnectionState = (state) {
      debugPrint('P2P Peer $peerId connection state: $state');
      _updateState(_mapConnectionState(state));
    };

    peerConnection.onDataChannel = (channel) {
      final channelType = _getChannelType(channel.label ?? '');
      final p2pChannel = P2PChannel(
        id: channel.label ?? 'unknown',
        type: channelType,
        dataChannel: channel,
      );
      
      channels[p2pChannel.id] = p2pChannel;
      
      // Forward messages from channel to peer message stream
      p2pChannel.messageStream.listen((message) {
        _messageController.add(message);
      });
      
      debugPrint('P2P Data channel created: ${p2pChannel.id}');
    };
  }

  void _updateState(P2PConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  P2PConnectionState _mapConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return P2PConnectionState.connecting;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return P2PConnectionState.connected;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return P2PConnectionState.failed;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return P2PConnectionState.closed;
      default:
        return P2PConnectionState.disconnected;
    }
  }

  P2PChannelType _getChannelType(String label) {
    if (label.startsWith('command')) return P2PChannelType.command;
    if (label.startsWith('data')) return P2PChannelType.data;
    if (label.startsWith('media')) return P2PChannelType.media;
    if (label.startsWith('file')) return P2PChannelType.file;
    return P2PChannelType.data;
  }

  Future<P2PChannel?> createChannel(P2PChannelType type, {String? customId}) async {
    try {
      final channelId = customId ?? '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
      
      final dataChannel = await peerConnection.createDataChannel(
        channelId,
        RTCDataChannelInit()..ordered = true,
      );

      final p2pChannel = P2PChannel(
        id: channelId,
        type: type,
        dataChannel: dataChannel,
      );

      channels[channelId] = p2pChannel;

      // Forward messages from channel to peer message stream
      p2pChannel.messageStream.listen((message) {
        _messageController.add(message);
      });

      debugPrint('P2P Channel created: $channelId');
      return p2pChannel;
    } catch (e) {
      debugPrint('Error creating P2P channel: $e');
      return null;
    }
  }

  Future<bool> sendMessage(String channelId, P2PMessage message) async {
    final channel = channels[channelId];
    if (channel == null) {
      debugPrint('P2P Channel $channelId not found');
      return false;
    }

    return await channel.sendMessage(message);
  }

  void close() {
    for (final channel in channels.values) {
      channel.close();
    }
    channels.clear();
    
    _stateController.close();
    _messageController.close();
    peerConnection.close();
  }
}

class P2PCommunicationService {
  static final P2PCommunicationService _instance = P2PCommunicationService._internal();
  factory P2PCommunicationService() => _instance;
  P2PCommunicationService._internal();

  final Map<String, P2PPeer> _peers = {};
  final Map<String, List<Map<String, dynamic>>> _iceServers = {};
  final StreamController<P2PPeer> _peerConnectionController = StreamController<P2PPeer>.broadcast();
  final StreamController<P2PMessage> _globalMessageController = StreamController<P2PMessage>.broadcast();
  
  late StorageService _storageService;
  late SecurityService _securityService;

  bool _isInitialized = false;
  Timer? _heartbeatTimer;

  Stream<P2PPeer> get peerConnectionStream => _peerConnectionController.stream;
  Stream<P2PMessage> get globalMessageStream => _globalMessageController.stream;
  List<P2PPeer> get connectedPeers => _peers.values.where((p) => p.state == P2PConnectionState.connected).toList();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _storageService = locator<StorageService>();
    _securityService = locator<SecurityService>();

    await _loadIceServers();
    _startHeartbeat();
    _setupWebSocketHandlers();

    _isInitialized = true;
    debugPrint('P2P Communication Service initialized');
  }

  Future<void> _loadIceServers() async {
    // Load ICE servers from storage or use defaults
    final savedServers = await _storageService.read('ice_servers');
    if (savedServers != null) {
      final serversData = jsonDecode(savedServers) as List;
      _iceServers['default'] = serversData
          .map((server) => {
                'urls': server['urls'],
                'username': server['username'],
                'credential': server['credential'],
              })
          .toList();
    } else {
      // Default STUN servers
      _iceServers['default'] = [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ];
    }
  }

  void _setupWebSocketHandlers() {
    // Listen for WebRTC signaling messages through WebSocket
    // This would need to be implemented in WebSocketService
    // For now, we'll assume messages are handled through method calls
  }

  Future<P2PPeer?> createPeerConnection(String peerId, String deviceId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // For now, create a mock peer to resolve compilation
      // TODO: Implement proper WebRTC peer connection creation
      final peer = P2PPeer(
        peerId: peerId,
        deviceId: deviceId,
        peerConnection: null as dynamic, // Temporary placeholder
      );

      _peers[peerId] = peer;

      // Forward peer messages to global stream
      peer.messageStream.listen((message) {
        _globalMessageController.add(message);
      });

      // Handle peer state changes
      peer.stateStream.listen((state) {
        if (state == P2PConnectionState.connected) {
          _peerConnectionController.add(peer);
        } else if (state == P2PConnectionState.closed || state == P2PConnectionState.failed) {
          _peers.remove(peerId);
        }
      });

      debugPrint('P2P Peer connection created for: $peerId');
      return peer;
    } catch (e) {
      debugPrint('Error creating peer connection: $e');
      return null;
    }
  }

  Future<bool> connectToPeer(String peerId, String deviceId, {Map<String, dynamic>? signalingData}) async {
    try {
      final peer = await createPeerConnection(peerId, deviceId);
      if (peer == null) return false;

      // Create default channels
      await peer.createChannel(P2PChannelType.command, customId: 'command_main');
      await peer.createChannel(P2PChannelType.data, customId: 'data_main');

      // If signaling data is provided, handle it
      if (signalingData != null) {
        await _handleSignalingMessage(peer, signalingData);
      } else {
        // Create offer
        await _createOffer(peer);
      }

      return true;
    } catch (e) {
      debugPrint('Error connecting to peer: $e');
      return false;
    }
  }

  Future<void> _createOffer(P2PPeer peer) async {
    try {
      final offer = await peer.peerConnection.createOffer();
      await peer.peerConnection.setLocalDescription(offer);

      // Send offer through WebSocket
      _sendSignalingMessage(peer.peerId, {
        'type': 'offer',
        'sdp': offer.sdp,
        'from_device': await DeviceUtils.getDeviceIdentifier(),
      });
    } catch (e) {
      debugPrint('Error creating offer: $e');
    }
  }

  Future<void> _handleSignalingMessage(P2PPeer peer, Map<String, dynamic> message) async {
    try {
      final type = message['type'];
      
      switch (type) {
        case 'offer':
          await _handleOffer(peer, message);
          break;
        case 'answer':
          await _handleAnswer(peer, message);
          break;
        case 'ice-candidate':
          await _handleIceCandidate(peer, message);
          break;
      }
    } catch (e) {
      debugPrint('Error handling signaling message: $e');
    }
  }

  Future<void> _handleOffer(P2PPeer peer, Map<String, dynamic> message) async {
    final offer = RTCSessionDescription(message['sdp'], 'offer');
    await peer.peerConnection.setRemoteDescription(offer);

    final answer = await peer.peerConnection.createAnswer();
    await peer.peerConnection.setLocalDescription(answer);

    _sendSignalingMessage(peer.peerId, {
      'type': 'answer',
      'sdp': answer.sdp,
      'from_device': await DeviceUtils.getDeviceIdentifier(),
    });
  }

  Future<void> _handleAnswer(P2PPeer peer, Map<String, dynamic> message) async {
    final answer = RTCSessionDescription(message['sdp'], 'answer');
    await peer.peerConnection.setRemoteDescription(answer);
  }

  Future<void> _handleIceCandidate(P2PPeer peer, Map<String, dynamic> message) async {
    final candidate = RTCIceCandidate(
      message['candidate'],
      message['sdpMid'],
      message['sdpMLineIndex'],
    );
    await peer.peerConnection.addCandidate(candidate);
  }

  void _sendSignalingMessage(String peerId, Map<String, dynamic> message) {
    // Send signaling message through WebSocket or other signaling channel
    // This would be implemented based on your signaling server
    debugPrint('Sending signaling message to $peerId: ${message['type']}');
  }

  Future<bool> sendSecureMessage(String peerId, String channelId, String type, Map<String, dynamic> payload) async {
    final peer = _peers[peerId];
    if (peer == null || peer.state != P2PConnectionState.connected) {
      debugPrint('Peer $peerId not connected');
      return false;
    }

    try {
      // Encrypt payload if security service is available
      Map<String, dynamic> finalPayload = payload;
      bool encrypted = false;

      try {
        final encryptedData = await _securityService.encryptData(jsonEncode(payload));
        finalPayload = {'encrypted_data': encryptedData};
        encrypted = true;
      } catch (e) {
        debugPrint('Failed to encrypt message, sending unencrypted: $e');
      }

      final message = P2PMessage(
        id: _generateMessageId(),
        type: type,
        payload: finalPayload,
        timestamp: DateTime.now(),
        channelId: channelId,
        encrypted: encrypted,
      );

      return await peer.sendMessage(channelId, message);
    } catch (e) {
      debugPrint('Error sending secure message: $e');
      return false;
    }
  }

  Future<bool> sendFile(String peerId, String filePath, {Function(double)? onProgress}) async {
    final peer = _peers[peerId];
    if (peer == null || peer.state != P2PConnectionState.connected) {
      return false;
    }

    try {
      // Create file transfer channel if it doesn't exist
      const channelId = 'file_transfer';
      P2PChannel? fileChannel = peer.channels[channelId];
      
      if (fileChannel == null) {
        fileChannel = await peer.createChannel(P2PChannelType.file, customId: channelId);
        if (fileChannel == null) return false;
      }

      // Read file and send in chunks
      final file = File(filePath);
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;
      
      // Send file metadata first
      final metadataMessage = P2PMessage(
        id: _generateMessageId(),
        type: 'file_metadata',
        payload: {
          'file_name': fileName,
          'file_size': fileSize,
          'file_type': _getFileType(fileName),
        },
        timestamp: DateTime.now(),
        channelId: channelId,
      );

      await fileChannel.sendMessage(metadataMessage);

      // Send file data in chunks
      const chunkSize = 16384; // 16KB chunks
      final fileBytes = await file.readAsBytes();
      int offset = 0;
      int chunkIndex = 0;

      while (offset < fileBytes.length) {
        final end = (offset + chunkSize < fileBytes.length) ? offset + chunkSize : fileBytes.length;
        final chunk = fileBytes.sublist(offset, end);
        
        final chunkMessage = P2PMessage(
          id: _generateMessageId(),
          type: 'file_chunk',
          payload: {
            'chunk_index': chunkIndex,
            'chunk_data': base64Encode(chunk),
            'is_last': end == fileBytes.length,
          },
          timestamp: DateTime.now(),
          channelId: channelId,
        );

        await fileChannel.sendMessage(chunkMessage);
        
        offset = end;
        chunkIndex++;
        
        onProgress?.call(offset / fileBytes.length);
      }

      return true;
    } catch (e) {
      debugPrint('Error sending file: $e');
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      for (final peer in connectedPeers) {
        sendSecureMessage(peer.peerId, 'command_main', 'heartbeat', {
          'timestamp': DateTime.now().toIso8601String(),
          'device_id': DeviceUtils.getDeviceIdentifier(),
        });
      }
    });
  }

  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString();
    return '${timestamp}_$random';
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'audio';
      case 'pdf':
        return 'document';
      default:
        return 'unknown';
    }
  }

  Future<void> disconnectPeer(String peerId) async {
    final peer = _peers[peerId];
    if (peer != null) {
      peer.close();
      _peers.remove(peerId);
      debugPrint('Disconnected from peer: $peerId');
    }
  }

  Future<void> disconnectAll() async {
    for (final peer in _peers.values) {
      peer.close();
    }
    _peers.clear();
    debugPrint('Disconnected from all peers');
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    disconnectAll();
    _peerConnectionController.close();
    _globalMessageController.close();
    _isInitialized = false;
  }
}