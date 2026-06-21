import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/core/utils/media_permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionCategory { essential, monitoring, media, system }

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  provisional,
  limited
}

class PermissionInfo {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String explanationKey;
  final PermissionCategory category;
  final bool isRequired;
  final String? icon;
  final Permission? standardPermission;
  final String? customPermissionKey;
  final String? settingsPath;
  AppPermissionStatus status;

  PermissionInfo({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.explanationKey,
    required this.category,
    required this.isRequired,
    this.icon,
    this.standardPermission,
    this.customPermissionKey,
    this.settingsPath,
    this.status = AppPermissionStatus.denied,
  });
}

class PermissionManagerService {
  static const MethodChannel _channel =
      MethodChannel('monitored_app/permissions');

  static final List<PermissionInfo> _allPermissions = [
    // Essential permissions
    PermissionInfo(
      id: 'location',
      titleKey: 'locationPermission',
      descriptionKey: 'locationPermissionDescription',
      explanationKey: 'locationPermissionExplanation',
      category: PermissionCategory.essential,
      isRequired: true,
      icon: 'location_on',
      standardPermission: Permission.location,
    ),

    PermissionInfo(
      id: 'locationAlways',
      titleKey: 'locationAlwaysPermission',
      descriptionKey: 'locationAlwaysPermissionDescription',
      explanationKey: 'locationAlwaysPermissionExplanation',
      category: PermissionCategory.essential,
      isRequired: true,
      icon: 'location_history',
      standardPermission: Permission.locationAlways,
    ),

    // Monitoring permissions
    PermissionInfo(
      id: 'sms',
      titleKey: 'smsPermission',
      descriptionKey: 'smsPermissionDescription',
      explanationKey: 'smsPermissionExplanation',
      category: PermissionCategory.monitoring,
      isRequired: true,
      icon: 'sms',
      standardPermission: Permission.sms,
    ),

    PermissionInfo(
      id: 'phone',
      titleKey: 'phonePermission',
      descriptionKey: 'phonePermissionDescription',
      explanationKey: 'phonePermissionExplanation',
      category: PermissionCategory.monitoring,
      isRequired: true,
      icon: 'call',
      standardPermission: Permission.phone,
    ),

    PermissionInfo(
      id: 'usageStats',
      titleKey: 'usageStatsPermission',
      descriptionKey: 'usageStatsPermissionDescription',
      explanationKey: 'usageStatsPermissionExplanation',
      category: PermissionCategory.monitoring,
      isRequired: true,
      icon: 'assessment',
      customPermissionKey: 'usage_stats',
      settingsPath: 'android.settings.USAGE_ACCESS_SETTINGS',
    ),

    PermissionInfo(
      id: 'accessibilityService',
      titleKey: 'accessibilityServicePermission',
      descriptionKey: 'accessibilityServicePermissionDescription',
      explanationKey: 'accessibilityServicePermissionExplanation',
      category: PermissionCategory.monitoring,
      isRequired: true,
      icon: 'accessibility',
      customPermissionKey: 'accessibility_service',
      settingsPath: 'android.settings.ACCESSIBILITY_SETTINGS',
    ),

    // Media permissions
    PermissionInfo(
      id: 'camera',
      titleKey: 'cameraPermission',
      descriptionKey: 'cameraPermissionDescription',
      explanationKey: 'cameraPermissionExplanation',
      category: PermissionCategory.media,
      isRequired: false,
      icon: 'camera_alt',
      standardPermission: Permission.camera,
    ),

    PermissionInfo(
      id: 'microphone',
      titleKey: 'microphonePermission',
      descriptionKey: 'microphonePermissionDescription',
      explanationKey: 'microphonePermissionExplanation',
      category: PermissionCategory.media,
      isRequired: false,
      icon: 'mic',
      standardPermission: Permission.microphone,
    ),

    PermissionInfo(
      id: 'storage',
      titleKey: 'storagePermission',
      descriptionKey: 'storagePermissionDescription',
      explanationKey: 'storagePermissionExplanation',
      category: PermissionCategory.media,
      isRequired: true,
      icon: 'storage',
      customPermissionKey: 'media_read',
    ),

    // System permissions
    PermissionInfo(
      id: 'deviceAdmin',
      titleKey: 'deviceAdminPermission',
      descriptionKey: 'deviceAdminPermissionDescription',
      explanationKey: 'deviceAdminPermissionExplanation',
      category: PermissionCategory.system,
      isRequired: true,
      icon: 'admin_panel_settings',
      customPermissionKey: 'device_admin',
      settingsPath: 'android.settings.SECURITY_SETTINGS',
    ),

    PermissionInfo(
      id: 'batteryOptimization',
      titleKey: 'batteryOptimizationPermission',
      descriptionKey: 'batteryOptimizationPermissionDescription',
      explanationKey: 'batteryOptimizationPermissionExplanation',
      category: PermissionCategory.system,
      isRequired: true,
      icon: 'battery_saver',
      customPermissionKey: 'battery_optimization',
      settingsPath: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
    ),

    PermissionInfo(
      id: 'notification',
      titleKey: 'notificationPermission',
      descriptionKey: 'notificationPermissionDescription',
      explanationKey: 'notificationPermissionExplanation',
      category: PermissionCategory.system,
      isRequired: true,
      icon: 'notifications',
      standardPermission: Permission.notification,
    ),
  ];

