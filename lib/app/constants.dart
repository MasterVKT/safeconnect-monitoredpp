class AppConstants {
  // API URLs
  // Override in development with:
  // flutter run --dart-define=API_BASE_URL=http://<LAN_IP_DE_TA_MACHINE>:8000
  static const String devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String stagingBaseUrl = 'https://staging-api.safeconnect.com';
  static const String prodBaseUrl = 'https://api.xpsafeconnect.com';
  static const String baseUrl = devBaseUrl;
  static const String apiV1 = '$devBaseUrl/api/v1';
  static const String validatePairingCodeEndpoint =
      '/devices/validate-pairing-code/';
  // FIX: WebSocket URL must match the backend server
  // In dev: use devBaseUrl with ws:// or wss://
  // In prod: use wss://api.safeconnect.com
  static String get wsBaseUrl {
    // In development/debug mode, use the same host as the REST API
    if (devBaseUrl.startsWith('http://')) {
      return devBaseUrl.replaceFirst('http://', 'ws://');
    } else if (devBaseUrl.startsWith('https://')) {
      return devBaseUrl.replaceFirst('https://', 'wss://');
    }
    // Fallback for production
    return 'wss://api.safeconnect.com';
  }

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String deviceIdentifierKey = 'device_identifier';
  static const String languageKey = 'app_language';

  // Timeouts
  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 60000; // 60 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Retry
  static const int maxRetries = 3;
  static const int reconnectDelay = 5000; // 5 seconds

  // Service
  static const int statusUpdateInterval = 300000; // 5 minutes
  static const int batteryUpdateThreshold = 5; // 5%

  // App Info
  static const String appName = 'XP SafeConnect';
  static const String appVersion = '1.0.0';
  static const String contactEmail = 'support@xpsafeconnect.com';
}
