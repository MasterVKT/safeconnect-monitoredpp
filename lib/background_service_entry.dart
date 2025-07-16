import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/utils/error_logger.dart';

// Cette fonction est le point d'entrée du service d'arrière-plan
@pragma('vm:entry-point')
void backgroundServiceEntryPoint() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure l'isolate Flutter pour recevoir les messages
  final ReceivePort receivePort = ReceivePort();
  final SendPort uiSendPort = IsolateNameServer.lookupPortByName('background_isolate_send_port')!;
  
  // Enregistrer la fonction de callback dans l'isolate principal
  IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    'background_isolate_receive_port',
  );
  
  // Configuration du mode d'erreur
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.logError(
      'Background service error',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  
  // Initialiser les services nécessaires
  final dataCollectorService = DataCollectorService();
  final batteryMonitorService = BatteryMonitorService();
  final websocketService = WebSocketService();
  
  // Récupérer les services dans une fonction asynchrone
  Future<void> initServices() async {
    try {
      await dataCollectorService.initialize();
      await websocketService.connect();
      batteryMonitorService.startMonitoring();
      await dataCollectorService.startCollectors();
      
      // Envoi d'un message à l'UI pour confirmer le démarrage
      uiSendPort.send({'type': 'service_started', 'timestamp': DateTime.now().toIso8601String()});
    } catch (e, stackTrace) {
      ErrorLogger.logError('Failed to initialize background services', e, stackTrace);
      uiSendPort.send({'type': 'service_error', 'error': e.toString()});
    }
  }
  
  // Démarrer l'initialisation
  initServices();
  
  // Écouter les messages du thread principal
  receivePort.listen((dynamic message) {
    if (message is Map<String, dynamic>) {
      final type = message['type'];
      
      switch (type) {
        case 'stop_service':
          _cleanupAndStop(dataCollectorService, batteryMonitorService, websocketService);
          break;
        case 'heartbeat':
          uiSendPort.send({'type': 'heartbeat_response', 'timestamp': DateTime.now().toIso8601String()});
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
    }
  });

  // Garder l'isolate actif
  Timer.periodic(const Duration(minutes: 15), (_) async {
    try {
      // Vérifier l'état des services et redémarrer si nécessaire
      if (!websocketService.isConnected) {
        await websocketService.connect();
      }
      
      // Synchroniser les données si nécessaire
      await dataCollectorService.syncData();
      
      // Envoyer un heartbeat à l'UI
      uiSendPort.send({'type': 'heartbeat', 'timestamp': DateTime.now().toIso8601String()});
    } catch (e, stackTrace) {
      ErrorLogger.logError('Error in background service periodic check', e, stackTrace);
    }
  });
}

Future<void> _cleanupAndStop(
  DataCollectorService dataCollectorService,
  BatteryMonitorService batteryMonitorService,
  WebSocketService websocketService,
) async {
  try {
    await dataCollectorService.stopCollectors();
    batteryMonitorService.stopMonitoring();
    await websocketService.disconnect();
    
    // Désinscrire le port
    IsolateNameServer.removePortNameMapping('background_isolate_receive_port');
  } catch (e, stackTrace) {
    ErrorLogger.logError('Error stopping background services', e, stackTrace);
  }
}