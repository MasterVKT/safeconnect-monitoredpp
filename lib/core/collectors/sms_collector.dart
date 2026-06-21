import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/collectors/base_collector.dart';
import 'package:monitored_app/core/collectors/bootstrap_checkpoint.dart';

class SmsCollector extends BaseCollector {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/sms');
  static const Duration _bootstrapHistoryWindow = Duration(days: 90);
  static const int _nativeBatchLimit = 500;
  static const int _checkpointStateVersion = 2;

  Timer? _checkTimer;
  bool _isCollectionInProgress = false;

  // Database service reference
  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  late final BootstrapCheckpoint _checkpoint = BootstrapCheckpoint(
    storageService: _storageService,
    keyPrefix: 'sms_collector',
    historyWindow: _bootstrapHistoryWindow,
    stateVersion: _checkpointStateVersion,
  );

  @override
  String get collectorName => 'SMS';

  @override
  String get dataType => 'sms';

  @override
  List<Permission> get requiredPermissions => [Permission.sms];

  @override
  Future<void> initializeSpecific() async {
    try {
      await _storageService.reloadPreferences();
      await _checkpoint.initialize();

      debugPrint(
        '[SMS] initialized with bootstrapPending=${_checkpoint.isBootstrapPending}, '
        'lastCheckTime=${_checkpoint.lastCheckpoint}',
      );

      // Set up native event channel for real-time SMS detection
      // This is handled in the platform-specific code
    } catch (e) {
      debugPrint('Error initializing SMS collector specific: $e');
    }
  }

