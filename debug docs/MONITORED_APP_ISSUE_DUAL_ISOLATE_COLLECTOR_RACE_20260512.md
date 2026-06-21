# Monitored App Issue — Double exécution des collecteurs (main isolate + BackgroundCollectorService)

**Target Application**: MONITORED_APP (flutter_apps/monitored_app)
**Detected From**: monitor_app (flutter_apps/monitor_app)
**Issue Type**: MONITORED_APP_ISSUE_LIFECYCLE
**Date Created**: 2026-05-12
**Date Revised**: 2026-05-15 (analyse re-validée contre le code réel — voir §0)
**Status**: 🔴 Blocked — implémentation monitored_app requise
**Priority**: High (régression critique : l'appareil surveillé disparaît de monitor_app après jumelage + données jamais à jour)
**Data / Feature Affected**: SMS, Calls, App_info, AppUsage, Location, Media (tous les collecteurs)

---

## Related Issue File
**Cross-dependency** : lié à `BACKEND_ISSUE_BULK_COLLECT_SYNCHRONOUS_SATURATION_20260512.md`.
Les deux correctifs doivent être appliqués. **Ordre recommandé : monitored_app d'abord** (supprime la duplication = ~50 % de charge en moins + plus de double flux parallèle, ce qui à soi seul peut résoudre la régression visible), backend ensuite (robustesse sous charge légitime future).

---

## 0. Corrections par rapport à la version précédente (À LIRE EN PREMIER)

La version initiale de ce rapport contenait des recommandations **partiellement erronées ou insuffisantes**. Cette révision les corrige après lecture du code réel (`MainActivity.kt`, `BackgroundCollectorService.kt`, `lib/background_service_entry.dart`, `lib/core/collectors/sms_collector.dart`, `lib/core/collectors/base_collector.dart`, `lib/core/services/storage_service.dart`, `lib/core/services/data_collector_service.dart`).

| # | Recommandation initiale | Verdict | Correction apportée ici |
|---|---|---|---|
| 6.1 | Retirer les plugins COLLECTEURS de `BackgroundCollectorService.kt` | ⚠️ **Insuffisant** | Retirer les plugins Kotlin ne suffit PAS : l'entrypoint Dart `backgroundServiceEntryPoint` appelle de toute façon `dataCollectorService.startCollectors()` + un `syncData()` périodique (15 min). Il faut traiter la **couche Dart** (propriété unique de la collecte), pas seulement la couche Kotlin. Voir §6.1. |
| 6.2 | Lock single-instance via `SharedPreferences` | ⚠️ **Non fiable** | `SharedPreferences` n'est **pas atomique inter-isolates** (race TOCTOU) et son cache mémoire n'est pas cohérent entre isolates. Lock à baser sur la base Drift (transactionnelle, fichier SQLite unique cohérent inter-isolates). Voir §6.2. |
| 6.3 | « Ajouter la persistance de `bootstrapDone` dans SharedPreferences » | ❌ **Faux — déjà implémenté** | `sms_collector.dart` persiste DÉJÀ `bootstrapDone`/`lastCheckTime` (clés `sms_collector_bootstrap_done`, `sms_collector_last_check_ms`, l.14-16 ; lecture l.38-47 ; écriture l.190-198). La vraie cause du re-bootstrap = **cache mémoire `SharedPreferences` périmé dans le 2ᵉ isolate**. Correctif réel = `prefs.reload()` avant lecture, OU déplacer l'état dans Drift. Voir §6.3. |
| 6.4 | Augmenter les timeouts Dio (`constants.dart:38-40`) | ✅ **Correct** | Conservé tel quel — lignes confirmées exactes. |
| 6.5 | Plafonner les retries | ⚠️ **Largement déjà présent** | `RetryMechanism` + `retryMechanism.canRetry` + `_maxRetries=3` existent déjà. Affiné en §6.5 (ne garder que le marquage `failed_permanent` si absent). |

---

## 1. Issue Summary

`BackgroundCollectorService.kt` instancie un **second `FlutterEngine`** dont l'entrypoint Dart (`backgroundServiceEntryPoint`) démarre la **suite complète de collecteurs** et un `syncData()` périodique, **en parallèle** des collecteurs déjà actifs dans le `FlutterEngine` de `MainActivity` — ce qui (a) double tout le bootstrap historique, (b) génère deux flux parallèles de `POST /data/collect/bulk/` qui saturent le backend, et (c) empêche monitor_app d'afficher l'appareil surveillé (timeout du GET liste).

---

## 2. Context & When It Occurred

- **Écran monitor_app affecté** : liste des appareils (`lib/features/devices/views/devices_screen.dart` → `DevicesViewModel.loadDevices()` → `GET /api/v1/devices/devices/`).
- **Action déclenchante** : juste après un jumelage réussi, ouverture de la liste des appareils ; simultanément monitored_app lance son premier bootstrap (149 SMS + 140 appels + apps + app_usage).
- **Environnement** : dev (API `http://192.168.1.127:8000`, monitor_app émulateur Android via `10.0.2.2`, monitored_app HONOR NLA-LX2P / Android 15).
- **Fréquence** : 100 % systématique à chaque jumelage suivi d'une première sync, et à chaque démarrage où l'app est au premier plan ET le service de fond tourne.

---

## 3. Expected Behavior (Per Specifications)

D'après `docs/monitor-app-features-guide.md` et l'architecture de référence `lib/core/services/data_collector_service.dart` :

- **Un seul** cycle de collecte par type de donnée par appareil par intervalle configuré (`location: 900s`, `app_usage: 1800s`, etc.).
- Le `BackgroundCollectorService` assure la **continuité** quand l'app est tuée, **sans dupliquer** le travail quand l'app est au premier plan.
- Le bootstrap historique est déclenché **une seule fois**, persisté, et ne se relance pas tant que `bootstrapDone=true`.
- Un seul flux de `POST /data/collect/bulk/` à la fois, séquentiel, avec backoff en cas d'échec.

---

## 4. Actual Behavior (Observed)

### 4.1 Preuve — code (source de vérité)

**`android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/MainActivity.kt` (l.21-34)** enregistre 14 plugins, dont `SmsCollectorPlugin`, `CallsCollectorPlugin`, `AppsCollectorPlugin`, `MediaCapturePlugin`.

**`android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/BackgroundCollectorService.kt` (l.130-143)** enregistre **les 14 mêmes plugins** dans un `FlutterEngine` **distinct** (l.125 `flutterEngine = FlutterEngine(this)`), puis exécute le callback Dart (l.184-190).

**`lib/background_service_entry.dart` (l.45-48 et l.92-118)** — l'entrypoint Dart du service de fond :
```dart
await dataCollectorService.initialize();
await websocketService.connect();
batteryMonitorService.startMonitoring();
await dataCollectorService.startCollectors();          // ← collecte COMPLÈTE
...
Timer.periodic(const Duration(minutes: 15), (_) async {
  ...
  await collector.syncData();                          // ← sync périodique
});
```
→ Le second isolate ne fait pas que « du natif utile en fond » : il **relance toute la collecte et la sync**. C'est la cause réelle de la duplication, **indépendante** des plugins Kotlin enregistrés.

### 4.2 Preuve — guard de sync non partagé entre isolates

`lib/core/services/data_collector_service.dart:347-348` :
```dart
Future<void> _syncData() async {
  if (_isSyncing || _syncQueue.isEmpty) return;   // _isSyncing = bool EN MÉMOIRE
```
`_isSyncing` (l.127) est un booléen d'instance : il protège **dans un isolate**, jamais **entre** les deux isolates → deux `_syncData()` parallèles, deux `ApiClient` Dio, deux files → flux bulk parallèles.

### 4.3 Preuve — re-bootstrap : cause = cache SharedPreferences périmé (pas absence de persistance)

`lib/core/collectors/sms_collector.dart` :
- l.14-16 : clés `sms_collector_last_check_ms`, `sms_collector_bootstrap_done`.
- l.38-47 : `initializeSpecific()` lit `_storageService.getBool(_bootstrapDoneKey)`.
- l.190-198 : persiste `_bootstrapDone=true` + `lastCheckTime`.

`lib/core/services/storage_service.dart:4-25` : `StorageService` encapsule un `SharedPreferences _preferences` **chargé en mémoire à l'init de l'isolate**. Or `SharedPreferences` met les valeurs en cache **au moment du `getInstance()`** et **ne se rafraîchit pas** quand un autre isolate écrit sur le même fichier. Séquence observée :
1. Main isolate bootstrap SMS → écrit `sms_collector_bootstrap_done=true` (disque + son cache).
2. Background isolate a fait son `getInstance()` **avant** cette écriture → son cache mémoire dit encore `false` → **re-bootstrap des 149 SMS / 140 appels**.

→ La persistance existe ; c'est la **cohérence inter-isolates du cache** qui manque.

### 4.4 Conséquence côté monitor_app

`GET /api/v1/devices/devices/` (liste) timeout (le backend mono-thread sync est étranglé par le double flux bulk — voir le rapport backend lié), alors que `GET /api/v1/devices/devices/{id}/` (détail) réussit dans la même session. L'appareil jumelé n'apparaît jamais dans la liste.

### 4.5 Delta exact

| Attendu | Observé |
|---|---|
| 1 isolate collecte | 2 isolates collectent en parallèle (couche Dart, pas seulement Kotlin) |
| Bootstrap SMS 149 × **1** | Bootstrap SMS 149 × **2** (cache prefs périmé dans le 2ᵉ isolate) |
| 1 flux `POST /bulk/` séquentiel | 2 flux `POST /bulk/` parallèles |
| Guard de sync inter-isolates | `_isSyncing` en mémoire, par isolate uniquement |

---

## 5. Monitor App Code Involved

`lib/features/devices/viewmodels/devices_viewmodel.dart:36-45` :
```dart
Future<void> loadDevices() async {
  state = const DevicesState.loading();
  try {
    final devices = await _repository.getDevices();
    state = DevicesState.loaded(_filterDisplayableDevices(devices));
  } catch (e) {
    state = DevicesState.error(e.toString());   // ← timeout backend saturé
  }
}
```
`lib/core/api/safe_connect_api_service.dart` — `getDevices()` appelle `GET /devices/devices/`. **Pourquoi la racine n'est pas monitor_app** : le GET détail (single device) réussit 200 OK dans la même session ; seul le GET liste timeoute, et uniquement pendant la fenêtre de saturation backend corrélée temporellement aux bulks parallèles de monitored_app. monitor_app n'émet aucun POST volumineux.

---

## 6. Required Changes in monitored_app

> **Principe directeur de fiabilité** : la seule garantie « sûre de fonctionner » est qu'**un seul isolate exécute la collecte et la sync à un instant donné**. Tout le reste (timeouts, retries) n'est qu'atténuation. Les §6.1 + §6.3 ci-dessous sont **obligatoires et suffisants** pour la régression ; §6.2/§6.4/§6.5 sont des durcissements.

### 6.1 — Fix principal : un seul propriétaire de la collecte (couche Dart + Kotlin)

**6.1.a — Kotlin** : `BackgroundCollectorService.kt` (l.130-143) — retirer les plugins de collecte redondants ; ne garder que ceux réellement utiles en fond :
```kotlin
flutterEngine?.plugins?.add(BatteryMonitorPlugin())     // statut batterie en fond
flutterEngine?.plugins?.add(MediaStoreScannerPlugin())  // scan média on-demand
flutterEngine?.plugins?.add(UnlockDevicePlugin())       // commande à distance
// NE PAS réenregistrer Sms/Calls/Apps/MediaCapture/Security/Keystore/
// Performance/Permissions/Stealth/AntiTamper/BatteryOptimization ici.
```
*(Réduit le coût natif et la surface de double-collecte, mais ne suffit pas seul — d'où 6.1.b.)*

**6.1.b — Dart (décisif)** : `lib/background_service_entry.dart` — le service de fond ne doit lancer la collecte/sync **que si le main isolate n'est pas déjà propriétaire**. Implémenter une **propriété unique inter-isolates basée sur la base Drift** (voir §6.2 pour le mécanisme de lease). Concrètement :

```dart
Future<void> initServices() async {
  ...
  await setupBackgroundLocator();
  final ownership = locator<CollectionOwnershipService>(); // nouveau, voir 6.2
  final acquired = await ownership.tryAcquire(
    owner: 'background_isolate',
    ttl: const Duration(minutes: 20),
  );
  if (!acquired) {
    ErrorLogger.logInfo(
      'Background isolate: main isolate owns collection — skipping collectors');
    // Le service reste vivant pour battery/keepalive UNIQUEMENT.
    batteryMonitorService = locator<BatteryMonitorService>()..startMonitoring();
    return; // PAS de startCollectors(), PAS de syncData() périodique
  }
  // Propriétaire confirmé : collecte normale
  await dataCollectorService.initialize();
  ...
}
```
Et **symétriquement** dans le main isolate (point d'entrée principal de l'app, là où `DataCollectorService.startCollectors()` est appelé aujourd'hui) : n'appeler `startCollectors()` qu'après `ownership.tryAcquire(owner: 'main_isolate', ...)`, et libérer le lease (`ownership.release()`) quand l'app passe en arrière-plan / est tuée (via `WidgetsBindingObserver.detached` + handler `stop_service`).

> **Pourquoi c'est sûr** : la propriété est arbitrée par une **transaction Drift** sur un fichier SQLite unique. Les lectures voient toujours les écritures committées des autres isolates (contrairement au cache `SharedPreferences`). Le TTL évite un blocage définitif si un isolate meurt en tenant le lease.

### 6.2 — Lease de propriété inter-isolates (base Drift, PAS SharedPreferences)

Créer `lib/core/services/collection_ownership_service.dart` adossé à une table Drift dédiée :

```dart
// Table Drift (DatabaseService) :
//   collection_lease(id INTEGER PRIMARY KEY CHECK(id=1),
//                    owner TEXT, acquired_at_ms INTEGER)
class CollectionOwnershipService {
  final DatabaseService _db = locator<DatabaseService>();

  Future<bool> tryAcquire({required String owner, required Duration ttl}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.transaction(() async {                 // transaction atomique
      final row = await _db.getCollectionLease();      // SELECT ... LIMIT 1
      final expired = row == null ||
          (now - row.acquiredAtMs) > ttl.inMilliseconds;
      if (row != null && row.owner == owner) {
        await _db.upsertCollectionLease(owner, now);   // renouvellement
        return true;
      }
      if (expired) {
        await _db.upsertCollectionLease(owner, now);   // prise du lease
        return true;
      }
      return false;                                    // autre isolate propriétaire
    });
  }

  Future<void> heartbeat(String owner) =>
      _db.touchCollectionLeaseIfOwner(owner,
          DateTime.now().millisecondsSinceEpoch);

  Future<void> release(String owner) => _db.clearCollectionLeaseIfOwner(owner);
}
```
- Le propriétaire appelle `heartbeat()` toutes les ~5 min (rafraîchit `acquired_at_ms`) tant qu'il collecte.
- TTL recommandé : 20 min (> au plus long intervalle de collecte `app_usage: 1800s` n'est pas atteint ; ajuster si un intervalle dépasse 20 min).
- **Ne PAS** utiliser `SharedPreferences` pour ce lease (non atomique, cache périmé inter-isolates).

> Remplace l'ancien `_isSyncing` purement mémoire : conserver `_isSyncing` comme garde intra-isolate, mais la garde inter-isolate devient le lease Drift.

### 6.3 — Re-bootstrap : forcer la cohérence de lecture (la persistance existe déjà)

**Ne rien ajouter en persistance** (déjà présent). Corriger la **lecture périmée**. Deux options, choisir l'une :

**Option A (minimale, recommandée)** — forcer un `reload()` du backing store avant lecture des flags de bootstrap, dans chaque collecteur (`sms_collector.dart`, `calls_collector.dart`, et tout collecteur lisant un flag persistant). Exemple `sms_collector.dart` `initializeSpecific()` (l.38-47) :
```dart
Future<void> initializeSpecific() async {
  await _storageService.reloadPreferences(); // nouveau wrapper -> SharedPreferences.reload()
  _bootstrapDone = _storageService.getBool(_bootstrapDoneKey) ?? false;
  final lastCheckMs = _storageService.getInt(_lastCheckTimeKey);
  _lastCheckTime = lastCheckMs != null
      ? DateTime.fromMillisecondsSinceEpoch(lastCheckMs)
      : null;
  debugPrint('[SMS] initialized with bootstrapDone=$_bootstrapDone, '
      'lastCheckTime=$_lastCheckTime');
}
```
Ajouter dans `StorageService` :
```dart
Future<void> reloadPreferences() async {
  await SharedPreferences.getInstance().then((p) => p.reload());
  // si _preferences est conservé en champ : ré-affecter l'instance rechargée.
}
```

**Option B (la plus robuste)** — déplacer `bootstrap_done` / `last_check_ms` de chaque collecteur dans une table Drift (cohérence inter-isolates native). Plus de travail mais aligné avec §6.2.

> Avec §6.1 correctement appliqué (un seul isolate collecte), le re-bootstrap disparaît **mécaniquement**. §6.3 reste un filet de sécurité indispensable (ex. transition main→background pendant un bootstrap en cours).

### 6.4 — Timeouts Dio adaptés au bulk

`lib/app/constants.dart:38-40` (lignes confirmées exactes) :
```dart
static const int connectTimeout = 15000;  // 15s — inchangé
static const int receiveTimeout = 60000;  // 60s — le backend bulk peut être lent
static const int sendTimeout    = 30000;  // 30s — upload bulk volumineux
```

### 6.5 — Plafond de retry (l'essentiel existe déjà)

`RetryMechanism` + `retryMechanism.canRetry` + `_maxRetries=3` (`base_collector.dart:38`) sont déjà en place. **Seul ajout requis** : si un même `batchId` épuise ses retries (`!retryMechanism.canRetry`), le marquer `failed_permanent` en base Drift (au lieu de le re-queuer indéfiniment), loguer une alerte, **ne pas supprimer** l'item. Vérifier dans `_sendDataBatchWithRetry` / `_sendOptimizedBulkBatch` qu'aucun chemin ne re-enfile un batch après épuisement.

---

## 7. Temporary Workaround in monitor_app (déjà appliqué)

Voir §9 : monitor_app a été durci (retry/backoff borné + timeout lecture 45s + message d'erreur clair). Cela évite la dégradation UX mais **ne corrige pas** la cause racine (duplication d'isolates). À conserver de toute façon.

---

## 8. Verification Steps

### 8.1 monitored_app
1. `adb logcat -c` puis `adb shell am force-stop` + relance.
2. `adb logcat -d | findstr /i "bootstrapDone Bootstrap completed"` → `bootstrapDone=true` après le 1ᵉʳ bootstrap ; **aucune** ligne `Bootstrap completed: 149 ...` en double dans la même run.
3. `adb logcat -d | findstr "POST.*collect/bulk"` → REQUEST/RESPONSE **séquentiels** (jamais 2 REQUEST sans RESPONSE intercalée).
4. App au premier plan + service de fond actif simultanément → un seul isolate logue `startCollectors` ; l'autre logue `main isolate owns collection — skipping`.
5. `adb shell am force-stop` (app tuée) → après ≤ 1 min, le background isolate **acquiert** le lease et reprend la collecte sans re-bootstrap complet.

### 8.2 backend (corrélation)
`findstr /i "took too long to shut down" safeconnect_dev.log` → 0 occurrence (ou < 3 / 10 min).

### 8.3 monitor_app (résultat final)
1. Jumeler un appareil → ouvrir la liste → appareil visible en < 5 s.
2. Détail appareil → SMS / Calls / Apps / Location se remplissent dans les 2 min suivant le jumelage.

### 8.4 End-to-end
Reboot appareil surveillé → `BootCompletedReceiver` relance le service → aucun bootstrap répété si la base Drift contient déjà l'historique.

---

## 9. Monitor App Actions Already Completed

**Statut** : ✅ Durcissement appliqué (mitigation UX), backend/monitored_app restent bloquants pour le fond.

**Fichiers modifiés** :
- `lib/core/api/safe_connect_api_service.dart`

**Changements** :
- `receiveTimeout` 30s → **45s** (laisse Daphne reprendre la main entre deux vagues bulk).
- Nouveau `_getWithTransientRetry()` : retry borné (3 tentatives, backoff 2s puis 4s) sur erreurs réseau transitoires (`connectionTimeout`/`receiveTimeout`/`sendTimeout`/`connectionError`) **uniquement** pour `GET /devices/devices/`. Les erreurs HTTP 4xx/5xx ne sont jamais retentées.
- `_handleDioException` : message clair en français pour les erreurs réseau sans réponse (au lieu du message Dio brut en anglais affiché tel quel à l'utilisateur).

**Avant / Après** : avant, un seul timeout à 30s → écran d'erreur avec texte anglais Dio. Après, jusqu'à ~3 tentatives espacées + message FR explicite ; l'appareil s'affiche dès que le backend répond.

**Validation** : `flutter analyze lib/core/api/safe_connect_api_service.dart` → *No issues found*.

**Dépendance restante** : la fraîcheur des données et la disparition de la régression à la racine dépendent de §6.1+§6.3 (monitored_app) et du rapport backend lié.

---

## 10. Pointeurs précis dans le code (référence rapide)

| Élément | Fichier | Ligne |
|---|---|---|
| Plugins main isolate | `android/.../MainActivity.kt` | 21-34 |
| Plugins background isolate (à réduire) | `android/.../BackgroundCollectorService.kt` | 130-143 |
| Entrypoint Dart fond (collecte+sync à conditionner) | `lib/background_service_entry.dart` | 45-48, 92-118 |
| Guard sync mémoire (à compléter par lease Drift) | `lib/core/services/data_collector_service.dart` | 127, 347-348 |
| Persistance bootstrap (DÉJÀ présente) | `lib/core/collectors/sms_collector.dart` | 14-16, 38-47, 190-198 |
| Backing store non cohérent inter-isolates | `lib/core/services/storage_service.dart` | 4-25 |
| RetryMechanism / maxRetries (déjà présent) | `lib/core/collectors/base_collector.dart` | 38, 43 |
| Timeouts Dio | `lib/app/constants.dart` | 38-40 |

---

**Fin du rapport.** Document autonome. Les §6.1 (propriété unique Dart+Kotlin) et §6.3 (cohérence de lecture) sont **obligatoires** pour résoudre la régression ; §6.2 fournit le mécanisme de lease fiable ; §6.4/§6.5 sont des durcissements. Appliquer monitored_app **avant** le backend.
