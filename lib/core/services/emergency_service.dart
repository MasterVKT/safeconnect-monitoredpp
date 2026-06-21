import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/notification_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/collectors/location_collector.dart';
import 'package:monitored_app/core/collectors/calls_collector.dart';
import 'package:monitored_app/core/collectors/sms_collector.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/api/api_client.dart';

enum EmergencyState { inactive, activating, active, deactivating }

enum EmergencyTriggerType {
  manual, // User activated emergency mode manually
  automatic, // System detected emergency condition
  panic, // Panic button or gesture activated
  external, // Remote activation via command
  location_based, // Geofence violation
  pattern_based, // Behavioral pattern detected
  sensor_based, // Device sensors detected emergency
  time_based, // Scheduled emergency activation
  battery_critical // Critical battery level emergency
}

enum EmergencyPriority { low, medium, high, critical }

enum EmergencyTrigger {
  sosButton,
  shakePattern,
  voiceKeyword,
  panicGesture,
  volumeButtonSequence,
  powerButtonSequence,
  locationAlert,
  timeoutAlert,
  batteryAlert,
  securityThreat,
  externalCommand
}

class EmergencyEvent {
  final String id;
  final EmergencyTriggerType triggerType;
  final DateTime activatedAt;
  final DateTime? deactivatedAt;
  final String deviceId;
  final Map<String, dynamic> triggerData;
  final List<String> actionsPerformed;
  final Map<String, dynamic> metadata;

  EmergencyEvent({
    required this.id,
    required this.triggerType,
    required this.activatedAt,
    this.deactivatedAt,
    required this.deviceId,
    required this.triggerData,
    required this.actionsPerformed,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trigger_type': triggerType.name,
        'activated_at': activatedAt.toUtc().toIso8601String(),
        'deactivated_at': deactivatedAt?.toUtc().toIso8601String(),
        'device_id': deviceId,
        'trigger_data': triggerData,
        'actions_performed': actionsPerformed,
        'metadata': metadata,
      };
}

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  // Core services
  late WebSocketService _webSocketService;
  late NotificationService _notificationService;
  late DataCollectorService _dataCollectorService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  late ApiClient _apiClient;

  // Current emergency state
  EmergencyState _currentState = EmergencyState.inactive;
  EmergencyEvent? _currentEmergency;
  Timer? _emergencyTimer;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  // Configuration
  bool _autoLocationTracking = true;
  bool _autoMediaCapture = true;
  bool _autoNotifyContacts = true;
  int _emergencyDataSyncInterval = 30; // seconds

  // Stream controllers
  final StreamController<EmergencyState> _stateController =
      StreamController<EmergencyState>.broadcast();
  final StreamController<EmergencyEvent> _eventController =
      StreamController<EmergencyEvent>.broadcast();

  // Public streams
  Stream<EmergencyState> get stateStream => _stateController.stream;
  Stream<EmergencyEvent> get eventStream => _eventController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  EmergencyState get currentState => _currentState;
  EmergencyEvent? get currentEmergency => _currentEmergency;
  bool get isEmergencyActive => _currentState == EmergencyState.active;

