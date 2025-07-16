import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:uuid/uuid.dart';

class MediaCollector {
  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/media');
  final DataCollectorService _dataCollectorService = locator<DataCollectorService>();
  
  bool _isCollecting = false;
  final _uuid = const Uuid();
  
  Future<void> initialize() async {
    try {
      // Check if camera and storage permissions are granted
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('Camera or storage permissions not granted');
      }
      
      // Setup method channel handler
      _channel.setMethodCallHandler(_handleMethodCall);
    } catch (e) {
      debugPrint('Error initializing media collector: $e');
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
  
  Future<bool> _requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestMediaPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting media permissions: $e');
      return false;
    }
  }
  
  Future<void> startCollecting() async {
    if (_isCollecting) return;
    
    try {
      // Check permissions first
      var hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        hasPermissions = await _requestPermissions();
        if (!hasPermissions) {
          debugPrint('Cannot start media collection: permissions not granted');
          return;
        }
      }
      
      _isCollecting = true;
      debugPrint('Media collector started');
    } catch (e) {
      debugPrint('Error starting media collector: $e');
    }
  }
  
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    _isCollecting = false;
    debugPrint('Media collector stopped');
  }
  
  Future<Map<String, dynamic>?> captureScreenshot() async {
    if (!_isCollecting) {
      debugPrint('Cannot capture screenshot: collector not started');
      return null;
    }
    
    try {
      final String? filePath = await _channel.invokeMethod<String>('captureScreenshot');
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
      
      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': _uuid.v4(),
        'file_path': filePath,
        'file_name': 'screenshot_${timestamp.millisecondsSinceEpoch}.jpg',
        'file_size': fileSize,
        'mime_type': 'image/jpeg',
        'media_type': 'SCREENSHOT',
        'created_at': timestamp.toIso8601String(),
        'width': 0, // Will be updated from native side
        'height': 0, // Will be updated from native side
      };
      
      // Queue for sync
      _dataCollectorService.queueForSync('media_metadata', [mediaMetadata]);
      
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
      final String? filePath = await _channel.invokeMethod<String>(
        'capturePhoto',
        {'front_camera': frontCamera},
      );
      
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
      
      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': _uuid.v4(),
        'file_path': filePath,
        'file_name': 'photo_${timestamp.millisecondsSinceEpoch}.jpg',
        'file_size': fileSize,
        'mime_type': 'image/jpeg',
        'media_type': 'PHOTO',
        'camera_type': frontCamera ? 'FRONT' : 'BACK',
        'created_at': timestamp.toIso8601String(),
        'width': 0, // Will be updated from native side
        'height': 0, // Will be updated from native side
      };
      
      // Queue for sync
      _dataCollectorService.queueForSync('media_metadata', [mediaMetadata]);
      
      return mediaMetadata;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
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
      final String? filePath = await _channel.invokeMethod<String>(
        'recordAudio',
        {'duration_seconds': durationSeconds},
      );
      
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
      
      final mediaMetadata = {
        'device_id': deviceId,
        'media_id': _uuid.v4(),
        'file_path': filePath,
        'file_name': 'audio_${timestamp.millisecondsSinceEpoch}.m4a',
        'file_size': fileSize,
        'mime_type': 'audio/m4a',
        'media_type': 'AUDIO',
        'duration': durationSeconds,
        'created_at': timestamp.toIso8601String(),
      };
      
      // Queue for sync
      _dataCollectorService.queueForSync('media_metadata', [mediaMetadata]);
      
      return mediaMetadata;
    } catch (e) {
      debugPrint('Error recording audio: $e');
      return null;
    }
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMediaCaptured':
        final mediaData = call.arguments as Map<dynamic, dynamic>;
        // Handle remote capture request completion
        break;
      default:
        debugPrint('Unknown method: ${call.method}');
    }
  }
}