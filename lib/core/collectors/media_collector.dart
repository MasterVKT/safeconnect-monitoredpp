import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/utils/media_duration_utils.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

enum MediaQuality { low, medium, high, ultra }

enum CompressionType { none, light, medium, heavy }

enum StreamingMode { off, realtime, buffered }

enum FaceDetectionMode { off, basic, advanced }

class AdvancedMediaConfiguration {
  final MediaQuality videoQuality;
  final CompressionType compression;
  final StreamingMode streaming;
  final FaceDetectionMode faceDetection;
  final bool enableEncryption;
  final bool enableWatermark;
  final bool enableNoiseReduction;
  final bool enableVoiceRecognition;
  final int maxFileSizeMB;
  final String? customWatermarkText;

  const AdvancedMediaConfiguration({
    this.videoQuality = MediaQuality.medium,
    this.compression = CompressionType.medium,
    this.streaming = StreamingMode.off,
    this.faceDetection = FaceDetectionMode.off,
    this.enableEncryption = true,
    this.enableWatermark = false,
    this.enableNoiseReduction = false,
    this.enableVoiceRecognition = false,
    this.maxFileSizeMB = 50,
    this.customWatermarkText,
  });
}

class MediaCollector {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/media');

  // Callback for sending collected data
  Function(String dataType, List<dynamic> items)? _onDataCollected;

  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final WebSocketService _webSocketService = locator<WebSocketService>();

  bool _isCollecting = false;
  bool _isStreaming = false;
  final _uuid = const Uuid();

  AdvancedMediaConfiguration _config = const AdvancedMediaConfiguration();
  Timer? _streamingTimer;

  // Live streaming data
  final List<Uint8List> _streamBuffer = [];
  final StreamController<Map<String, dynamic>> _mediaStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get mediaStream => _mediaStreamController.stream;

  // Set the callback for data collection
  void setDataCollectedCallback(
      Function(String dataType, List<dynamic> items) callback) {
    _onDataCollected = callback;
  }

  // Configure advanced media settings
  void setAdvancedConfiguration(AdvancedMediaConfiguration config) {
    _config = config;
    debugPrint(
        'Advanced media configuration updated: ${config.videoQuality.name} quality, ${config.compression.name} compression');
  }

  AdvancedMediaConfiguration get configuration => _config;

