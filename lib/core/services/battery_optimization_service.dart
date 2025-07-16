import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('com.xpsafeconnect.monitored_app/battery');
  final ConnectivityService _connectivityService = locator<ConnectivityService>();
  
  // Modes d'optimisation
  static const String LOW = 'LOW';     // Minimum d'économie
  static const String MEDIUM = 'MEDIUM'; // Équilibre
  static const String HIGH = 'HIGH';   // Maximum d'économie
  
  late String _currentMode;
  final int _lowBatteryThreshold = 20; // Seuil de batterie faible (%)
  
  BatteryOptimizationService() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final config = AppConfig();
    _currentMode = await config.getBatteryOptimizationLevel();
  }
  
  // Ajuste les intervalles de collecte en fonction du mode d'optimisation
  int getLocationIntervalForMode(String mode, int batteryLevel) {
    if (batteryLevel <= _lowBatteryThreshold) {
      // En batterie faible, réduire la fréquence quelle que soit la configuration
      return 1800; // 30 minutes
    }
    
    switch (mode) {
      case LOW:
        return 300; // 5 minutes
      case MEDIUM:
        return 900; // 15 minutes
      case HIGH:
        return 1800; // 30 minutes
      default:
        return 900; // Par défaut 15 minutes
    }
  }
  
  // Ajuste la précision GPS en fonction du mode d'optimisation et du niveau de batterie
  String getLocationAccuracyForMode(String mode, int batteryLevel) {
    if (batteryLevel <= _lowBatteryThreshold) {
      return 'LOW_POWER';
    }
    
    switch (mode) {
      case LOW:
        return 'HIGH';
      case MEDIUM:
        return 'BALANCED';
      case HIGH:
        return 'LOW_POWER';
      default:
        return 'BALANCED';
    }
  }
  
  // Détermine si une tâche doit être exécutée en fonction du réseau et du niveau de batterie
  Future<bool> shouldRunTask(String taskType, int batteryLevel) async {
    // Vérifier la connectivité
    final networkStatus = await _connectivityService.checkConnectivity();
    final isWifiConnected = networkStatus == NetworkStatus.wifi;
    
    if (batteryLevel <= _lowBatteryThreshold) {
      // En batterie faible, exécuter uniquement les tâches critiques
      return taskType == 'CRITICAL';
    }
    
    switch (_currentMode) {
      case LOW:
        // Exécuter toutes les tâches normalement
        return true;
      case MEDIUM:
        // En mode équilibré, certaines tâches ne s'exécutent que sur WiFi
        if (taskType == 'MEDIA_SYNC' || taskType == 'HEAVY_SYNC') {
          return isWifiConnected;
        }
        return true;
      case HIGH:
        // En mode économie maximum, la plupart des tâches ne s'exécutent que sur WiFi
        if (taskType == 'LOCATION' || taskType == 'CRITICAL') {
          return true;
        }
        return isWifiConnected;
      default:
        return true;
    }
  }
  
  // Demande à l'appareil de désactiver l'optimisation de batterie pour l'application
  Future<bool> requestBatteryOptimizationDisable() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestDisableBatteryOptimization');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting battery optimization disable: $e');
      return false;
    }
  }
  
  // Vérifie si l'application est exclue de l'optimisation de batterie
  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization status: $e');
      return false;
    }
  }
}