import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaPermissionUtils {
  static Future<bool> isAndroid13Plus() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt >= 33;
  }

  static Future<List<Permission>> readPermissions() async {
    if (await isAndroid13Plus()) {
      return const [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ];
    }

    return const [Permission.storage];
  }

  static Future<Map<Permission, PermissionStatus>> readStatuses() async {
    final permissions = await readPermissions();
    return {
      for (final permission in permissions) permission: await permission.status,
    };
  }

  static Future<Map<Permission, PermissionStatus>>
      requestReadPermissions() async {
    final permissions = await readPermissions();
    return permissions.request();
  }

  static Future<bool> hasAnyReadAccess() async {
    final statuses = await readStatuses();

    if (statuses.containsKey(Permission.storage)) {
      return statuses[Permission.storage]?.isGranted ?? false;
    }

    return _hasVisualReadAccess(statuses[Permission.photos]) ||
        _hasVisualReadAccess(statuses[Permission.videos]) ||
        (statuses[Permission.audio]?.isGranted ?? false);
  }

  static Future<PermissionStatus> aggregateReadStatus() async {
    final statuses = await readStatuses();

    if (statuses.containsKey(Permission.storage)) {
      return statuses[Permission.storage] ?? PermissionStatus.denied;
    }

    final photos = statuses[Permission.photos] ?? PermissionStatus.denied;
    final videos = statuses[Permission.videos] ?? PermissionStatus.denied;
    final audio = statuses[Permission.audio] ?? PermissionStatus.denied;

    if (_hasVisualReadAccess(photos) ||
        _hasVisualReadAccess(videos) ||
        audio.isGranted) {
      if (photos.isLimited || videos.isLimited) {
        return PermissionStatus.limited;
      }
      return PermissionStatus.granted;
    }

    if (photos.isPermanentlyDenied ||
        videos.isPermanentlyDenied ||
        audio.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }

    if (photos.isRestricted || videos.isRestricted || audio.isRestricted) {
      return PermissionStatus.restricted;
    }

    return PermissionStatus.denied;
  }

  static String serializeStatus(PermissionStatus status) {
    if (status.isGranted) return 'granted';
    if (status.isLimited) return 'partial';
    if (status.isPermanentlyDenied) return 'permanently_denied';
    if (status.isDenied) return 'denied';
    if (status.isRestricted) return 'restricted';
    if (status.isProvisional) return 'provisional';
    return 'unknown';
  }

  static bool _hasVisualReadAccess(PermissionStatus? status) {
    return status?.isGranted == true || status?.isLimited == true;
  }
}
