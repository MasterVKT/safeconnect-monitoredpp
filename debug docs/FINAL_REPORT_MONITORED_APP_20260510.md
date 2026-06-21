# 🎯 Rapport Final — monitored_app XP SafeConnect

**Date** : 2026-05-10
**Cible** : Équipe monitored_app (`H:\Projects\XP SafeConnect\flutter_apps\monitored_app\`)
**Auteur** : Audit consolidé monitor_app team
**Statut global** : 🔴 **6 BUGS BLOQUANTS** + 3 bugs non-bloquants à appliquer dans l'ordre indiqué

---

## 1. Synthèse exécutive

Suite à l'audit complet du **2026-05-10**, le `monitored_app` présente **6 bugs critiques** qui empêchent actuellement la récupération complète des données par le `monitor_app`. Seuls les SMS fonctionnent (139 messages historiques bien remontés depuis le pattern bootstrap). Les **calls**, **médias**, **détail app usage** et **localisation** restent inaccessibles côté `monitor_app` parce que :

- Les collecteurs natifs ne tournent pas ou crashent (LIMIT mal placé dans la requête `ContentResolver`)
- Les permissions Android 13+ pour la galerie média ne sont pas déclarées
- L'application ne scanne **jamais** les médias existants (la galerie complète du téléphone est ignorée)
- Le rapport de permissions envoyé au backend est **hardcodé** (mensonge involontaire)
- Les inserts SQLite échouent silencieusement à chaque restart (rendant le debug difficile)

Ces 6 bugs doivent être appliqués dans **l'ordre indiqué section 4** pour un déblocage progressif et vérifiable.

---

## 2. Ce qui a déjà été correctement appliqué ✅

### 2.1 — Pattern bootstrap historique pour SMS
**Fichier** : `lib/core/collectors/sms_collector.dart`
**Validation** : log `[SMS] Bootstrap completed: 139 historical SMS captured` confirmé le 2026-05-10.

Le pattern `bootstrapDone` + `lastCheckTime` persistants en SharedPreferences fonctionne. À répliquer pour `calls_collector` et tous nouveaux collecteurs nécessitant un historique.

### 2.2 — `_handleMethodCall('onCallStateChanged')` corrigé
**Fichier** : `lib/core/collectors/calls_collector.dart` lignes 204-216 (vérifié le 2026-05-10)

Le handler déclenche désormais `_checkForNewCalls()` quand `state == 0` (IDLE) au lieu d'essayer de convertir le payload live `{state, number, timestamp}` qui n'a pas la même forme que `getNewCalls()` côté natif. ✅

### 2.3 — `AppsCollectorPlugin.kt` permission USAGE_STATS
**Fichier** : `android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/AppsCollectorPlugin.kt` lignes 54-71

Utilise correctement `AppOpsManager.unsafeCheckOpNoThrow(OPSTR_GET_USAGE_STATS, ...)` (Android 10+) avec fallback. ✅ — pas de modification requise dans ce code, mais voir bug #4.2 pour le UX.

### 2.4 — `data_collector_service._collectApiDataTypes` complet
**Fichier** : `lib/core/services/data_collector_service.dart` lignes 36-44
Contient bien `'media_metadata'` mappé à `'media'`. ✅

---

## 3. 🔴 Bugs critiques bloquants — à appliquer dans l'ordre

> **Ordre d'application recommandé** : 3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6
> Chaque fix débloque progressivement une catégorie de données et peut être testé indépendamment.

---

### 3.1 — `AndroidManifest.xml` : permissions Android 13+ manquantes

**🔴 Priorité 1 — Prérequis pour tous les autres fixes média**

**Fichier** : `h:\Projects\XP SafeConnect\flutter_apps\monitored_app\android\app\src\main\AndroidManifest.xml`

**Problème** : Sur Android 13+ (API 33+), la permission `READ_EXTERNAL_STORAGE` est dépréciée. Pour lire la galerie photo/vidéo/audio, il faut déclarer explicitement `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`. Sur HONOR NLA-LX2P (Android 15, API 35), sans ces déclarations, **aucune photo/vidéo ne peut être lue de la galerie**, même si l'utilisateur accordait toutes les permissions visibles.

**Fix** :

Ajouter dans `<manifest>` :
```xml
<!-- Android 13+ (API 33+) granular media permissions -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />

<!-- Android <= 12 (API <= 32) legacy storage -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

S'assurer aussi que ces permissions soient présentes (probablement déjà OK, à vérifier) :
```xml
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_CALL_LOG" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

**Validation** : `flutter clean && flutter run` ; au runtime, `Permission.photos.request()` doit afficher le dialogue système.

**Impact si non corrigé** : 0 média de galerie remontés, même après tous les autres fixes.

---

### 3.2 — `device_service.dart:445` : `_getPermissionsStatus()` hardcodé

**🔴 Priorité 2 — Permet au backend de connaître la vérité sur l'état des permissions**

**Fichier** : `lib/core/services/device_service.dart`

**Bug** : La méthode retourne actuellement des valeurs **hardcodées** `'granted'` pour toutes les permissions, peu importe leur état réel :

```dart
// BUGGY actuellement (lignes 445-457) :
Future<Map<String, String>> _getPermissionsStatus() async {
  // This should integrate with the permission system
  // For now, return a basic status
  return {
    'location': 'granted',
    'camera': 'granted',
    'microphone': 'granted',
    'contacts': 'granted',
    'storage': 'granted',
    'sms': 'granted',
    'call_log': 'granted',
  };
}
```

**Impact** :
- Le backend reçoit toujours `permissions_status: {camera: granted, ...}` même si CAMERA est `denied`
- Le `media_collector` voit la vérité (denied) et ne démarre pas
- L'utilisateur (parent) ne peut jamais savoir quelles permissions manquent sur l'appareil de l'enfant

**Fix proposé** :

Ajouter en haut du fichier :
```dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
```

Remplacer la méthode :
```dart
Future<Map<String, String>> _getPermissionsStatus() async {
  final isAndroid13Plus = Platform.isAndroid && (await _getAndroidSdkInt()) >= 33;

  final results = <String, PermissionStatus>{
    'location': await Permission.locationAlways.status,
    'camera': await Permission.camera.status,
    'microphone': await Permission.microphone.status,
    'contacts': await Permission.contacts.status,
    'sms': await Permission.sms.status,
    'call_log': await Permission.phone.status,
  };

  if (isAndroid13Plus) {
    // Sur Android 13+, "storage" est agrégé depuis photos+videos+audio
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    final audio = await Permission.audio.status;
    final allMedia =
        photos.isGranted && videos.isGranted && audio.isGranted;
    results['storage'] = allMedia
        ? PermissionStatus.granted
        : PermissionStatus.denied;
  } else {
    results['storage'] = await Permission.storage.status;
  }

  return results.map(
    (key, value) => MapEntry(key, _serializeStatus(value)),
  );
}

String _serializeStatus(PermissionStatus s) {
  if (s.isGranted) return 'granted';
  if (s.isPermanentlyDenied) return 'permanently_denied';
  if (s.isDenied) return 'denied';
  if (s.isRestricted) return 'restricted';
  return 'unknown';
}

Future<int> _getAndroidSdkInt() async {
  if (!Platform.isAndroid) return 0;
  final info = await DeviceInfoPlugin().androidInfo;
  return info.version.sdkInt;
}
```

**Validation** :
1. Refuser explicitement la permission CAMERA (Settings → Apps → monitored_app → Permissions → Camera → Deny)
2. Restart l'app
3. Observer le PATCH device sortant
4. **Attendu** : `permissions_status: {..., camera: "denied", ...}` (pas `granted`)

**Impact si non corrigé** : le backend continue d'être trompé ; l'utilisateur ne saura jamais quelles permissions manquent.

---

### 3.3 — `CallsCollectorPlugin.kt:157` : LIMIT dans sortOrder (régression critique)

**🔴 Priorité 3 — Débloque la liste des appels**

**Fichier** : `android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/CallsCollectorPlugin.kt`

**Bug actuel** ligne 157 :
```kotlin
val sortOrder = "${CallLog.Calls.DATE} ASC LIMIT $safeLimit"
```

`ContentResolver.query(uri, projection, selection, selectionArgs, sortOrder)` **rejette** `LIMIT` dans le `sortOrder` pour le `CallLog` provider Android :
```
java.lang.IllegalArgumentException: Invalid token LIMIT
  at android.database.DatabaseUtils.readExceptionFromParcel(DatabaseUtils.java:185)
  at com.xpsafeconnect.monitored_app.CallsCollectorPlugin.getNewCalls(CallsCollectorPlugin.kt:161)
```

Résultat : `getNewCalls()` retourne 0 → aucun appel n'est jamais remonté → écran appels vide perpétuel côté monitor_app.

**Note importante** : `SmsCollectorPlugin.kt:136` a **la même structure** mais fonctionne **par chance** (le provider `Telephony.Sms` est plus permissif). Pour la robustesse à long terme, appliquer le **même fix** aux deux fichiers.

**Fix correct** : utiliser `ContentResolver.QUERY_ARG_LIMIT` via `Bundle` (API 26+) avec fallback troncature pour API plus anciennes.

```kotlin
import android.content.ContentResolver
import android.os.Build
import android.os.Bundle

private fun getNewCalls(since: Long, limit: Int = 500): List<Map<String, Any>> {
    val result = ArrayList<Map<String, Any>>()
    if (!checkCallLogPermissions()) {
        return result
    }

    val uri = CallLog.Calls.CONTENT_URI
    val projection = arrayOf(
        CallLog.Calls._ID,
        CallLog.Calls.NUMBER,
        CallLog.Calls.TYPE,
        CallLog.Calls.DATE,
        CallLog.Calls.DURATION,
        CallLog.Calls.CACHED_NAME
    )
    val safeLimit = limit.coerceIn(1, 1000)

    var cursor: Cursor? = null
    try {
        cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // API 26+ : query args Bundle officiel
            val args = Bundle().apply {
                putString(
                    ContentResolver.QUERY_ARG_SQL_SELECTION,
                    "${CallLog.Calls.DATE} > ?"
                )
                putStringArray(
                    ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                    arrayOf(since.toString())
                )
                putStringArray(
                    ContentResolver.QUERY_ARG_SORT_COLUMNS,
                    arrayOf(CallLog.Calls.DATE)
                )
                putInt(
                    ContentResolver.QUERY_ARG_SORT_DIRECTION,
                    ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
                )
                putInt(ContentResolver.QUERY_ARG_LIMIT, safeLimit)
            }
            context.contentResolver.query(uri, projection, args, null)
        } else {
            // API < 26 : pas de LIMIT côté provider, on tronque côté Kotlin
            context.contentResolver.query(
                uri,
                projection,
                "${CallLog.Calls.DATE} > ?",
                arrayOf(since.toString()),
                "${CallLog.Calls.DATE} ASC"
            )
        }

        cursor?.let {
            var count = 0
            while (it.moveToNext() && count < safeLimit) {
                val callData = mapOf<String, Any>(
                    "number" to (it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: ""),
                    "type" to it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE)),
                    "date" to it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE)),
                    "duration" to it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION)),
                    "name" to (it.getString(it.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME)) ?: ""),
                    "sim_slot" to -1,
                    "is_conference" to false
                )
                result.add(callData)
                count++
            }
        }
    } catch (e: Exception) {
        android.util.Log.e("CallsCollectorPlugin", "Error querying call log: ${e.message}", e)
    } finally {
        cursor?.close()
    }

    return result
}
```

**Appliquer le même pattern** dans `SmsCollectorPlugin.kt:136` avec les constantes `Telephony.Sms.*` et la table `Telephony.Sms.CONTENT_URI`.

**Validation** :
1. Avoir des appels historiques sur l'appareil
2. Pairing + attendre 2-3 minutes
3. **Attendu logs monitored_app** :
   ```
   [Calls] getNewCalls returned <N>>=1</N> entries since 2026-... (bootstrap=true)
   [Calls] Bootstrap completed: <N> historical calls captured.
   Queued calls data for sync
   ```
4. Plus aucune trace de `IllegalArgumentException: Invalid token LIMIT`.
5. Côté monitor_app : `GET /api/v1/calls/?device=<uuid>` retourne `count >= 1`.

**Impact si non corrigé** : la liste d'appels côté monitor_app reste vide indéfiniment.

---

### 3.4 — **NOUVEAU** : Absence de scanner MediaStore pour la galerie existante

**🔴 Priorité 4 — Bug fondamental : aucun média n'est jamais collecté**

**Fichiers** : `lib/core/collectors/media_collector.dart`, `lib/core/services/advanced_media_service.dart`, `android/.../MediaCapturePlugin.kt`

**Bug** : L'application capture des médias en temps réel (caméra à la demande, audio) mais **ne scanne JAMAIS** les photos/vidéos déjà présentes dans la galerie du téléphone. `MediaCapturePlugin.kt` importe bien `android.provider.MediaStore` mais ne l'utilise jamais.

**Conséquence** : L'écran média côté monitor_app reste vide même quand le téléphone contient des centaines de photos. C'est probablement la cause #1 de l'attente infinie de l'utilisateur.

**Fix proposé** :

#### A) Côté natif Kotlin

Créer `android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/MediaStoreScannerPlugin.kt` :

```kotlin
package com.xpsafeconnect.monitored_app

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MediaStoreScannerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger,
            "com.xpsafeconnect.monitored_app/mediastore_scanner"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanImages" -> {
                val since = call.argument<Long>("since") ?: 0L
                val limit = call.argument<Int>("limit") ?: 500
                result.success(scanImages(since, limit))
            }
            "scanVideos" -> {
                val since = call.argument<Long>("since") ?: 0L
                val limit = call.argument<Int>("limit") ?: 500
                result.success(scanVideos(since, limit))
            }
            "scanAudio" -> {
                val since = call.argument<Long>("since") ?: 0L
                val limit = call.argument<Int>("limit") ?: 500
                result.success(scanAudio(since, limit))
            }
            else -> result.notImplemented()
        }
    }

    private fun scanImages(since: Long, limit: Int): List<Map<String, Any>> {
        return queryMediaStore(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.MIME_TYPE,
                MediaStore.Images.Media.DATE_ADDED,
                MediaStore.Images.Media.DATA,
                MediaStore.Images.Media.WIDTH,
                MediaStore.Images.Media.HEIGHT
            ),
            MediaStore.Images.Media.DATE_ADDED,
            since,
            limit,
            "PHOTO"
        )
    }

    private fun scanVideos(since: Long, limit: Int): List<Map<String, Any>> {
        return queryMediaStore(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            arrayOf(
                MediaStore.Video.Media._ID,
                MediaStore.Video.Media.DISPLAY_NAME,
                MediaStore.Video.Media.SIZE,
                MediaStore.Video.Media.MIME_TYPE,
                MediaStore.Video.Media.DATE_ADDED,
                MediaStore.Video.Media.DATA,
                MediaStore.Video.Media.DURATION
            ),
            MediaStore.Video.Media.DATE_ADDED,
            since,
            limit,
            "VIDEO"
        )
    }

    private fun scanAudio(since: Long, limit: Int): List<Map<String, Any>> {
        return queryMediaStore(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.MIME_TYPE,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DURATION
            ),
            MediaStore.Audio.Media.DATE_ADDED,
            since,
            limit,
            "AUDIO"
        )
    }

    private fun queryMediaStore(
        uri: android.net.Uri,
        projection: Array<String>,
        dateColumn: String,
        since: Long,
        limit: Int,
        mediaType: String
    ): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        val safeLimit = limit.coerceIn(1, 1000)

        var cursor: Cursor? = null
        try {
            cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val args = Bundle().apply {
                    putString(ContentResolver.QUERY_ARG_SQL_SELECTION, "$dateColumn > ?")
                    putStringArray(
                        ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                        arrayOf((since / 1000).toString())
                    )
                    putStringArray(ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(dateColumn))
                    putInt(
                        ContentResolver.QUERY_ARG_SORT_DIRECTION,
                        ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
                    )
                    putInt(ContentResolver.QUERY_ARG_LIMIT, safeLimit)
                }
                context.contentResolver.query(uri, projection, args, null)
            } else {
                context.contentResolver.query(
                    uri,
                    projection,
                    "$dateColumn > ?",
                    arrayOf((since / 1000).toString()),
                    "$dateColumn ASC"
                )
            }

            cursor?.let { c ->
                var count = 0
                while (c.moveToNext() && count < safeLimit) {
                    val map = mutableMapOf<String, Any>(
                        "media_type" to mediaType,
                        "id_native" to c.getLong(c.getColumnIndexOrThrow(projection[0])),
                        "file_name" to (c.getString(c.getColumnIndexOrThrow(projection[1])) ?: ""),
                        "file_size" to c.getLong(c.getColumnIndexOrThrow(projection[2])),
                        "mime_type" to (c.getString(c.getColumnIndexOrThrow(projection[3])) ?: ""),
                        "created_at_epoch" to c.getLong(c.getColumnIndexOrThrow(dateColumn)) * 1000,
                        "local_path" to (c.getString(c.getColumnIndexOrThrow(projection[5])) ?: "")
                    )
                    result.add(map)
                    count++
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MediaStoreScannerPlugin", "Error querying MediaStore: ${e.message}", e)
        } finally {
            cursor?.close()
        }
        return result
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

L'enregistrer dans `MainActivity.kt` :
```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine.plugins.add(MediaStoreScannerPlugin())
}
```

#### B) Côté Dart — créer `lib/core/collectors/media_store_collector.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/database_service.dart';
import 'package:monitored_app/core/services/storage_service.dart';
import 'package:monitored_app/core/collectors/base_collector.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaStoreCollector extends BaseCollector {
  static const _channel = MethodChannel(
    'com.xpsafeconnect.monitored_app/mediastore_scanner',
  );

  static const _kLastScanMsKey = 'mediastore_last_scan_ms';
  static const _kBootstrapDoneKey = 'mediastore_bootstrap_done';
  static const _bootstrapWindow = Duration(days: 90);

  Timer? _scanTimer;
  DateTime? _lastScan;
  bool _bootstrapDone = false;

  final DatabaseService _db = locator<DatabaseService>();
  final StorageService _storage = locator<StorageService>();

  @override
  String get collectorName => 'MediaStore';

  @override
  String get dataType => 'media_metadata';

  @override
  List<Permission> get requiredPermissions => const [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ];

  @override
  Future<void> initializeSpecific() async {
    _bootstrapDone =
        (await _storage.getBool(_kBootstrapDoneKey)) ?? false;
    final ms = await _storage.getInt(_kLastScanMsKey);
    _lastScan = ms != null
        ? DateTime.fromMillisecondsSinceEpoch(ms)
        : null;
    debugPrint(
      '[MediaStore] initialized: bootstrapDone=$_bootstrapDone, lastScan=$_lastScan',
    );
  }

  @override
  Future<bool> checkSpecificPermissions() async {
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    final audio = await Permission.audio.status;
    return photos.isGranted && videos.isGranted && audio.isGranted;
  }

  @override
  Future<void> requestSpecificPermissions() async {
    await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
  }

  @override
  Future<void> startSpecificCollection() async {
    _scanTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _scanAll(),
    );
    await _scanAll(); // Initial
  }

  @override
  Future<void> stopSpecificCollection() async {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  DateTime _resolveSince() {
    if (!_bootstrapDone) {
      return DateTime.now().subtract(_bootstrapWindow);
    }
    return _lastScan ?? DateTime.now().subtract(const Duration(days: 7));
  }

  Future<void> _scanAll() async {
    final since = _resolveSince();
    final all = <Map<String, dynamic>>[];

    for (final method in ['scanImages', 'scanVideos', 'scanAudio']) {
      try {
        final list = await _channel.invokeMethod<List<dynamic>>(
          method,
          {'since': since.millisecondsSinceEpoch, 'limit': 500},
        );
        if (list != null) {
          all.addAll(list.cast<Map>().map(
                (m) => Map<String, dynamic>.from(m),
              ));
        }
      } catch (e) {
        debugPrint('[MediaStore] $method failed: $e');
      }
    }

    debugPrint(
      '[MediaStore] scanned ${all.length} items since $since (bootstrap=${!_bootstrapDone})',
    );

    if (all.isNotEmpty) {
      await processData(all);
    }

    final now = DateTime.now();
    _lastScan = now;
    await _storage.setInt(_kLastScanMsKey, now.millisecondsSinceEpoch);
    if (!_bootstrapDone) {
      _bootstrapDone = true;
      await _storage.setBool(_kBootstrapDoneKey, true);
      debugPrint('[MediaStore] Bootstrap completed: ${all.length} items.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> collectData() async => [];
}
```

#### C) Enregistrer le collecteur dans `data_collector_service.dart`

Ajouter `MediaStoreCollector` à la liste des collecteurs initialisés au démarrage. Le `data_type` `media_metadata` est déjà supporté par `_collectApiDataTypes` (vérifié).

**Validation** :
1. Avoir des photos dans la galerie du device
2. Accorder `Permission.photos`, `Permission.videos`, `Permission.audio` à monitored_app
3. Restart + pairing
4. **Attendu** : log `[MediaStore] scanned <N> items since ...` puis `Queued media_metadata data for sync`
5. Côté monitor_app : `GET /api/v1/media/?device=<uuid>&media_type=PHOTO` retourne `count >= 1`

**Impact si non corrigé** : aucune photo/vidéo existante du téléphone n'est jamais détectée. Seules les captures en temps réel via `MediaCapturePlugin` (si jamais déclenchées) seraient remontées.

---

### 3.5 — `media_collector.dart:92-94` : pas de fallback MediaStore

**🔴 Priorité 5 — Évite l'arrêt complet si CAMERA est refusée**

**Fichier** : `lib/core/collectors/media_collector.dart`

**Bug actuel** lignes 88-94 :
```dart
Future<void> initialize() async {
  try {
    final hasPermissions = await _checkPermissions();
    if (!hasPermissions) {
      debugPrint('Camera or storage permissions not granted');
    }
    // ... setup
```

Et ligne 203-209 :
```dart
final hasPermissions = await _checkPermissions();
if (!hasPermissions) {
  debugPrint(
      '[MEDIA] Cannot start media collection: permissions not granted');
  return;  // ← Arrêt complet
}
```

`_checkPermissions()` vérifie `cameraPermission && storagePermission`. Si CAMERA est `denied`, on stoppe tout, ce qui empêcherait aussi le démarrage du scanner MediaStore (#3.4).

**Fix proposé** :

Découpler les permissions caméra/audio (capture en temps réel) de celles de lecture MediaStore (galerie existante) :

```dart
Future<bool> _hasCapturePermissions() async {
  try {
    final result = await _channel.invokeMethod<bool>(
      'checkMediaPermissions',
    );
    return result ?? false;
  } catch (_) {
    return false;
  }
}

Future<bool> _hasMediaStoreReadPermissions() async {
  if (!Platform.isAndroid) return false;
  final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  if (sdk >= 33) {
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    return photos.isGranted && videos.isGranted;
  }
  return (await Permission.storage.status).isGranted;
}

Future<void> startCollection() async {
  final canCapture = await _hasCapturePermissions();
  final canRead = await _hasMediaStoreReadPermissions();

  if (!canCapture && !canRead) {
    debugPrint('[MEDIA] No permissions for capture nor MediaStore read');
    return;
  }

  _isCollecting = true;

  if (canCapture) {
    // Démarrer schedulers de capture temps réel
  }
  if (canRead) {
    // Démarrer scanner MediaStore (cf. #3.4)
    await _mediaStoreCollector.startSpecificCollection();
  }
}
```

**Validation** : Refuser CAMERA mais accorder READ_MEDIA_IMAGES → le scanner MediaStore doit démarrer quand même et remonter les photos existantes.

**Impact si non corrigé** : même avec la permission galerie, si CAMERA est refusée → aucun média.

---

### 3.6 — `database.dart:65` : `INSERT` sans `mode: InsertMode.insertOrIgnore`

**🟡 Priorité 6 — Nettoie les logs pollués mais non bloquant**

**Fichier** : `lib/core/database/database.dart`

**Bug actuel** ligne 64-66 :
```dart
Future<int> insertSmsData(SmsDataTableCompanion sms) {
  return into(smsDataTable).insert(sms);
}
```

Drift utilise `INSERT` strict par défaut. Quand un SMS existe déjà (même `hash`), une `SqliteException(2067) UNIQUE constraint failed: sms_data_table.hash` est levée. Sur le bootstrap après un restart, 139 erreurs sont loguées. Le code applicatif catch silencieusement, mais les logs deviennent illisibles.

**Fix proposé** :
```dart
import 'package:drift/drift.dart';

Future<int> insertSmsData(SmsDataTableCompanion sms) {
  return into(smsDataTable).insert(sms, mode: InsertMode.insertOrIgnore);
}
```

**Appliquer le même fix** à toutes les autres tables avec contraintes UNIQUE :
- `insertCallData`
- `insertLocationData`
- (à identifier exhaustivement dans `database.dart`)

**Validation** : Restart l'app. **Attendu** : aucune trace de `SqliteException(2067)` dans les logs, même si le bootstrap re-lit les 139 SMS.

**Impact si non corrigé** : logs pollués mais sync fonctionne. Risque de masquer de vraies erreurs.

---

## 4. Bugs non-bloquants à fixer en suivant

### 4.1 — `apps_collector.dart` : UX pour PACKAGE_USAGE_STATS

La permission `PACKAGE_USAGE_STATS` n'est pas une runtime permission. Elle nécessite l'utilisateur d'ouvrir Settings → Apps → Special app access → Usage data access → monitored_app → Enable.

Ajouter un écran de configuration ou un bouton qui déclenche :
```dart
await OpenSettings.openUsageAccessSettings();
// ou
await SystemNavigator.routeUpdated(routeName: 'android.settings.USAGE_ACCESS_SETTINGS', previousRouteName: '');
```

### 4.2 — `location_collector.dart` : pas de bootstrap historique

Décision de design : la localisation est plus pertinente en temps réel qu'en historique massif. Si l'utilisateur veut couvrir l'historique de 90 jours, appliquer le même pattern `bootstrapDone` + `lastCheckTime` que SMS, mais ce n'est pas critique pour le scénario actuel.

### 4.3 — `battery_status` et `performance_metrics` queue rejet

Ces deux types sont queueés mais rejetés par `/data/collect/` API parce qu'absents de `_collectApiDataTypes`. Décision :
- **Option A** (recommandée) : ne pas les queuer du tout dans `battery_monitor_service` et `performance_optimizer_service`. `battery_level` et `is_charging` sont déjà envoyés via PATCH `/devices/<id>/`.
- **Option B** : demander au backend de supporter ces types via `/data/collect/`.

---

## 5. Plan d'application recommandé (ordre)

| Ordre | Bug | Effort | Débloquage |
|---|---|---|---|
| 1 | #3.1 — Manifest Android 13+ permissions | XS (5 min) | Préalable obligatoire |
| 2 | #3.2 — `_getPermissionsStatus()` honnête | S (15 min) | Visibilité backend |
| 3 | #3.3 — `CallsCollectorPlugin.kt` LIMIT | M (30 min) | **Liste appels** |
| 4 | #3.6 — `INSERT OR IGNORE` Drift | XS (5 min) | Logs propres |
| 5 | #3.4 — Scanner MediaStore (nouveau plugin + collecteur) | L (2-3 h) | **Liste médias** |
| 6 | #3.5 — Fallback dans media_collector | S (10 min) | Résilience permissions |

Après les fixes #3.1 → #3.3, **les appels devraient apparaître** côté monitor_app. Après les fixes #3.4 → #3.5, **les médias devraient apparaître** côté monitor_app.

---

## 6. Tests de validation end-to-end après application

### Test global
1. Reset complet : désinstaller monitored_app, le réinstaller avec tous les fixes appliqués
2. Sur le device HONOR NLA-LX2P, accorder explicitement toutes les permissions :
   - SMS, Phone, Call Log
   - Location (Always)
   - Camera, Microphone
   - Photos + Videos + Audio (Android 13+)
   - Contacts
   - Usage data access (Settings spécial)
3. Pairing avec le code généré par monitor_app
4. Attendre 5 minutes

### Validations attendues côté monitor_app
| Écran | Endpoint | Résultat attendu |
|---|---|---|
| SMS/Conversations | `/messages/conversations/?device_id=...` | ≥ 17 conversations |
| Détail conversation | `/messages/conversations/<id>/messages/` | liste de messages réelle |
| Appels | `/calls/?device=...` | `count >= 1` si historique sur l'appareil |
| Détail appel | `/calls/<id>/` | détail correctement affiché (pas de crash) |
| Apps liste | `/app_usage/app-info/?device_id=...` | ≥ 4 apps |
| Détail app usage | `/devices/<id>/apps/<app_id>/usage/` | ≥ 1 enregistrement après quelques minutes |
| Médias | `/media/?device=...&media_type=PHOTO` | `count >= 1` si photos dans la galerie |
| Localisation | `/location/locations/last_known/?device_id=...` | position GPS courante |

### Validations attendues côté monitored_app (logs)
```
[SMS] Bootstrap completed: <N> historical SMS captured.
[Calls] Bootstrap completed: <N> historical calls captured.
[MediaStore] Bootstrap completed: <N> items.
Queued sms data for sync...
Queued calls data for sync...
Queued media_metadata data for sync...
Synced sms batch: ...
Synced calls batch: ...
Synced media_metadata batch: ...
```

**Aucune** trace de :
- `IllegalArgumentException: Invalid token LIMIT`
- `SqliteException(2067): UNIQUE constraint failed`
- `Camera or storage permissions not granted` (sauf si l'utilisateur a vraiment refusé)

---

## 7. Annexe — Liens vers la documentation historique

Pour la traçabilité, les documents intermédiaires créés en cours de débogage restent disponibles :

- `MONITORED_APP_ISSUE_COLLECTORS_DATA_LOSS_20260509.md`
- `MONITORED_APP_ISSUE_INITIAL_HISTORICAL_SYNC_20260510.md`
- `MONITORED_APP_ISSUE_CALLS_KOTLIN_LIMIT_CRASH_20260510.md`
- `MONITORED_APP_ISSUE_REMAINING_BUGS_20260510.md`
- `MONITORED_APP_ISSUE_PERMISSIONS_STATUS_HARDCODED_20260510.md`

Le présent rapport **consolide** et **complète** tous ces documents avec les 3 nouveautés identifiées par l'audit final :
- Manifest Android 13+ permissions manquantes
- Absence de scanner MediaStore (bug fondamental médias)
- Pas de fallback dans `media_collector` quand CAMERA est refusée

---

**Frontend Team Contact** : Eric Vekout (ericvekout@gmail.com)
**Last verified** : 2026-05-10 (code source lu et vérifié pour chaque diagnostic)
