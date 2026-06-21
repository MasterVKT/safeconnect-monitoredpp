# Rapport Final Consolidé — monitored_app (Android/Flutter)
# XP SafeConnect — Problèmes et Solutions

**Date** : 2026-05-11
**Projet cible** : monitored_app (`H:\Projects\XP SafeConnect\flutter_apps\monitored_app\`)
**Auteur** : Audit multi-sessions 2026-05-09 → 2026-05-11
**Statut général** : 🔴 8 bugs actifs — dont 4 critiques bloquants

---

## Synthèse exécutive

L'application monitored_app souffre de 8 bugs regroupés en 3 catégories :

1. **Collecte** : les données sont lues depuis l'appareil mais perdues avant d'atteindre le backend (calls sans `recorded_at`, double-queueing, apps jamais queueées)
2. **Transport** : la logique de sync marque les items comme "synced" sans vérifier que le backend les a réellement acceptés
3. **Accès natif** : le plugin MediaStore n'est pas enregistré dans le bon contexte, les permissions Android 13+ sont absentes du manifeste, le plugin CallLog crashe sur ContentResolver

Le fix #4 (1 ligne Kotlin) et le fix #5 (2 lignes Dart) sont les plus rapides. Le fix #3 et #1/#2 débloquent les appels. Le fix #7/#8 débloquent les médias.

---

## Plan d'application recommandé (ordre de priorité)

| # | Bug | Fichier | Effort | Impact |
|---|---|---|---|---|
| 1 | `AndroidManifest` permissions Android 13+ manquantes | `AndroidManifest.xml` | 5 min | Prérequis médias |
| 2 | `CallsCollectorPlugin` LIMIT invalide dans sortOrder | `CallsCollectorPlugin.kt:157` | 30 min | Débloque lecture appels |
| 3 | `recorded_at` absent du payload calls | `database_service.dart:148-198` | 20 min | Débloque sync appels |
| 4 | Plugin `MediaStoreScannerPlugin` absent de `BackgroundCollectorService` | `BackgroundCollectorService.kt:133` | 2 min | Débloque médias |
| 5 | `_sendDataBatch` marque synced sans vérifier `error_count` | `data_collector_service.dart:497` | 30 min | Élimine data loss silencieux |
| 6 | `insertCallData` double-queue les appels | `calls_collector.dart:252` | 20 min | Nettoie architecture |
| 7 | `insertAppData` ne queue jamais les apps installées | `database_service.dart:301-331` | 30 min | Débloque sync apps |
| 8 | `INSERT` sans `insertOrIgnore` dans Drift | `database_service.dart` (plusieurs) | 20 min | Supprime exceptions au restart |

---

## Bug #1 — `AndroidManifest.xml` : permissions Android 13+ manquantes

**Statut** : 🔴 CRITIQUE — bloque l'accès à la galerie sur tout appareil Android 13+ (API 33+)

**Fichier** : `android/app/src/main/AndroidManifest.xml`

### Description

Sur Android 13+ (API 33+), `READ_EXTERNAL_STORAGE` ne couvre plus l'accès aux médias. Trois permissions granulaires le remplacent. Sur le HONOR NLA-LX2P (Android 15, API 35), l'app ne peut PAS lire la galerie même si l'utilisateur accorde toutes les permissions visibles, car les permissions correctes ne sont pas déclarées dans le manifeste.

### Fix

```xml
<!-- AVANT — permissions actuelles dans AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- APRÈS — ajouter ces 4 lignes -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />   <!-- Garder pour Android ≤ 12 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### Validation

Après modification :
1. Désinstaller l'app et réinstaller (les permissions déclarées changent)
2. Sur Android 13+ : le dialogue de permission doit demander "Accès aux photos" et "Accès aux vidéos" séparément
3. Après accord : MediaStore doit retourner les fichiers existants

---

## Bug #2 — `CallsCollectorPlugin.kt:157` : LIMIT invalide dans ContentResolver

**Statut** : 🔴 CRITIQUE — peut crasher ou retourner 0 appels sur certains appareils

**Fichier** : `android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/CallsCollectorPlugin.kt`

### Description

La ligne 157 construit le `sortOrder` pour `ContentResolver.query()` en y insérant une clause `LIMIT` :

```kotlin
// LIGNE 157 — BUG
val sortOrder = "${CallLog.Calls.DATE} ASC LIMIT $safeLimit"
```

Le fournisseur `CallLog` d'Android (`content://call_log/calls`) n'accepte pas `LIMIT` dans le paramètre `sortOrder` de `ContentResolver.query()`. Cela peut provoquer une `IllegalArgumentException` ou retourner simplement 0 résultats selon le fabricant.

**Note** : `SmsCollectorPlugin.kt:136` a la même structure mais fonctionne par chance (le fournisseur SMS est plus permissif sur certains appareils). Appliquer le même fix par cohérence.

### Fix

**Pour API 26+ (Android 8+)** : utiliser `ContentResolver.QUERY_ARG_LIMIT` via un `Bundle`.
**Pour API < 26** : tronquer les résultats côté Kotlin après la query.

```kotlin
// AVANT (bug — ligne 157)
val sortOrder = "${CallLog.Calls.DATE} ASC LIMIT $safeLimit"
val cursor = contentResolver.query(CallLog.Calls.CONTENT_URI, projection, selection, null, sortOrder)

// APRÈS (correct)
val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    val queryArgs = Bundle().apply {
        putString(ContentResolver.QUERY_ARG_SORT_COLUMNS, CallLog.Calls.DATE)
        putInt(ContentResolver.QUERY_ARG_SORT_DIRECTION, ContentResolver.QUERY_SORT_DIRECTION_ASCENDING)
        putInt(ContentResolver.QUERY_ARG_LIMIT, safeLimit)
        if (!selection.isNullOrEmpty()) {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
        }
    }
    contentResolver.query(CallLog.Calls.CONTENT_URI, projection, queryArgs, null)
} else {
    // API < 26 : query sans LIMIT, tronquer manuellement
    val sortOrder = "${CallLog.Calls.DATE} ASC"
    contentResolver.query(CallLog.Calls.CONTENT_URI, projection, selection, null, sortOrder)
}

// Après la boucle de lecture du cursor, tronquer si API < 26 :
val results = mutableListOf<Map<String, Any?>>()
cursor?.use { c ->
    while (c.moveToNext() && results.size < safeLimit) {
        results.add(readCallLogRow(c))  // votre méthode existante de lecture
    }
}
```

**Même fix à appliquer dans `SmsCollectorPlugin.kt:136`** (en utilisant `Telephony.Sms.CONTENT_URI` et `Telephony.Sms.DATE`).

### Validation

```bash
# Sur l'appareil, déclencher une collecte manuelle et vérifier les logs :
adb logcat | grep -i "calls"
# Attendu : "Collected X calls" avec X > 0
# Avant fix : possiblement "Collected 0 calls" ou crash IllegalArgumentException
```

---

## Bug #3 — `database_service.dart:148-198` : `recorded_at` absent du payload calls

**Statut** : 🔴 CRITIQUE — 100% des appels rejetés par le backend

**Fichier** : `lib/core/services/database_service.dart`

### Description

La méthode `insertCallData()` ne prend pas de paramètre `recordedAt`. Quand elle appelle `queueDataForSync('calls', {...})`, le map n'inclut pas le champ `recorded_at`. Le backend l'exige strictement (`required=True` par défaut), ce qui fait rejeter 100% des appels.

**Signature actuelle (lignes 148-159) — MANQUE `recordedAt`** :
```dart
Future<void> insertCallData({
  required String deviceId,
  required String callType,
  required String phoneNumber,
  String? contactName,
  required DateTime startTime,
  DateTime? endTime,
  int duration = 0,
  bool isVideoCall = false,
  int? simSlot,
  bool isConference = false,
  // ❌ MANQUE : required DateTime recordedAt,
}) async {
```

**Map `queueDataForSync` actuel (lignes 184-198) — MANQUE `recorded_at`** :
```dart
await queueDataForSync(
    'calls',
    {
      'device_id': deviceId,
      'call_type': callType,
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': duration,
      'is_video_call': isVideoCall,
      'sim_slot': simSlot,
      'is_conference': isConference,
      // ❌ MANQUE : 'recorded_at': recordedAt.toIso8601String(),
    },
    priority: 1);
```

### Fix — Étendre la signature et le map

**Étape 1** : Ajouter `recordedAt` à la signature de `insertCallData` :

```dart
Future<void> insertCallData({
  required String deviceId,
  required String callType,
  required String phoneNumber,
  String? contactName,
  required DateTime startTime,
  DateTime? endTime,
  int duration = 0,
  bool isVideoCall = false,
  int? simSlot,
  bool isConference = false,
  DateTime? recordedAt,  // ← AJOUT (nullable pour rétrocompatibilité)
}) async {
```

**Étape 2** : Inclure `recorded_at` dans le map `queueDataForSync` :

```dart
await queueDataForSync(
    'calls',
    {
      'device_id': deviceId,
      'call_type': callType,
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': duration,
      'is_video_call': isVideoCall,
      'sim_slot': simSlot,
      'is_conference': isConference,
      'recorded_at': (recordedAt ?? startTime).toIso8601String(),  // ← AJOUT avec fallback
    },
    priority: 1);
```

**Étape 3** : Mettre à jour les appelants de `insertCallData`. Le principal est dans `calls_collector.dart:252` — voir Bug #6 ci-dessous pour le traitement combiné.

### Validation

Après fix, déclencher un cycle de sync et vérifier les logs backend :
```
✅ Attendu : "processed_count": 50, "error_count": 0
❌ Avant fix : "processed_count": 0, "error_count": 50
```

---

## Bug #4 — `BackgroundCollectorService.kt` : `MediaStoreScannerPlugin` non enregistré

**Statut** : 🔴 CRITIQUE — `MissingPluginException` sur tous les appels MediaStore depuis le background service

**Fichier** : `android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/BackgroundCollectorService.kt`

### Description

**Important** : Le plugin `MediaStoreScannerPlugin.kt` EXISTE déjà et est correctement enregistré dans `MainActivity.kt:26`. Ce n'est PAS un bug de création de plugin.

`BackgroundCollectorService` crée sa **propre `FlutterEngine`** (ligne 125) pour exécuter le code Dart en arrière-plan. Cette FlutterEngine secondaire n'hérite pas des plugins enregistrés dans `MainActivity`. Quand `MediaStoreCollector` (Dart) s'exécute dans l'isolate du background service et appelle `_channel.invokeMethod('checkReadPermissions')` sur le channel `com.xpsafeconnect.monitored_app/mediastore_scanner`, aucun handler n'existe dans cette FlutterEngine → `MissingPluginException`.

**Code actuel (lignes 125-133)** :
```kotlin
flutterEngine = FlutterEngine(this)

// Register plugins
flutterEngine?.plugins?.add(SmsCollectorPlugin())
flutterEngine?.plugins?.add(CallsCollectorPlugin())
flutterEngine?.plugins?.add(AppsCollectorPlugin())
flutterEngine?.plugins?.add(MediaCapturePlugin())
flutterEngine?.plugins?.add(BatteryMonitorPlugin())
flutterEngine?.plugins?.add(UnlockDevicePlugin())
// ❌ MANQUE : MediaStoreScannerPlugin() et 7 autres
```

### Fix — Ajouter les plugins manquants (1 ligne minimum, 8 lignes recommandées)

**Fix minimal** (1 ligne — débloque MediaStore) :
```kotlin
flutterEngine?.plugins?.add(UnlockDevicePlugin())
flutterEngine?.plugins?.add(MediaStoreScannerPlugin())  // ← AJOUT
```

**Fix complet recommandé** (8 lignes — prévient les MissingPluginException futurs) :

Les 8 plugins enregistrés dans `MainActivity` mais absents de `BackgroundCollectorService` :

```kotlin
// À ajouter après la ligne 133 (dernier plugin existant) :
// Synchroniser avec les plugins enregistrés dans MainActivity
flutterEngine?.plugins?.add(MediaStoreScannerPlugin())
flutterEngine?.plugins?.add(BatteryOptimizationPlugin())
flutterEngine?.plugins?.add(SecurityPlugin())
flutterEngine?.plugins?.add(KeystorePlugin())
flutterEngine?.plugins?.add(PerformancePlugin())
flutterEngine?.plugins?.add(PermissionsPlugin())
flutterEngine?.plugins?.add(StealthPlugin())
flutterEngine?.plugins?.add(AntiTamperPlugin())
```

**Ajouter un commentaire** pour éviter que cette désynchronisation se reproduise :
```kotlin
// IMPORTANT: Keep in sync with MainActivity plugin registration.
// BackgroundCollectorService uses its own FlutterEngine and does NOT
// inherit plugins from MainActivity. Any plugin called from Dart
// background code must be registered here too.
```

### Tableau complet des plugins manquants

| Plugin | MainActivity | BackgroundCollectorService | Risque |
|---|---|---|---|
| `MediaStoreScannerPlugin` | ✅ | ❌ | **Confirmé bloquant** — MissingPluginException |
| `BatteryOptimizationPlugin` | ✅ | ❌ | MissingPluginException latent |
| `SecurityPlugin` | ✅ | ❌ | MissingPluginException latent |
| `KeystorePlugin` | ✅ | ❌ | MissingPluginException latent |
| `PerformancePlugin` | ✅ | ❌ | MissingPluginException latent |
| `PermissionsPlugin` | ✅ | ❌ | MissingPluginException latent |
| `StealthPlugin` | ✅ | ❌ | MissingPluginException latent |
| `AntiTamperPlugin` | ✅ | ❌ | MissingPluginException latent |

### Validation

```bash
adb logcat | grep -i "MissingPlugin"
# Attendu après fix : aucune ligne
# Avant fix : "MissingPluginException for mediastore_scanner"
```

---

## Bug #5 — `data_collector_service.dart:497` : `_sendDataBatch` ignore `error_count`

**Statut** : 🔴 CRITIQUE — data loss silencieux et irréversible

**Fichier** : `lib/core/services/data_collector_service.dart`

### Description

La méthode `_sendDataBatch()` considère un batch comme "réussi" basé **uniquement** sur le code HTTP de la réponse. Elle n'inspecte pas le corps JSON pour vérifier `error_count`. Résultat : quand le backend retourne HTTP 200 avec `{"processed_count": 0, "error_count": 50}`, monitored_app marque quand même tous les 50 items comme synchronisés → perte définitive.

**Ligne 497 (bug)** :
```dart
return _isSuccessfulCollectStatusCode(response.statusCode);
// ↑ retourne true si HTTP 200/201/207, sans lire le body
```

**Ligne 426-434 (conséquence)** :
```dart
final success = await _sendDataBatch(dataType, batch, deviceId);
if (success) {
  await _markItemsSynced(batch.map((e) => e.id).toList());
  // ↑ Marque synced MÊME si error_count == 50
}
```

### Fix

```dart
// AVANT (bug — ligne 497)
Future<bool> _sendDataBatch(String dataType, List<SyncQueueItem> batch, String deviceId) async {
  try {
    final response = await _apiClient.post('/api/v1/data/collect/', data: payload);
    return _isSuccessfulCollectStatusCode(response.statusCode);  // ❌
  } catch (e) {
    return false;
  }
}

// APRÈS (correct)
Future<bool> _sendDataBatch(String dataType, List<SyncQueueItem> batch, String deviceId) async {
  try {
    final response = await _apiClient.post('/api/v1/data/collect/', data: payload);

    if (!_isSuccessfulCollectStatusCode(response.statusCode)) {
      return false;
    }

    // Vérifier aussi le corps JSON
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final errorCount = responseData['error_count'] as int? ?? 0;
      final processedCount = responseData['processed_count'] as int? ?? 0;

      if (errorCount > 0) {
        debugPrint(
          '[DataCollector] Batch $dataType: $processedCount synced, $errorCount rejected by backend'
        );
        // Log item_errors si disponible (après fix backend)
        final itemErrors = responseData['item_errors'];
        if (itemErrors != null) {
          debugPrint('[DataCollector] Errors: $itemErrors');
        }
      }

      // Considérer succès seulement si au moins 1 item traité, OU si batch était vide
      return processedCount > 0 || batch.isEmpty;
    }

    return true;
  } catch (e) {
    return false;
  }
}
```

**Note** : Ce fix seul ne résout pas le bug `recorded_at` (Bug #3), mais il évite que les items soient marqués synced quand ils échouent, quelle que soit la raison. Les items resteront dans la queue et seront retentés au prochain cycle.

### Validation

Sans fix backend (Bug #1 rapport backend) + avec ce fix Dart : les 50 appels doivent rester dans la sync queue après le cycle, et être retentés indéfiniment (non perdus).

---

## Bug #6 — `calls_collector.dart:232-280` : double-queueing des appels

**Statut** : 🟡 NON BLOQUANT mais cause des race conditions et du travail en double

**Fichier** : `lib/core/collectors/calls_collector.dart`

### Description

Les appels sont queueés **deux fois** par cycle de collecte, via deux chemins de code différents :

**Path A — via `insertCallData` (ligne 252)** → queue SANS `recorded_at` :
```
_convertCallData() ligne 232
  → _databaseService.insertCallData(...) ligne 252
    → queueDataForSync('calls', {...sans recorded_at...}, priority: 1)
```

**Path B — via `processData` → `_storeInDatabase` (base_collector.dart:191)** → queue AVEC `recorded_at` :
```
_convertCallData() ligne 232
  → retourne map AVEC 'recorded_at': startTime.toIso8601String() (ligne 272)
collectData() retourne la liste
processData(callData)
  → _storeInDatabase(processedData)
    → queueDataForSync(dataType, item)  // AVEC recorded_at
```

**Logs confirmant le double-queueing** :
```
I/flutter: Queued calls data for sync with priority 1   ← Path A
I/flutter: Queued calls data for sync with priority 1   ← Path B
```

### Fix

Supprimer l'appel direct à `_databaseService.insertCallData()` dans `_convertCallData()` et laisser `processData` être l'unique chemin vers la DB+queue.

```dart
// AVANT (ligne 232-280 de calls_collector.dart)
Map<String, dynamic> _convertCallData(CallLogEntry callEntry) {
  // ... conversion ...
  
  // ❌ SUPPRIMER cet appel direct — cause le double-queueing
  _databaseService.insertCallData(
    deviceId: deviceId,
    callType: callEntry.callType,
    // ... autres champs SANS recordedAt ...
  );
  
  // Retourner le map (qui sera traité par processData → Path B)
  return {
    'call_type': callEntry.callType,
    // ...
    'recorded_at': startTime.toIso8601String(),  // ← correct
  };
}

// APRÈS (supprimer uniquement l'appel insertCallData, garder le return)
Map<String, dynamic> _convertCallData(CallLogEntry callEntry) {
  // ... conversion ...
  
  // ✅ Pas d'appel direct à insertCallData — laisser processData gérer tout
  
  return {
    'call_type': callEntry.callType,
    // ...
    'recorded_at': startTime.toIso8601String(),
  };
}
```

**Note** : Après ce fix, `insertCallData` dans `database_service.dart` peut être gardé pour d'éventuels autres usages, mais n'est plus appelé dans ce flow. Le Bug #3 (extension de la signature) reste utile pour assurer la cohérence de `insertCallData` si elle est utilisée ailleurs.

### Validation

Après fix : les logs ne doivent plus afficher deux lignes "Queued calls data" consécutives pour le même item.

---

## Bug #7 — `database_service.dart:301-331` : apps installées jamais synchronisées

**Statut** : 🟡 NON BLOQUANT mais fonctionnalité partiellement absente

**Fichier** : `lib/core/services/database_service.dart`

### Description

La méthode `insertAppData()` (lignes 301-331) stocke les données d'apps dans la table locale `appDataTable` via Drift mais **n'appelle jamais** `queueDataForSync`. La liste des 160 apps installées n'est donc jamais envoyée au backend.

**Code actuel (bug)** :
```dart
Future<void> insertAppData({...}) async {
  try {
    final appData = AppDataTableCompanion(...);
    await _database
        .into(_database.appDataTable)
        .insert(appData, mode: InsertMode.insertOrReplace);
    // ❌ AUCUN appel à queueDataForSync
  } catch (e) {
    debugPrint('Error inserting app data: $e');
  }
}
```

**Conséquence** : `GET /api/v1/app-usage/app-info/` ne retourne que les apps avec des enregistrements d'usage (créées automatiquement par `_process_app_usage_data` côté backend), jamais la liste complète des 160 apps installées.

### Fix

```dart
Future<void> insertAppData({
  required String packageName,
  required String appName,
  String? versionName,
  int? versionCode,
  bool isSystemApp = false,
  DateTime? installDate,
}) async {
  try {
    final appData = AppDataTableCompanion(
      packageName: Value(packageName),
      appName: Value(appName),
      versionName: Value(versionName),
      versionCode: Value(versionCode),
      isSystemApp: Value(isSystemApp),
      installDate: Value(installDate),
    );
    await _database
        .into(_database.appDataTable)
        .insert(appData, mode: InsertMode.insertOrReplace);

    // ✅ AJOUT : queuer pour synchronisation avec le backend
    await queueDataForSync('app_info', {
      'package_name': packageName,
      'app_name': appName,
      'version_name': versionName,
      'version_code': versionCode,
      'is_system_app': isSystemApp,
      'install_date': installDate?.toIso8601String(),
    });
  } catch (e) {
    debugPrint('Error inserting app data: $e');
  }
}
```

**Prérequis backend** : Le backend doit implémenter `_process_app_info_data` pour accepter le type `app_info` (voir rapport backend, Amélioration #3).

### Validation

Après fix côté monitored_app ET backend :
```bash
curl -X GET http://<backend>/api/v1/app-usage/app-info/?device=<uuid> \
  -H "Authorization: Bearer <token>"
# Attendu : count: 160 (ou le nombre d'apps installées)
# Avant fix : count basé uniquement sur les apps avec usage enregistré
```

---

## Bug #8 — `database_service.dart` : `INSERT` sans `insertOrIgnore` dans Drift

**Statut** : 🟡 NON BLOQUANT mais cause des exceptions dans les logs à chaque restart

**Fichier** : `lib/core/services/database_service.dart` (plusieurs méthodes)

### Description

Certaines méthodes d'insertion Drift utilisent `insert()` sans spécifier le mode de résolution des conflits. Lors des restarts de l'app ou des cycles de collecte qui re-traitent les mêmes données, les doublons causent des `SqliteException(2067)` (UNIQUE constraint failed).

**Exemple typique** :
```dart
// Bug — lève SqliteException si doublon
await _database.into(smsDataTable).insert(sms);

// Fix
await _database.into(smsDataTable).insert(sms, mode: InsertMode.insertOrIgnore);
```

### Fix — Appliquer `insertOrIgnore` à toutes les tables concernées

| Méthode | Table | Ligne approximative | Action |
|---|---|---|---|
| `insertSmsData` | `smsDataTable` | ~ligne 80 | Remplacer `insert(sms)` par `insert(sms, mode: InsertMode.insertOrIgnore)` |
| `insertCallData` | `callDataTable` | ~ligne 163 | Idem |
| `insertLocationData` | `locationDataTable` | - | Idem |
| `insertAppData` | `appDataTable` | ~ligne 312 | Idem (déjà `insertOrReplace` — correct) |

**Note** : `insertOrReplace` (utilisé dans `insertAppData`) convient aussi. `insertOrIgnore` est préférable quand on ne veut pas écraser les données existantes.

### Validation

```bash
adb logcat | grep -i "SqliteException"
# Attendu après fix : aucune ligne
# Avant fix : "SqliteException(2067): UNIQUE constraint failed" à chaque restart
```

---

## Contexte : Fixes déjà appliqués (référence)

Les éléments suivants ont été corrigés en sessions précédentes et **fonctionnent correctement** :

| Fix | Fichier | Statut |
|---|---|---|
| Bootstrap historique SMS (`bootstrapDone` + `lastCheckTime` persistants) | `sms_collector.dart` | ✅ 143 SMS historiques récupérés, 17+ conversations visibles |
| `_handleMethodCall('onCallStateChanged')` corrigé | `calls_collector.dart` | ✅ Déclenche `_checkForNewCalls()` au lieu de convertir |
| `_getPermissionsStatus()` hardcodé corrigé | `device_service.dart:445` | ✅ Confirmé corrigé par l'utilisateur |
| Trailing slashes sur endpoints | `api_endpoints.dart:76-84` | ✅ (côté monitor_app) |
| URL `/calls/device/$deviceId/statistics/` | `call_statistics_service.dart:52` | ✅ (côté monitor_app) |

---

## Résumé des données par type après tous les fixes

| Type de données | État actuel | Après tous les fixes |
|---|---|---|
| SMS | ✅ 143 historiques, 17+ conversations | ✅ Opérationnel |
| Appels | ❌ 0 appels (rejetés backend) | ✅ Débloqué après Bug #2 + #3 |
| Localisation | ⚠️ GPS désactivé sur appareil | Données existantes visibles |
| Apps | ⚠️ Seulement apps avec usage | ✅ 160 apps après Bug #7 |
| Médias | ❌ 0 médias | ✅ Débloqué après Bug #1 + #4 |

---

**Contact Frontend** : Eric Vekout (ericvekout@gmail.com)
**Date du rapport** : 2026-05-11 (consolidation finale)
