import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/battery_optimization_service.dart';
import 'package:monitored_app/core/collectors/base_collector.dart';

class LocationCollector extends BaseCollector {
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  int _locationIntervalSeconds = 900; // Default: 15 minutes
  bool _locationServiceDisabledLogged = false;

  // Service references
  final StorageService _storageService = locator<StorageService>();
  final DatabaseService _databaseService = locator<DatabaseService>();
  final BatteryMonitorService _batteryMonitorService =
      locator<BatteryMonitorService>();
  final BatteryOptimizationService _batteryOptimizationService =
      locator<BatteryOptimizationService>();

  @override
  String get collectorName => 'Location';

  @override
  String get dataType => 'location';

  @override
  List<Permission> get requiredPermissions =>
      [Permission.locationAlways, Permission.locationWhenInUse];

  @override
  Future<void> initializeSpecific() async {
    try {
      // Load settings from storage
      final intervalSeconds =
          _storageService.getInt('location_interval_seconds');
      if (intervalSeconds != null && intervalSeconds > 0) {
        _locationIntervalSeconds = intervalSeconds;
      } else {
        // Load battery optimization settings
        final config = AppConfig();
        final batteryLevel =
            await _batteryMonitorService.getCurrentBatteryLevel();
        final optimizationLevel = await config.getBatteryOptimizationLevel();

        // Adjust interval based on battery level and optimization mode
        final batteryOptimizationService =
            locator<BatteryOptimizationService>();
        _locationIntervalSeconds =
            batteryOptimizationService.getLocationIntervalForMode(
          optimizationLevel,
          batteryLevel,
        );
      }
    } catch (e) {
      debugPrint('Error initializing location collector specific: $e');
    }
  }

  // Nouvelle méthode pour ajuster la fréquence en fonction du niveau de batterie
  Future<void> adjustFrequencyBasedOnBattery() async {
    final config = AppConfig();
    final batteryLevel = await _batteryMonitorService.getCurrentBatteryLevel();
    final optimizationLevel = await config.getBatteryOptimizationLevel();

    final newInterval = _batteryOptimizationService.getLocationIntervalForMode(
        optimizationLevel, batteryLevel);

    // Si l'intervalle a changé, mettre à jour
    if (newInterval != _locationIntervalSeconds) {
      await updateCollectionInterval(newInterval);
    }
  }

  @override
  Future<bool> checkSpecificPermissions() async {
    try {
      final status = await Geolocator.checkPermission();
      return status == LocationPermission.always ||
          status == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
      return false;
    }
  }

  @override
  Future<void> requestSpecificPermissions() async {
    try {
      await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Error requesting location permissions: $e');
    }
  }

