import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/network/production_webrtc_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:path/path.dart' as path;

enum FileTransferStatus {
  pending,
  negotiating,
  transferring,
  completed,
  failed,
  cancelled,
  paused
}

enum FileTransferType {
  sms,
  call_log,
  location,
  media,
  app_data,
  emergency_data,
  config,
  other
}

class FileTransferRequest {
  final String id;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final FileTransferType type;
  final String fromPeer;
  final String toPeer;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final int priority;

  const FileTransferRequest({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.type,
    required this.fromPeer,
    required this.toPeer,
    required this.metadata,
    required this.createdAt,
    this.priority = 5,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
        'type': type.name,
        'from_peer': fromPeer,
        'to_peer': toPeer,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'priority': priority,
      };

  factory FileTransferRequest.fromJson(Map<String, dynamic> json) {
    return FileTransferRequest(
      id: json['id'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
      type: FileTransferType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FileTransferType.other,
      ),
      fromPeer: json['from_peer'],
      toPeer: json['to_peer'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      priority: json['priority'] ?? 5,
    );
  }
}

class FileTransferSession {
  final String id;
  final FileTransferRequest request;
  FileTransferStatus status;
  int bytesTransferred;
  final DateTime startedAt;
  DateTime? completedAt;
  String? errorMessage;
  double transferRate;
  int chunksTotal;
  int chunksTransferred;
  final Set<int> receivedChunks;
  String? checksum;

  FileTransferSession({
    required this.id,
    required this.request,
    this.status = FileTransferStatus.pending,
    this.bytesTransferred = 0,
    required this.startedAt,
    this.transferRate = 0.0,
    this.chunksTotal = 0,
    this.chunksTransferred = 0,
  }) : receivedChunks = <int>{};

  double get progress =>
      chunksTotal > 0 ? chunksTransferred / chunksTotal : 0.0;

  bool get isCompleted => status == FileTransferStatus.completed;
  bool get isFailed => status == FileTransferStatus.failed;
  bool get isActive => status == FileTransferStatus.transferring;

  Duration get elapsedTime =>
      completedAt?.difference(startedAt) ??
      DateTime.now().difference(startedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'status': status.name,
        'bytes_transferred': bytesTransferred,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'error_message': errorMessage,
        'transfer_rate': transferRate,
        'chunks_total': chunksTotal,
        'chunks_transferred': chunksTransferred,
        'progress': progress,
        'checksum': checksum,
      };
}

class P2PFileTransferService {
  static const int _defaultChunkSize = 16384; // 16KB chunks
  static const int _maxConcurrentTransfers = 3;
  static const Duration _transferTimeout = Duration(minutes: 30);

  final ProductionWebRTCService _webRTCService =
      locator<ProductionWebRTCService>();
  final DatabaseService _databaseService = locator<DatabaseService>();

  final Map<String, FileTransferSession> _activeSessions = {};
  final Map<String, Timer> _sessionTimers = {};
  final Map<String, Completer<bool>> _transferCompleters = {};
  final Map<String, Uint8List> _assemblyBuffers = {};

  final StreamController<FileTransferSession> _sessionUpdatesController =
      StreamController<FileTransferSession>.broadcast();
  final StreamController<FileTransferRequest> _incomingRequestsController =
      StreamController<FileTransferRequest>.broadcast();

  bool _isInitialized = false;
  String? _tempDirectory;

  static final P2PFileTransferService _instance =
      P2PFileTransferService._internal();
  factory P2PFileTransferService() => _instance;
  P2PFileTransferService._internal();

  Stream<FileTransferSession> get sessionUpdates =>
      _sessionUpdatesController.stream;
  Stream<FileTransferRequest> get incomingRequests =>
      _incomingRequestsController.stream;

  List<FileTransferSession> get activeSessions =>
      _activeSessions.values.toList();
  int get activeTransferCount => _activeSessions.length;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing P2P File Transfer Service...');

      // Setup temp directory for file assembly
      await _setupTempDirectory();

      // Setup message handlers for file transfer
      _setupMessageHandlers();

      // Load pending sessions from database
      await _loadPendingSessions();

      _isInitialized = true;
      debugPrint('P2P File Transfer Service initialized');
    } catch (e) {
      debugPrint('Error initializing P2P File Transfer Service: $e');
      throw Exception('Failed to initialize P2P File Transfer Service: $e');
    }
  }

