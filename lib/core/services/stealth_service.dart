import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/app/locator.dart';

enum StealthMode {
  none, // Normal operation
  minimal, // Hide notifications only
  moderate, // Hide app icon and notifications
  full, // Full stealth with disguise
  invisible, // Maximum stealth - app appears completely hidden
}

enum DisguiseType {
  none,
  calculator,
  flashlight,
  weather,
  notes,
  calendar,
  gameApp,
  utilityApp,
  custom,
}

class StealthConfiguration {
  final StealthMode mode;
  final DisguiseType disguiseType;
  final String? customAppName;
  final String? customIcon;
  final bool hideFromRecents;
  final bool hideNotifications;
  final bool disableScreenshots;
  final bool enableIncognito;
  final Map<String, dynamic> customSettings;

  const StealthConfiguration({
    this.mode = StealthMode.none,
    this.disguiseType = DisguiseType.none,
    this.customAppName,
    this.customIcon,
    this.hideFromRecents = false,
    this.hideNotifications = false,
    this.disableScreenshots = false,
    this.enableIncognito = false,
    this.customSettings = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'disguiseType': disguiseType.name,
      'customAppName': customAppName,
      'customIcon': customIcon,
      'hideFromRecents': hideFromRecents,
      'hideNotifications': hideNotifications,
      'disableScreenshots': disableScreenshots,
      'enableIncognito': enableIncognito,
      'customSettings': customSettings,
    };
  }

  factory StealthConfiguration.fromJson(Map<String, dynamic> json) {
    return StealthConfiguration(
      mode: StealthMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => StealthMode.none,
      ),
      disguiseType: DisguiseType.values.firstWhere(
        (e) => e.name == json['disguiseType'],
        orElse: () => DisguiseType.none,
      ),
      customAppName: json['customAppName'],
      customIcon: json['customIcon'],
      hideFromRecents: json['hideFromRecents'] ?? false,
      hideNotifications: json['hideNotifications'] ?? false,
      disableScreenshots: json['disableScreenshots'] ?? false,
      enableIncognito: json['enableIncognito'] ?? false,
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }
}

class StealthService {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/stealth');

  final DatabaseService _databaseService = locator<DatabaseService>();
  // final NotificationService _notificationService = locator<NotificationService>();
  final StorageService _storageService = locator<StorageService>();

  StealthConfiguration _currentConfig = const StealthConfiguration();
  bool _isInitialized = false;
  Timer? _stealthModeTimer;

  // Stream controllers for UI updates
  final StreamController<StealthConfiguration> _configController =
      StreamController.broadcast();
  final StreamController<bool> _activeController = StreamController.broadcast();

  static final StealthService _instance = StealthService._internal();
  factory StealthService() => _instance;
  StealthService._internal();

  // Getters
  bool get isInitialized => _isInitialized;
  StealthConfiguration get currentConfig => _currentConfig;
  Stream<StealthConfiguration> get configStream => _configController.stream;
  Stream<bool> get activeStream => _activeController.stream;
  bool get isStealthActive => _currentConfig.mode != StealthMode.none;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing stealth service...');

      // Load saved configuration
      await _loadConfiguration();

      // Apply current configuration if not in normal mode
      if (_currentConfig.mode != StealthMode.none) {
        await _applyStealthConfiguration(_currentConfig, notify: false);
      }

      _isInitialized = true;
      debugPrint(
          'Stealth service initialized with mode: ${_currentConfig.mode.name}');