  @override
  Future<bool> checkSpecificPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkSmsPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking SMS permissions: $e');
      return false;
    }
  }

  @override
  Future<void> requestSpecificPermissions() async {
    try {
      await _channel.invokeMethod('requestSmsPermissions');
    } catch (e) {
      debugPrint('Error requesting SMS permissions: $e');
    }
  }

  @override
  Future<void> startSpecificCollection() async {
    try {
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

      debugPrint('SMS specific collection started');
    } catch (e) {
      debugPrint('Error starting SMS specific collection: $e');
    }
  }

  @override
  Future<void> stopSpecificCollection() async {
    try {
      // Stop listening for SMS broadcasts
      await _channel.invokeMethod('stopSmsTracking');

      // Stop periodic check
      _checkTimer?.cancel();
      _checkTimer = null;

      // Remove method call handler
      _channel.setMethodCallHandler(null);

      debugPrint('SMS specific collection stopped');
    } catch (e) {
      debugPrint('Error stopping SMS specific collection: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> collectData() async {
    if (_isCollectionInProgress) {
      debugPrint('[SMS] Collection skipped: another collection is running');
      return [];
    }

    _isCollectionInProgress = true;
    try {
      if (!await checkSpecificPermissions()) {
        debugPrint(
          '[SMS] Collection deferred: SMS permissions are not granted',
        );
        return [];
      }

      var checkpoint = _checkpoint.resolve();
      final isBootstrap = _checkpoint.isBootstrapPending;
      final processedSms = <Map<String, dynamic>>[];
      var keepFetching = true;

      while (keepFetching) {
        final smsList = await _channel.invokeMethod<List<dynamic>>(
          'getNewSms',
          {
            'since': checkpoint.millisecondsSinceEpoch,
            'limit': _nativeBatchLimit,
          },
        );
        final batch = smsList ?? const <dynamic>[];

        debugPrint(
            '[SMS] getNewSms returned ${batch.length} entries since $checkpoint (bootstrap=$isBootstrap)');

        var latestMessageDateMs = checkpoint.millisecondsSinceEpoch;
        for (final sms in batch) {
          final smsMap = sms as Map<dynamic, dynamic>;
          final rawDate = _readInt(smsMap['date']);
          if (rawDate != null && rawDate > latestMessageDateMs) {
            latestMessageDateMs = rawDate;
          }

          final processedSmsData = await _convertSmsData(smsMap);
          if (processedSmsData != null) {
            processedSms.add(processedSmsData);
          }
        }

        keepFetching = batch.length >= _nativeBatchLimit &&
            latestMessageDateMs > checkpoint.millisecondsSinceEpoch;
        checkpoint = DateTime.fromMillisecondsSinceEpoch(latestMessageDateMs);
      }

      if (!await checkSpecificPermissions()) {
        debugPrint(
          '[SMS] Checkpoint not advanced: permission changed during scan',
        );
        return processedSms;
      }

      if (isBootstrap && processedSms.isEmpty) {
        debugPrint(
            '[SMS] Bootstrap returned 0 entries — checkpoint NOT advanced, will retry on next cycle');
      } else {
        await _checkpoint.completeSuccessfulScan(
          processedSms.isEmpty ? DateTime.now() : checkpoint,
        );
        if (isBootstrap) {
          debugPrint(
              '[SMS] Bootstrap completed: ${processedSms.length} historical SMS captured.');
        }
      }

      return processedSms;
    } catch (e) {
      debugPrint('[SMS] Error collecting SMS data: $e');
      return [];
    } finally {
      _isCollectionInProgress = false;
    }
  }

  Future<void> resetBootstrap() async {
    await _checkpoint.reset();
    debugPrint('[SMS] Historical bootstrap reset');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSmsReceived':
        final smsData = call.arguments as Map<dynamic, dynamic>;
        final processedSms = await _convertSmsData(smsData);
        if (processedSms != null) {
          await processData([processedSms]);
        }
        break;
      default:
        debugPrint('Unknown method: ${call.method}');
    }
  }

  Future<void> _checkForNewSms() async {
    try {
      // Use the collectData method for consistency
      final smsData = await collectData();
      if (smsData.isNotEmpty) {
        await processData(smsData);
        debugPrint(
            'SMS periodic check complete: ${smsData.length} new messages');
      }
    } catch (e) {
      debugPrint('Error checking for new SMS: $e');
    }
  }

  Future<Map<String, dynamic>?> _convertSmsData(
      Map<dynamic, dynamic> smsData) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final rawDate = _readInt(smsData['date']);
      if (rawDate == null) {
        debugPrint('[SMS] Skipping SMS data with missing date');
        return null;
      }

      final sentAt = DateTime.fromMillisecondsSinceEpoch(rawDate);
      final sender = smsData['sender'] ?? '';
      final recipient = smsData['recipient'] ?? '';
      final body = smsData['body'] ?? '';
      final direction =
          _readInt(smsData['type']) == 1 ? 'INCOMING' : 'OUTGOING';

      // Store in database using database service
      await _databaseService.insertSmsData(
        deviceId: deviceId,
        messageType: 'SMS',
        direction: direction,
        sender: direction == 'INCOMING' ? sender : recipient,
        senderName: null,
        body: body,
        sentAt: sentAt,
        conversationId: smsData['thread_id']?.toString(),
        hasAttachment: false,
      );

      // Return processed SMS data for sync
      return {
        'message_type': 'SMS',
        'direction': direction,
        'sender': direction == 'INCOMING' ? sender : recipient,
        'body': body,
        'sent_at': sentAt.toUtc().toIso8601String(),
        'thread_id': smsData['thread_id']?.toString() ?? '',
        'has_attachment': false,
      };
    } catch (e) {
      debugPrint('Error converting SMS data: $e');
      return null;
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Emergency-specific SMS collection method
  Future<void> collectRecentMessages({bool emergency = false}) async {
    try {
      // Collect messages from the last 24 hours for emergency mode
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final recentMessages = await _channel.invokeMethod<List<dynamic>>(
          'getRecentMessages',
          {'cutoff_time': cutoffTime.millisecondsSinceEpoch});

      if (recentMessages != null && recentMessages.isNotEmpty) {
        final processedMessages = <Map<String, dynamic>>[];

        for (final messageData in recentMessages) {
          final convertedData = await _convertEmergencyMessageData(
              messageData as Map<dynamic, dynamic>,
              emergency: emergency);
          if (convertedData != null) {
            processedMessages.add(convertedData);
          }
        }

        if (processedMessages.isNotEmpty) {
          await processData(processedMessages);
          debugPrint(
              'Emergency SMS collection complete: ${processedMessages.length} recent messages');
        }
      }
    } catch (e) {
      debugPrint('Error collecting recent SMS messages: $e');
    }
  }

  Future<Map<String, dynamic>?> _convertEmergencyMessageData(
      Map<dynamic, dynamic> smsData,
      {bool emergency = false}) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final rawDate = _readInt(smsData['date']);
      if (rawDate == null) {
        debugPrint('[SMS] Skipping emergency SMS data with missing date');
        return null;
      }

      final sentAt = DateTime.fromMillisecondsSinceEpoch(rawDate);
      final sender = smsData['sender'] ?? '';
      final recipient = smsData['recipient'] ?? '';
      final body = smsData['body'] ?? '';
      final direction =
          _readInt(smsData['type']) == 1 ? 'INCOMING' : 'OUTGOING';

      // Store in database with emergency flag
      await _databaseService.insertSmsData(
        deviceId: deviceId,
        messageType: emergency ? 'EMERGENCY_SMS' : 'SMS',
        direction: direction,
        sender: direction == 'INCOMING' ? sender : recipient,
        senderName: null,
        body: body,
        sentAt: sentAt,
        conversationId: smsData['thread_id']?.toString(),
        hasAttachment: false,
      );

      // Prepare data for sync with emergency flag
      final messageData = {
        'message_type': emergency ? 'EMERGENCY_SMS' : 'SMS',
        'direction': direction,
        'sender': direction == 'INCOMING' ? sender : recipient,
        'body': body,
        'sent_at': sentAt.toUtc().toIso8601String(),
        'thread_id': smsData['thread_id']?.toString() ?? '',
        'has_attachment': false,
        'emergency': emergency,
        'collected_at': DateTime.now().toUtc().toIso8601String(),
      };

      // If emergency, queue with highest priority
      if (emergency) {
        await _databaseService.queueDataForSync('emergency_sms', messageData,
            priority: 1);
      }

      return messageData;
    } catch (e) {
      debugPrint('Error converting emergency SMS data: $e');
      return null;
    }
  }
}
