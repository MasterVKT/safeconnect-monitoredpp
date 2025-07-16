import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';

class SmsCollector {
  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/sms');
  final DataCollectorService _dataCollectorService = locator<DataCollectorService>();
  
  bool _isCollecting = false;
  Timer? _checkTimer;
  DateTime _lastCheckTime = DateTime.now();
  
  Future<void> initialize() async {
    try {
      // Check if SMS permissions are granted
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('SMS permissions not granted');
        return;
      }
      
      // Set up native event channel for real-time SMS detection
      // This is handled in the platform-specific code
    } catch (e) {
      debugPrint('Error initializing SMS collector: $e');
    }
  }
  
  Future<bool> _checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkSmsPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking SMS permissions: $e');
      return false;
    }
  }
  
  Future<void> startCollecting() async {
    if (_isCollecting) return;
    
    try {
      // Check permissions first
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('Cannot start SMS collection: permissions not granted');
        return;
      }
      
      // Start listening for SMS broadcasts from native side
      await _channel.invokeMethod('startSmsTracking');
      
      // Register callback for incoming SMS
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Start periodic check for missed SMS
      _checkTimer = Timer.periodic(const Duration(minutes: 15), (_) {
        _checkForNewSms();
      });
      
      // Do an initial check
      _checkForNewSms();
      
      _isCollecting = true;
      debugPrint('SMS collector started');
    } catch (e) {
      debugPrint('Error starting SMS collector: $e');
    }
  }
  
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    try {
      // Stop listening for SMS broadcasts
      await _channel.invokeMethod('stopSmsTracking');
      
      // Stop periodic check
      _checkTimer?.cancel();
      _checkTimer = null;
      
      // Remove method call handler
      _channel.setMethodCallHandler(null);
      
      _isCollecting = false;
      debugPrint('SMS collector stopped');
    } catch (e) {
      debugPrint('Error stopping SMS collector: $e');
    }
  }
  
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSmsReceived':
        final smsData = call.arguments as Map<dynamic, dynamic>;
        await _processSms(smsData);
        break;
      default:
        debugPrint('Unknown method: ${call.method}');
    }
  }
  
  Future<void> _checkForNewSms() async {
    try {
      // Get current time
      final now = DateTime.now();
      
      // Get SMS since last check
      final smsList = await _channel.invokeMethod<List<dynamic>>(
        'getNewSms',
        {'since': _lastCheckTime.millisecondsSinceEpoch},
      );
      
      if (smsList != null && smsList.isNotEmpty) {
        for (final sms in smsList) {
          await _processSms(sms as Map<dynamic, dynamic>);
        }
      }
      
      // Update last check time
      _lastCheckTime = now;
      
      debugPrint('SMS check complete: ${smsList?.length ?? 0} new messages');
    } catch (e) {
      debugPrint('Error checking for new SMS: $e');
    }
  }
  
  Future<void> _processSms(Map<dynamic, dynamic> smsData) async {
    try {
      // Convert to proper format for sync
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      
      final processedSms = {
        'device_id': deviceId,
        'message_type': 'SMS',
        'direction': smsData['type'] == 1 ? 'INCOMING' : 'OUTGOING',
        'sender': smsData['sender'] ?? '',
        'recipient': smsData['recipient'] ?? '',
        'body': smsData['body'] ?? '',
        'sent_at': DateTime.fromMillisecondsSinceEpoch(smsData['date'] as int).toIso8601String(),
        'recorded_at': DateTime.now().toIso8601String(),
        'thread_id': smsData['thread_id']?.toString() ?? '',
        'is_read': smsData['read'] == 1,
      };
      
      // Queue for sync
      _dataCollectorService.queueForSync('sms', [processedSms]);
      
      debugPrint('Processed new SMS from ${processedSms['sender']}');
    } catch (e) {
      debugPrint('Error processing SMS: $e');
    }
  }
}