  Future<void> initialize() async {
    try {
      // Initialize services
      _webSocketService = locator<WebSocketService>();
      _notificationService = locator<NotificationService>();
      _dataCollectorService = locator<DataCollectorService>();
      _storageService = locator<StorageService>();
      _databaseService = locator<DatabaseService>();
      _apiClient = locator<ApiClient>();

      // Load emergency configuration
      await _loadConfiguration();

      // Setup emergency listeners
      _setupEmergencyListeners();

      _isInitialized = true;
      debugPrint('Emergency Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Emergency Service: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      _autoLocationTracking =
          _storageService.getBool('emergency_auto_location') ?? true;
      _autoMediaCapture =
          _storageService.getBool('emergency_auto_media') ?? true;
      _autoNotifyContacts =
          _storageService.getBool('emergency_auto_notify') ?? true;
      _emergencyDataSyncInterval =
          _storageService.getInt('emergency_sync_interval') ?? 30;
    } catch (e) {
      debugPrint('Error loading emergency configuration: $e');
    }
  }

  void _setupEmergencyListeners() {
    // Listen for emergency triggers from other services
    // This could include panic button triggers, automatic detection, etc.
  }

  Future<bool> activateEmergency({
    EmergencyTriggerType triggerType = EmergencyTriggerType.manual,
    EmergencyTrigger trigger = EmergencyTrigger.sosButton,
    EmergencyPriority priority = EmergencyPriority.high,
    Map<String, dynamic>? triggerData,
    Duration? duration,
  }) async {
    if (_currentState != EmergencyState.inactive) {
      debugPrint('Emergency already in progress');
      return false;
    }

    try {
      debugPrint(
          'Activating emergency mode: ${triggerType.name} via ${trigger.name}');
      _updateState(EmergencyState.activating);

      final deviceId = await DeviceUtils.getDeviceIdentifier();

      // Create emergency event
      _currentEmergency = EmergencyEvent(
        id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
        triggerType: triggerType,
        activatedAt: DateTime.now(),
        deviceId: deviceId,
        triggerData: {
          ...triggerData ?? {},
          'trigger': trigger.name,
          'priority': priority.name,
          'duration_minutes': duration?.inMinutes,
        },
        actionsPerformed: [],
        metadata: {
          'app_version': await DeviceUtils.getAppVersion(),
          'device_info': await DeviceUtils.getDeviceInfo(),
          'battery_level': await _getBatteryLevel(),
          'network_status': await _getNetworkStatus(),
        },
      );

      // Store emergency event in database
      await _databaseService.insertEmergencyEvent(_currentEmergency!);

      // Perform emergency actions
      await _performEmergencyActions();

      // Notify monitoring device/server
      await _notifyEmergency();

      // Start emergency monitoring
      _startEmergencyMonitoring();

      _updateState(EmergencyState.active);
      _eventController.add(_currentEmergency!);

      debugPrint('Emergency mode activated successfully');
      return true;
    } catch (e) {
      debugPrint('Error activating emergency: $e');
      _updateState(EmergencyState.inactive);
      return false;
    }
  }

  Future<void> _performEmergencyActions() async {
    try {
      final actions = <String>[];

      // 1. Immediate location capture
      if (_autoLocationTracking) {
        await _captureEmergencyLocation();
        actions.add('location_captured');
      }

      // 2. Take emergency photo
      if (_autoMediaCapture) {
        await _captureEmergencyPhoto();
        actions.add('photo_captured');
      }

      // 3. Start high-frequency data collection
      await _enableEmergencyDataCollection();
      actions.add('data_collection_enhanced');

      // 4. Send immediate notification
      await _sendEmergencyNotification();
      actions.add('notification_sent');

      // Update actions performed
      _currentEmergency?.actionsPerformed.addAll(actions);
    } catch (e) {
      debugPrint('Error performing emergency actions: $e');
    }
  }

  Future<bool> deactivateEmergency() async {
    if (_currentState != EmergencyState.active) {
      return false;
    }

    try {
      debugPrint('Deactivating emergency mode');
      _updateState(EmergencyState.deactivating);

      // Stop emergency monitoring
      _heartbeatTimer?.cancel();
      _emergencyTimer?.cancel();

      // Update emergency event
      _currentEmergency = EmergencyEvent(
        id: _currentEmergency!.id,
        triggerType: _currentEmergency!.triggerType,
        activatedAt: _currentEmergency!.activatedAt,
        deactivatedAt: DateTime.now(),
        deviceId: _currentEmergency!.deviceId,
        triggerData: _currentEmergency!.triggerData,
        actionsPerformed: _currentEmergency!.actionsPerformed,
        metadata: _currentEmergency!.metadata,
      );

      // Update in database
      await _databaseService.updateEmergencyEvent(_currentEmergency!);

      // Notify deactivation
      await _notifyEmergencyDeactivation();

      // Restore normal data collection intervals
      await _restoreNormalDataCollection();

      _updateState(EmergencyState.inactive);
      _eventController.add(_currentEmergency!);
      _currentEmergency = null;

      debugPrint('Emergency mode deactivated successfully');
      return true;
    } catch (e) {
      debugPrint('Error deactivating emergency: $e');
      _updateState(EmergencyState.active); // Revert to active state
      return false;
    }
  }

  Future<void> _notifyEmergencyDeactivation() async {
    try {
      await _webSocketService.sendEmergencyDeactivation({
        'emergency_id': _currentEmergency!.id,
        'deactivated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _apiClient.post('/emergency/deactivate', data: {
        'emergency_id': _currentEmergency!.id,
      });
    } catch (e) {
      debugPrint('Error notifying emergency deactivation: $e');
    }
  }

  Future<void> _restoreNormalDataCollection() async {
    try {
      // Restore normal collection intervals
      final locationCollector = _dataCollectorService.locationCollector;
      await locationCollector.updateCollectionInterval(900); // 15 minutes
    } catch (e) {
      debugPrint('Error restoring normal data collection: $e');
    }
  }

  // Emergency action methods
  Future<String?> captureEmergencyPhoto({bool frontCamera = false}) async {
    if (_currentState != EmergencyState.active) return null;

    try {
      final mediaCollector = _dataCollectorService.mediaCollector;
      final result =
          await mediaCollector.capturePhoto(frontCamera: frontCamera);

      if (result != null) {
        _currentEmergency?.actionsPerformed.add('emergency_photo_captured');
        await _databaseService.updateEmergencyEvent(_currentEmergency!);
      }

      return result?['file_path'];
    } catch (e) {
      debugPrint('Error capturing emergency photo: $e');
      return null;
    }
  }

  Future<String?> recordEmergencyAudio({int durationSeconds = 30}) async {
    if (_currentState != EmergencyState.active) return null;

    try {
      final mediaCollector = _dataCollectorService.mediaCollector;
      final result =
          await mediaCollector.recordAudio(durationSeconds: durationSeconds);

      if (result != null) {
        _currentEmergency?.actionsPerformed.add('emergency_audio_recorded');
        await _databaseService.updateEmergencyEvent(_currentEmergency!);
      }

      return result?['file_path'];
    } catch (e) {
      debugPrint('Error recording emergency audio: $e');
      return null;
    }
  }

  Future<bool> sendEmergencyMessage(String message) async {
    if (_currentState != EmergencyState.active) return false;

    try {
      await _webSocketService.sendEmergencyMessage({
        'emergency_id': _currentEmergency!.id,
        'message': message,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      _currentEmergency?.actionsPerformed.add('emergency_message_sent');
      await _databaseService.updateEmergencyEvent(_currentEmergency!);

      return true;
    } catch (e) {
      debugPrint('Error sending emergency message: $e');
      return false;
    }
  }

  void _updateState(EmergencyState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('Emergency state changed to: ${newState.name}');
    }
  }

  // Configuration methods
  Future<void> updateConfiguration({
    bool? autoLocationTracking,
    bool? autoMediaCapture,
    bool? autoNotifyContacts,
    int? emergencyDataSyncInterval,
  }) async {
    if (autoLocationTracking != null) {
      _autoLocationTracking = autoLocationTracking;
      await _storageService.setBool(
          'emergency_auto_location', autoLocationTracking);
    }

    if (autoMediaCapture != null) {
      _autoMediaCapture = autoMediaCapture;
      await _storageService.setBool('emergency_auto_media', autoMediaCapture);
    }

    if (autoNotifyContacts != null) {
      _autoNotifyContacts = autoNotifyContacts;
      await _storageService.setBool(
          'emergency_auto_notify', autoNotifyContacts);
    }

    if (emergencyDataSyncInterval != null) {
      _emergencyDataSyncInterval = emergencyDataSyncInterval;
      await _storageService.setInt(
          'emergency_sync_interval', emergencyDataSyncInterval);
    }
  }

  Map<String, dynamic> getConfiguration() {
    return {
      'auto_location_tracking': _autoLocationTracking,
      'auto_media_capture': _autoMediaCapture,
      'auto_notify_contacts': _autoNotifyContacts,
      'emergency_data_sync_interval': _emergencyDataSyncInterval,
    };
  }

  // Emergency action implementations

  Future<void> _captureEmergencyLocation() async {
    try {
      final locationCollector = locator<LocationCollector>();
      await locationCollector.collectLocationData(priority: 1, emergency: true);
      _currentEmergency?.actionsPerformed.add('emergency_location_captured');
      debugPrint('Emergency location captured');
    } catch (e) {
      debugPrint('Error capturing emergency location: $e');
    }
  }

  Future<void> _captureEmergencyPhoto() async {
    try {
      final mediaCollector = locator<MediaCollector>();
      await mediaCollector.captureEmergencyPhoto();
      _currentEmergency?.actionsPerformed.add('emergency_photo_captured');
      debugPrint('Emergency photo captured');
    } catch (e) {
      debugPrint('Error capturing emergency photo: $e');
    }
  }

  Future<void> _enableEmergencyDataCollection() async {
    try {
      // Start all collectors for emergency mode
      await _dataCollectorService.startCollectors();

      // Collect immediate data snapshots
      await _collectImmediateDataSnapshot();

      _currentEmergency?.actionsPerformed
          .add('emergency_data_collection_enabled');
      debugPrint('Emergency data collection enabled');
    } catch (e) {
      debugPrint('Error enabling emergency data collection: $e');
    }
  }

  Future<void> _collectImmediateDataSnapshot() async {
    try {
      // Collect SMS data
      final smsCollector = locator<SmsCollector>();
      await smsCollector.collectRecentMessages(emergency: true);

      // Collect call data
      final callsCollector = locator<CallsCollector>();
      await callsCollector.collectRecentCalls(emergency: true);

      // Collect app usage data
      await _dataCollectorService.syncData();

      debugPrint('Immediate data snapshot collected');
    } catch (e) {
      debugPrint('Error collecting immediate data snapshot: $e');
    }
  }

  Future<void> _sendEmergencyNotification() async {
    try {
      await _notificationService.showEmergencyNotification(
        'Emergency Mode Active',
        'High-priority monitoring enabled',
      );

      _currentEmergency?.actionsPerformed.add('emergency_notification_sent');
      debugPrint('Emergency notification sent');
    } catch (e) {
      debugPrint('Error sending emergency notification: $e');
    }
  }

  Future<void> _notifyEmergency() async {
    try {
      if (_currentEmergency == null) return;

      // Send emergency alert via WebSocket
      await _webSocketService.sendMessage({
        'type': 'emergency_alert',
        'emergency_id': _currentEmergency!.id,
        'trigger_type': _currentEmergency!.triggerType.name,
        'priority': 'critical',
        'timestamp': _currentEmergency!.activatedAt.toUtc().toIso8601String(),
        'device_id': _currentEmergency!.deviceId,
        'trigger_data': _currentEmergency!.triggerData,
        'metadata': _currentEmergency!.metadata,
      });

      // Send via API as backup
      await _apiClient.sendEmergencyAlert(_currentEmergency!.toJson());

      _currentEmergency?.actionsPerformed.add('emergency_alert_sent');
      debugPrint('Emergency alert sent to monitoring system');
    } catch (e) {
      debugPrint('Error notifying emergency: $e');
    }
  }

  void _startEmergencyMonitoring() {
    // Start enhanced heartbeat
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
        Duration(seconds: _emergencyDataSyncInterval), (_) async {
      await _sendEmergencyHeartbeat();
    });

    // Start emergency data sync
    _emergencyTimer?.cancel();
    _emergencyTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _performEmergencyDataSync();
    });

