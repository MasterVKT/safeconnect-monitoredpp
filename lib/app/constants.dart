class AppConstants {
  // API URLs
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String apiV1 = '$baseUrl/api/v1';
  static const String wsBaseUrl = 'wss://api.safeconnect.com';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String deviceIdentifierKey = 'device_identifier';
  static const String languageKey = 'app_language';
  
  // Timeouts
  static const int connectTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds
  static const int sendTimeout = 15000;    // 15 seconds
  
  // Retry
  static const int maxRetries = 3;
  static const int reconnectDelay = 5000;  // 5 seconds
  
  // Service
  static const int statusUpdateInterval = 300000; // 5 minutes
  static const int batteryUpdateThreshold = 5;    // 5%
  
  // App Info
  static const String appName = 'XP SafeConnect';
  static const String appVersion = '1.0.0';
  static const String contactEmail = 'support@xpsafeconnect.com';
}