  @override
  Future<void> startSpecificCollection() async {
    try {
      // Start periodic location updates
      _locationTimer = Timer.periodic(
          Duration(seconds: _locationIntervalSeconds),
          (_) => _getAndProcessLocation());

      // Get initial location
      _getAndProcessLocation();

      // Start location change stream for significant changes
      _startLocationChangeStream();

      debugPrint(
          'Location specific collection started with interval: $_locationIntervalSeconds seconds');
    } catch (e) {
      debugPrint('Error starting location specific collection: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> collectData() async {
    try {
      if (!await _isLocationServiceAvailable()) {
        return [];
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationData = await _convertLocationData(position);
      return locationData != null ? [locationData] : [];
    } catch (e) {
      debugPrint('Error collecting location data: $e');
      return [];
    }
  }

  void _startLocationChangeStream() {
    if (_positionStream != null) return;

    // Start position stream only for significant changes (300m)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 300, // 300 meters
      ),
    ).listen((Position position) async {
      final locationData = await _convertLocationData(position);
      if (locationData != null) {
        await processData([locationData]);
      }
    }, onError: (error) {
      _handlePositionStreamError(error);
    });
  }

  @override
  Future<void> stopSpecificCollection() async {
    try {
      // Stop periodic timer
      _locationTimer?.cancel();
      _locationTimer = null;

      // Stop position stream
      await _positionStream?.cancel();
      _positionStream = null;

      debugPrint('Location specific collection stopped');
    } catch (e) {
      debugPrint('Error stopping location specific collection: $e');
    }
  }

  Future<void> _getAndProcessLocation() async {
    try {
      final serviceAvailable = await _isLocationServiceAvailable();
      if (!serviceAvailable) {
        await _positionStream?.cancel();
        _positionStream = null;
        return;
      }

      _startLocationChangeStream();

      // Use the collectData method for consistency
      final locationData = await collectData();
      if (locationData.isNotEmpty) {
        await processData(locationData);
      }
    } catch (e) {
      debugPrint('Error getting and processing location: $e');
    }
  }

  Future<Map<String, dynamic>?> _convertLocationData(Position position) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final recordedAt = DateTime.now();

      // Store in database using database service
      await _databaseService.insertLocationData(
        deviceId: deviceId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        recordedAt: recordedAt,
        provider: 'gps',
      );

      // Return processed location data for sync
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'provider': 'gps',
        'activity_type': 'UNKNOWN',
      };
    } catch (e) {
      debugPrint('Error converting location data: $e');
      return null;
    }
  }

  Future<bool> _isLocationServiceAvailable() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      if (_locationServiceDisabledLogged) {
        debugPrint('[LOCATION] System location services re-enabled.');
      }
      _locationServiceDisabledLogged = false;
      return true;
    }

    if (!_locationServiceDisabledLogged) {
      _locationServiceDisabledLogged = true;
      debugPrint(
          '[LOCATION] System location services disabled. Collection paused until re-enabled.');
    }
    return false;
  }

  void _handlePositionStreamError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('location service') &&
        message.toLowerCase().contains('disabled')) {
      if (!_locationServiceDisabledLogged) {
        _locationServiceDisabledLogged = true;
        debugPrint(
            '[LOCATION] System location services disabled. Position stream paused.');
      }
      _positionStream?.cancel();
      _positionStream = null;
      return;
    }

    debugPrint('Error from position stream: $error');
  }

  // Update collection interval
  @override
  Future<void> updateCollectionInterval(int seconds) async {
    if (seconds < 60) seconds = 60; // Minimum 1 minute
    if (seconds > 3600) seconds = 3600; // Maximum 1 hour

    _locationIntervalSeconds = seconds;
    await _storageService.setInt('location_interval_seconds', seconds);

    // Restart collection if currently active
    if (isCollecting) {
      await stopSpecificCollection();
      await startSpecificCollection();
    }

    debugPrint('Location interval updated to $seconds seconds');
  }

  // Backward compatibility method
  Future<void> updateLocationInterval(int seconds) async {
    await updateCollectionInterval(seconds);
  }

  // Emergency-specific location collection methods
  Future<void> collectLocationData(
      {int priority = 2, bool emergency = false}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final locationData = await _convertEmergencyLocationData(position,
          emergency: emergency, priority: priority);
      if (locationData != null) {
        await processData([locationData]);
      }

      debugPrint('Emergency location data collected with priority $priority');
    } catch (e) {
      debugPrint('Error collecting emergency location data: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp.toUtc().toIso8601String(),
        'provider': 'gps',
      };
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _convertEmergencyLocationData(Position position,
      {bool emergency = false, int priority = 2}) async {
    try {
      final deviceId = await DeviceUtils.getDeviceIdentifier();
      final batteryLevel =
          await _batteryMonitorService.getCurrentBatteryLevel();
      final recordedAt = DateTime.now();

      // Store in database with emergency flag
      await _databaseService.insertLocationData(
        deviceId: deviceId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        bearing: position.heading,
        provider: emergency ? 'emergency_gps' : 'gps',
        batteryLevel: batteryLevel,
        recordedAt: recordedAt,
      );

      // If emergency, queue with high priority
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'provider': emergency ? 'emergency_gps' : 'gps',
        'battery_level': batteryLevel,
        'emergency': emergency,
        'priority': priority,
      };

      if (emergency) {
        await _databaseService
            .queueDataForSync('emergency_location', locationData, priority: 1);
      }

      return locationData;
    } catch (e) {
      debugPrint('Error converting emergency location data: $e');
      return null;
    }
  }
}
