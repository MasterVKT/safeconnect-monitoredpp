import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/collection_ownership_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/utils/error_logger.dart';
import 'package:monitored_app/firebase_options.dart';

@pragma('vm:entry-point')
void backgroundServiceEntryPoint() {
  WidgetsFlutterBinding.ensureInitialized();

  final ReceivePort receivePort = ReceivePort();
  final SendPort? uiSendPort =
      IsolateNameServer.lookupPortByName('background_isolate_send_port');

  IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    'background_isolate_receive_port',
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.logError(
      'Background service error',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  Future<void> initServices() async {
    DataCollectorService? dataCollectorService;
    BatteryMonitorService? batteryMonitorService;
    WebSocketService? websocketService;
    Timer? ownershipRetryTimer;
    Timer? periodicSyncTimer;
    var ownsCollection = false;

    Future<bool> startOwnedCollection() async {
      final collector = dataCollectorService;
      final socket = websocketService;
      if (collector == null || socket == null) {
        return false;
      }

      final started = await collector.startCollectors(
        owner: CollectionLeaseOwner.backgroundIsolate,
      );
      if (!started) {
        if (ownsCollection) {
          ownsCollection = false;
          await socket.disconnect();
        }
        debugPrint(
          'Background isolate: another isolate owns collection; keeping service alive',
        );
        return false;
      }

      if (!socket.isConnected) {
        await socket.connect();
      }
      ownsCollection = true;
      return true;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await setupBackgroundLocator();

      dataCollectorService = locator<DataCollectorService>();
      batteryMonitorService = locator<BatteryMonitorService>();
      websocketService = locator<WebSocketService>();

      batteryMonitorService.startMonitoring();
      await startOwnedCollection();

      uiSendPort?.send({
        'type': 'service_started',
        'owns_collection': ownsCollection,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Failed to initialize background services',
        e,
        stackTrace,
      );
      uiSendPort?.send({'type': 'service_error', 'error': e.toString()});
    }

    receivePort.listen((dynamic message) {
      if (message is! Map<String, dynamic>) {
        return;
      }

      final type = message['type'];
      switch (type) {
        case 'stop_service':
          ownershipRetryTimer?.cancel();
          periodicSyncTimer?.cancel();
          if (dataCollectorService != null &&
              batteryMonitorService != null &&
              websocketService != null) {
            _cleanupAndStop(
              dataCollectorService,
              batteryMonitorService,
              websocketService,
            );
          }
          break;
        case 'heartbeat':
          uiSendPort?.send({
            'type': 'heartbeat_response',
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
    });

    ownershipRetryTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (ownsCollection &&
          dataCollectorService?.collectionOwner !=
              CollectionLeaseOwner.backgroundIsolate) {
        ownsCollection = false;
      }

      if (!ownsCollection) {
        try {
          await startOwnedCollection();
        } catch (e, stackTrace) {
          ErrorLogger.logError(
            'Error while retrying background collection ownership',
            e,
            stackTrace,
          );
        }
      }
    });

    periodicSyncTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      try {
        if (dataCollectorService == null || websocketService == null) {
          return;
        }

        final collector = dataCollectorService;
        final socket = websocketService;
        if (!ownsCollection) {
          uiSendPort?.send({
            'type': 'heartbeat',
            'owns_collection': false,
            'timestamp': DateTime.now().toIso8601String(),
          });
          return;
        }

        if (!socket.isConnected) {
          await socket.connect();
        }

        await collector.syncData(
          owner: CollectionLeaseOwner.backgroundIsolate,
        );
        ownsCollection =
            collector.collectionOwner == CollectionLeaseOwner.backgroundIsolate;

        uiSendPort?.send({
          'type': 'heartbeat',
          'owns_collection': ownsCollection,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e, stackTrace) {
        ErrorLogger.logError(
          'Error in background service periodic check',
          e,
          stackTrace,
        );
      }
    });
  }

  initServices();
}

Future<void> _cleanupAndStop(
  DataCollectorService dataCollectorService,
  BatteryMonitorService batteryMonitorService,
  WebSocketService websocketService,
) async {
  try {
    await dataCollectorService.stopCollectors(
      owner: CollectionLeaseOwner.backgroundIsolate,
    );
    batteryMonitorService.stopMonitoring();
    await websocketService.disconnect();

    IsolateNameServer.removePortNameMapping('background_isolate_receive_port');
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error stopping background services', e, stackTrace);
  }
}