  Future<void> initialize() async {
    try {
      // Check if camera and storage permissions are granted
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('Camera or storage permissions not granted');
      }

      // Setup method channel handler
      _channel.setMethodCallHandler(_handleMethodCall);

      // Initialize advanced features
      await _initializeAdvancedFeatures();

      // Load saved configuration
      await _loadConfiguration();
    } catch (e) {
      debugPrint('Error initializing media collector: $e');
    }
  }

  Future<void> _initializeAdvancedFeatures() async {
    try {
      // Initialize face detection if enabled
      if (_config.faceDetection != FaceDetectionMode.off) {
        await _channel.invokeMethod('initializeFaceDetection', {
          'mode': _config.faceDetection.name,
        });
      }

      // Initialize voice recognition if enabled
      if (_config.enableVoiceRecognition) {
        await _channel.invokeMethod('initializeVoiceRecognition');
      }

      // Initialize streaming if enabled
      if (_config.streaming != StreamingMode.off) {
        await _initializeStreaming();
      }
    } catch (e) {
      debugPrint('Error initializing advanced features: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final configJson = await _storageService.getSecureData('media_config');
      if (configJson != null) {
        final config = jsonDecode(configJson);
        _config = AdvancedMediaConfiguration(
          videoQuality: MediaQuality.values.firstWhere(
            (e) => e.name == config['videoQuality'],
            orElse: () => MediaQuality.medium,
          ),
          compression: CompressionType.values.firstWhere(
            (e) => e.name == config['compression'],
            orElse: () => CompressionType.medium,
          ),
          streaming: StreamingMode.values.firstWhere(
            (e) => e.name == config['streaming'],
            orElse: () => StreamingMode.off,
          ),
          faceDetection: FaceDetectionMode.values.firstWhere(
            (e) => e.name == config['faceDetection'],
            orElse: () => FaceDetectionMode.off,
          ),
          enableEncryption: config['enableEncryption'] ?? true,
          enableWatermark: config['enableWatermark'] ?? false,
          enableNoiseReduction: config['enableNoiseReduction'] ?? false,
          enableVoiceRecognition: config['enableVoiceRecognition'] ?? false,
          maxFileSizeMB: config['maxFileSizeMB'] ?? 50,
          customWatermarkText: config['customWatermarkText'],
        );
      }
    } catch (e) {
      debugPrint('Error loading media configuration: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      final configMap = {
        'videoQuality': _config.videoQuality.name,
        'compression': _config.compression.name,
        'streaming': _config.streaming.name,
        'faceDetection': _config.faceDetection.name,
        'enableEncryption': _config.enableEncryption,
        'enableWatermark': _config.enableWatermark,
        'enableNoiseReduction': _config.enableNoiseReduction,
        'enableVoiceRecognition': _config.enableVoiceRecognition,
        'maxFileSizeMB': _config.maxFileSizeMB,
        'customWatermarkText': _config.customWatermarkText,
      };

      await _storageService.setSecureData(
          'media_config', jsonEncode(configMap));
    } catch (e) {
      debugPrint('Error saving media configuration: $e');
    }
  }

  Future<bool> _checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkMediaPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking media permissions: $e');
      return false;
    }
  }

  Future<void> startCollecting() async {
    if (_isCollecting) return;

    try {
      // Check permissions first
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint(
            '[MEDIA] Cannot start media collection: permissions not granted');
        return;
      }

      _isCollecting = true;

      // Start streaming if enabled
      if (_config.streaming != StreamingMode.off) {
        await startStreaming();
      }

      debugPrint(
          'Advanced media collector started with config: ${_config.videoQuality.name}');
    } catch (e) {
      debugPrint('Error starting media collector: $e');
    }
  }

  Future<void> stopCollecting() async {
    if (!_isCollecting) return;

    _isCollecting = false;

    // Stop streaming if active
    if (_isStreaming) {
      await stopStreaming();
    }

    debugPrint('Advanced media collector stopped');
  }

  // Live Streaming Features
  Future<void> startStreaming() async {
    if (_isStreaming || _config.streaming == StreamingMode.off) return;

    try {
      _isStreaming = true;

      // Start streaming based on mode
      if (_config.streaming == StreamingMode.realtime) {
        await _startRealtimeStreaming();
      } else if (_config.streaming == StreamingMode.buffered) {
        await _startBufferedStreaming();
      }

      debugPrint('Media streaming started: ${_config.streaming.name} mode');
    } catch (e) {
      debugPrint('Error starting streaming: $e');
      _isStreaming = false;
    }
  }

  Future<void> stopStreaming() async {
    if (!_isStreaming) return;

    try {
      _isStreaming = false;
      _streamingTimer?.cancel();
      _streamBuffer.clear();

      await _channel.invokeMethod('stopStreaming');
      debugPrint('Media streaming stopped');
    } catch (e) {
      debugPrint('Error stopping streaming: $e');
    }
  }

  Future<void> _startRealtimeStreaming() async {
    await _channel.invokeMethod('startRealtimeStreaming', {
      'quality': _config.videoQuality.name,
      'compression': _config.compression.name,
    });

    // Start periodic frame capture for real-time streaming
    _streamingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _captureStreamFrame();
    });
  }

  Future<void> _startBufferedStreaming() async {
    await _channel.invokeMethod('startBufferedStreaming', {
      'quality': _config.videoQuality.name,
      'bufferSize': 30, // 30 frames buffer
    });

    // Start periodic buffer processing
    _streamingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processStreamBuffer();
    });
  }

  Future<void> _captureStreamFrame() async {
    try {
      final frameData =
          await _channel.invokeMethod<Uint8List>('captureStreamFrame');
      if (frameData != null) {
        // Send frame via WebSocket if connected
        if (_webSocketService.isConnected) {
          await _webSocketService.sendStreamFrame(frameData, {
            'quality': _config.videoQuality.name,
            'compression': _config.compression.name,
          });
        }

        // Emit to stream listeners
        _mediaStreamController.add({
          'type': 'frame',
          'data': frameData,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint('Error capturing stream frame: $e');
    }
  }

  Future<void> _processStreamBuffer() async {
    try {
      if (_streamBuffer.isNotEmpty) {
        // Compress and send buffered frames
        final compressedBuffer = await _compressFrameBuffer(_streamBuffer);

        if (_webSocketService.isConnected) {
          await _webSocketService.sendStreamBuffer(compressedBuffer, 'video');
        }

        _streamBuffer.clear();
      }
    } catch (e) {
      debugPrint('Error processing stream buffer: $e');
    }
  }

  Future<Uint8List> _compressFrameBuffer(List<Uint8List> frames) async {
    try {
      final result =
          await _channel.invokeMethod<Uint8List>('compressFrameBuffer', {
        'frames': frames,
        'compression': _config.compression.name,
      });
      return result ?? Uint8List(0);
    } catch (e) {
      debugPrint('Error compressing frame buffer: $e');
      return Uint8List(0);
    }
  }

  Future<void> _initializeStreaming() async {
    try {
      await _channel.invokeMethod('initializeStreaming', {
        'mode': _config.streaming.name,
        'quality': _config.videoQuality.name,
      });
    } catch (e) {
      debugPrint('Error initializing streaming: $e');
    }
  }

  Future<Map<String, dynamic>?> captureScreenshot() async {
    if (!_isCollecting) {
      debugPrint('Cannot capture screenshot: collector not started');
      return null;
    }

    try {
      final String? filePath =
          await _channel.invokeMethod<String>('captureScreenshot');
      if (filePath == null || filePath.isEmpty) {
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final fileSize = await file.length();
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final timestamp = DateTime.now();

      final mediaId = _uuid.v4();
      final fileName = 'screenshot_${timestamp.millisecondsSinceEpoch}.jpg';

      // Store in database
      await _databaseService.insertMediaData(
        deviceId: deviceId,
        mediaId: mediaId,
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: 'image/jpeg',
        mediaType: 'SCREENSHOT',
        createdAt: timestamp,
        width: 0,
        height: 0,
      );

      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': mediaId,
        'file_path': filePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': 'image/jpeg',
        'media_type': 'SCREENSHOT',
        'created_at': timestamp.toUtc().toIso8601String(),
        'width': 0,
        'height': 0,
      };

      _onDataCollected?.call('media_metadata', [mediaMetadata]);

      return mediaMetadata;
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> capturePhoto({bool frontCamera = false}) async {
    if (!_isCollecting) {
      debugPrint('Cannot capture photo: collector not started');
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'captureAdvancedPhoto',
        {
          'front_camera': frontCamera,
          'quality': _config.videoQuality.name,
          'enable_face_detection':
              _config.faceDetection != FaceDetectionMode.off,
          'face_detection_mode': _config.faceDetection.name,
          'enable_watermark': _config.enableWatermark,
          'watermark_text': _config.customWatermarkText ?? 'XP SafeConnect',
          'compression': _config.compression.name,
        },
      );

      if (result == null) {
        return null;
      }

      final filePath = result['filePath'] as String?;
      final fileSize = result['fileSize'] as int? ?? 0;
      final width = result['width'] as int? ?? 0;
      final height = result['height'] as int? ?? 0;
      final faces = result['faces'] as List<dynamic>? ?? [];

      if (filePath == null || filePath.isEmpty) {
        return null;
      }

      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final timestamp = DateTime.now();
      final mediaId = _uuid.v4();
      final fileName = 'photo_${timestamp.millisecondsSinceEpoch}.jpg';
      final cameraType = frontCamera ? 'FRONT' : 'BACK';

      // Encrypt file if enabled
      String finalFilePath = filePath;
      if (_config.enableEncryption) {
        finalFilePath = await _encryptMediaFile(filePath, mediaId);
      }

      // Store in database with advanced metadata
      await _databaseService.insertMediaData(
        deviceId: deviceId,
        mediaId: mediaId,
        filePath: finalFilePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: 'image/jpeg',
        mediaType: 'PHOTO',
        createdAt: timestamp,
        width: width,
        height: height,
        cameraType: cameraType,
      );

      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': mediaId,
        'file_path': finalFilePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': 'image/jpeg',
        'media_type': 'PHOTO',
        'camera_type': cameraType,
        'created_at': timestamp.toUtc().toIso8601String(),
        'width': width,
        'height': height,
        'quality': _config.videoQuality.name,
        'compressed': _config.compression != CompressionType.none,
        'encrypted': _config.enableEncryption,
        'watermarked': _config.enableWatermark,
        'faces_detected': faces.length,
        'face_data':
            _config.faceDetection != FaceDetectionMode.off ? faces : null,
      };

      _onDataCollected?.call('media_metadata', [mediaMetadata]);

      return mediaMetadata;
    } catch (e) {
      debugPrint('Error capturing advanced photo: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> recordAudio({int durationSeconds = 30}) async {
    if (!_isCollecting) {
      debugPrint('Cannot record audio: collector not started');
      return null;
    }

    if (durationSeconds <= 0 || durationSeconds > 600) {
      durationSeconds = 30; // Default to 30 seconds if invalid
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'recordAdvancedAudio',
        {
          'duration_seconds': durationSeconds,
          'enable_noise_reduction': _config.enableNoiseReduction,
          'enable_voice_recognition': _config.enableVoiceRecognition,
          'quality': _config.videoQuality.name,
          'compression': _config.compression.name,
        },
      );

      if (result == null) {
        return null;
      }

      final filePath = result['filePath'] as String?;
      final fileSize = result['fileSize'] as int? ?? 0;
      final durationMilliseconds = mediaDurationMillisecondsFromSeconds(
        result['duration'],
        fallbackSeconds: durationSeconds,
      );
      final voiceAnalysis =
          result['voiceAnalysis'] as Map<dynamic, dynamic>? ?? {};

      if (filePath == null || filePath.isEmpty) {
        return null;
      }

      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final timestamp = DateTime.now();
      final mediaId = _uuid.v4();
      final fileName = 'audio_${timestamp.millisecondsSinceEpoch}.m4a';

      // Encrypt file if enabled
      String finalFilePath = filePath;
      if (_config.enableEncryption) {
        finalFilePath = await _encryptMediaFile(filePath, mediaId);
      }

      // Store in database with advanced metadata
      await _databaseService.insertMediaData(
        deviceId: deviceId,
        mediaId: mediaId,
        filePath: finalFilePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: 'audio/m4a',
        mediaType: 'AUDIO',
        createdAt: timestamp,
        duration: durationMilliseconds,
      );

      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': mediaId,
        'file_path': finalFilePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': 'audio/m4a',
        'media_type': 'AUDIO',
        'duration': durationMilliseconds,
        'created_at': timestamp.toUtc().toIso8601String(),
        'quality': _config.videoQuality.name,
        'compressed': _config.compression != CompressionType.none,
        'encrypted': _config.enableEncryption,
        'noise_reduced': _config.enableNoiseReduction,
        'voice_recognition': _config.enableVoiceRecognition,
        'voice_analysis': _config.enableVoiceRecognition ? voiceAnalysis : null,
      };

      _onDataCollected?.call('media_metadata', [mediaMetadata]);

      return mediaMetadata;
    } catch (e) {
      debugPrint('Error recording advanced audio: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> recordVideo({
    int durationSeconds = 30,
    bool frontCamera = false,
  }) async {
    if (durationSeconds <= 0 || durationSeconds > 600) {
      durationSeconds = 30;
    }

    try {
      debugPrint(
          'Recording advanced video for $durationSeconds seconds (front camera: $frontCamera)');

      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final mediaId = _uuid.v4();
      final timestamp = DateTime.now();
      final fileName = 'video_${timestamp.millisecondsSinceEpoch}.mp4';

      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('recordAdvancedVideo', {
        'durationSeconds': durationSeconds,
        'frontCamera': frontCamera,
        'fileName': fileName,
        'quality': _config.videoQuality.name,
        'compression': _config.compression.name,
        'enable_face_detection': _config.faceDetection != FaceDetectionMode.off,
        'face_detection_mode': _config.faceDetection.name,
        'enable_watermark': _config.enableWatermark,
        'watermark_text': _config.customWatermarkText ?? 'XP SafeConnect',
        'max_file_size_mb': _config.maxFileSizeMB,
      });

      if (result == null) {
        debugPrint('Advanced video recording failed - no result from native');
        return null;
      }

      final filePath = result['filePath'] as String?;
      final fileSize = result['fileSize'] as int? ?? 0;
      final durationMilliseconds = mediaDurationMillisecondsFromSeconds(
        result['duration'],
        fallbackSeconds: durationSeconds,
      );
      final width = result['width'] as int? ?? 0;
      final height = result['height'] as int? ?? 0;
      final frameRate = result['frameRate'] as double? ?? 30.0;
      final faces = result['faces'] as List<dynamic>? ?? [];

      if (filePath == null) {
        debugPrint('Advanced video recording failed - no file path');
        return null;
      }

      debugPrint(
          'Advanced video recorded successfully: $filePath ($fileSize bytes)');

      // Encrypt file if enabled
      String finalFilePath = filePath;
      if (_config.enableEncryption) {
        finalFilePath = await _encryptMediaFile(filePath, mediaId);
      }

      // Store media information in database with advanced metadata
      await _databaseService.insertMediaData(
        deviceId: deviceId,
        mediaId: mediaId,
        filePath: finalFilePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: 'video/mp4',
        mediaType: 'VIDEO',
        createdAt: timestamp,
        duration: durationMilliseconds,
        width: width,
        height: height,
      );

      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': mediaId,
        'file_path': finalFilePath,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': 'video/mp4',
        'media_type': 'VIDEO',
        'duration': durationMilliseconds,
        'front_camera': frontCamera,
        'created_at': timestamp.toUtc().toIso8601String(),
        'width': width,
        'height': height,
        'frame_rate': frameRate,
        'quality': _config.videoQuality.name,
        'compressed': _config.compression != CompressionType.none,
        'encrypted': _config.enableEncryption,
        'watermarked': _config.enableWatermark,
        'faces_detected': faces.length,
        'face_data':
            _config.faceDetection != FaceDetectionMode.off ? faces : null,
      };

      _onDataCollected?.call('media_metadata', [mediaMetadata]);

      return mediaMetadata;
    } catch (e) {
      debugPrint('Error recording advanced video: $e');
      return null;
    }
  }

  // Advanced Media Processing Functions
  Future<String> _encryptMediaFile(String filePath, String mediaId) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Generate encryption key from media ID and device info
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final keySource =
          '${mediaId}_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
      final key = sha256.convert(utf8.encode(keySource)).bytes;

      // Encrypt the file data (simplified encryption)
      final encryptedBytes = _simpleEncrypt(bytes, key);

      // Save encrypted file
      final encryptedFilePath = '${filePath}.enc';
      final encryptedFile = File(encryptedFilePath);
      await encryptedFile.writeAsBytes(encryptedBytes);

      // Store encryption metadata
      await _storageService.setSecureData(
          'encryption_key_$mediaId', base64.encode(key));

      // Delete original file
      await file.delete();

      return encryptedFilePath;
    } catch (e) {
      debugPrint('Error encrypting media file: $e');
      return filePath; // Return original path if encryption fails
    }
  }

  Uint8List _simpleEncrypt(Uint8List data, List<int> key) {
    final encrypted = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ key[i % key.length];
    }
    return encrypted;
  }

  Future<Uint8List?> decryptMediaFile(
      String mediaId, String encryptedFilePath) async {
    try {
      final keyData =
          await _storageService.getSecureData('encryption_key_$mediaId');
      if (keyData == null) {
        debugPrint('Encryption key not found for media: $mediaId');
        return null;
      }

      final key = base64.decode(keyData);
      final encryptedFile = File(encryptedFilePath);
      final encryptedBytes = await encryptedFile.readAsBytes();

      // Decrypt the data (reverse of simple encrypt)
      return _simpleEncrypt(encryptedBytes, key);
    } catch (e) {
      debugPrint('Error decrypting media file: $e');
      return null;
    }
  }

  // Smart Detection Features
  Future<Map<String, dynamic>?> analyzeImage(String filePath) async {
    if (_config.faceDetection == FaceDetectionMode.off) {
      return null;
    }

    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('analyzeImage', {
        'file_path': filePath,
        'detection_mode': _config.faceDetection.name,
      });

      return result?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeAudio(String filePath) async {
    if (!_config.enableVoiceRecognition) {
      return null;
    }

    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('analyzeAudio', {
        'file_path': filePath,
      });

      return result?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('Error analyzing audio: $e');
      return null;
    }
  }

  // Smart Capture based on triggers
  Future<Map<String, dynamic>?> smartCapture({
    required String trigger,
    Map<String, dynamic>? context,
  }) async {
    try {
      debugPrint('Smart capture triggered: $trigger');

      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('smartCapture', {
        'trigger': trigger,
        'context': context ?? {},
        'config': {
          'video_quality': _config.videoQuality.name,
          'enable_face_detection':
              _config.faceDetection != FaceDetectionMode.off,
          'enable_voice_recognition': _config.enableVoiceRecognition,
          'enable_encryption': _config.enableEncryption,
        },
      });

      if (result == null) {
        return null;
      }

      final mediaType = result['media_type'] as String?;
      final filePath = result['file_path'] as String?;

      if (filePath != null && mediaType != null) {
        // Process based on media type
        switch (mediaType.toLowerCase()) {
          case 'photo':
            return await _processSmartPhoto(result.cast<String, dynamic>());
          case 'video':
            return await _processSmartVideo(result.cast<String, dynamic>());
          case 'audio':
            return await _processSmartAudio(result.cast<String, dynamic>());
        }
      }

      return result.cast<String, dynamic>();
    } catch (e) {
      debugPrint('Error in smart capture: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _processSmartPhoto(
      Map<String, dynamic> data) async {
    final filePath = data['file_path'] as String;

    // Encrypt if enabled
    if (_config.enableEncryption) {
      final mediaId = _uuid.v4();
      data['file_path'] = await _encryptMediaFile(filePath, mediaId);
      data['media_id'] = mediaId;
      data['encrypted'] = true;
    }

    // Analyze image if face detection is enabled
    if (_config.faceDetection != FaceDetectionMode.off) {
      final analysis = await analyzeImage(filePath);
      if (analysis != null) {
        data['analysis'] = analysis;
      }
    }

    return data;
  }

  Future<Map<String, dynamic>> _processSmartVideo(
      Map<String, dynamic> data) async {
    final filePath = data['file_path'] as String;

    // Encrypt if enabled
    if (_config.enableEncryption) {
      final mediaId = _uuid.v4();
      data['file_path'] = await _encryptMediaFile(filePath, mediaId);
      data['media_id'] = mediaId;
      data['encrypted'] = true;
    }

    return data;
  }

  Future<Map<String, dynamic>> _processSmartAudio(
      Map<String, dynamic> data) async {
    final filePath = data['file_path'] as String;

    // Encrypt if enabled
    if (_config.enableEncryption) {
      final mediaId = _uuid.v4();
      data['file_path'] = await _encryptMediaFile(filePath, mediaId);
      data['media_id'] = mediaId;
      data['encrypted'] = true;
    }

    // Analyze audio if voice recognition is enabled
    if (_config.enableVoiceRecognition) {
      final analysis = await analyzeAudio(filePath);
      if (analysis != null) {
        data['analysis'] = analysis;
      }
    }

    return data;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMediaCaptured':
        // Handle remote capture request completion
        break;
      default:
        debugPrint('Unknown method: ${call.method}');
    }
  }

  // Public getter for collection status
  bool get isCollecting => _isCollecting;

  // Get collector statistics
  Map<String, dynamic> getStatistics() {
    return {
      'collector_name': 'Advanced Media',
      'is_collecting': _isCollecting,
      'is_streaming': _isStreaming,
      'permissions_granted': false, // Will be updated when checking permissions
      'supported_media_types': [
        'photo',
        'screenshot',
        'audio',
        'video',
        'live_stream'
      ],
      'advanced_features': {
        'face_detection': _config.faceDetection.name,
        'voice_recognition': _config.enableVoiceRecognition,
        'encryption': _config.enableEncryption,
        'watermarking': _config.enableWatermark,
        'noise_reduction': _config.enableNoiseReduction,
        'streaming': _config.streaming.name,
        'compression': _config.compression.name,
        'quality': _config.videoQuality.name,
      },
      'streaming_stats': {
        'buffer_size': _streamBuffer.length,
        'is_streaming': _isStreaming,
        'mode': _config.streaming.name,
      },
    };
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      // Clear stream buffer
      _streamBuffer.clear();

      // Clear any cached media files or temporary data
      await _channel.invokeMethod('clearMediaCache');

      debugPrint('Advanced media collector cache cleared');
    } catch (e) {
      debugPrint('Error clearing media cache: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _streamingTimer?.cancel();
    _mediaStreamController.close();
    _streamBuffer.clear();
    debugPrint('Advanced media collector disposed');
  }

  // Remote Control Methods for monitoring device
  Future<bool> enableRemoteCapture() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableRemoteCapture');
      return result ?? false;
    } catch (e) {
      debugPrint('Error enabling remote capture: $e');
      return false;
    }
  }

  Future<bool> disableRemoteCapture() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableRemoteCapture');
      return result ?? false;
    } catch (e) {
      debugPrint('Error disabling remote capture: $e');
      return false;
    }
  }

  // Quality and bandwidth optimization
  Future<void> optimizeForBandwidth(int availableBandwidthKbps) async {
    try {
      MediaQuality newQuality;
      CompressionType newCompression;

      if (availableBandwidthKbps < 500) {
        newQuality = MediaQuality.low;
        newCompression = CompressionType.heavy;
      } else if (availableBandwidthKbps < 1000) {
        newQuality = MediaQuality.medium;
        newCompression = CompressionType.medium;
      } else {
        newQuality = MediaQuality.high;
        newCompression = CompressionType.light;
      }

      final optimizedConfig = AdvancedMediaConfiguration(
        videoQuality: newQuality,
        compression: newCompression,
        streaming: _config.streaming,
        faceDetection: _config.faceDetection,
        enableEncryption: _config.enableEncryption,
        enableWatermark: _config.enableWatermark,
        enableNoiseReduction: _config.enableNoiseReduction,
        enableVoiceRecognition: _config.enableVoiceRecognition,
        maxFileSizeMB: _config.maxFileSizeMB,
        customWatermarkText: _config.customWatermarkText,
      );

      setAdvancedConfiguration(optimizedConfig);
      await _saveConfiguration();

      debugPrint(
          'Media collection optimized for ${availableBandwidthKbps}kbps bandwidth');
    } catch (e) {
      debugPrint('Error optimizing for bandwidth: $e');
    }
  }

  // Get available camera info
  Future<List<Map<String, dynamic>>> getAvailableCameras() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getAvailableCameras');
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('Error getting available cameras: $e');
      return [];
    }
  }

  // Get media capabilities
  Future<Map<String, dynamic>> getMediaCapabilities() async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('getMediaCapabilities');
      return result?.cast<String, dynamic>() ?? {};
    } catch (e) {
      debugPrint('Error getting media capabilities: $e');
      return {};
    }
  }

  // Export configuration
  Map<String, dynamic> exportConfiguration() {
    return {
      'video_quality': _config.videoQuality.name,
      'compression': _config.compression.name,
      'streaming': _config.streaming.name,
      'face_detection': _config.faceDetection.name,
      'enable_encryption': _config.enableEncryption,
      'enable_watermark': _config.enableWatermark,
      'enable_noise_reduction': _config.enableNoiseReduction,
      'enable_voice_recognition': _config.enableVoiceRecognition,
      'max_file_size_mb': _config.maxFileSizeMB,
      'custom_watermark_text': _config.customWatermarkText,
    };
  }

  // Import configuration
  void importConfiguration(Map<String, dynamic> config) {
    _config = AdvancedMediaConfiguration(
      videoQuality: MediaQuality.values.firstWhere(
        (e) => e.name == config['video_quality'],
        orElse: () => MediaQuality.medium,
      ),
      compression: CompressionType.values.firstWhere(
        (e) => e.name == config['compression'],
        orElse: () => CompressionType.medium,
      ),
      streaming: StreamingMode.values.firstWhere(
        (e) => e.name == config['streaming'],
        orElse: () => StreamingMode.off,
      ),
      faceDetection: FaceDetectionMode.values.firstWhere(
        (e) => e.name == config['face_detection'],
        orElse: () => FaceDetectionMode.off,
      ),
      enableEncryption: config['enable_encryption'] ?? true,
      enableWatermark: config['enable_watermark'] ?? false,
      enableNoiseReduction: config['enable_noise_reduction'] ?? false,
      enableVoiceRecognition: config['enable_voice_recognition'] ?? false,
      maxFileSizeMB: config['max_file_size_mb'] ?? 50,
      customWatermarkText: config['custom_watermark_text'],
    );

    _saveConfiguration();
  }

  // Emergency-specific media capture methods
  Future<void> captureEmergencyPhoto() async {
    try {
      debugPrint('Capturing emergency photo...');
      // Capture from both cameras if possible for emergency
      final frontPhoto = await capturePhoto(frontCamera: true);
      if (frontPhoto != null) {
        // Mark as emergency and queue with high priority
        frontPhoto['emergency'] = true;
        await _databaseService.queueDataForSync('emergency_media', frontPhoto,
            priority: 1);
      }
      // Small delay between captures
      await Future.delayed(const Duration(milliseconds: 500));
      final backPhoto = await capturePhoto(frontCamera: false);
      if (backPhoto != null) {
        // Mark as emergency and queue with high priority
        backPhoto['emergency'] = true;
        await _databaseService.queueDataForSync('emergency_media', backPhoto,
            priority: 1);
      }

      debugPrint('Emergency photos captured successfully');
    } catch (e) {
      debugPrint('Error capturing emergency photo: $e');
    }
  }

  Future<void> captureEmergencyAudio(
      {Duration duration = const Duration(minutes: 2)}) async {
    try {
      debugPrint(
          'Capturing emergency audio for ${duration.inSeconds} seconds...');
      final audioData = await recordAudio(durationSeconds: duration.inSeconds);
      if (audioData != null) {
        // Mark as emergency and queue with highest priority
        audioData['emergency'] = true;
        audioData['emergency_duration'] = duration.inSeconds;
        await _databaseService.queueDataForSync('emergency_media', audioData,
            priority: 1);
        debugPrint('Emergency audio captured successfully');
      }
    } catch (e) {
      debugPrint('Error capturing emergency audio: $e');
    }
  }

  Future<Map<String, dynamic>?> captureEmergencyScreenshot() async {
    try {
      debugPrint('Capturing emergency screenshot...');
      final screenshotData = await captureScreenshot();
      if (screenshotData != null) {
        // Mark as emergency and queue with high priority
        screenshotData['emergency'] = true;
        await _databaseService
            .queueDataForSync('emergency_media', screenshotData, priority: 1);
        debugPrint('Emergency screenshot captured successfully');
        return screenshotData;
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing emergency screenshot: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> captureEmergencyVideo(
      {Duration duration = const Duration(minutes: 1),
      bool frontCamera = false}) async {
    try {
      debugPrint(
          'Capturing emergency video for ${duration.inSeconds} seconds...');
      final videoData = await recordVideo(
        durationSeconds: duration.inSeconds,
        frontCamera: frontCamera,
      );
      if (videoData != null) {
        // Mark as emergency and queue with highest priority
        videoData['emergency'] = true;
        videoData['emergency_duration'] = duration.inSeconds;
        await _databaseService.queueDataForSync('emergency_media', videoData,
            priority: 1);
        debugPrint('Emergency video captured successfully');
        return videoData;
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing emergency video: $e');
      return null;
    }
  }

  // Comprehensive emergency media collection
  Future<void> performEmergencyCapture() async {
    try {
      debugPrint('Performing comprehensive emergency media capture...');
      // Capture emergency photos (both cameras)
      await captureEmergencyPhoto();
      // Small delay
      await Future.delayed(const Duration(milliseconds: 300));
      // Capture emergency screenshot
      await captureEmergencyScreenshot();
      // Start emergency audio recording in background
      unawaited(captureEmergencyAudio(duration: const Duration(minutes: 2)));
      debugPrint('Emergency media capture sequence initiated');
    } catch (e) {
      debugPrint('Error performing emergency capture: $e');
    }
  }
}
