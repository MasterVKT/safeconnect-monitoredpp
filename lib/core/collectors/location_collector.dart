import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/battery_optimization_service.dart';

class LocationCollector {
  final DataCollectorService _dataCollectorService = locator<DataCollectorService>();
  final StorageService _storageService = locator<StorageService>();

  final BatteryMonitorService _batteryMonitorService = locator<BatteryMonitorService>();
  final BatteryOptimizationService _batteryOptimizationService = locator<BatteryOptimizationService>();
  
  bool _isCollecting = false;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  int _locationIntervalSeconds = 900; // Default: 15 minutes
  
  Future<void> initialize() async {
  try {
    // Load settings from storage
    final intervalSeconds = _storageService.getInt('location_interval_seconds');
    if (intervalSeconds != null && intervalSeconds > 0) {
      _locationIntervalSeconds = intervalSeconds;
    } else {
      // Charger les paramètres d'optimisation de batterie
      final config = AppConfig();
      final batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
      final optimizationLevel = await config.getBatteryOptimizationLevel();
      
      // Ajuster l'intervalle en fonction du niveau de batterie et du mode d'optimisation
      _locationIntervalSeconds = _batteryOptimizationService.getLocationIntervalForMode(
        optimizationLevel,
        batteryLevel,
      );
    }

    // Vérifier les permissions
    final status = await _checkPermissions();
    if (status != LocationPermission.always && status != LocationPermission.whileInUse) {
      debugPrint('Location permissions not granted: $status');
    }
  } catch (e) {
    debugPrint('Error initializing location collector: $e');
  }
}


// Nouvelle méthode pour ajuster la fréquence en fonction du niveau de batterie
  Future<void> adjustFrequencyBasedOnBattery() async {
    final config = AppConfig();
    final batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
    final optimizationLevel = await config.getBatteryOptimizationLevel();
    
    final newInterval = _batteryOptimizationService.getLocationIntervalForMode(
      optimizationLevel, 
      batteryLevel
    );
    
    // Si l'intervalle a changé, mettre à jour
    if (newInterval != _locationIntervalSeconds) {
      await updateLocationInterval(newInterval);
    }
  }
  
  Future<LocationPermission> _checkPermissions() async {
    return await Geolocator.checkPermission();
  }
  
  Future<bool> _requestPermissions() async {
    try {
      final status = await Geolocator.requestPermission();
      return status == LocationPermission.always || 
             status == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error requesting location permissions: $e');
      return false;
    }
  }
  
  Future<void> startCollecting() async {
    if (_isCollecting) return;
    
    try {
      // Check permissions first
      LocationPermission permission = await _checkPermissions();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }
      
      // Start periodic location updates
      _locationTimer = Timer.periodic(
        Duration(seconds: _locationIntervalSeconds), 
        (_) => _getAndProcessLocation()
      );
      
      // Get initial location
      _getAndProcessLocation();
      
      // Start location change stream for significant changes
      _startLocationChangeStream();
      
      _isCollecting = true;
      debugPrint('Location collector started with interval: $_locationIntervalSeconds seconds');
    } catch (e) {
      debugPrint('Error starting location collector: $e');
    }
  }
  
  void _startLocationChangeStream() {
    // Start position stream only for significant changes (300m)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 300, // 300 meters
      ),
    ).listen((Position position) {
      _processLocation(position);
    }, onError: (error) {
      debugPrint('Error from position stream: $error');
    });
  }
  
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    try {
      // Stop periodic timer
      _locationTimer?.cancel();
      _locationTimer = null;
      
      // Stop position stream
      await _positionStream?.cancel();
      _positionStream = null;
      
      _isCollecting = false;
      debugPrint('Location collector stopped');
    } catch (e) {
      debugPrint('Error stopping location collector: $e');
    }
  }
  
  Future<void> _getAndProcessLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _processLocation(position);
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }
  
  Future<void> _processLocation(Position position) async {
    try {
      // Convert to proper format for sync
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      
      final processedLocation = {
        'device_id': deviceId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'recorded_at': DateTime.now().toIso8601String(),
        'provider': 'gps',
      };
      
      // Queue for sync
      _dataCollectorService.queueForSync('location', [processedLocation]);
      
      debugPrint('Processed new location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error processing location: $e');
    }
  }
  
  // Update collection interval
  Future<void> updateLocationInterval(int seconds) async {
    if (seconds < 60) seconds = 60; // Minimum 1 minute
    if (seconds > 3600) seconds = 3600; // Maximum 1 hour
    
    _locationIntervalSeconds = seconds;
    await _storageService.setInt('location_interval_seconds', seconds);
    
    // Restart collection if currently active
    if (_isCollecting) {
      await stopCollecting();
      await startCollecting();
    }
    
    debugPrint('Location interval updated to $seconds seconds');
  }
}