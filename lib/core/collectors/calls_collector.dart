import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

class CallsCollector {
  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/calls');
  final DataCollectorService _dataCollectorService = locator<DataCollectorService>();
  
  bool _isCollecting = false;
  Timer? _checkTimer;
  DateTime _lastCheckTime = DateTime.now();
  
  Future<void> initialize() async {
    try {
      // Check if call log permissions are granted
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('Call log permissions not granted');
        return;
      }
      
      // Set up native event channel for real-time call detection
      // This is handled in the platform-specific code
    } catch (e) {
      debugPrint('Error initializing calls collector: $e');
    }
  }
  
  Future<bool> _checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkCallLogPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking call log permissions: $e');
      return false;
    }
  }
  
  Future<void> startCollecting() async {
    if (_isCollecting) return;
    
    try {
      // Check permissions first
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('Cannot start calls collection: permissions not granted');
        return;
      }
      
      // Start listening for call events from native side
      await _channel.invokeMethod('startCallTracking');
      
      // Register callback for call events
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Start periodic check for missed calls
      _checkTimer = Timer.periodic(const Duration(minutes: 15), (_) {
        _checkForNewCalls();
      });
      
      // Do an initial check
      _checkForNewCalls();
      
      _isCollecting = true;
      debugPrint('Calls collector started');
    } catch (e) {
      debugPrint('Error starting calls collector: $e');
    }
  }
  
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    try {
      // Stop listening for call events
      await _channel.invokeMethod('stopCallTracking');
      
      // Stop periodic check
      _checkTimer?.cancel();
      _checkTimer = null;
      
      // Remove method call handler
      _channel.setMethodCallHandler(null);
      
      _isCollecting = false;
      debugPrint('Calls collector stopped');
    } catch (e) {
      debugPrint('Error stopping calls collector: $e');
    }
  }
  
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCallStateChanged':
        final callData = call.arguments as Map<dynamic, dynamic>;
        await _processCall(callData);
        break;
      default:
        debugPrint('Unknown method: ${call.method}');
    }
  }
  
  Future<void> _checkForNewCalls() async {
    try {
      // Get current time
      final now = DateTime.now();
      
      // Get calls since last check
      final callsList = await _channel.invokeMethod<List<dynamic>>(
        'getNewCalls',
        {'since': _lastCheckTime.millisecondsSinceEpoch},
      );
      
      if (callsList != null && callsList.isNotEmpty) {
        for (final call in callsList) {
          await _processCall(call as Map<dynamic, dynamic>);
        }
      }
      
      // Update last check time
      _lastCheckTime = now;
      
      debugPrint('Calls check complete: ${callsList?.length ?? 0} new calls');
    } catch (e) {
      debugPrint('Error checking for new calls: $e');
    }
  }
  
  Future<void> _processCall(Map<dynamic, dynamic> callData) async {
    try {
      // Convert to proper format for sync
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      
      final callType = _getCallType(callData['type'] as int);
      final startTime = DateTime.fromMillisecondsSinceEpoch(callData['date'] as int);
      final endTimeMs = callData['duration'] != null 
          ? (callData['date'] as int) + ((callData['duration'] as int) * 1000)
          : null;
      final endTime = endTimeMs != null ? DateTime.fromMillisecondsSinceEpoch(endTimeMs) : null;
      
      final processedCall = {
        'device_id': deviceId,
        'call_type': callType,
        'phone_number': callData['number'] ?? '',
        'contact_name': callData['name'] ?? '',
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration': callData['duration'] ?? 0,
        'recorded_at': DateTime.now().toIso8601String(),
        'sim_slot': callData['sim_slot'],
        'is_conference': callData['is_conference'] == true,
      };
      
      // Queue for sync
      _dataCollectorService.queueForSync('calls', [processedCall]);
      
      debugPrint('Processed new call to/from ${processedCall['phone_number']}');
    } catch (e) {
      debugPrint('Error processing call: $e');
    }
  }
  
  String _getCallType(int type) {
    // Android call types:
    // 1 - Incoming
    // 2 - Outgoing
    // 3 - Missed
    // 4 - Voicemail
    // 5 - Rejected
    // 6 - Blocked
    switch (type) {
      case 1:
        return 'INCOMING';
      case 2:
        return 'OUTGOING';
      case 3:
        return 'MISSED';
      case 5:
        return 'REJECTED';
      case 6:
        return 'BLOCKED';
      default:
        return 'UNKNOWN';
    }
  }
}