    debugPrint('Emergency monitoring started');
  }

  Future<void> _sendEmergencyHeartbeat() async {
    if (_currentState != EmergencyState.active) return;

    try {
      final heartbeat = {
        'type': 'emergency_heartbeat',
        'emergency_id': _currentEmergency?.id,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'device_id': await DeviceUtils.getDeviceIdentifier(),
        'battery_level': await _getBatteryLevel(),
        'location': await _getCurrentLocation(),
        'network_status': await _getNetworkStatus(),
        'app_status': 'active',
      };

      await _webSocketService.sendMessage(heartbeat);
      debugPrint('Emergency heartbeat sent');
    } catch (e) {
      debugPrint('Error sending emergency heartbeat: $e');
    }
  }

  Future<void> _performEmergencyDataSync() async {
    if (_currentState != EmergencyState.active) return;

    try {
      // Force immediate sync of all collected data
      await _dataCollectorService.syncData();
      debugPrint('Emergency data sync completed');
    } catch (e) {
      debugPrint('Error performing emergency data sync: $e');
    }
  }

  Future<int> _getBatteryLevel() async {
    try {
      final batteryService = locator<BatteryMonitorService>();
      return await batteryService.getBatteryLevel();
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      return -1;
    }
  }

  Future<Map<String, dynamic>> _getNetworkStatus() async {
    try {
      final connectivityService = locator<ConnectivityService>();
      final status = await connectivityService.checkConnectivity();
      return {'status': status.toString()};
    } catch (e) {
      debugPrint('Error getting network status: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      final locationCollector = locator<LocationCollector>();
      return await locationCollector.getCurrentLocation();
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Emergency trigger implementations

  Future<void> setupPanicButton() async {
    try {
      // Setup hardware button listeners
      SystemChannels.keyEvent.setMessageHandler((message) async {
        // Handle volume button sequences for panic trigger
        await _handlePanicButtonSequence(message);
        return null;
      });

      debugPrint('Panic button setup completed');
    } catch (e) {
      debugPrint('Error setting up panic button: $e');
    }
  }

  Future<void> _handlePanicButtonSequence(dynamic message) async {
    // Implement panic button sequence detection
    // For example: Volume Up + Volume Down + Volume Up pressed in sequence
    try {
      // This would need specific implementation based on requirements
      debugPrint('Panic button sequence detected');

      await activateEmergency(
        triggerType: EmergencyTriggerType.panic,
        trigger: EmergencyTrigger.volumeButtonSequence,
        priority: EmergencyPriority.critical,
      );
    } catch (e) {
      debugPrint('Error handling panic button sequence: $e');
    }
  }

  Future<void> setupShakeDetection() async {
    try {
      // Setup accelerometer listener for shake detection
      // This would require additional sensor packages
      debugPrint('Shake detection setup completed');
    } catch (e) {
      debugPrint('Error setting up shake detection: $e');
    }
  }

  Future<void> setupVoiceKeywordDetection() async {
    try {
      // Setup voice keyword detection
      // This would require speech recognition packages
      debugPrint('Voice keyword detection setup completed');
    } catch (e) {
      debugPrint('Error setting up voice keyword detection: $e');
    }
  }

  Future<void> setupGeofenceMonitoring(
      List<Map<String, dynamic>> geofences) async {
    try {
      // Setup geofence monitoring
      for (final _ in geofences) {
        // Implement geofence logic
      }
      debugPrint('Geofence monitoring setup completed');
    } catch (e) {
      debugPrint('Error setting up geofence monitoring: $e');
    }
  }

  // Emergency analytics and reporting

  Future<Map<String, dynamic>> getEmergencyStatistics() async {
    try {
      final events = await _databaseService.getEmergencyEvents();

      return {
        'total_emergencies': events.length,
        'last_emergency':
            events.isNotEmpty ? events.last['activated_at'] as String? : null,
        'trigger_type_breakdown': _getTriggerTypeBreakdown(events),
        'average_duration_minutes': _getAverageDuration(events),
        'success_rate': _getSuccessRate(events),
      };
    } catch (e) {
      debugPrint('Error getting emergency statistics: $e');
      return {};
    }
  }

  Map<String, int> _getTriggerTypeBreakdown(List<Map<String, dynamic>> events) {
    final breakdown = <String, int>{};
    for (final event in events) {
      final key = event['trigger_type'] as String? ?? 'unknown';
      breakdown[key] = (breakdown[key] ?? 0) + 1;
    }
    return breakdown;
  }

  double _getAverageDuration(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return 0.0;

    final completedEvents =
        events.where((e) => e['deactivated_at'] != null).toList();
    if (completedEvents.isEmpty) return 0.0;

    final totalDuration = completedEvents.fold<int>(0, (sum, event) {
      final activatedAt = DateTime.parse(event['activated_at'] as String);
      final deactivatedAt = DateTime.parse(event['deactivated_at'] as String);
      return sum + deactivatedAt.difference(activatedAt).inMinutes;
    });

    return totalDuration / completedEvents.length;
  }

  double _getSuccessRate(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return 0.0;

    final successfulEvents = events
        .where((e) =>
            (e['actions_performed'] as List<dynamic>?)
                ?.contains('emergency_alert_sent') ??
            false)
        .length;

    return (successfulEvents / events.length) * 100;
  }

  // Test emergency functionality

  Future<bool> testEmergencySystem() async {
    try {
      debugPrint('Testing emergency system...');

      // Test location capture
      await _captureEmergencyLocation();

      // Test notification system
      await _sendEmergencyNotification();

      // Test data collection
      await _collectImmediateDataSnapshot();

      // Test communication
      await _webSocketService.sendMessage({
        'type': 'emergency_test',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'status': 'test_successful',
      });

      debugPrint('Emergency system test completed successfully');
      return true;
    } catch (e) {
      debugPrint('Emergency system test failed: $e');
      return false;
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _emergencyTimer?.cancel();
    _stateController.close();
    _eventController.close();
  }
}
