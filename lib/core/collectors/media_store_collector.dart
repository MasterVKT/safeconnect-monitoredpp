import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/collectors/bootstrap_checkpoint.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/utils/media_permission_utils.dart';

class MediaStoreCollector {
  static const MethodChannel _channel = MethodChannel(
    'com.xpsafeconnect.monitored_app/mediastore_scanner',
  );
  static const Duration _bootstrapHistoryWindow = Duration(days: 90);
  static const Duration _scanInterval = Duration(hours: 6);
  static const int _nativeBatchLimit = 500;
  static const int _checkpointStateVersion = 2;
  static const Map<String, String> _permissionKeysByMethod = {
    'scanImages': 'images',
    'scanVideos': 'videos',
    'scanAudio': 'audio',
  };

  final StorageService _storageService = locator<StorageService>();
  late final Map<String, BootstrapCheckpoint> _checkpoints = {
    for (final permissionKey in _permissionKeysByMethod.values)
      permissionKey: BootstrapCheckpoint(
        storageService: _storageService,
        keyPrefix: 'mediastore_collector_$permissionKey',
        historyWindow: _bootstrapHistoryWindow,
        stateVersion: _checkpointStateVersion,
      ),
  };

  Function(String dataType, List<dynamic> items)? _onDataCollected;
  Timer? _scanTimer;
  bool _isCollecting = false;
  bool _isScanInProgress = false;

  bool get isCollecting => _isCollecting;

  void setDataCollectedCallback(
    Function(String dataType, List<dynamic> items) callback,
  ) {
    _onDataCollected = callback;
  }

  Future<void> initialize() async {
    await _storageService.reloadPreferences();
    for (final checkpoint in _checkpoints.values) {
      await checkpoint.initialize();
    }

    debugPrint(
      '[MediaStore] initialized with per-category bootstrap checkpoints',
    );
  }

