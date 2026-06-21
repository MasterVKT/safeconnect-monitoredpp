import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:monitored_app/app/constants.dart';
import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/config/app_config.dart';
import 'package:monitored_app/core/models/user.dart';
import 'package:monitored_app/core/services/data_collector_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/device_service.dart';
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/utils/device_utils.dart';
import 'package:monitored_app/features/auth/models/auth_models.dart';
import 'package:monitored_app/app/locator.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;
  DatabaseService? _databaseService;
  WebSocketService? _webSocketService;

  Timer? _tokenRefreshTimer;
  bool _isInitialized = false;

  AuthService(this._apiClient, this._storageService);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _databaseService = locator<DatabaseService>();
      _webSocketService = locator<WebSocketService>();

      // Start auto token refresh if authenticated
      if (await isAuthenticated()) {
        await _startTokenRefresh();

        // Connect WebSocket for real-time commands
        await _webSocketService!.connect();
      }

      _isInitialized = true;
      debugPrint('Auth service initialized');
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  // Pairing device with enhanced integration
  Future<AuthResult> pairDevice(PairingParams params) async {
    try {
      debugPrint('[PAIRING] Starting device pairing process...');

      // Add device information to pairing request
      final localDeviceIdentifier = await DeviceUtils.getDeviceIdentifier();
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      final enhancedParams = <String, dynamic>{
        // Support legacy + current backend payload naming conventions.
        'pairing_code': params.pairingCode,
        'pairingCode': params.pairingCode,
        'device_identifier': localDeviceIdentifier,
        'device_info': deviceInfo,
        'deviceInfo': deviceInfo,
      };

      // Backend expects UUID for device_id. Local Android identifiers like
      // "PPR1.180610.011" are not UUIDs and trigger backend validation errors.
      if (_isBackendUuid(localDeviceIdentifier)) {
        enhancedParams['device_id'] = localDeviceIdentifier;
      }

      debugPrint('[PAIRING] Calling validate-pairing-code endpoint...');
      final response = await validatePairingCodeRequestAsync(enhancedParams);
      debugPrint('[PAIRING] Received response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[PAIRING] Parsing auth response...');
        final authResponse = _parseAuthResponse(response.data);
        debugPrint('[PAIRING] Auth response parsed successfully');

        // Store tokens and user
        debugPrint('[PAIRING] Storing auth data...');
        await _storeAuthData(authResponse);
        await _storageService.write(
          AppConstants.deviceIdentifierKey,
          localDeviceIdentifier,
        );

        final pairedDeviceId = _extractServerDeviceId(response.data);
        if (pairedDeviceId != null) {
          debugPrint('[PAIRING] Storing paired device ID: $pairedDeviceId');
          await _storageService.write(AppConstants.deviceIdKey, pairedDeviceId);
        }

        // Initialize WebSocket connection.
        // Ne pas utiliser _webSocketService (null avant initialize()) —
        // utiliser directement le singleton du locator.
        debugPrint('[PAIRING] Connecting WebSocket...');
        try {
          await locator<WebSocketService>().connect();
        } catch (e) {
          debugPrint('[PAIRING] Warning: WebSocket connection failed: $e');
        }

        // Device service needs valid auth + server UUID mapping.
        // Run in background to not block pairing completion
        // The DeviceService will retry config loading in the background
        debugPrint('[PAIRING] Starting DeviceService in background...');
        try {
          // Don't await - run in background so pairing can complete
          locator<DeviceService>().initialize().then((_) {
            debugPrint(
                '[PAIRING] DeviceService background initialization completed');
          }).catchError((e) {
            debugPrint(
                '[PAIRING] DeviceService background initialization failed: $e');
          });
        } catch (e) {
          debugPrint(
              '[PAIRING] Warning: DeviceService initialization failed: $e');
        }

        // Start token refresh
        debugPrint('[PAIRING] Starting token refresh...');
        try {
          await _startTokenRefresh();
        } catch (e) {
          debugPrint('[PAIRING] Warning: Token refresh setup failed: $e');
        }

        // Log successful pairing - skip if database not initialized
        debugPrint('[PAIRING] Logging security event...');
        try {
          if (_isInitialized && _databaseService != null) {
            await _databaseService!.logSecurityEvent(
              eventType: 'DEVICE_PAIRED',
              description: 'Device successfully paired with monitoring system',
              severity: 'medium',
            );
          } else {
            debugPrint(
                '[PAIRING] Skipping security event log - not initialized');
          }
        } catch (e) {
          debugPrint('[PAIRING] Warning: Failed to log security event: $e');
        }

        debugPrint('[PAIRING] Pairing completed successfully!');

        // Étape 2 — Force-release any background isolate lease, then restart
        // collectors so main isolate can collect+sync immediately after pairing.
        // triggerFullSync() alone would be blocked if the background isolate
        // holds the collection lease (returns early with "Full sync skipped").
        debugPrint(
            '[PAIRING] Triggering initial full data sync with new auth tokens...');
        try {
          // Fire-and-forget: do not await so pairing flow is not blocked.
          // restartCollectorsAfterPermissionChange releases the background
          // isolate's lease, resets _isRunning, then starts collectors fresh.
          locator<DataCollectorService>().restartCollectorsAfterPermissionChange();
        } catch (e) {
          debugPrint(
              '[PAIRING] Warning: Failed to trigger initial full data sync: $e');
        }

        return AuthResult.success(authResponse.user);
      } else {
        debugPrint('[PAIRING] Failed with status: ${response.statusCode}');
        return AuthResult.error(
          message: response.data['detail'] ?? 'Failed to pair device',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[PAIRING] Error during pairing: $e');
      debugPrint('[PAIRING] Stack trace: $stackTrace');
      return _handleAuthError(e);
    }
  }

  /// Sends the pairing validation request to the single backend endpoint
  /// defined by the API contract.
  @visibleForTesting
  Future<Response<dynamic>> validatePairingCodeRequestAsync(
    Map<String, dynamic> payload,
  ) async {
    return _apiClient.post(
      AppConstants.validatePairingCodeEndpoint,
      data: payload,
      options: Options(
        extra: {
          // Pairing must work before the monitored app has valid auth tokens.
          'skipAuth': true,
          'skipAuthRefresh': true,
        },
      ),
    );
  }

  // Logout
  Future<void> signOut() async {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    // Étape 3 — Stop data collectors BEFORE clearing tokens so the in-flight
    // sync timer cannot fire one last time with a stale token and cause a 401.
    try {
      await locator<DataCollectorService>().stopCollectors();
      debugPrint('Data collectors stopped on sign out');
    } catch (e) {
      debugPrint('Warning: Failed to stop data collectors on sign out: $e');
    }

    await _storageService.delete(AppConstants.tokenKey);
    await _storageService.delete(AppConstants.refreshTokenKey);
    await _storageService.delete(AppConstants.userKey);
    await _storageService.delete(AppConstants.deviceIdKey);
    await _storageService.delete(AppConstants.deviceIdentifierKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.read(AppConstants.tokenKey);
    return token != null;
  }

  Future<bool> hasValidStoredSession() async {
    final token = await _storageService.read(AppConstants.tokenKey);
    if (token == null || token.isEmpty) {
      return false;
    }

    return !_isJwtExpired(token);
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final userJson = await _storageService.read(AppConstants.userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Get user info from server
  Future<AuthResult> fetchUserInfo() async {
    try {
      final response = await _apiClient.get('/users/me/');

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);

        // Update user info in storage
        await _storageService.write(
          AppConstants.userKey,
          jsonEncode(user.toJson()),
        );

        return AuthResult.success(user);
      } else {
        return AuthResult.error(
          message: response.data['detail'] ?? 'Failed to get user info',
        );
      }
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Token refresh functionality
  Future<void> _startTokenRefresh() async {
    _tokenRefreshTimer?.cancel();

    final accessToken = await _storageService.read(AppConstants.tokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final expiresAt = _getJwtExpiry(accessToken);
    if (expiresAt == null) {
      _tokenRefreshTimer = Timer(
        const Duration(minutes: 10),
        () => _refreshTokenIfNeeded(),
      );
      return;
    }

    final refreshAt = expiresAt.subtract(const Duration(minutes: 2));
    final delay = refreshAt.difference(DateTime.now());

    _tokenRefreshTimer = Timer(
      delay.isNegative ? const Duration(seconds: 30) : delay,
      () => _refreshTokenIfNeeded(),
    );
  }

  Future<void> _refreshTokenIfNeeded() async {
    try {
      final refreshToken =
          await _storageService.read(AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        return;
      }

      final response = await _apiClient.post(
        '/users/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access'];
        await _storageService.write(AppConstants.tokenKey, newToken);
        final newRefreshToken = response.data['refresh'];
        if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
          await _storageService.write(
            AppConstants.refreshTokenKey,
            newRefreshToken,
          );
        }
        await _startTokenRefresh();
        debugPrint('Token refreshed successfully');
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      // If refresh fails, user needs to re-authenticate
      await signOut();
    }
  }

  // Device registration with server
  Future<AuthResult> registerDevice() async {
    try {
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      final deviceId = await DeviceUtils.getDeviceIdentifier();

      final response = await _apiClient.post(
        '/devices/register/',
        data: {
          'device_id': deviceId,
          'device_info': deviceInfo,
          'platform': 'android',
          'app_version': deviceInfo['app_version'],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _databaseService?.logSecurityEvent(
          eventType: 'DEVICE_REGISTERED',
          description: 'Device registered with monitoring system',
          severity: 'medium',
        );

        return AuthResult.success(null);
      } else {
        return AuthResult.error(
          message: response.data['detail'] ?? 'Failed to register device',
        );
      }
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Helper methods

  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _storageService.write(AppConstants.tokenKey, authResponse.access);
    await _storageService.write(
        AppConstants.refreshTokenKey, authResponse.refresh);
    await _storageService.write(
      AppConstants.userKey,
      jsonEncode(authResponse.user.toJson()),
    );
  }

  AuthResponse _parseAuthResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid auth response format');
    }

    // FIX FRONTEND PAIRING SUCCESS ERROR:
    // Handle the case where backend returns {"success": true, "access": ..., "user": ...}
    // The pairing validation endpoint returns success=true but may NOT return refresh token
    if (data.containsKey('success') && data['success'] == true) {
      // Extract tokens from the success response
      final accessToken = data['access'] ?? data['access_token'];
      final refreshToken = data['refresh'] ?? data['refresh_token'];
      final userData = data['user'];

      if (accessToken != null && userData != null) {
        final normalized = <String, dynamic>{
          'access': accessToken,
          // If refresh token is not provided, use a placeholder or empty string
          // The app will need to re-authenticate or get a new refresh token later
          'refresh': refreshToken ?? '',
          'user': userData,
        };
        return AuthResponse.fromJson(normalized);
      }
    }

    // Standard response format: {"access": ..., "refresh": ..., "user": ...}
    if (data.containsKey('access') &&
        data.containsKey('refresh') &&
        data.containsKey('user')) {
      return AuthResponse.fromJson(data);
    }

    // Wrapped response format: {"data": {"tokens": {...}, "user": {...}}}
    final dataWrapper = data['data'];
    final tokens =
        (dataWrapper is Map<String, dynamic> ? dataWrapper['tokens'] : null) ??
            data['tokens'];
    final user =
        (dataWrapper is Map<String, dynamic> ? dataWrapper['user'] : null) ??
            data['user'];

    if (tokens is Map<String, dynamic> && user is Map<String, dynamic>) {
      final normalized = <String, dynamic>{
        'access': tokens['access'] ?? data['access'] ?? data['access_token'],
        'refresh':
            tokens['refresh'] ?? data['refresh'] ?? data['refresh_token'],
        'user': user,
      };
      return AuthResponse.fromJson(normalized);
    }

    throw const FormatException(
        'Missing required auth fields in pairing response');
  }

  String? _extractServerDeviceId(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    // FIX FRONTEND PAIRING SUCCESS ERROR: Handle success response with device_id
    // The backend returns device_id directly in the success response
    final directId = data['device_id'] ?? data['paired_device_id'];
    if (directId is String && directId.isNotEmpty) return directId;

    // Also check in monitored_device for the ID
    final monitoredDevice = data['monitored_device'];
    if (monitoredDevice is Map<String, dynamic>) {
      final id = monitoredDevice['id'];
      if (id is String && id.isNotEmpty) return id;
    }

    final device = data['device'];
    if (device is Map<String, dynamic>) {
      final id = device['id'];
      if (id is String && id.isNotEmpty) return id;
    }

    final wrappedData = data['data'];
    if (wrappedData is Map<String, dynamic>) {
      final wrappedDeviceId =
          wrappedData['device_id'] ?? wrappedData['paired_device_id'];
      if (wrappedDeviceId is String && wrappedDeviceId.isNotEmpty) {
        return wrappedDeviceId;
      }

      final wrappedDevice = wrappedData['device'];
      if (wrappedDevice is Map<String, dynamic>) {
        final id = wrappedDevice['id'];
        if (id is String && id.isNotEmpty) return id;
      }
    }

    return null;
  }

  bool _isBackendUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  DateTime? _getJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final exp = payload['exp'];
      if (exp is! int) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  bool _isJwtExpired(String token) {
    final expiresAt = _getJwtExpiry(token);
    if (expiresAt == null) {
      return false;
    }

    return !DateTime.now().isBefore(expiresAt);
  }

  AuthResult _handleAuthError(dynamic error) {
    if (error is Map<String, dynamic> && error.containsKey('detail')) {
      return AuthResult.error(message: error['detail']);
    }

    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('detail')) {
        return AuthResult.error(message: responseData['detail']);
      }

      if (error.response?.statusCode == 404) {
        return const AuthResult.error(
          message:
              'Endpoint de validation du jumelage introuvable (404). Verifiez le contrat API backend pour la validation du code.',
        );
      }

      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        final apiBaseUrl = AppConfig().apiBaseUrl.toLowerCase();
        final isLocalhostConfig = apiBaseUrl.contains('127.0.0.1') ||
            apiBaseUrl.contains('localhost');

        if (isLocalhostConfig) {
          return const AuthResult.error(
            message:
                'Connexion impossible au backend local. Configure API_BASE_URL avec l\'IP LAN de la machine backend (ex: http://192.168.x.x:8000).',
          );
        }

        return const AuthResult.error(
          message:
              'Connexion au serveur impossible. Verifiez le reseau et le backend.',
        );
      }

      if (error.message != null && error.message!.isNotEmpty) {
        return AuthResult.error(message: error.message!);
      }
    }

    return const AuthResult.error(message: 'An error occurred');
  }
}
