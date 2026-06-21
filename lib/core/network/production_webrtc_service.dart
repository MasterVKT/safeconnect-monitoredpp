import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'dart:math' as dart_math;

enum ProductionConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
  closed
}

enum ConnectionQuality { excellent, good, poor, critical }

class ConnectionMetrics {
  final int latency;
  final double packetLoss;
  final int bandwidth;
  final ConnectionQuality quality;
  final DateTime timestamp;

  const ConnectionMetrics({
    required this.latency,
    required this.packetLoss,
    required this.bandwidth,
    required this.quality,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latency': latency,
        'packet_loss': packetLoss,
        'bandwidth': bandwidth,
        'quality': quality.name,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ReconnectionConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool exponentialBackoff;

  const ReconnectionConfig({
    this.maxRetries = 10,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
    this.exponentialBackoff = true,
  });
}

class ProductionWebRTCService {
  static final ProductionWebRTCService _instance =
      ProductionWebRTCService._internal();
  factory ProductionWebRTCService() => _instance;
  ProductionWebRTCService._internal();

  final Map<String, webrtc.RTCPeerConnection> _peerConnections = {};
  final Map<String, Map<String, webrtc.RTCDataChannel>> _dataChannels = {};
  final Map<String, ProductionConnectionState> _connectionStates = {};
  final Map<String, Timer> _reconnectionTimers = {};
  final Map<String, int> _reconnectionAttempts = {};
  final Map<String, ConnectionMetrics> _connectionMetrics = {};

  final StreamController<Map<String, dynamic>> _connectionEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Uint8List> _mediaStreamController =
      StreamController<Uint8List>.broadcast();

  late StorageService _storageService;
  late WebSocketService _webSocketService;

  bool _isInitialized = false;
  Timer? _metricsTimer;
  Timer? _heartbeatTimer;
  List<Map<String, dynamic>> _iceServers = [];
  ReconnectionConfig _reconnectionConfig = const ReconnectionConfig();

  Stream<Map<String, dynamic>> get connectionEventStream =>
      _connectionEventController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Uint8List> get mediaStream => _mediaStreamController.stream;

  bool get isInitialized => _isInitialized;
  Map<String, ProductionConnectionState> get connectionStates =>
      Map.unmodifiable(_connectionStates);
  Map<String, ConnectionMetrics> get connectionMetrics =>
      Map.unmodifiable(_connectionMetrics);

  Future<void> initialize({
    List<Map<String, dynamic>>? customIceServers,
    ReconnectionConfig? reconnectionConfig,
  }) async {
    if (_isInitialized) return;

    try {
      _storageService = locator<StorageService>();
      _webSocketService = locator<WebSocketService>();

      if (reconnectionConfig != null) {
        _reconnectionConfig = reconnectionConfig;
      }

      await _loadConfiguration();

      if (customIceServers != null) {
        _iceServers = customIceServers;
      } else {
        await _loadIceServers();
      }

      await _initializeWebRTC();
      _startMetricsCollection();
      _startHeartbeat();
      _setupWebSocketHandlers();

      _isInitialized = true;
      debugPrint('Production WebRTC Service initialized successfully');

      _connectionEventController.add({
        'event': 'service_initialized',
        'timestamp': DateTime.now().toIso8601String(),
        'ice_servers_count': _iceServers.length,
      });
    } catch (e) {
      debugPrint('Error initializing Production WebRTC Service: $e');
      rethrow;
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final configData = await _storageService.getSecureData('webrtc_config');
      if (configData != null) {
        final config = jsonDecode(configData);
        if (config['reconnection'] != null) {
          _reconnectionConfig = ReconnectionConfig(
            maxRetries: config['reconnection']['max_retries'] ?? 10,
            initialDelay: Duration(
                seconds: config['reconnection']['initial_delay_seconds'] ?? 1),
            backoffMultiplier:
                config['reconnection']['backoff_multiplier'] ?? 2.0,
            maxDelay: Duration(
                minutes: config['reconnection']['max_delay_minutes'] ?? 5),
            exponentialBackoff:
                config['reconnection']['exponential_backoff'] ?? true,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading WebRTC configuration: $e');
    }
  }

  Future<void> _loadIceServers() async {
    try {
      final savedServers = await _storageService.getSecureData('ice_servers');
      if (savedServers != null) {
        final serversData = jsonDecode(savedServers) as List;
        _iceServers = serversData.cast<Map<String, dynamic>>();
      } else {
        // Production-grade ICE servers
        _iceServers = [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
          {'urls': 'stun:stun.cloudflare.com:3478'},
          // Add more production STUN/TURN servers as needed
        ];
      }

      debugPrint('Loaded ${_iceServers.length} ICE servers');
    } catch (e) {
      debugPrint('Error loading ICE servers: $e');
    }
  }

  Future<void> _initializeWebRTC() async {
    try {
      // Initialize WebRTC with optimal settings for production
      if (kIsWeb) {
        // Web-specific initialization
        await webrtc.WebRTC.initialize();
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile-specific initialization
        await webrtc.WebRTC.initialize();
      }

      debugPrint(
          'WebRTC initialized for platform: ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('Error initializing WebRTC: $e');
      rethrow;
    }
  }

  void _setupWebSocketHandlers() {
    // Listen for WebRTC signaling messages through WebSocket
    _webSocketService.addMessageHandler('webrtc_signaling', (message) {
      _handleSignalingMessage(message);
    });

    _webSocketService.addMessageHandler('peer_connection_request', (message) {
      final peerId = message['peer_id'] as String?;
      if (peerId != null) {
        createPeerConnection(peerId, isInitiator: false);
      }
    });

    debugPrint('WebSocket handlers setup for WebRTC signaling');
  }

  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _collectConnectionMetrics();
    });
    debugPrint('WebRTC metrics collection started');
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
    debugPrint('WebRTC heartbeat started');
  }

  Future<void> _collectConnectionMetrics() async {
    for (final entry in _peerConnections.entries) {
      final peerId = entry.key;
      final peerConnection = entry.value;

      try {
        final stats = await peerConnection.getStats();
        final metrics = await _calculateMetrics(stats);
        _connectionMetrics[peerId] = metrics;

        // Check connection quality and take action if needed
        if (metrics.quality == ConnectionQuality.critical) {
          _handlePoorConnection(peerId);
        }

        _connectionEventController.add({
          'event': 'metrics_updated',
          'peer_id': peerId,
          'metrics': metrics.toJson(),
        });
      } catch (e) {
        debugPrint('Error collecting metrics for peer $peerId: $e');
      }
    }
  }

  Future<ConnectionMetrics> _calculateMetrics(
      List<webrtc.StatsReport> stats) async {
    int latency = 0;
    double packetLoss = 0.0;
    int bandwidth = 0;

    try {
      // Parse stats and calculate metrics
      for (final report in stats) {
        final values = report.values;

        if (report.type == 'candidate-pair' && values['selected'] == true) {
          final rttValue = values['currentRoundTripTime'];
          latency = rttValue is num ? rttValue.round() : 0;
        }

        if (report.type == 'inbound-rtp') {
          final packetsLost = values['packetsLost'] ?? 0;
          final packetsReceived = values['packetsReceived'] ?? 0;
          if (packetsReceived > 0) {
            packetLoss = (packetsLost / (packetsLost + packetsReceived)) * 100;
          }
        }

        if (report.type == 'candidate-pair') {
          bandwidth = values['availableOutgoingBitrate']?.round() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error parsing stats: $e');
    }

    final quality = _determineConnectionQuality(latency, packetLoss, bandwidth);

    return ConnectionMetrics(
      latency: latency,
      packetLoss: packetLoss,
      bandwidth: bandwidth,
      quality: quality,
      timestamp: DateTime.now(),
    );
  }

  ConnectionQuality _determineConnectionQuality(
      int latency, double packetLoss, int bandwidth) {
    if (latency > 500 || packetLoss > 10 || bandwidth < 100000) {
      return ConnectionQuality.critical;
    } else if (latency > 200 || packetLoss > 5 || bandwidth < 500000) {
      return ConnectionQuality.poor;
    } else if (latency > 100 || packetLoss > 2 || bandwidth < 1000000) {
      return ConnectionQuality.good;
    } else {
      return ConnectionQuality.excellent;
    }
  }

  Future<void> _handlePoorConnection(String peerId) async {
    debugPrint('Poor connection quality detected for peer: $peerId');

    // Attempt to improve connection
    await _optimizeConnection(peerId);

    // If still poor after optimization, consider reconnection
    final metrics = _connectionMetrics[peerId];
    if (metrics != null && metrics.quality == ConnectionQuality.critical) {
      await _initiateReconnection(peerId);
    }
  }

  Future<void> _optimizeConnection(String peerId) async {
    try {
      final peerConnection = _peerConnections[peerId];
      if (peerConnection == null) return;

      // Adjust bandwidth constraints
      final transceivers = await peerConnection.getTransceivers();
      for (final _ in transceivers) {
        // Reduce bitrate for poor connections
        // This would need to be implemented based on specific requirements
      }

      debugPrint('Connection optimization attempted for peer: $peerId');
    } catch (e) {
      debugPrint('Error optimizing connection for peer $peerId: $e');
    }
  }

  void _sendHeartbeat() {
    for (final peerId in _peerConnections.keys) {
      if (_connectionStates[peerId] == ProductionConnectionState.connected) {
        _sendMessage(peerId, 'command', {
          'type': 'heartbeat',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'device_id': DeviceUtils.getDeviceIdentifier(),
        });
      }
    }
  }

  Future<bool> createPeerConnection(String peerId,
      {bool isInitiator = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _setupPeerConnection(peerId, isInitiator);
  }

  Future<bool> _setupPeerConnection(String peerId, bool isInitiator) async {
    try {
      _updateConnectionState(peerId, ProductionConnectionState.connecting);

      final rtcConfig = <String, dynamic>{
        'iceServers': _iceServers,
        'iceCandidatePoolSize': 10,
        'bundlePolicy': 'balanced',
        'rtcpMuxPolicy': 'require',
        'iceTransportPolicy': 'all',
      };

      final webrtc.RTCPeerConnection peerConnection =
          await webrtc.createPeerConnection(rtcConfig);
      _peerConnections[peerId] = peerConnection;
      _connectionStates[peerId] = ProductionConnectionState.connecting;
      _reconnectionAttempts[peerId] = 0;

      _setupPeerConnectionHandlers(peerId, peerConnection);

      // Create data channels for different types of communication
      await _createDataChannels(peerId, peerConnection);

      if (isInitiator) {
        await _createOffer(peerId);
      }

      debugPrint('Peer connection created for: $peerId');
      return true;
    } catch (e) {
      debugPrint('Error creating peer connection for $peerId: $e');
      _updateConnectionState(peerId, ProductionConnectionState.failed);
      return false;
    }
  }

  void _setupPeerConnectionHandlers(
      String peerId, webrtc.RTCPeerConnection peerConnection) {
    peerConnection.onConnectionState = (state) {
      debugPrint('Peer $peerId connection state: $state');
      _handleConnectionStateChange(peerId, state);
    };

    peerConnection.onIceCandidate = (candidate) {
      _sendSignalingMessage(peerId, {
        'type': 'ice_candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    peerConnection.onDataChannel = (dataChannel) {
      _handleIncomingDataChannel(peerId, dataChannel);
    };

    peerConnection.onIceConnectionState = (state) {
      debugPrint('Peer $peerId ICE connection state: $state');
      if (state == webrtc.RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state ==
              webrtc.RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _initiateReconnection(peerId);
      }
    };
  }

  void _handleConnectionStateChange(
      String peerId, webrtc.RTCPeerConnectionState state) {
    ProductionConnectionState newState;

    switch (state) {
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        newState = ProductionConnectionState.connecting;
        break;
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        newState = ProductionConnectionState.connected;
        _reconnectionAttempts[peerId] = 0; // Reset reconnection attempts
        break;
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        newState = ProductionConnectionState.failed;
        _initiateReconnection(peerId);
        break;
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        newState = ProductionConnectionState.closed;
        break;
      default:
        newState = ProductionConnectionState.disconnected;
    }

    _updateConnectionState(peerId, newState);
  }

  void _updateConnectionState(String peerId, ProductionConnectionState state) {
    final oldState = _connectionStates[peerId];
    if (oldState != state) {
      _connectionStates[peerId] = state;

      _connectionEventController.add({
        'event': 'connection_state_changed',
        'peer_id': peerId,
        'old_state': oldState?.name,
        'new_state': state.name,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint(
          'Peer $peerId state changed: ${oldState?.name} -> ${state.name}');
    }
  }

  Future<void> _createDataChannels(
      String peerId, webrtc.RTCPeerConnection peerConnection) async {
    final channels = <String, webrtc.RTCDataChannel>{};

    // Create different channels for different types of communication
    final channelTypes = ['command', 'data', 'media', 'file'];

    for (final channelType in channelTypes) {
      try {
        final dataChannel = await peerConnection.createDataChannel(
          '${channelType}_$peerId',
          webrtc.RTCDataChannelInit()
            ..ordered = channelType != 'media'
            ..maxRetransmits = channelType == 'media' ? 0 : 3,
        );

        _setupDataChannelHandlers(peerId, channelType, dataChannel);
        channels[channelType] = dataChannel;

        debugPrint('Created $channelType data channel for peer: $peerId');
      } catch (e) {
        debugPrint(
            'Error creating $channelType data channel for peer $peerId: $e');
      }
    }

    _dataChannels[peerId] = channels;
  }

  void _setupDataChannelHandlers(
      String peerId, String channelType, webrtc.RTCDataChannel dataChannel) {
    dataChannel.onDataChannelState = (state) {
      debugPrint('Data channel $channelType for peer $peerId state: $state');
    };

    dataChannel.onMessage = (message) {
      _handleDataChannelMessage(peerId, channelType, message);
    };
  }

  void _handleDataChannelMessage(
      String peerId, String channelType, webrtc.RTCDataChannelMessage message) {
    try {
      if (channelType == 'media') {
        // Handle binary media data
        _mediaStreamController.add(message.binary);
      } else {
        // Handle text messages
        final data = jsonDecode(message.text);

        _messageController.add({
          'peer_id': peerId,
          'channel_type': channelType,
          'message': data,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Handle heartbeat responses
        if (data['type'] == 'heartbeat_response') {
          final sentTime = data['original_timestamp'] as int;
          final latency = DateTime.now().millisecondsSinceEpoch - sentTime;

          _connectionEventController.add({
            'event': 'heartbeat_received',
            'peer_id': peerId,
            'latency': latency,
          });
        }
      }
    } catch (e) {
      debugPrint('Error handling data channel message from $peerId: $e');
    }
  }

  void _handleIncomingDataChannel(
      String peerId, webrtc.RTCDataChannel dataChannel) {
    final label = dataChannel.label ?? 'unknown';
    final channelType = label.split('_').first;

    _setupDataChannelHandlers(peerId, channelType, dataChannel);

    if (_dataChannels[peerId] == null) {
      _dataChannels[peerId] = {};
    }
    _dataChannels[peerId]![channelType] = dataChannel;

    debugPrint('Incoming data channel: $label for peer: $peerId');
  }

  Future<void> _createOffer(String peerId) async {
    try {
      final peerConnection = _peerConnections[peerId];
      if (peerConnection == null) return;

      final offer = await peerConnection.createOffer({
        'offerToReceiveVideo': false,
        'offerToReceiveAudio': false,
      });

      await peerConnection.setLocalDescription(offer);

      _sendSignalingMessage(peerId, {
        'type': 'offer',
        'sdp': offer.sdp,
      });
    } catch (e) {
      debugPrint('Error creating offer for peer $peerId: $e');
    }
  }

  Future<void> _createAnswer(String peerId, String offerSdp) async {
    try {
      final peerConnection = _peerConnections[peerId];
      if (peerConnection == null) return;

      await peerConnection.setRemoteDescription(
          webrtc.RTCSessionDescription(offerSdp, 'offer'));

      final answer = await peerConnection.createAnswer({
        'offerToReceiveVideo': false,
        'offerToReceiveAudio': false,
      });

      await peerConnection.setLocalDescription(answer);

      _sendSignalingMessage(peerId, {
        'type': 'answer',
        'sdp': answer.sdp,
      });
    } catch (e) {
      debugPrint('Error creating answer for peer $peerId: $e');
    }
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    try {
      final peerId = message['from_peer'] as String;
      final type = message['type'] as String;

      switch (type) {
        case 'offer':
          await _handleOffer(peerId, message['sdp'] as String);
          break;
        case 'answer':
          await _handleAnswer(peerId, message['sdp'] as String);
          break;
        case 'ice_candidate':
          await _handleIceCandidate(peerId, message);
          break;
        default:
          debugPrint('Unknown signaling message type: $type');
      }
    } catch (e) {
      debugPrint('Error handling signaling message: $e');
    }
  }

  Future<void> _handleOffer(String peerId, String offerSdp) async {
    // Create peer connection if it doesn't exist
    if (!_peerConnections.containsKey(peerId)) {
      await createPeerConnection(peerId, isInitiator: false);
    }

    await _createAnswer(peerId, offerSdp);
  }

  Future<void> _handleAnswer(String peerId, String answerSdp) async {
    try {
      final peerConnection = _peerConnections[peerId];
      if (peerConnection == null) return;

      await peerConnection.setRemoteDescription(
          webrtc.RTCSessionDescription(answerSdp, 'answer'));
    } catch (e) {
      debugPrint('Error handling answer from peer $peerId: $e');
    }
  }

  Future<void> _handleIceCandidate(
      String peerId, Map<String, dynamic> candidateData) async {
    try {
      final peerConnection = _peerConnections[peerId];
      if (peerConnection == null) return;

      final candidate = webrtc.RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      await peerConnection.addCandidate(candidate);
    } catch (e) {
      debugPrint('Error handling ICE candidate from peer $peerId: $e');
    }
  }

  void _sendSignalingMessage(String peerId, Map<String, dynamic> message) {
    // Use WebSocket service to send signaling messages
    _webSocketService.sendMessage({
      'type': 'webrtc_signaling',
      'target_peer': peerId,
      'from_peer': DeviceUtils.getDeviceIdentifier(),
      'signaling_data': message,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('Sending signaling message to $peerId: ${message['type']}');
  }

  // Reconnection Logic
  Future<void> _initiateReconnection(String peerId) async {
    if (_connectionStates[peerId] == ProductionConnectionState.reconnecting) {
      return; // Already reconnecting
    }

    final attempts = _reconnectionAttempts[peerId] ?? 0;
    if (attempts >= _reconnectionConfig.maxRetries) {
      debugPrint('Max reconnection attempts reached for peer: $peerId');
      _updateConnectionState(peerId, ProductionConnectionState.failed);
      return;
    }

    _updateConnectionState(peerId, ProductionConnectionState.reconnecting);
    _reconnectionAttempts[peerId] = attempts + 1;

    final delay = _calculateReconnectionDelay(attempts);
    debugPrint(
        'Reconnecting to peer $peerId in ${delay.inSeconds} seconds (attempt ${attempts + 1})');

    _reconnectionTimers[peerId] = Timer(delay, () {
      _performReconnection(peerId);
    });
  }

  Duration _calculateReconnectionDelay(int attempt) {
    if (!_reconnectionConfig.exponentialBackoff) {
      return _reconnectionConfig.initialDelay;
    }

    final delayMs = _reconnectionConfig.initialDelay.inMilliseconds *
        dart_math.pow(_reconnectionConfig.backoffMultiplier, attempt);
    final delay = Duration(milliseconds: delayMs.round());

    return delay > _reconnectionConfig.maxDelay
        ? _reconnectionConfig.maxDelay
        : delay;
  }

  Future<void> _performReconnection(String peerId) async {
    try {
      debugPrint('Performing reconnection for peer: $peerId');

      // Close existing connection
      await closePeerConnection(peerId, cleanup: false);

      // Create new connection
      await createPeerConnection(peerId, isInitiator: true);
    } catch (e) {
      debugPrint('Error during reconnection for peer $peerId: $e');
      _initiateReconnection(peerId); // Try again
    }
  }

  // Public API Methods
  Future<bool> sendMessage(
      String peerId, String channelType, Map<String, dynamic> message) async {
    return _sendMessage(peerId, channelType, message);
  }

  bool _sendMessage(
      String peerId, String channelType, Map<String, dynamic> message) {
    final channels = _dataChannels[peerId];
    if (channels == null) {
      debugPrint('No channels found for peer: $peerId');
      return false;
    }

    final channel = channels[channelType];
    if (channel == null) {
      debugPrint('Channel $channelType not found for peer: $peerId');
      return false;
    }

    try {
      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'from_device': DeviceUtils.getDeviceIdentifier(),
        ...message,
      };

      channel.send(webrtc.RTCDataChannelMessage(jsonEncode(messageData)));
      return true;
    } catch (e) {
      debugPrint('Error sending message to peer $peerId: $e');
      return false;
    }
  }

  Future<bool> sendMediaData(String peerId, Uint8List data) async {
    final channels = _dataChannels[peerId];
    if (channels == null) return false;

    final mediaChannel = channels['media'];
    if (mediaChannel == null) return false;

    try {
      await mediaChannel.send(webrtc.RTCDataChannelMessage.fromBinary(data));
      return true;
    } catch (e) {
      debugPrint('Error sending media data to peer $peerId: $e');
      return false;
    }
  }

  Future<bool> sendFile(String peerId, Uint8List fileData, String fileName,
      String mimeType) async {
    final channels = _dataChannels[peerId];
    if (channels == null) return false;

    final fileChannel = channels['file'];
    if (fileChannel == null) return false;

    try {
      // Send file metadata first
      final metadata = {
        'type': 'file_metadata',
        'file_name': fileName,
        'mime_type': mimeType,
        'file_size': fileData.length,
        'chunks': (fileData.length / 16384).ceil(), // 16KB chunks
      };

      fileChannel.send(webrtc.RTCDataChannelMessage(jsonEncode(metadata)));

      // Send file data in chunks
      const chunkSize = 16384;
      for (int i = 0; i < fileData.length; i += chunkSize) {
        final end =
            (i + chunkSize < fileData.length) ? i + chunkSize : fileData.length;
        final chunk = fileData.sublist(i, end);

        await fileChannel.send(webrtc.RTCDataChannelMessage.fromBinary(chunk));

        // Small delay to prevent overwhelming the channel
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Send completion signal
      fileChannel.send(
          webrtc.RTCDataChannelMessage(jsonEncode({'type': 'file_complete'})));

      return true;
    } catch (e) {
      debugPrint('Error sending file to peer $peerId: $e');
      return false;
    }
  }

  List<String> getConnectedPeers() {
    return _connectionStates.entries
        .where((entry) => entry.value == ProductionConnectionState.connected)
        .map((entry) => entry.key)
        .toList();
  }

  ProductionConnectionState? getConnectionState(String peerId) {
    return _connectionStates[peerId];
  }

  ConnectionMetrics? getConnectionMetrics(String peerId) {
    return _connectionMetrics[peerId];
  }

  Future<void> closePeerConnection(String peerId, {bool cleanup = true}) async {
    try {
      // Cancel reconnection timer
      _reconnectionTimers[peerId]?.cancel();
      _reconnectionTimers.remove(peerId);

      // Close data channels
      final channels = _dataChannels[peerId];
      if (channels != null) {
        for (final channel in channels.values) {
          channel.close();
        }
        _dataChannels.remove(peerId);
      }

      // Close peer connection
      final peerConnection = _peerConnections[peerId];
      if (peerConnection != null) {
        await peerConnection.close();
        _peerConnections.remove(peerId);
      }

      if (cleanup) {
        _connectionStates.remove(peerId);
        _reconnectionAttempts.remove(peerId);
        _connectionMetrics.remove(peerId);
      }

      _updateConnectionState(peerId, ProductionConnectionState.closed);
      debugPrint('Peer connection closed: $peerId');
    } catch (e) {
      debugPrint('Error closing peer connection $peerId: $e');
    }
  }

  Future<void> closeAllConnections() async {
    final peerIds = List.from(_peerConnections.keys);
    for (final peerId in peerIds) {
      await closePeerConnection(peerId);
    }
  }

  Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'service': 'Production WebRTC Service',
      'initialized': _isInitialized,
      'peer_connections': _peerConnections.length,
      'connected_peers': getConnectedPeers().length,
      'ice_servers': _iceServers.length,
      'connection_states': _connectionStates,
      'metrics_collection_active': _metricsTimer?.isActive ?? false,
      'heartbeat_active': _heartbeatTimer?.isActive ?? false,
      'reconnection_config': {
        'max_retries': _reconnectionConfig.maxRetries,
        'initial_delay_seconds': _reconnectionConfig.initialDelay.inSeconds,
        'backoff_multiplier': _reconnectionConfig.backoffMultiplier,
        'max_delay_minutes': _reconnectionConfig.maxDelay.inMinutes,
        'exponential_backoff': _reconnectionConfig.exponentialBackoff,
      },
    };
  }

  Future<void> dispose() async {
    _metricsTimer?.cancel();
    _heartbeatTimer?.cancel();

    for (final timer in _reconnectionTimers.values) {
      timer.cancel();
    }
    _reconnectionTimers.clear();

    await closeAllConnections();

    _connectionEventController.close();
    _messageController.close();
    _mediaStreamController.close();

    _isInitialized = false;
    debugPrint('Production WebRTC Service disposed');
  }
}
