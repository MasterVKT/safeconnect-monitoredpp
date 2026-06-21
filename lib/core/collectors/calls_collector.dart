import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/contact_resolution_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/collectors/base_collector.dart';
import 'package:monitored_app/core/collectors/bootstrap_checkpoint.dart';

class CallsCollector extends BaseCollector {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/calls');
  static const int _callStateIdle = 0;
  static const Duration _bootstrapHistoryWindow = Duration(days: 90);
  static const int _nativeBatchLimit = 500;
  static const int _checkpointStateVersion = 2;

  Timer? _checkTimer;
  bool _isCollectionInProgress = false;

  // Database service reference
  final DatabaseService _databaseService = locator<DatabaseService>();
  final StorageService _storageService = locator<StorageService>();
  final ContactResolutionService _contactResolutionService =
      locator<ContactResolutionService>();
  late final BootstrapCheckpoint _checkpoint = BootstrapCheckpoint(
    storageService: _storageService,
    keyPrefix: 'calls_collector',
    historyWindow: _bootstrapHistoryWindow,
    stateVersion: _checkpointStateVersion,
  );

  @override
  String get collectorName => 'Calls';

  @override
  String get dataType => 'calls';

  @override
  List<Permission> get requiredPermissions => [Permission.phone];

  @override
  Future<void> initializeSpecific() async {
    try {
      await _storageService.reloadPreferences();
      await _checkpoint.initialize();

      debugPrint(
        '[Calls] initialized with bootstrapPending=${_checkpoint.isBootstrapPending}, '
        'lastCheckTime=${_checkpoint.lastCheckpoint}',
      );

      // Set up native event channel for real-time call detection
      // This is handled in the platform-specific code
    } catch (e) {
      debugPrint('Error initializing calls collector specific: $e');
    }
  }