  static List<PermissionInfo> get allPermissions =>
      List.unmodifiable(_allPermissions);

  static List<PermissionInfo> getPermissionsByCategory(
      PermissionCategory category) {
    return _allPermissions.where((p) => p.category == category).toList();
  }

  static List<PermissionInfo> get requiredPermissions {
    return _allPermissions.where((p) => p.isRequired).toList();
  }

  static List<PermissionInfo> get optionalPermissions {
    return _allPermissions.where((p) => !p.isRequired).toList();
  }

  static Future<void> checkAllPermissions() async {
    for (final permission in _allPermissions) {
      await checkPermission(permission);
    }
  }

  static Future<void> checkPermission(PermissionInfo permission) async {
    try {
      if (permission.customPermissionKey == 'media_read') {
        final status = await MediaPermissionUtils.aggregateReadStatus();
        permission.status = status.isLimited
            ? AppPermissionStatus.granted
            : _mapStandardStatus(status);
      } else if (permission.standardPermission != null) {
        final status = await permission.standardPermission!.status;
        permission.status = _mapStandardStatus(status);
      } else if (permission.customPermissionKey != null) {
        final statusString = await _channel.invokeMethod<String>(
          'checkPermission',
          {'permission': permission.customPermissionKey},
        );
        permission.status = _mapCustomStatus(statusString ?? 'denied');
      }
    } catch (e) {
      permission.status = AppPermissionStatus.denied;
    }
  }

  static Future<bool> requestPermission(PermissionInfo permission) async {
    try {
      if (permission.customPermissionKey == 'media_read') {
        await MediaPermissionUtils.requestReadPermissions();
        await checkPermission(permission);
        return permission.status == AppPermissionStatus.granted;
      } else if (permission.standardPermission != null) {
        final status = await permission.standardPermission!.request();
        permission.status = _mapStandardStatus(status);
        return permission.status == AppPermissionStatus.granted;
      } else if (permission.settingsPath != null) {
        await _channel.invokeMethod('requestPermission', {
          'permission': permission.customPermissionKey,
          'settingsPath': permission.settingsPath,
        });
        await Future.delayed(const Duration(seconds: 1));
        await checkPermission(permission);
        return permission.status == AppPermissionStatus.granted;
      }
    } catch (e) {
      permission.status = AppPermissionStatus.denied;
    }
    return false;
  }

  static Future<void> openSettings(String settingsPath) async {
    try {
      await _channel
          .invokeMethod('openSettings', {'settingsPath': settingsPath});
    } catch (e) {
      // Handle error
    }
  }

  static Future<void> openAppSettings() async {
    try {
      // Use native method channel for opening app settings
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('Could not open app settings: $e');
    }
  }

  static bool areRequiredPermissionsGranted() {
    return requiredPermissions
        .every((p) => p.status == AppPermissionStatus.granted);
  }

  static bool areAllPermissionsGranted() {
    return _allPermissions
        .every((p) => p.status == AppPermissionStatus.granted);
  }

  static List<PermissionInfo> getDeniedRequiredPermissions() {
    return requiredPermissions
        .where((p) => p.status != AppPermissionStatus.granted)
        .toList();
  }

  static List<PermissionInfo> getPermanentlyDeniedPermissions() {
    return _allPermissions
        .where((p) => p.status == AppPermissionStatus.permanentlyDenied)
        .toList();
  }

  static AppPermissionStatus _mapStandardStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.provisional:
        return AppPermissionStatus.provisional;
      case PermissionStatus.limited:
        return AppPermissionStatus.limited;
    }
  }

  static AppPermissionStatus _mapCustomStatus(String status) {
    switch (status) {
      case 'granted':
        return AppPermissionStatus.granted;
      case 'denied':
        return AppPermissionStatus.denied;
      default:
        return AppPermissionStatus.denied;
    }
  }
}
