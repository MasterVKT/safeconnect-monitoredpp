import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Obtenir un identifiant unique pour cet appareil
  static Future<String> getDeviceIdentifier() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.id;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    } else {
      return 'unknown_platform';
    }
  }

  // Obtenir des informations complètes sur cet appareil
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      final deviceName = _buildAndroidDeviceDisplayName(androidInfo);

      return {
        'platform': 'ANDROID',
        'device_name': deviceName,
        'model': androidInfo.model,
        'device_model': deviceName,
        'manufacturer': androidInfo.manufacturer,
        'device_id': androidInfo.id,
        'os_version': androidInfo.version.release,
        'sdk_version': androidInfo.version.sdkInt.toString(),
        'app_version': packageInfo.version,
        'app_build_number': packageInfo.buildNumber,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;

      return {
        'platform': 'IOS',
        'device_name': iosInfo.name,
        'model': iosInfo.model,
        'device_model': iosInfo.model,
        'manufacturer': 'Apple',
        'device_id': iosInfo.identifierForVendor ?? 'unknown',
        'os_version': iosInfo.systemVersion,
        'app_version': packageInfo.version,
        'app_build_number': packageInfo.buildNumber,
      };
    } else {
      return {
        'platform': 'UNKNOWN',
        'device_name': 'Unknown Device',
        'model': 'Unknown',
        'device_model': 'Unknown',
        'device_id': 'unknown_device',
        'app_version': packageInfo.version,
        'app_build_number': packageInfo.buildNumber,
      };
    }
  }

  // Get OS version
  static Future<String> getOSVersion() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.version.release;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.systemVersion;
    } else {
      return 'unknown';
    }
  }

  // Get device model
  static Future<String> getDeviceModel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return _buildAndroidDeviceDisplayName(androidInfo);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.model;
    } else {
      return 'unknown';
    }
  }

  // Get device display name
  static Future<String> getDeviceName() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return _buildAndroidDeviceDisplayName(androidInfo);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.name.isNotEmpty ? iosInfo.name : iosInfo.model;
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      debugPrint('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  // Get app version
  static Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('Error getting app version: $e');
      return 'unknown';
    }
  }

  static String _buildAndroidDeviceDisplayName(AndroidDeviceInfo androidInfo) {
    final brand = _normalizeDevicePart(androidInfo.brand);
    final model = _normalizeDevicePart(androidInfo.model);

    if (model.isEmpty) {
      return brand.isNotEmpty ? brand : 'Unknown Device';
    }

    if (brand.isEmpty || model.toLowerCase().startsWith(brand.toLowerCase())) {
      return model;
    }

    return '$brand $model';
  }

  static String _normalizeDevicePart(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    return trimmed.split(RegExp(r'\s+')).map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}
