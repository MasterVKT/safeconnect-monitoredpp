import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/network/p2p_communication_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/app/locator.dart';

enum SignalingMessageType {
  offer,
  answer,
  iceCandidate,
  peerConnected,
  peerDisconnected,
  error
}

class SignalingMessage {
  final String id;
  final SignalingMessageType type;
  final String fromDeviceId;
  final String toDeviceId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SignalingMessage({
    required this.id,
    required this.type,
    required this.fromDeviceId,
    required this.toDeviceId,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'from_device_id': fromDeviceId,
    'to_device_id': toDeviceId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) => SignalingMessage(
    id: json['id'],
    type: SignalingMessageType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => SignalingMessageType.error,
    ),
    fromDeviceId: json['from_device_id'],
    toDeviceId: json['to_device_id'],
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class P2PSignalingService {
  static final P2PSignalingService _instance = P2PSignalingService._internal();
  factory P2PSignalingService() => _instance;
  P2PSignalingService._internal();

  late WebSocketService _webSocketService;
  late P2PCommunicationService _p2pService;

  final StreamController<SignalingMessage> _signalingController = StreamController<SignalingMessage>.broadcast();
  final Map<String, P2PPeer> _activePeers = {};
  final Map<String, Completer<SignalingMessage>> _pendingOffers = {};
  
  bool _isInitialized = false;
  String? _currentDeviceId;
  Timer? _connectionCheckTimer;

  Stream<SignalingMessage> get signalingStream => _signalingController.stream;
  List<P2PPeer> get activePeers => _activePeers.values.toList();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _webSocketService = locator<WebSocketService>();
    _p2pService = P2PCommunicationService();

    _currentDeviceId = await DeviceUtils.getDeviceIdentifier();
    
    await _p2pService.initialize();
    _setupSignalingHandlers();
    _setupP2PHandlers();
    _startConnectionMonitoring();
    
    // Register P2P signaling callback with WebSocket service
    _webSocketService.setP2PSignalingCallback(onSignalingMessageReceived);

    _isInitialized = true;
    debugPrint('P2P Signaling Service initialized');
  }

  void _setupSignalingHandlers() {
    // Listen for WebRTC signaling messages through existing WebSocket
    // This extends the WebSocket service to handle P2P signaling
    _signalingController.stream.listen(_handleSignalingMessage);
  }

  void _setupP2PHandlers() {
    // Listen for new peer connections
    _p2pService.peerConnectionStream.listen((peer) {
      _activePeers[peer.peerId] = peer;
      _notifyPeerConnected(peer.peerId);
      
      // Listen for peer disconnections
      peer.stateStream.listen((state) {
        if (state == P2PConnectionState.closed || state == P2PConnectionState.failed) {
          _activePeers.remove(peer.peerId);
          _notifyPeerDisconnected(peer.peerId);
        }
      });
    });
  }

  void _startConnectionMonitoring() {
    _connectionCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkPeerConnections();
    });
  }

  void _checkPeerConnections() {
    for (final peer in _activePeers.values.toList()) {
      if (peer.state != P2PConnectionState.connected) {
        debugPrint('Peer ${peer.peerId} is not connected, removing');
        _activePeers.remove(peer.peerId);
        _notifyPeerDisconnected(peer.peerId);
      }
    }
  }

  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    // Only handle messages intended for this device
    if (message.toDeviceId != _currentDeviceId) {
      return;
    }

    debugPrint('Handling signaling message: ${message.type} from ${message.fromDeviceId}');

    try {
      switch (message.type) {
        case SignalingMessageType.offer:
          await _handleOffer(message);
          break;
        case SignalingMessageType.answer:
          await _handleAnswer(message);
          break;
        case SignalingMessageType.iceCandidate:
          await _handleIceCandidate(message);
          break;
        case SignalingMessageType.peerConnected:
          await _handlePeerConnected(message);
          break;
        case SignalingMessageType.peerDisconnected:
          await _handlePeerDisconnected(message);
          break;
        case SignalingMessageType.error:
          _handleError(message);
          break;
      }
    } catch (e) {
      debugPrint('Error handling signaling message: $e');
    }
  }

  Future<void> _handleOffer(SignalingMessage message) async {
    final fromDeviceId = message.fromDeviceId;
    
    // Check if we already have a connection with this peer
    if (_activePeers.containsKey(fromDeviceId)) {
      debugPrint('Already connected to peer: $fromDeviceId');
      return;
    }

    try {
      // Create peer connection to handle the offer
      final peer = await _p2pService.createPeerConnection(fromDeviceId, fromDeviceId);
      if (peer == null) {
        debugPrint('Failed to create peer connection for offer');
        return;
      }

      // Set remote description (offer)
      final offerSdp = message.data['sdp'] as String;
      final offer = RTCSessionDescription(offerSdp, 'offer');
      await peer.peerConnection.setRemoteDescription(offer);

      // Create answer
      final answer = await peer.peerConnection.createAnswer();
      await peer.peerConnection.setLocalDescription(answer);

      // Send answer back through signaling
      await _sendSignalingMessage(
        SignalingMessageType.answer,
        fromDeviceId,
        {'sdp': answer.sdp},
      );

      debugPrint('Answer sent to peer: $fromDeviceId');
    } catch (e) {
      debugPrint('Error handling offer: $e');
      await _sendError(fromDeviceId, 'Failed to handle offer: $e');
    }
  }

  Future<void> _handleAnswer(SignalingMessage message) async {
    final fromDeviceId = message.fromDeviceId;
    final peer = _activePeers[fromDeviceId];
    
    if (peer == null) {
      debugPrint('No pending peer connection for answer from: $fromDeviceId');
      return;
    }

    try {
      final answerSdp = message.data['sdp'] as String;
      final answer = RTCSessionDescription(answerSdp, 'answer');
      await peer.peerConnection.setRemoteDescription(answer);
      
      debugPrint('Answer processed from peer: $fromDeviceId');
    } catch (e) {
      debugPrint('Error handling answer: $e');
      await _sendError(fromDeviceId, 'Failed to handle answer: $e');
    }
  }

  Future<void> _handleIceCandidate(SignalingMessage message) async {
    final fromDeviceId = message.fromDeviceId;
    final peer = _activePeers[fromDeviceId];
    
    if (peer == null) {
      debugPrint('No peer connection for ICE candidate from: $fromDeviceId');
      return;
    }

    try {
      final candidateData = message.data;
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      
      await peer.peerConnection.addCandidate(candidate);
      debugPrint('ICE candidate added from peer: $fromDeviceId');
    } catch (e) {
      debugPrint('Error handling ICE candidate: $e');
    }
  }

  Future<void> _handlePeerConnected(SignalingMessage message) async {
    debugPrint('Peer connected: ${message.fromDeviceId}');
    // Additional logic for peer connection notifications
  }

  Future<void> _handlePeerDisconnected(SignalingMessage message) async {
    final fromDeviceId = message.fromDeviceId;
    debugPrint('Peer disconnected: $fromDeviceId');
    
    final peer = _activePeers.remove(fromDeviceId);
    if (peer != null) {
      peer.close();
    }
  }

  void _handleError(SignalingMessage message) {
    debugPrint('Signaling error from ${message.fromDeviceId}: ${message.data}');
  }

  Future<bool> connectToPeer(String targetDeviceId, {Duration timeout = const Duration(seconds: 30)}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_activePeers.containsKey(targetDeviceId)) {
      debugPrint('Already connected to peer: $targetDeviceId');
      return true;
    }

    try {
      // Create peer connection
      final peer = await _p2pService.createPeerConnection(targetDeviceId, targetDeviceId);
      if (peer == null) {
        debugPrint('Failed to create peer connection');
        return false;
      }

      // Create data channels
      await peer.createChannel(P2PChannelType.command, customId: 'command_main');
      await peer.createChannel(P2PChannelType.data, customId: 'data_main');

      // Set up ICE candidate handling
      peer.peerConnection.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          _sendSignalingMessage(
            SignalingMessageType.iceCandidate,
            targetDeviceId,
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          );
        }
      };

      // Create offer
      final offer = await peer.peerConnection.createOffer();
      await peer.peerConnection.setLocalDescription(offer);

      // Send offer through signaling
      await _sendSignalingMessage(
        SignalingMessageType.offer,
        targetDeviceId,
        {'sdp': offer.sdp},
      );

      // Wait for connection to establish
      final connectionCompleter = Completer<bool>();
      late StreamSubscription subscription;
      
      subscription = peer.stateStream.listen((state) {
        if (state == P2PConnectionState.connected) {
          connectionCompleter.complete(true);
          subscription.cancel();
        } else if (state == P2PConnectionState.failed || state == P2PConnectionState.closed) {
          connectionCompleter.complete(false);
          subscription.cancel();
        }
      });

      final connected = await connectionCompleter.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          return false;
        },
      );

      if (connected) {
        debugPrint('Successfully connected to peer: $targetDeviceId');
        return true;
      } else {
        debugPrint('Failed to connect to peer: $targetDeviceId');
        peer.close();
        return false;
      }
    } catch (e) {
      debugPrint('Error connecting to peer: $e');
      return false;
    }
  }

  Future<bool> disconnectFromPeer(String peerId) async {
    final peer = _activePeers.remove(peerId);
    if (peer != null) {
      peer.close();
      await _notifyPeerDisconnected(peerId);
      debugPrint('Disconnected from peer: $peerId');
      return true;
    }
    return false;
  }

  Future<void> disconnectFromAllPeers() async {
    for (final peer in _activePeers.values) {
      peer.close();
    }
    _activePeers.clear();
    debugPrint('Disconnected from all peers');
  }

  Future<void> _sendSignalingMessage(
    SignalingMessageType type,
    String toDeviceId,
    Map<String, dynamic> data,
  ) async {
    if (_currentDeviceId == null) return;

    final message = SignalingMessage(
      id: _generateMessageId(),
      type: type,
      fromDeviceId: _currentDeviceId!,
      toDeviceId: toDeviceId,
      data: data,
      timestamp: DateTime.now(),
    );

    // Send through WebSocket (this would need to be implemented in WebSocketService)
    await _sendThroughWebSocket(message);
  }

  Future<void> _sendThroughWebSocket(SignalingMessage message) async {
    if (_webSocketService.isConnected) {
      debugPrint('Sending signaling message: ${message.type} to ${message.toDeviceId}');
      _webSocketService.sendP2PSignalingMessage(message.toJson());
    } else {
      debugPrint('WebSocket not connected, cannot send signaling message');
    }
  }

  Future<void> _sendError(String toDeviceId, String errorMessage) async {
    await _sendSignalingMessage(
      SignalingMessageType.error,
      toDeviceId,
      {'error': errorMessage},
    );
  }

  Future<void> _notifyPeerConnected(String peerId) async {
    await _sendSignalingMessage(
      SignalingMessageType.peerConnected,
      peerId,
      {'device_id': _currentDeviceId},
    );
  }

  Future<void> _notifyPeerDisconnected(String peerId) async {
    await _sendSignalingMessage(
      SignalingMessageType.peerDisconnected,
      peerId,
      {'device_id': _currentDeviceId},
    );
  }

  String _generateMessageId() {
    return 'sig_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }

  // Public API methods
  bool isPeerConnected(String peerId) {
    return _activePeers.containsKey(peerId) && 
           _activePeers[peerId]!.state == P2PConnectionState.connected;
  }

  P2PPeer? getPeer(String peerId) {
    return _activePeers[peerId];
  }

  List<String> getConnectedPeerIds() {
    return _activePeers.keys.toList();
  }

  // Method to be called from WebSocketService when signaling messages are received
  void onSignalingMessageReceived(Map<String, dynamic> messageData) {
    try {
      final message = SignalingMessage.fromJson(messageData);
      _signalingController.add(message);
    } catch (e) {
      debugPrint('Error parsing signaling message: $e');
    }
  }

  void dispose() {
    _connectionCheckTimer?.cancel();
    disconnectFromAllPeers();
    _signalingController.close();
    _pendingOffers.clear();
    _isInitialized = false;
  }
}