import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monitored_app/app/constants.dart';

class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Attributs de configuration
  bool _initialized = false;
  String _environment = 'dev';
  String _apiBaseUrl = AppConstants.apiV1;
  bool _analyticsEnabled = false;
  String _displayMode = 'NORMAL'; // NORMAL, DISCRETE, HIDDEN
  String _notificationMode = 'VISIBLE'; // VISIBLE, MINIMIZED, HIDDEN
  bool _autoStartEnabled = true;

  // Getters
  bool get isInitialized => _initialized;
  String get environment => _environment;
  String get apiBaseUrl => _apiBaseUrl;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get isDebug => _environment == 'dev';
  bool get isProduction => _environment == 'prod';
  String get displayMode => _displayMode;
  String get notificationMode => _notificationMode;
  bool get autoStartEnabled => _autoStartEnabled;

  /// Initialise la configuration
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Charger les préférences
      final prefs = await SharedPreferences.getInstance();

      // Charger la configuration depuis les préférences
      _environment =
          prefs.getString('environment') ?? (kReleaseMode ? 'prod' : 'dev');

      // Définir l'URL de base selon l'environnement
      if (_environment == 'dev') {
        _apiBaseUrl = '${AppConstants.baseUrl}/api/v1';
      } else if (_environment == 'staging') {
        _apiBaseUrl = 'https://staging-api.safeconnect.com/api/v1';
      } else {
        _apiBaseUrl = AppConstants.apiV1;
      }

      // Paramètres d'analyse
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? !kDebugMode;

      // Paramètres d'affichage
      _displayMode = prefs.getString('display_mode') ?? 'NORMAL';
      _notificationMode = prefs.getString('notification_mode') ?? 'VISIBLE';
      _autoStartEnabled = prefs.getBool('auto_start_enabled') ?? true;

      _initialized = true;

      debugPrint(
          'AppConfig initialized: env=$_environment, api=$_apiBaseUrl, displayMode=$_displayMode');
    } catch (e) {
      debugPrint('Error initializing AppConfig: $e');
      // Charger les valeurs par défaut en cas d'erreur
      _environment = kReleaseMode ? 'prod' : 'dev';
      _apiBaseUrl = AppConstants.apiV1;
      _analyticsEnabled = !kDebugMode;
      _displayMode = 'NORMAL';
      _notificationMode = 'VISIBLE';
      _autoStartEnabled = true;
      _initialized = true;
    }
  }

  /// Change le mode d'affichage (NORMAL, DISCRETE, HIDDEN)
  Future<void> setDisplayMode(String mode) async {
    if (mode != 'NORMAL' && mode != 'DISCRETE' && mode != 'HIDDEN') {
      throw ArgumentError(
          'Display mode must be one of: NORMAL, DISCRETE, HIDDEN');
    }

    _displayMode = mode;

    // Sauvegarder dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_mode', mode);

    debugPrint('Display mode changed to $mode');
  }

  /// Change le mode de notification (VISIBLE, MINIMIZED, HIDDEN)
  Future<void> setNotificationMode(String mode) async {
    if (mode != 'VISIBLE' && mode != 'MINIMIZED' && mode != 'HIDDEN') {
      throw ArgumentError(
          'Notification mode must be one of: VISIBLE, MINIMIZED, HIDDEN');
    }

    _notificationMode = mode;

    // Sauvegarder dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_mode', mode);

    debugPrint('Notification mode changed to $mode');
  }

  /// Active ou désactive le démarrage automatique
  Future<void> setAutoStartEnabled(bool enabled) async {
    _autoStartEnabled = enabled;

    // Sauvegarder dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_enabled', enabled);

    debugPrint('Auto start ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Sauvegarde les configurations initiales après la fin du setup
  Future<void> saveInitialConfig(String displayMode, String notificationMode,
      bool autoStartEnabled) async {
    await setDisplayMode(displayMode);
    await setNotificationMode(notificationMode);
    await setAutoStartEnabled(autoStartEnabled);

    // Marquer l'application comme configurée
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_configured', true);

    debugPrint('Initial configuration saved');
  }

  /// Vérifie si l'application a déjà été configurée
  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_configured') ?? false;
  }

  /// Vérifie si le démarrage automatique est activé
  Future<bool> isAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_start_enabled') ?? true;
  }

  /// Réinitialise la configuration aux valeurs par défaut
  Future<void> resetToDefaults() async {
    _environment = kReleaseMode ? 'prod' : 'dev';
    _apiBaseUrl = AppConstants.apiV1;
    _analyticsEnabled = !kDebugMode;
    _displayMode = 'NORMAL';
    _notificationMode = 'VISIBLE';
    _autoStartEnabled = true;

    // Sauvegarder dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('environment');
    await prefs.remove('analytics_enabled');
    await prefs.remove('display_mode');
    await prefs.remove('notification_mode');
    await prefs.remove('auto_start_enabled');
    await prefs.remove('is_configured');

    debugPrint('AppConfig reset to defaults');
  }

  // Gestion du niveau d'optimisation de batterie
  Future<String> getBatteryOptimizationLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('battery_optimization_level') ?? 'MEDIUM';
  }

  Future<void> setBatteryOptimizationLevel(String level) async {
    if (level != 'LOW' && level != 'MEDIUM' && level != 'HIGH') {
      throw ArgumentError('Battery optimization level must be one of: LOW, MEDIUM, HIGH');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('battery_optimization_level', level);
    
    debugPrint('Battery optimization level set to $level');
  }

}
