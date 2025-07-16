import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static const String _isolateName = 'safeconnect_background_isolate';
  static SendPort? _uiSendPort;

  final MethodChannel _channel = const MethodChannel('com.xpsafeconnect.monitored_app/background');
  final StorageService _storageService = locator<StorageService>();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  final BatteryMonitorService _batteryMonitorService = locator<BatteryMonitorService>();
  final DataCollectorService _dataCollectorService = locator<DataCollectorService>();

  // Singleton pattern
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isRunning = false;
  Timer? _heartbeatTimer;
  SendPort? _backgroundSendPort;

  bool get isRunning => _isRunning;

  Future<void> startService() async {
    if (_isRunning) return;

    try {
      // Récupérer le handle du callback
      final prefs = await SharedPreferences.getInstance();
      final callbackHandle = prefs.getInt('callback_handle');

      if (callbackHandle == null) {
        debugPrint('No callback handle found');
        return;
      }

      // Démarrer le service natif
      final result = await _channel.invokeMethod<bool>('startService', {
        'callback_handle': callbackHandle,
      });

      if (result != true) {
        debugPrint('Failed to start background service');
        return;
      }

      // Attendre que l'isolate d'arrière-plan s'enregistre
      await _waitForBackgroundIsolate();

      // Configurer le port pour la communication entre isolates
      final ReceivePort receivePort = ReceivePort();
      if (!IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName)) {
        IsolateNameServer.removePortNameMapping(_isolateName);
        IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName);
      }

      // Écouter les messages de l'isolate d'arrière-plan
      receivePort.listen(_handleMessage);

      // Démarrer les services de collecte de données
      await _webSocketService.connect();
      _batteryMonitorService.startMonitoring();
      await _dataCollectorService.initialize();
      await _dataCollectorService.startCollectors();

      // Démarrer le timer pour les heartbeats
      _startHeartbeatTimer();

      _isRunning = true;
      debugPrint('Background service started');
    } catch (e) {
      debugPrint('Error starting background service: $e');
    }
  }

  Future<void> stopService() async {
    if (!_isRunning) return;

    try {
      // Arrêter le timer des heartbeats
      _stopHeartbeatTimer();

      // Arrêter les services de collecte de données
      await _dataCollectorService.stopCollectors();
      _batteryMonitorService.stopMonitoring();
      await _webSocketService.disconnect();

      // Envoyer un message à l'isolate d'arrière-plan pour s'arrêter
      if (_backgroundSendPort != null) {
        _backgroundSendPort!.send({'type': 'stop_service'});
      }

      // Arrêter le service natif
      final result = await _channel.invokeMethod<bool>('stopService');

      if (result == true) {
        _isRunning = false;
        _backgroundSendPort = null;
        IsolateNameServer.removePortNameMapping(_isolateName);
        debugPrint('Background service stopped');
      } else {
        debugPrint('Failed to stop background service');
      }
    } catch (e) {
      debugPrint('Error stopping background service: $e');
    }
  }

  //Facilement accessible depuis l’interface IsolateNameServer
  void _handleMessage(dynamic message) {
    if (message is Map<String, dynamic>) {
      final type = message['type'];

      switch (type) {
        case 'data_collected':
          _handleDataCollected(message['data']);
          break;
        case 'heartbeat_response':
          // Service is still alive, do nothing
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
    }
  }

  void _handleDataCollected(Map<String, dynamic> data) {
    // Traiter les données collectées
    final dataType = data['data_type'];
    final items = data['items'];

    debugPrint('Received $dataType data: ${items.length} items');

    // Mettre en file d'attente pour la synchronisation
    _dataCollectorService.queueForSync(dataType, items);
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _sendHeartbeat();
    });
  }

  void _stopHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    final sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    if (sendPort != null) {
      sendPort.send({'type': 'heartbeat'});
    }
  }

  static void sendMessageToUi(Map<String, dynamic> message) {
    if (_uiSendPort != null) {
      _uiSendPort!.send(message);
    }
  }

  static void registerUiIsolate(SendPort sendPort) {
    _uiSendPort = sendPort;
  }

  Future<void> _waitForBackgroundIsolate() async {
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final port = IsolateNameServer.lookupPortByName('background_isolate_receive_port');
      if (port != null) {
        _backgroundSendPort = port;
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    debugPrint('Timed out waiting for background isolate to register');
  }

  Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      _isRunning = result ?? false;
      return _isRunning;
    } catch (e) {
      debugPrint('Error checking service status: $e');
      return false;
    }
  }

  void sendMessageToBackground(Map<String, dynamic> message) {
    if (_backgroundSendPort != null) {
      _backgroundSendPort!.send(message);
    } else {
      debugPrint('Background send port not available');
    }
  }
}