  @override
  Future<bool> checkSpecificPermissions() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkCallLogPermissions');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking call log permissions: $e');
      return false;
    }
  }

  @override
  Future<void> requestSpecificPermissions() async {
    try {
      await _channel.invokeMethod('requestCallLogPermissions');
    } catch (e) {
      debugPrint('Error requesting call log permissions: $e');
    }
  }

  @override
  Future<void> startSpecificCollection() async {
    try {
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

      debugPrint('Calls specific collection started');
    } catch (e) {
      debugPrint('Error starting calls specific collection: $e');
    }
  }

  @override
  Future<void> stopSpecificCollection() async {
    try {
      // Stop listening for call events
      await _channel.invokeMethod('stopCallTracking');

      // Stop periodic check
      _checkTimer?.cancel();
      _checkTimer = null;

      // Remove method call handler
      _channel.setMethodCallHandler(null);

      debugPrint('Calls specific collection stopped');
    } catch (e) {
      debugPrint('Error stopping calls specific collection: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> collectData() async {
    if (_isCollectionInProgress) {
      debugPrint('[Calls] Collection skipped: another collection is running');
      return [];
    }

    _isCollectionInProgress = true;
    try {
      if (!await checkSpecificPermissions()) {
        debugPrint(
          '[Calls] Collection deferred: call log permissions are not granted',
        );
        return [];
      }

      var checkpoint = _checkpoint.resolve();
      final isBootstrap = _checkpoint.isBootstrapPending;
      final processedCalls = <Map<String, dynamic>>[];
      var keepFetching = true;

      while (keepFetching) {
        final callsList = await _channel.invokeMethod<List<dynamic>>(
          'getNewCalls',
          {
            'since': checkpoint.millisecondsSinceEpoch,
            'limit': _nativeBatchLimit,
          },
        );
        final batch = callsList ?? const <dynamic>[];

        debugPrint(
            '[Calls] getNewCalls returned ${batch.length} entries since $checkpoint (bootstrap=$isBootstrap)');

        var latestCallDateMs = checkpoint.millisecondsSinceEpoch;
        for (final call in batch) {
          final callMap = call as Map<dynamic, dynamic>;
          final rawDate = _readInt(callMap['date']);
          if (rawDate != null && rawDate > latestCallDateMs) {
            latestCallDateMs = rawDate;
          }

          final processedCallData = await _convertCallData(callMap);
          if (processedCallData != null) {
            processedCalls.add(processedCallData);
          }
        }

        keepFetching = batch.length >= _nativeBatchLimit &&
            latestCallDateMs > checkpoint.millisecondsSinceEpoch;
        checkpoint = DateTime.fromMillisecondsSinceEpoch(latestCallDateMs);
      }

      if (!await checkSpecificPermissions()) {
        debugPrint(
          '[Calls] Checkpoint not advanced: permission changed during scan',
        );
        return processedCalls;
      }

      if (isBootstrap && processedCalls.isEmpty) {
        debugPrint(
            '[Calls] Bootstrap returned 0 entries — checkpoint NOT advanced, will retry on next cycle');
      } else {
        await _checkpoint.completeSuccessfulScan(
          processedCalls.isEmpty ? DateTime.now() : checkpoint,
        );
        if (isBootstrap) {
          debugPrint(
              '[Calls] Bootstrap completed: ${processedCalls.length} historical calls captured.');
        }
      }

      return processedCalls;
    } catch (e) {
      debugPrint('Error collecting call data: $e');
      return [];
    } finally {
      _isCollectionInProgress = false;
    }
  }

  Future<void> resetBootstrap() async {
    await _checkpoint.reset();
    debugPrint('[Calls] Historical bootstrap reset');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCallStateChanged':
        final callData = call.arguments as Map<dynamic, dynamic>?;
        final state = _readInt(callData?['state']);
        if (state == _callStateIdle) {
          await _checkForNewCalls();
        }
        break;
      default:
        debugPrint('Unknown method: ${call.method}');
    }
  }

  Future<void> _checkForNewCalls() async {
    try {
      // Use the collectData method for consistency
      final callData = await collectData();
      if (callData.isNotEmpty) {
        await processData(callData);
        debugPrint(
            'Calls periodic check complete: ${callData.length} new calls');
      }
    } catch (e) {
      debugPrint('Error checking for new calls: $e');
    }
  }

  Future<Map<String, dynamic>?> _convertCallData(
      Map<dynamic, dynamic> callData) async {
    try {
      final rawType = _readInt(callData['type']);
      final rawDate = _readInt(callData['date']);
      if (rawType == null || rawDate == null) {
        debugPrint('Skipping call data with missing type/date');
        return null;
      }

      final callType = _getCallType(rawType);
      final startTime = DateTime.fromMillisecondsSinceEpoch(rawDate);
      final duration = _readInt(callData['duration']) ?? 0;
      final endTime =
          duration > 0 ? startTime.add(Duration(seconds: duration)) : null;
      final phoneNumber = callData['number']?.toString() ?? '';
      var contactName = callData['name'] as String?;

      // Résoudre le nom du contact s'il est manquant
      if ((contactName == null || contactName.isEmpty) &&
          phoneNumber.isNotEmpty) {
        contactName =
            await _contactResolutionService.resolveContactName(phoneNumber);
      }

      // Return processed call data for sync
      return {
        'call_type': callType,
        'phone_number': phoneNumber,
        'contact_name': contactName,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime?.toUtc().toIso8601String(),
        'duration': duration,
        'recorded_at': startTime.toUtc().toIso8601String(),
        'sim_slot': callData['sim_slot'],
        'is_conference': callData['is_conference'] == true,
        'is_video_call': callData['is_video_call'] == true,
      };
    } catch (e) {
      debugPrint('Error converting call data: $e');
      return null;
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

  // Emergency-specific calls collection method
  Future<void> collectRecentCalls({bool emergency = false}) async {
    try {
      // Collect calls from the last 24 hours for emergency mode
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final recentCalls = await _channel.invokeMethod<List<dynamic>>(
          'getRecentCalls', {'cutoff_time': cutoffTime.millisecondsSinceEpoch});

      if (recentCalls != null && recentCalls.isNotEmpty) {
        final processedCalls = <Map<String, dynamic>>[];

        for (final callData in recentCalls) {
          final convertedData = await _convertEmergencyCallData(
              callData as Map<dynamic, dynamic>,
              emergency: emergency);
          if (convertedData != null) {
            processedCalls.add(convertedData);
          }
        }

        if (processedCalls.isNotEmpty) {
          await processData(processedCalls);
          debugPrint(
              'Emergency calls collection complete: ${processedCalls.length} recent calls');
        }
      }
    } catch (e) {
      debugPrint('Error collecting recent calls: $e');
    }
  }

  Future<Map<String, dynamic>?> _convertEmergencyCallData(
      Map<dynamic, dynamic> callData,
      {bool emergency = false}) async {
    try {
      final rawType = _readInt(callData['type']);
      final rawDate = _readInt(callData['date']);
      if (rawType == null || rawDate == null) {
        debugPrint('Skipping emergency call data with missing type/date');
        return null;
      }

      final callType = _getCallType(rawType);
      final startTime = DateTime.fromMillisecondsSinceEpoch(rawDate);
      final duration = _readInt(callData['duration']) ?? 0;
      final endTime =
          duration > 0 ? startTime.add(Duration(seconds: duration)) : null;
      final phoneNumber = callData['number']?.toString() ?? '';
      var contactName = callData['name'] as String?;

      // Résoudre le nom du contact s'il est manquant
      if ((contactName == null || contactName.isEmpty) &&
          phoneNumber.isNotEmpty) {
        contactName =
            await _contactResolutionService.resolveContactName(phoneNumber);
      }

      // Prepare data for sync with emergency flag
      final emergencyCallData = {
        'call_type': emergency ? 'EMERGENCY_$callType' : callType,
        'phone_number': phoneNumber,
        'contact_name': contactName,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime?.toUtc().toIso8601String(),
        'duration': duration,
        'recorded_at': startTime.toUtc().toIso8601String(),
        'sim_slot': callData['sim_slot'],
        'is_conference': callData['is_conference'] == true,
        'is_video_call': callData['is_video_call'] == true,
        'emergency': emergency,
        'collected_at': DateTime.now().toUtc().toIso8601String(),
      };

      // If emergency, queue with highest priority
      if (emergency) {
        await _databaseService.queueDataForSync(
            'emergency_calls', emergencyCallData,
            priority: 1);
      }

      return emergencyCallData;
    } catch (e) {
      debugPrint('Error converting emergency call data: $e');
      return null;
    }
  }
}