  Future<void> startCollecting() async {
    if (_isCollecting) return;

    final hasPermissions = await checkReadPermissions();
    if (!hasPermissions) {
      debugPrint(
          '[MediaStore] Cannot start scan: media read permissions missing');
      return;
    }

    _isCollecting = true;
    _scanTimer = Timer.periodic(_scanInterval, (_) => _scanAll());
    await _scanAll();
  }

  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    _scanTimer?.cancel();
    _scanTimer = null;
    _isCollecting = false;
    debugPrint('[MediaStore] collector stopped');
  }

  Future<bool> checkReadPermissions() async {
    if (!Platform.isAndroid) return false;

    final statuses = await _readPermissionStatuses();
    if (statuses.isNotEmpty) {
      return statuses.values.any(_hasReadAccess);
    }

    return MediaPermissionUtils.hasAnyReadAccess();
  }

  Future<Map<String, String>> _readPermissionStatuses() async {
    if (!Platform.isAndroid) return const {};

    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getReadPermissionStatus');
      if (result != null) {
        return result.map(
          (key, value) => MapEntry(key, value?.toString() ?? 'denied'),
        );
      }
    } catch (e) {
      debugPrint('[MediaStore] Native permission check failed: $e');
    }

    return const {};
  }

  Future<bool> requestReadPermissions() async {
    if (!Platform.isAndroid) return false;

    await MediaPermissionUtils.requestReadPermissions();
    final granted = await checkReadPermissions();
    if (granted && _isCollecting) {
      await _scanAll();
    }
    return granted;
  }

  Future<void> _scanAll() async {
    if (_isScanInProgress) {
      debugPrint('[MediaStore] Scan skipped: another scan is running');
      return;
    }

    _isScanInProgress = true;
    try {
      final allItems = <Map<String, dynamic>>[];
      final permissionStatuses = await _readPermissionStatuses();

      for (final entry in _permissionKeysByMethod.entries) {
        final method = entry.key;
        final permissionKey = entry.value;
        final permissionStatus = permissionStatuses[permissionKey] ?? 'denied';
        final checkpoint = _checkpoints[permissionKey]!;
        final permissionScopeKey =
            'mediastore_collector_${permissionKey}_permission_scope';
        final previousPermissionStatus =
            _storageService.getString(permissionScopeKey);

        if (previousPermissionStatus == 'limited' &&
            permissionStatus == 'granted') {
          await checkpoint.reset();
          debugPrint(
            '[MediaStore] $permissionKey access expanded; '
            'historical bootstrap reset',
          );
        }

        final isBootstrap = checkpoint.isBootstrapPending;

        if (!_hasReadAccess(permissionStatus)) {
          debugPrint(
            '[MediaStore] $permissionKey scan deferred: permission is $permissionStatus',
          );
          continue;
        }

        final startCheckpoint =
            checkpoint.resolve(fallback: const Duration(days: 7));
        try {
          final items = await _scanMethod(method, startCheckpoint);
          var latestTimestamp = startCheckpoint.millisecondsSinceEpoch;

          for (final item in items) {
            final createdAtMs = _readInt(item['created_at_epoch']);
            if (createdAtMs != null && createdAtMs > latestTimestamp) {
              latestTimestamp = createdAtMs;
            }
            allItems.add(_normalizeMediaItem(item));
          }

          final refreshedStatuses = await _readPermissionStatuses();
          final refreshedStatus = refreshedStatuses[permissionKey] ?? 'denied';
          if (!_hasReadAccess(refreshedStatus)) {
            debugPrint(
              '[MediaStore] $permissionKey checkpoint not advanced: '
              'permission changed during scan',
            );
            continue;
          }

          await checkpoint.completeSuccessfulScan(
            items.isEmpty
                ? DateTime.now()
                : DateTime.fromMillisecondsSinceEpoch(latestTimestamp),
          );
          await _storageService.setString(
            permissionScopeKey,
            refreshedStatus,
          );

          debugPrint(
            '[MediaStore] scanned ${items.length} $permissionKey items '
            'since $startCheckpoint (bootstrap=$isBootstrap)',
          );

          if (isBootstrap) {
            debugPrint(
              '[MediaStore] $permissionKey bootstrap completed: '
              '${items.length} items.',
            );
          }
        } catch (e) {
          debugPrint(
            '[MediaStore] $permissionKey scan failed; checkpoint preserved: $e',
          );
        }
      }

      if (allItems.isNotEmpty) {
        _onDataCollected?.call('media_metadata', allItems);
      }
    } catch (e) {
      debugPrint('[MediaStore] Scan failed: $e');
    } finally {
      _isScanInProgress = false;
    }
  }

  Future<List<Map<String, dynamic>>> _scanMethod(
    String method,
    DateTime initialCheckpoint,
  ) async {
    var checkpoint = initialCheckpoint;
    var keepFetching = true;
    final items = <Map<String, dynamic>>[];

    while (keepFetching) {
      final list = await _channel.invokeMethod<List<dynamic>>(
        method,
        {
          'since': checkpoint.millisecondsSinceEpoch,
          'limit': _nativeBatchLimit,
        },
      );
      final batch = list ?? const <dynamic>[];
      var latestTimestamp = checkpoint.millisecondsSinceEpoch;

      for (final rawItem in batch) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final createdAtMs = _readInt(item['created_at_epoch']);
        if (createdAtMs != null && createdAtMs > latestTimestamp) {
          latestTimestamp = createdAtMs;
        }
        items.add(item);
      }

      keepFetching = batch.length >= _nativeBatchLimit &&
          latestTimestamp > checkpoint.millisecondsSinceEpoch;
      checkpoint = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);
    }

    return items;
  }

  Map<String, dynamic> _normalizeMediaItem(Map<String, dynamic> item) {
    final createdAtMs = _readInt(item['created_at_epoch']) ??
        DateTime.now().millisecondsSinceEpoch;
    final mediaType = item['media_type']?.toString() ?? 'UNKNOWN';
    final nativeId = item['id_native']?.toString() ?? createdAtMs.toString();
    final mediaId =
        item['media_id']?.toString() ?? '${mediaType.toLowerCase()}_$nativeId';

    return {
      'media_id': mediaId,
      'media_type': mediaType,
      'file_name': item['file_name']?.toString() ?? '',
      'file_path': item['file_path']?.toString() ?? '',
      'file_size': _readInt(item['file_size']) ?? 0,
      'mime_type': item['mime_type']?.toString() ?? '',
      'created_at':
          DateTime.fromMillisecondsSinceEpoch(createdAtMs).toUtc().toIso8601String(),
      'width': _readInt(item['width']),
      'height': _readInt(item['height']),
      'duration': _readInt(item['duration']),
      'capture_method': 'mediastore',
    };
  }

  bool _hasReadAccess(String status) {
    return status == 'granted' || status == 'limited';
  }

  Future<void> resetBootstrap() async {
    for (final checkpoint in _checkpoints.values) {
      await checkpoint.reset();
    }
    debugPrint('[MediaStore] Historical bootstrap reset for all categories');
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
