import 'package:flutter/foundation.dart';

class ProductionConfig {
  // Build configuration
  static const bool isProduction = kReleaseMode;
  static const bool enableDebugLogs = !kReleaseMode;
  static const bool enablePerformanceOverlay = false;
  static const bool enableNetworkLogging = !kReleaseMode;
  
  // Security configuration
  static const bool enableCodeObfuscation = true;
  static const bool enableMinification = true;
  static const bool stripDebugInfo = true;
  static const bool enableTreeShaking = true;
  
  // API configuration
  static const String baseApiUrl = kReleaseMode 
      ? 'https://api.xpsafeconnect.com'
      : 'https://dev-api.xpsafeconnect.com';
  
  static const String websocketUrl = kReleaseMode
      ? 'wss://ws.xpsafeconnect.com'
      : 'wss://dev-ws.xpsafeconnect.com';
  
  // Analytics and monitoring
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;
  static const bool enablePerformanceMonitoring = true;
  
  // Feature flags
  static const bool enableP2PCommunication = true;
  static const bool enableStealthMode = true;
  static const bool enableEmergencyMode = true;
  static const bool enableAdvancedSecurity = true;
  
  // Build metadata
  static const String buildVariant = kReleaseMode ? 'production' : 'development';
  static const String buildType = kReleaseMode ? 'release' : 'debug';
  
  // Security keys (these would be injected during build)
  static const String? encryptionKey = String.fromEnvironment('ENCRYPTION_KEY');
  static const String? signingKey = String.fromEnvironment('SIGNING_KEY');
  static const String? apiKey = String.fromEnvironment('API_KEY');
  
  // Obfuscation settings
  static const bool obfuscateClassNames = kReleaseMode;
  static const bool obfuscateMethodNames = kReleaseMode;
  static const bool obfuscateFieldNames = kReleaseMode;
  static const bool removeAssertions = kReleaseMode;
  
  // Performance settings
  static const int maxCacheSize = kReleaseMode ? 100 * 1024 * 1024 : 50 * 1024 * 1024; // 100MB prod, 50MB dev
  static const int maxLogFiles = kReleaseMode ? 5 : 10;
  static const Duration logRetentionPeriod = kReleaseMode 
      ? Duration(days: 7) 
      : Duration(days: 30);
  
  // Network settings
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 60;
  static const int sendTimeoutSeconds = 60;
  static const int maxRetryAttempts = 3;
  
  // Validation methods
  static bool get isValidConfiguration {
    if (kReleaseMode) {
      return encryptionKey != null && 
             encryptionKey!.isNotEmpty &&
             signingKey != null && 
             signingKey!.isNotEmpty &&
             apiKey != null && 
             apiKey!.isNotEmpty;
    }
    return true; // Development builds don't require all keys
  }
  
  static Map<String, dynamic> get buildInfo => {
    'is_production': isProduction,
    'build_variant': buildVariant,
    'build_type': buildType,
    'enable_debug_logs': enableDebugLogs,
    'enable_obfuscation': enableCodeObfuscation,
    'base_api_url': baseApiUrl,
    'websocket_url': websocketUrl,
    'features': {
      'p2p_communication': enableP2PCommunication,
      'stealth_mode': enableStealthMode,
      'emergency_mode': enableEmergencyMode,
      'advanced_security': enableAdvancedSecurity,
    },
    'performance': {
      'max_cache_size': maxCacheSize,
      'max_log_files': maxLogFiles,
      'log_retention_days': logRetentionPeriod.inDays,
    },
    'network': {
      'connect_timeout': connectTimeoutSeconds,
      'receive_timeout': receiveTimeoutSeconds,
      'send_timeout': sendTimeoutSeconds,
      'max_retry_attempts': maxRetryAttempts,
    },
  };
}