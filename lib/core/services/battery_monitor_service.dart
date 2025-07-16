import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/websocket_service.dart';

class BatteryMonitorService {
  final Battery _battery = Battery();
  final WebSocketService _webSocketService = locator<WebSocketService>();
  
  Timer? _monitorTimer;
  StreamSubscription? _batteryStateSubscription;
  
  int _lastReportedLevel = -1;
  BatteryState _lastReportedState = BatteryState.unknown;
  
  // Singleton pattern
  static final BatteryMonitorService _instance = BatteryMonitorService._internal();
  
  factory BatteryMonitorService() {
    return _instance;
  }
  
  BatteryMonitorService._internal();
  
  Future<void> startMonitoring() async {
    await stopMonitoring();
    
    try {
      // Monitorer le niveau de batterie périodiquement
      _monitorTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
        await _checkAndReportBattery();
      });
      
      // Monitorer les changements d'état de batterie (chargement/déchargement)
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
        _checkAndReportBatteryState(state);
      });
      
      // Rapport initial
      await _checkAndReportBattery();
      
      debugPrint('Battery monitoring started');
    } catch (e) {
      debugPrint('Error starting battery monitoring: $e');
    }
  }
  
  Future<void> stopMonitoring() async {
    if (_monitorTimer != null) {
      _monitorTimer!.cancel();
      _monitorTimer = null;
    }
    
    if (_batteryStateSubscription != null) {
      await _batteryStateSubscription!.cancel();
      _batteryStateSubscription = null;
    }
    
    debugPrint('Battery monitoring stopped');
  }
  
  Future<void> _checkAndReportBattery() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      // Si le niveau a changé de plus de 5% ou si l'état a changé
      if (_shouldReportChange(batteryLevel, batteryState)) {
        _reportBatteryStatus(batteryLevel, batteryState);
      }
    } catch (e) {
      debugPrint('Error checking battery: $e');
    }
  }
  
  void _checkAndReportBatteryState(BatteryState state) async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      
      // Si l'état a changé, rapport immédiat
      if (state != _lastReportedState) {
        _reportBatteryStatus(batteryLevel, state);
      }
    } catch (e) {
      debugPrint('Error checking battery state: $e');
    }
  }
  
  bool _shouldReportChange(int level, BatteryState state) {
    // Rapport si:
    // - Premier rapport (-1 signifie que c'est le premier)
    // - Le niveau a changé de plus de 5%
    // - L'état de chargement a changé
    return _lastReportedLevel == -1 || 
           (level - _lastReportedLevel).abs() >= 5 || 
           state != _lastReportedState;
  }
  
  void _reportBatteryStatus(int level, BatteryState state) {
    _lastReportedLevel = level;
    _lastReportedState = state;
    
    final isCharging = state == BatteryState.charging || 
                      state == BatteryState.full;
    
    _webSocketService.sendStatusUpdate(
      batteryLevel: level,
      isCharging: isCharging,
    );
    
    debugPrint('Reported battery status: $level%, charging: $isCharging');
  }

  Future<int> getCurrentBatteryLevel() async {
  try {
    final level = await _battery.batteryLevel;
    return level;
  } catch (e) {
    debugPrint('Error getting battery level: $e');
    return 100; // Valeur par défaut sécurisée
  }
}
}