  Future<void> _setupTempDirectory() async {
    try {
      final tempDir = Directory.systemTemp;
      _tempDirectory = path.join(tempDir.path, 'monitored_app_transfers');

      final dir = Directory(_tempDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      debugPrint('Temp directory setup: $_tempDirectory');
    } catch (e) {
      debugPrint('Error setting up temp directory: $e');
      rethrow;
    }
  }

  void _setupMessageHandlers() {
    // Listen to WebRTC messages for file transfer
    _webRTCService.messageStream.listen((message) async {
      final channelType = message['channel_type'] as String?;
      if (channelType == 'file') {
        await _handleFileTransferMessage(message);
      }
    });

    debugPrint('File transfer message handlers setup');
  }

  Future<void> _loadPendingSessions() async {
    try {
      // Load incomplete transfers from database
      final pendingSessions = await _databaseService.getPendingFileTransfers();

      for (final sessionData in pendingSessions) {
        final session = _sessionFromJson(sessionData);
        if (session.status == FileTransferStatus.transferring ||
            session.status == FileTransferStatus.paused) {
          session.status = FileTransferStatus.pending;
          _activeSessions[session.id] = session;
        }
      }

      debugPrint(
          'Loaded ${_activeSessions.length} pending file transfer sessions');
    } catch (e) {
      debugPrint('Error loading pending sessions: $e');
    }
  }

  FileTransferSession _sessionFromJson(Map<String, dynamic> json) {
    final session = FileTransferSession(
      id: json['id'],
      request: FileTransferRequest.fromJson(json['request']),
      startedAt: DateTime.parse(json['started_at']),
    );

    session.status = FileTransferStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => FileTransferStatus.pending,
    );
    session.bytesTransferred = json['bytes_transferred'] ?? 0;
    session.transferRate = json['transfer_rate'] ?? 0.0;
    session.chunksTotal = json['chunks_total'] ?? 0;
    session.chunksTransferred = json['chunks_transferred'] ?? 0;
    session.errorMessage = json['error_message'];
    session.checksum = json['checksum'];

    if (json['completed_at'] != null) {
      session.completedAt = DateTime.parse(json['completed_at']);
    }

    return session;
  }

  Future<String> sendFile(
    String filePath,
    String toPeer, {
    FileTransferType type = FileTransferType.other,
    Map<String, dynamic>? metadata,
    int priority = 5,
  }) async {
    if (!_isInitialized) {
      throw Exception('P2P File Transfer Service not initialized');
    }

    if (_activeSessions.length >= _maxConcurrentTransfers) {
      throw Exception('Maximum concurrent transfers reached');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      final fileSize = await file.length();
      final fileName = path.basename(filePath);
      final mimeType = _getMimeType(fileName);

      final request = FileTransferRequest(
        id: _generateTransferId(),
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        type: type,
        fromPeer: await DeviceUtils.getDeviceIdentifier(),
        toPeer: toPeer,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        priority: priority,
      );

      // Send transfer request
      final accepted = await _sendTransferRequest(request);
      if (!accepted) {
        throw Exception('Transfer request was rejected');
      }

      // Start transfer session
      final session = FileTransferSession(
        id: request.id,
        request: request,
        status: FileTransferStatus.negotiating,
        startedAt: DateTime.now(),
      );

      _activeSessions[session.id] = session;
      await _saveSession(session);

      // Start file transfer
      _startFileTransfer(session, filePath);

      return session.id;
    } catch (e) {
      debugPrint('Error sending file: $e');
      rethrow;
    }
  }

