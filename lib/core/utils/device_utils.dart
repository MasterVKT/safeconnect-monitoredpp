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
      
      return {
        'platform': 'ANDROID',
        'model': androidInfo.model,
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
        'model': iosInfo.model,
        'manufacturer': 'Apple',
        'device_id': iosInfo.identifierForVendor ?? 'unknown',
        'os_version': iosInfo.systemVersion,
        'app_version': packageInfo.version,
        'app_build_number': packageInfo.buildNumber,
      };
    } else {
      return {
        'platform': 'UNKNOWN',
        'model': 'Unknown',
        'device_id': 'unknown_device',
        'app_version': packageInfo.version,
        'app_build_number': packageInfo.buildNumber,
      };
    }
  }
}