      // Log initialization
      await _logStealthEvent(
        'STEALTH_SERVICE_INIT',
        'Stealth service initialized with mode: ${_currentConfig.mode.name}',
        'medium',
      );
    } catch (e) {
      debugPrint('Error initializing stealth service: $e');
      await _logStealthEvent(
        'STEALTH_SERVICE_INIT_FAILED',
        'Failed to initialize stealth service: $e',
        'high',
      );
    }
  }

  Future<bool> activateStealthMode(StealthConfiguration config) async {
    try {
      debugPrint('Activating stealth mode: ${config.mode.name}');

      // Validate configuration
      if (!_validateConfiguration(config)) {
        debugPrint('Invalid stealth configuration');
        return false;
      }

      final success = await _applyStealthConfiguration(config);

      if (success) {
        _currentConfig = config;
        await _saveConfiguration();

        await _logStealthEvent(
          'STEALTH_MODE_ACTIVATED',
          'Stealth mode activated: ${config.mode.name}',
          'medium',
          metadata: config.toJson(),
        );

        _configController.add(_currentConfig);
        _activeController.add(true);
      }

      return success;
    } catch (e) {
      debugPrint('Error activating stealth mode: $e');
      await _logStealthEvent(
        'STEALTH_MODE_ACTIVATION_FAILED',
        'Failed to activate stealth mode: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> deactivateStealthMode() async {
    try {
      debugPrint('Deactivating stealth mode');

      final success =
          await _applyStealthConfiguration(const StealthConfiguration());

      if (success) {
        _currentConfig = const StealthConfiguration();
        await _saveConfiguration();

        await _logStealthEvent(
          'STEALTH_MODE_DEACTIVATED',
          'Stealth mode deactivated',
          'medium',
        );

        _configController.add(_currentConfig);
        _activeController.add(false);
      }

      return success;
    } catch (e) {
      debugPrint('Error deactivating stealth mode: $e');
      await _logStealthEvent(
        'STEALTH_MODE_DEACTIVATION_FAILED',
        'Failed to deactivate stealth mode: $e',
        'high',
      );
      return false;
    }
  }

  Future<bool> updateStealthConfiguration(StealthConfiguration config) async {
    if (_currentConfig.mode == StealthMode.none &&
        config.mode == StealthMode.none) {
      // Just save configuration without applying
      _currentConfig = config;
      await _saveConfiguration();
      _configController.add(_currentConfig);
      return true;
    }

    return await activateStealthMode(config);
  }

  Future<bool> enableQuickStealth({Duration? duration}) async {
    try {
      final quickConfig = StealthConfiguration(
        mode: StealthMode.moderate,
        disguiseType: DisguiseType.calculator,
        hideFromRecents: true,
        hideNotifications: true,
        disableScreenshots: true,
      );

      final success = await activateStealthMode(quickConfig);

      if (success && duration != null) {
        _stealthModeTimer?.cancel();
        _stealthModeTimer = Timer(duration, () async {
          await deactivateStealthMode();
        });
      }

      return success;
    } catch (e) {
      debugPrint('Error enabling quick stealth: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDisguiseOptions() async {
    return {
      'calculator': {
        'name': 'Calculator',
        'icon': 'calculator',
        'description': 'Appears as a simple calculator app',
        'features': ['Basic math operations', 'Standard calculator UI'],
      },
      'flashlight': {
        'name': 'Flashlight',
        'icon': 'flashlight_on',
        'description': 'Appears as a flashlight utility',
        'features': ['LED control', 'Screen light'],
      },
      'weather': {
        'name': 'Weather',
        'icon': 'wb_sunny',
        'description': 'Appears as a weather forecast app',
        'features': ['Current weather', 'Location-based forecasts'],
      },
      'notes': {
        'name': 'Notes',
        'icon': 'note',
        'description': 'Appears as a note-taking app',
        'features': ['Text notes', 'Simple editor'],
      },
      'calendar': {
        'name': 'Calendar',
        'icon': 'calendar_today',
        'description': 'Appears as a calendar app',
        'features': ['Date display', 'Event viewing'],
      },
      'gameApp': {
        'name': 'Game',
        'icon': 'games',
        'description': 'Appears as a simple game',
        'features': ['Mini-game', 'Entertainment facade'],
      },
    };
  }

  Future<Map<String, dynamic>> getStealthStatus() async {
    return {
      'active': isStealthActive,
      'mode': _currentConfig.mode.name,
      'disguiseType': _currentConfig.disguiseType.name,
      'customAppName': _currentConfig.customAppName,
      'hideFromRecents': _currentConfig.hideFromRecents,
      'hideNotifications': _currentConfig.hideNotifications,
      'disableScreenshots': _currentConfig.disableScreenshots,
      'enableIncognito': _currentConfig.enableIncognito,
      'initialized': _isInitialized,
    };
  }

  Future<Map<String, dynamic>?> getCurrentUIConfig() async {
    try {
      // Return UI configuration based on current stealth settings
      return {
        'mode': _currentConfig.mode.name,
        'disguiseType': _currentConfig.disguiseType.name,
        'secret_access_pattern':
            _currentConfig.customSettings['secret_access_pattern'] ?? '1337',
        'customAppName': _currentConfig.customAppName,
        'customIcon': _currentConfig.customIcon,
        'hideFromRecents': _currentConfig.hideFromRecents,
        'hideNotifications': _currentConfig.hideNotifications,
        'disableScreenshots': _currentConfig.disableScreenshots,
        'enableIncognito': _currentConfig.enableIncognito,
        ..._currentConfig.customSettings,
      };
    } catch (e) {
      debugPrint('Error getting current UI config: $e');
      return null;
    }
  }

  // Private methods

  Future<bool> _applyStealthConfiguration(StealthConfiguration config,
      {bool notify = true}) async {
    try {
      final Map<String, dynamic> nativeConfig = {
        'mode': config.mode.name,
        'disguiseType': config.disguiseType.name,
        'customAppName': config.customAppName,
        'customIcon': config.customIcon,
        'hideFromRecents': config.hideFromRecents,
        'hideNotifications': config.hideNotifications,
        'disableScreenshots': config.disableScreenshots,
        'enableIncognito': config.enableIncognito,
      };

      // Apply native configuration
      bool nativeSuccess = false;
      try {
        nativeSuccess = await _channel.invokeMethod<bool>(
                'applyStealthConfig', nativeConfig) ??
            false;
      } catch (e) {
        debugPrint(
            'Native stealth configuration failed, continuing with Dart-only: $e');
        nativeSuccess = true; // Continue with Dart-only implementation
      }

      // Apply Dart-side configurations
      await _applyNotificationSettings(config);
      await _applyUISettings(config);

      return nativeSuccess;
    } catch (e) {
      debugPrint('Error applying stealth configuration: $e');
      return false;
    }
  }

  Future<void> _applyNotificationSettings(StealthConfiguration config) async {
    try {
      if (config.hideNotifications) {
        // Minimize notification visibility
        await _storageService.write('stealth_notifications_hidden', 'true');
      } else {
        await _storageService.delete('stealth_notifications_hidden');
      }
    } catch (e) {
      debugPrint('Error applying notification settings: $e');
    }
  }

  Future<void> _applyUISettings(StealthConfiguration config) async {
    try {
      // Store UI stealth settings for the app to use
      await _storageService.write('stealth_ui_mode', config.mode.name);
      await _storageService.write(
          'stealth_disguise_type', config.disguiseType.name);

      if (config.customAppName != null) {
        await _storageService.write(
            'stealth_custom_name', config.customAppName!);
      } else {
        await _storageService.delete('stealth_custom_name');
      }
    } catch (e) {
      debugPrint('Error applying UI settings: $e');
    }
  }

  bool _validateConfiguration(StealthConfiguration config) {
    // Basic validation
    if (config.disguiseType == DisguiseType.custom &&
        (config.customAppName == null || config.customAppName!.isEmpty)) {
      return false;
    }

    return true;
  }

  Future<void> _loadConfiguration() async {
    try {
      final configData =
          await _databaseService.getConfiguration('stealth_configuration');

      if (configData != null) {
        final configMap = jsonDecode(configData) as Map<String, dynamic>;
        _currentConfig = StealthConfiguration.fromJson(configMap);
        debugPrint('Loaded stealth configuration: ${_currentConfig.mode.name}');
      } else {
        debugPrint('No saved stealth configuration found');
      }
    } catch (e) {
      debugPrint('Error loading stealth configuration: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      final configData = jsonEncode(_currentConfig.toJson());
      await _databaseService.setConfiguration(
          'stealth_configuration', configData);
      debugPrint('Stealth configuration saved');
    } catch (e) {
      debugPrint('Error saving stealth configuration: $e');
    }
  }

  Future<void> _logStealthEvent(
    String eventType,
    String description,
    String severity, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _databaseService.logSecurityEvent(
        eventType: eventType,
        description: description,
        severity: severity,
        metadata: metadata?.toString(),
      );
    } catch (e) {
      debugPrint('Error logging stealth event: $e');
    }
  }

  // Public utility methods

  Future<String> getDisguiseAppName() async {
    if (_currentConfig.disguiseType == DisguiseType.custom &&
        _currentConfig.customAppName != null) {
      return _currentConfig.customAppName!;
    }

    return _getDefaultDisguiseAppName(_currentConfig.disguiseType);
  }

  String _getDefaultDisguiseAppName(DisguiseType type) {
    switch (type) {
      case DisguiseType.calculator:
        return 'Calculator';
      case DisguiseType.flashlight:
        return 'Flashlight';
      case DisguiseType.weather:
        return 'Weather';
      case DisguiseType.notes:
        return 'Notes';
      case DisguiseType.calendar:
        return 'Calendar';
      case DisguiseType.gameApp:
        return 'Puzzle Game';
      case DisguiseType.utilityApp:
        return 'Quick Tools';
      case DisguiseType.custom:
      case DisguiseType.none:
        return 'XP SafeConnect';
    }
  }

  Future<String> getDisguiseIcon() async {
    if (_currentConfig.disguiseType == DisguiseType.custom &&
        _currentConfig.customIcon != null) {
      return _currentConfig.customIcon!;
    }

    return _getDefaultDisguiseIcon(_currentConfig.disguiseType);
  }

  String _getDefaultDisguiseIcon(DisguiseType type) {
    switch (type) {
      case DisguiseType.calculator:
        return 'calculator';
      case DisguiseType.flashlight:
        return 'flashlight_on';
      case DisguiseType.weather:
        return 'wb_sunny';
      case DisguiseType.notes:
        return 'note';
      case DisguiseType.calendar:
        return 'calendar_today';
      case DisguiseType.gameApp:
        return 'games';
      case DisguiseType.utilityApp:
        return 'build';
      case DisguiseType.custom:
      case DisguiseType.none:
        return 'security';
    }
  }

  bool shouldHideFromRecents() {
    return _currentConfig.hideFromRecents;
  }

  bool shouldHideNotifications() {
    return _currentConfig.hideNotifications;
  }

  bool shouldDisableScreenshots() {
    return _currentConfig.disableScreenshots;
  }

  bool isIncognitoEnabled() {
    return _currentConfig.enableIncognito;
  }

  // Emergency stealth disable (for debugging or emergencies)
  Future<void> emergencyDisableStealth() async {
    try {
      debugPrint('Emergency stealth disable triggered');

      _stealthModeTimer?.cancel();
      _currentConfig = const StealthConfiguration();

      await _saveConfiguration();
      await _applyStealthConfiguration(_currentConfig);

      await _logStealthEvent(
        'EMERGENCY_STEALTH_DISABLE',
        'Emergency stealth disable activated',
        'high',
      );

      _configController.add(_currentConfig);
      _activeController.add(false);
    } catch (e) {
      debugPrint('Error in emergency stealth disable: $e');
    }
  }

  Future<void> dispose() async {
    _stealthModeTimer?.cancel();
    await _configController.close();
    await _activeController.close();
    _isInitialized = false;
  }
}