  Future<bool> _sendTransferRequest(FileTransferRequest request) async {
    try {
      final completer = Completer<bool>();
      _transferCompleters[request.id] = completer;

      // Send request through WebRTC
      final success = await _webRTCService.sendMessage(
        request.toPeer,
        'file',
        {
          'type': 'transfer_request',
          'request': request.toJson(),
        },
      );

      if (!success) {
        _transferCompleters.remove(request.id);
        return false;
      }

      // Wait for response with timeout
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _transferCompleters.remove(request.id);
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error sending transfer request: $e');
      _transferCompleters.remove(request.id);
      return false;
    }
  }

  Future<void> _startFileTransfer(
      FileTransferSession session, String filePath) async {
    try {
      session.status = FileTransferStatus.transferring;
      _sessionUpdatesController.add(session);

      final file = File(filePath);
      final fileData = await file.readAsBytes();

      // Calculate checksum
      session.checksum = _calculateChecksum(fileData);

      // Calculate chunks
      session.chunksTotal = (fileData.length / _defaultChunkSize).ceil();

      // Setup transfer timer
      _sessionTimers[session.id] = Timer(_transferTimeout, () {
        _handleTransferTimeout(session.id);
      });

      // Send file metadata
      await _sendFileMetadata(session, fileData.length);

      // Send file chunks
      await _sendFileChunks(session, fileData);
    } catch (e) {
      debugPrint('Error starting file transfer: $e');
      await _handleTransferError(session.id, 'Transfer start failed: $e');
    }
  }

  Future<void> _sendFileMetadata(
      FileTransferSession session, int totalSize) async {
    final metadata = {
      'type': 'file_metadata',
      'transfer_id': session.id,
      'file_name': session.request.fileName,
      'file_size': totalSize,
      'mime_type': session.request.mimeType,
      'chunks_total': session.chunksTotal,
      'chunk_size': _defaultChunkSize,
      'checksum': session.checksum,
      'priority': session.request.priority,
    };

    await _webRTCService.sendMessage(
      session.request.toPeer,
      'file',
      metadata,
    );
  }

  Future<void> _sendFileChunks(
      FileTransferSession session, Uint8List fileData) async {
    final startTime = DateTime.now();

    for (int chunkIndex = 0; chunkIndex < session.chunksTotal; chunkIndex++) {
      if (session.status != FileTransferStatus.transferring) {
        break; // Transfer was cancelled or paused
      }

      final start = chunkIndex * _defaultChunkSize;
      final end = (start + _defaultChunkSize < fileData.length)
          ? start + _defaultChunkSize
          : fileData.length;

      final chunk = fileData.sublist(start, end);

      // Send chunk with retry logic
      bool sent = false;
      int attempts = 0;
      const maxAttempts = 3;

      while (!sent && attempts < maxAttempts) {
        try {
          final chunkMessage = {
            'type': 'file_chunk',
            'transfer_id': session.id,
            'chunk_index': chunkIndex,
            'chunk_data': base64Encode(chunk),
            'chunk_size': chunk.length,
          };

          sent = await _webRTCService.sendMessage(
            session.request.toPeer,
            'file',
            chunkMessage,
          );

          if (sent) {
            session.chunksTransferred++;
            session.bytesTransferred += chunk.length;

            // Update transfer rate
            final elapsed = DateTime.now().difference(startTime);
            session.transferRate = session.bytesTransferred / elapsed.inSeconds;

            // Update session and notify listeners
            _sessionUpdatesController.add(session);
            await _saveSession(session);
          }
        } catch (e) {
          debugPrint('Error sending chunk $chunkIndex: $e');
          attempts++;

          if (attempts < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 100 * attempts));
          }
        }
      }

      if (!sent) {
        await _handleTransferError(
            session.id, 'Failed to send chunk $chunkIndex');
        return;
      }

      // Small delay to prevent overwhelming the connection
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Send completion signal
    await _sendTransferComplete(session);
  }

  Future<void> _sendTransferComplete(FileTransferSession session) async {
    await _webRTCService.sendMessage(
      session.request.toPeer,
      'file',
      {
        'type': 'transfer_complete',
        'transfer_id': session.id,
        'total_chunks': session.chunksTotal,
        'total_bytes': session.request.fileSize,
        'checksum': session.checksum,
      },
    );

    // Wait for acknowledgment
    Timer(const Duration(seconds: 10), () {
      _completeTransfer(session.id);
    });
  }

  Future<void> _handleFileTransferMessage(Map<String, dynamic> message) async {
    final messageData = message['message'] as Map<String, dynamic>;
    final messageType = messageData['type'] as String;

    switch (messageType) {
      case 'transfer_request':
        _handleTransferRequest(message);
        break;
      case 'transfer_response':
        _handleTransferResponse(messageData);
        break;
      case 'file_metadata':
        await _handleFileMetadata(messageData);
        break;
      case 'file_chunk':
        _handleFileChunk(messageData);
        break;
      case 'transfer_complete':
        _handleTransferComplete(messageData);
        break;
      case 'transfer_ack':
        _handleTransferAck(messageData);
        break;
      case 'chunk_request':
        _handleChunkRequest(messageData);
        break;
      default:
        debugPrint('Unknown file transfer message type: $messageType');
    }
  }

  void _handleTransferRequest(Map<String, dynamic> message) {
    try {
      final requestData = message['message']['request'] as Map<String, dynamic>;
      final request = FileTransferRequest.fromJson(requestData);
      final fromPeer = message['peer_id'] as String;

      debugPrint(
          'Incoming transfer request from $fromPeer: ${request.fileName}');

      // Notify listeners about incoming request
      _incomingRequestsController.add(request);
    } catch (e) {
      debugPrint('Error handling transfer request: $e');
    }
  }

  Future<void> acceptTransferRequest(String requestId,
      {String? savePath}) async {
    try {
      // Find the request
      // In a real implementation, you'd store pending requests

      await _webRTCService.sendMessage(
        'requester_peer_id', // This would come from the request
        'file',
        {
          'type': 'transfer_response',
          'request_id': requestId,
          'accepted': true,
          'save_path': savePath,
        },
      );
    } catch (e) {
      debugPrint('Error accepting transfer request: $e');
    }
  }

  Future<void> rejectTransferRequest(String requestId, String reason) async {
    try {
      await _webRTCService.sendMessage(
        'requester_peer_id', // This would come from the request
        'file',
        {
          'type': 'transfer_response',
          'request_id': requestId,
          'accepted': false,
          'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('Error rejecting transfer request: $e');
    }
  }

  void _handleTransferResponse(Map<String, dynamic> messageData) {
    final requestId = messageData['request_id'] as String;
    final accepted = messageData['accepted'] as bool;

    final completer = _transferCompleters.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(accepted);
    }
  }

  Future<void> _handleFileMetadata(Map<String, dynamic> messageData) async {
    try {
      final transferId = messageData['transfer_id'] as String;
      final fileName = messageData['file_name'] as String;
      final fileSize = messageData['file_size'] as int;
      final chunksTotal = messageData['chunks_total'] as int;
      final checksum = messageData['checksum'] as String?;

      // Create receiving session
      final request = FileTransferRequest(
        id: transferId,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: messageData['mime_type'] ?? 'application/octet-stream',
        type: FileTransferType.other,
        fromPeer: 'sender_peer', // This would come from the message
        toPeer: await DeviceUtils.getDeviceIdentifier(),
        metadata: {},
        createdAt: DateTime.now(),
      );

      final session = FileTransferSession(
        id: transferId,
        request: request,
        status: FileTransferStatus.transferring,
        startedAt: DateTime.now(),
      );

      session.chunksTotal = chunksTotal;
      session.checksum = checksum;

      _activeSessions[transferId] = session;
      _assemblyBuffers[transferId] = Uint8List(fileSize);

      _sessionUpdatesController.add(session);
    } catch (e) {
      debugPrint('Error handling file metadata: $e');
    }
  }

  void _handleFileChunk(Map<String, dynamic> messageData) {
    try {
      final transferId = messageData['transfer_id'] as String;
      final chunkIndex = messageData['chunk_index'] as int;
      final chunkData = base64Decode(messageData['chunk_data'] as String);

      final session = _activeSessions[transferId];
      if (session == null) {
        debugPrint('No session found for transfer: $transferId');
        return;
      }

      final buffer = _assemblyBuffers[transferId];
      if (buffer == null) {
        debugPrint('No assembly buffer found for transfer: $transferId');
        return;
      }

      // Write chunk to buffer
      final start = chunkIndex * _defaultChunkSize;
      final end = start + chunkData.length;

      if (end <= buffer.length) {
        buffer.setRange(start, end, chunkData);
        session.receivedChunks.add(chunkIndex);
        session.chunksTransferred = session.receivedChunks.length;
        session.bytesTransferred += chunkData.length;

        _sessionUpdatesController.add(session);

        // Check if we need to request missing chunks
        if (session.chunksTransferred % 100 == 0) {
          _requestMissingChunks(session);
        }
      }
    } catch (e) {
      debugPrint('Error handling file chunk: $e');
    }
  }

  void _handleTransferComplete(Map<String, dynamic> messageData) {
    try {
      final transferId = messageData['transfer_id'] as String;
      final totalChunks = messageData['total_chunks'] as int;
      final expectedChecksum = messageData['checksum'] as String?;

      final session = _activeSessions[transferId];
      if (session == null) return;

      // Check if all chunks received
      if (session.receivedChunks.length == totalChunks) {
        final buffer = _assemblyBuffers[transferId];
        if (buffer != null) {
          // Verify checksum
          final actualChecksum = _calculateChecksum(buffer);
          if (expectedChecksum == null || actualChecksum == expectedChecksum) {
            _finalizeFileReceive(session, buffer);
          } else {
            _handleTransferError(transferId, 'Checksum verification failed');
          }
        }
      } else {
        // Request missing chunks
        _requestMissingChunks(session);
      }
    } catch (e) {
      debugPrint('Error handling transfer complete: $e');
    }
  }

  void _requestMissingChunks(FileTransferSession session) {
    final missingChunks = <int>[];

    for (int i = 0; i < session.chunksTotal; i++) {
      if (!session.receivedChunks.contains(i)) {
        missingChunks.add(i);
      }
    }

    if (missingChunks.isNotEmpty) {
      _webRTCService.sendMessage(
        session.request.fromPeer,
        'file',
        {
          'type': 'chunk_request',
          'transfer_id': session.id,
          'missing_chunks': missingChunks,
        },
      );
    }
  }

  void _handleChunkRequest(Map<String, dynamic> messageData) {
    // Handle requests for missing chunks during transfer
    final transferId = messageData['transfer_id'] as String;
    final missingChunks = List<int>.from(messageData['missing_chunks']);

    debugPrint(
        'Received request for ${missingChunks.length} missing chunks for transfer: $transferId');

    // In a real implementation, you'd resend the requested chunks
  }

  void _handleTransferAck(Map<String, dynamic> messageData) {
    final transferId = messageData['transfer_id'] as String;
    _completeTransfer(transferId);
  }

  Future<void> _finalizeFileReceive(
      FileTransferSession session, Uint8List fileData) async {
    try {
      // Save file to permanent location
      final fileName = session.request.fileName;
      final filePath = path.join(_tempDirectory!, fileName);
      final file = File(filePath);

      await file.writeAsBytes(fileData);

      // Send acknowledgment
      await _webRTCService.sendMessage(
        session.request.fromPeer,
        'file',
        {
          'type': 'transfer_ack',
          'transfer_id': session.id,
          'status': 'completed',
          'file_path': filePath,
        },
      );

      _completeTransfer(session.id);
    } catch (e) {
      debugPrint('Error finalizing file receive: $e');
      await _handleTransferError(session.id, 'File save failed: $e');
    }
  }

  void _completeTransfer(String transferId) {
    final session = _activeSessions[transferId];
    if (session != null) {
      session.status = FileTransferStatus.completed;
      session.completedAt = DateTime.now();

      _sessionTimers[transferId]?.cancel();
      _sessionTimers.remove(transferId);
      _assemblyBuffers.remove(transferId);

      _sessionUpdatesController.add(session);
      _saveSession(session);

      debugPrint('Transfer completed: $transferId');
    }
  }

  Future<void> _handleTransferError(String transferId, String error) async {
    final session = _activeSessions[transferId];
    if (session != null) {
      session.status = FileTransferStatus.failed;
      session.errorMessage = error;
      session.completedAt = DateTime.now();

      _sessionTimers[transferId]?.cancel();
      _sessionTimers.remove(transferId);
      _assemblyBuffers.remove(transferId);

      _sessionUpdatesController.add(session);
      await _saveSession(session);

      debugPrint('Transfer failed: $transferId - $error');
    }
  }

  void _handleTransferTimeout(String transferId) {
    _handleTransferError(transferId, 'Transfer timeout');
  }

  Future<void> cancelTransfer(String transferId) async {
    final session = _activeSessions[transferId];
    if (session != null) {
      session.status = FileTransferStatus.cancelled;
      session.completedAt = DateTime.now();

      // Notify peer about cancellation
      await _webRTCService.sendMessage(
        session.request.toPeer,
        'file',
        {
          'type': 'transfer_cancelled',
          'transfer_id': transferId,
        },
      );

      _sessionTimers[transferId]?.cancel();
      _sessionTimers.remove(transferId);
      _assemblyBuffers.remove(transferId);
      _activeSessions.remove(transferId);

      _sessionUpdatesController.add(session);
      await _saveSession(session);
    }
  }

  Future<void> pauseTransfer(String transferId) async {
    final session = _activeSessions[transferId];
    if (session != null && session.status == FileTransferStatus.transferring) {
      session.status = FileTransferStatus.paused;
      _sessionUpdatesController.add(session);
      await _saveSession(session);
    }
  }

  Future<void> resumeTransfer(String transferId) async {
    final session = _activeSessions[transferId];
    if (session != null && session.status == FileTransferStatus.paused) {
      session.status = FileTransferStatus.transferring;
      _sessionUpdatesController.add(session);
      await _saveSession(session);

      // Resume transfer logic would go here
    }
  }

  String _generateTransferId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond * 1000) % 10000;
    return 'FT_${timestamp}_$random';
  }

  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    const mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.pdf': 'application/pdf',
      '.txt': 'text/plain',
      '.json': 'application/json',
      '.zip': 'application/zip',
      '.mp4': 'video/mp4',
      '.mp3': 'audio/mpeg',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  String _calculateChecksum(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  Future<void> _saveSession(FileTransferSession session) async {
    try {
      await _databaseService.saveFileTransferSession(session.toJson());
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> clearCompletedTransfers() async {
    final completedSessions = _activeSessions.values
        .where((session) => session.isCompleted || session.isFailed)
        .toList();

    for (final session in completedSessions) {
      _activeSessions.remove(session.id);
      await _databaseService.removeFileTransferSession(session.id);
    }
  }

  Map<String, dynamic> getTransferStatistics() {
    final sessions = _activeSessions.values.toList();

    return {
      'active_transfers': sessions.where((s) => s.isActive).length,
      'completed_transfers': sessions.where((s) => s.isCompleted).length,
      'failed_transfers': sessions.where((s) => s.isFailed).length,
      'total_bytes_transferred':
          sessions.fold<int>(0, (sum, s) => sum + s.bytesTransferred),
      'average_transfer_rate': sessions.isNotEmpty
          ? sessions.fold<double>(0, (sum, s) => sum + s.transferRate) /
              sessions.length
          : 0.0,
    };
  }

  Future<void> dispose() async {
    // Cancel all timers
    for (final timer in _sessionTimers.values) {
      timer.cancel();
    }
    _sessionTimers.clear();

    // Clear assembly buffers
    _assemblyBuffers.clear();

    // Close streams
    _sessionUpdatesController.close();
    _incomingRequestsController.close();

    // Clear active sessions
    _activeSessions.clear();

    _isInitialized = false;
    debugPrint('P2P File Transfer Service disposed');
  }
}
