# Monitored_app Issue — Collecteurs perdent ou rejettent silencieusement des données critiques

**Issue Type**: MONITORED_APP_ISSUE_DATA_LOSS
**Date Created**: 2026-05-09
**Status**: 🔴 Critique — Plusieurs catégories de données ne remontent jamais au backend
**Priority**: Haute
**Project Cible**: **monitored_app** (`H:\Projects\XP SafeConnect\flutter_apps\monitored_app\`)
**Assigné à**: Équipe monitored_app

---

## 1. Issue Summary

L'application surveillée (`monitored_app`) collecte localement plusieurs types de données mais **plusieurs catégories ne remontent jamais au backend** à cause de bugs ou de problèmes de configuration. Conséquence : le `monitor_app` voit des listes vides (`count: 0`) pour les appels, SMS, médias, et n'a aucune mise à jour de localisation ou de batterie via le canal data/collect.

Les seules données qui arrivent actuellement au backend sont :
- ✅ `app_usage` (via `POST /api/v1/data/collect/`)
- ✅ `battery_level`, `is_charging`, `is_online`, `last_seen` (via `PATCH /api/v1/devices/devices/<id>/`)

Tout le reste est perdu ou rejeté.

---

## 2. Context & When It Occurred

**Date** : 2026-05-09
**Appareil testé** : HONOR NLA-LX2P (Android 15, OS 35)
**Action utilisateur** : Jumelage réussi puis ouverture normale de l'application surveillée.
**Environnement** : Backend `http://192.168.1.127:8000/api/v1` ; monitored_app sur device physique en mode debug.

**Logs concernés (extraits)** :
```
I/flutter: Skipping call data with missing type/date
I/flutter: Skipped battery_status sync: data type is not supported by /data/collect API
I/flutter: Error collecting location data: The location service on the device is disabled.
I/flutter: Error from position stream: The location service on the device is disabled.
I/flutter: Cannot start media collection: permissions not granted
I/flutter: Error requesting media permissions: PlatformException(NO_ACTIVITY, No activity available to request permissions, null, null)
I/flutter: Camera or storage permissions not granted
```

**Frequency** : 100% — chaque cycle de collecte génère ces erreurs.

---

## 3. Issues Détaillées

### Issue 3.1 — Bug calls_collector : mauvaise forme de données dans `_handleMethodCall`

**Fichier** : `lib/core/collectors/calls_collector.dart`

**Diagnostic** :

Le handler `_handleMethodCall(MethodCall call)` reçoit deux types d'événements via le `MethodChannel` :

| Source native (Kotlin) | Méthode Dart | Forme du `Map` |
|---|---|---|
| `getNewCalls()` (lecture call log historique) | `collectData()` | `{number, type:int, date:long, duration:long, name, sim_slot, is_conference}` |
| `onCallStateChanged` (live event Telephony) | `_handleMethodCall('onCallStateChanged')` | `{state, number, timestamp}` |

Le code Dart appelle `_convertCallData(callData)` pour les **deux** formes. Or `_convertCallData` attend les clés `type` et `date` :

```dart
Future<Map<String, dynamic>?> _convertCallData(Map<dynamic, dynamic> callData) async {
  final rawType = _readInt(callData['type']);
  final rawDate = _readInt(callData['date']);
  if (rawType == null || rawDate == null) {
    debugPrint('Skipping call data with missing type/date'); // ← ICI
    return null;
  }
  // ...
}
```

Pour les événements `onCallStateChanged`, `type` et `date` n'existent pas → l'événement est jeté.

**Impact** : Les appels en cours (live calls) ne sont **jamais** enregistrés. Seuls les appels historiques détectés lors du polling toutes les 15 minutes par `_checkForNewCalls()` peuvent l'être — mais sur un device sans nouveaux appels depuis le pairing, rien ne remonte.

**Code Kotlin source du bug** : `android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/CallsCollectorPlugin.kt`
```kotlin
override fun onCallStateChanged(state: Int, phoneNumber: String?) {
    super.onCallStateChanged(state, phoneNumber)
    val callData = mapOf(
            "state" to state,        // ← pas "type"
            "number" to (phoneNumber ?: ""),
            "timestamp" to System.currentTimeMillis()  // ← pas "date"
    )
    channel.invokeMethod("onCallStateChanged", callData)
}
```

**Fix proposé** :

Option A (préférée) — Ajouter un convertisseur dédié pour les événements live :

```dart
Future<void> _handleMethodCall(MethodCall call) async {
  switch (call.method) {
    case 'onCallStateChanged':
      final callData = call.arguments as Map<dynamic, dynamic>;
      final processed = await _convertLiveCallEvent(callData);
      if (processed != null) {
        await processData([processed]);
      }
      break;
    default:
      debugPrint('Unknown method: ${call.method}');
  }
}

Future<Map<String, dynamic>?> _convertLiveCallEvent(Map<dynamic, dynamic> data) async {
  final state = _readInt(data['state']);
  final phoneNumber = data['number']?.toString() ?? '';
  final timestamp = _readInt(data['timestamp']);
  if (state == null || timestamp == null) return null;

  // Mapper Telephony state → call_type
  // CALL_STATE_RINGING (1) = INCOMING in progress
  // CALL_STATE_OFFHOOK (2) = OUTGOING/INCOMING active
  // CALL_STATE_IDLE (0) = call ended
  // Live events don't have a final type — skip until call ends or wait for call log
  return null; // Live events are advisory, real recording is via getNewCalls()
}
```

Option B — Faire en sorte que le `getNewCalls()` soit déclenché immédiatement après chaque `onCallStateChanged` pour recharger le call log :

```dart
case 'onCallStateChanged':
  final state = _readInt((call.arguments as Map)['state']);
  if (state == 0 /* IDLE = call ended */) {
    // Trigger fresh poll of call log to capture the just-ended call
    await _checkForNewCalls();
  }
  break;
```

**Recommandation** : **Option B** est plus fiable : le call log Android contient déjà l'entrée quand `state = IDLE` est reçu, donc un poll immédiat capture l'appel.

---

### Issue 3.2 — `battery_status` queué mais rejeté par `/data/collect/`

**Fichier** : `lib/core/services/battery_monitor_service.dart` (ligne ~262)

**Diagnostic** :

```dart
await _databaseService.queueDataForSync('battery_status', reportData, priority: 2);
```

Le service queue ce type de données pour le sync `/data/collect/`. Mais dans `data_collector_service.dart` :

```dart
static const Set<String> _collectApiDataTypes = {
  'location', 'messages', 'sms', 'calls', 'app_usage', 'media', 'media_metadata',
};
// 'battery_status' n'est PAS dans la liste
```

→ `_isCollectApiDataType('battery_status')` retourne `false` → `_markUnsupportedCollectTypeAsHandled('battery_status')` est appelé → les items sont marqués `synced` sans rien envoyer au backend.

**Logs observés** :
```
I/flutter: Queued battery_status data for sync with priority 2
I/flutter: Enhanced battery status reported: 76%, charging: true, health: good
[...]
I/flutter: Skipped battery_status sync: data type is not supported by /data/collect API
```

**Impact** : Les rapports détaillés de batterie (incluant `health`, et probablement température, voltage si Android les expose) sont perdus. Cependant `battery_level` et `is_charging` arrivent bien au backend via le PATCH device. Il n'y a donc PAS de perte critique pour l'historique batterie minimal, mais l'historique enrichi (timestamps, health) est perdu.

**Fix proposé** :

Décider du comportement attendu :

1. **Si l'historique batterie n'est pas requis côté backend** : ne pas queuer `battery_status` du tout. Modifier `battery_monitor_service.dart` pour ne pas appeler `queueDataForSync('battery_status', ...)`. Conserver uniquement la mise à jour via PATCH device.

   ```dart
   // Avant :
   await _databaseService.queueDataForSync('battery_status', reportData, priority: 2);

   // Après :
   // Battery status est envoyé via PATCH /devices/<id>/ (champs battery_level, is_charging).
   // L'historique enrichi (health, timestamps) n'est pas requis par le backend.
   ```

2. **Si l'historique batterie EST requis** : demander au backend de supporter `data_type='battery_status'` dans `/data/collect/`, et ajouter `'battery_status'` dans `_collectApiDataTypes` côté monitored_app.

**Recommandation** : Option 1 (le plus simple, pas de besoin métier identifié pour l'historique enrichi).

---

### Issue 3.3 — SMS collector ne remonte rien (cause à investiguer)

**Fichier** : `lib/core/collectors/sms_collector.dart` (présumé)

**Diagnostic** :

Logs observés :
```
I/flutter: Initializing SMS collector
I/flutter: SMS collector initialized successfully
I/flutter: SMS specific collection started
I/flutter: SMS collector started with interval: 900 seconds
```

Aucun log "Queued sms data" ou "Synced sms batch" n'apparaît, contrairement à `app_usage`. Cela signifie que :
- soit le device n'a aucun SMS (improbable sur device physique)
- soit la lecture du `content://sms` échoue silencieusement
- soit `getNewSms()` côté natif retourne une liste vide

**Action requise** : Ajouter du logging diagnostic dans `sms_collector.dart` pour confirmer :

```dart
@override
Future<List<Map<String, dynamic>>> collectData() async {
  try {
    final smsList = await _channel.invokeMethod<List<dynamic>>(
      'getNewSms',
      {'since': _lastCheckTime.millisecondsSinceEpoch},
    );

    debugPrint('[SMS] getNewSms returned ${smsList?.length ?? 0} entries since $_lastCheckTime');

    if (smsList != null && smsList.isNotEmpty) {
      // ... process
    }
    return [];
  } catch (e) {
    debugPrint('[SMS] Error collecting SMS data: $e'); // ← log explicit error
    return [];
  }
}
```

Et côté Kotlin natif (équivalent de `CallsCollectorPlugin.kt` pour SMS) : vérifier que la requête `content://sms` utilise le bon `selection` et que la permission `READ_SMS` est bien runtime-granted.

---

### Issue 3.4 — Location service désactivé sur le device

**Fichier** : `lib/core/collectors/location_collector.dart`

**Logs observés** :
```
I/flutter: Error collecting location data: The location service on the device is disabled.
I/flutter: Error from position stream: The location service on the device is disabled.
```

**Diagnostic** : Pas un bug de code — le device a sa localisation système désactivée.

**Fix proposé** :

1. Détecter `Geolocator.isLocationServiceEnabled() == false` au démarrage et :
   - Afficher une notification persistante demandant à l'utilisateur d'activer la localisation système
   - OU diriger automatiquement vers `Geolocator.openLocationSettings()`

2. Cacher l'erreur récurrente `Error from position stream: ...` qui pollue les logs : la logger une seule fois et stopper le stream tant que la localisation reste désactivée.

```dart
// Pseudo-code
if (!await Geolocator.isLocationServiceEnabled()) {
  if (!_locationDisabledWarned) {
    _locationDisabledWarned = true;
    debugPrint('[LOCATION] System location services disabled. Stopping collection until re-enabled.');
    await _notificationService.showPersistent(
      title: 'Localisation désactivée',
      body: 'Activez la localisation pour le suivi parental.',
      action: () => Geolocator.openLocationSettings(),
    );
  }
  return; // Don't even try to read position
}
```

---

### Issue 3.5 — Permissions media non accordées (PlatformException NO_ACTIVITY)

**Fichier** : Probablement `lib/core/services/advanced_media_service.dart`

**Logs observés** :
```
I/flutter: Camera or storage permissions not granted
I/flutter: Error requesting media permissions: PlatformException(NO_ACTIVITY, No activity available to request permissions, null, null)
I/flutter: Cannot start media collection: permissions not granted
```

**Diagnostic** : Tentative de demander des permissions via `permission_handler` quand l'app est en background (pas d'activité Android visible). C'est un anti-pattern : `Permission.camera.request()` requiert une activité au premier plan.

**Fix proposé** :

1. Ne demander les permissions caméra/storage que **lors de la première interaction utilisateur** (par exemple à l'ouverture de l'écran de configuration), pas dans `initializeSpecific()` du collecteur.
2. Si les permissions ne sont pas accordées au moment du `start`, logger une fois et désactiver le collecteur silencieusement jusqu'au prochain démarrage.

```dart
@override
Future<bool> checkSpecificPermissions() async {
  final camera = await Permission.camera.status;
  final storage = await Permission.storage.status;
  return camera.isGranted && storage.isGranted;
}

@override
Future<void> requestSpecificPermissions() async {
  // Only request if there's a foreground activity
  if (!await _hasForegroundActivity()) {
    debugPrint('[MEDIA] Skipping permission request — no foreground activity');
    return;
  }
  await [Permission.camera, Permission.storage].request();
}
```

---

## 4. Vérification après fix

### Test 1 — Calls
1. Sur le device surveillé : passer ou recevoir un appel test (n'importe quel numéro), laisser sonner ≥3s, raccrocher.
2. Attendre 16 minutes (cycle de poll), OU déclencher manuellement `_checkForNewCalls()`.
3. **Attendu** : log `[CALLS] Queued calls data for sync` puis `[CALLS] Synced calls batch: 1 items`.
4. Côté monitor_app : `GET /api/v1/calls/?device=<uuid>` retourne `count >= 1`.

### Test 2 — Battery (si Option 1 retenue)
1. Vérifier qu'aucun log `Queued battery_status data for sync` n'apparaît plus.
2. Vérifier que `battery_level` reste correctement mis à jour via PATCH device toutes les ~minutes.

### Test 3 — SMS
1. Envoyer un SMS test au device surveillé.
2. **Attendu** : log `[SMS] getNewSms returned 1 entries` puis `Queued messages data` puis `Synced messages batch`.
3. Côté monitor_app : `GET /api/v1/messages/conversations/?device_id=<uuid>` retourne au moins une conversation.

### Test 4 — Location
1. Activer la localisation système Android.
2. **Attendu** : log `[LOCATION] Position stream started, accuracy=BALANCED, interval=900s`.
3. Côté monitor_app : `GET /api/v1/location/?device=<uuid>` retourne au moins une position.

### Test 5 — Media
1. Ouvrir l'app au premier plan, accorder caméra+storage à la première demande.
2. **Attendu** : log `Media collector started` au prochain cycle.

---

## 5. Frontend Actions Already Completed

**Status** : ✅ Le `monitor_app` est prêt — toutes les routes côté serveur que ces données alimentent fonctionnent et la désérialisation est en place. Tant que le monitored_app ne pousse pas les données, le monitor_app affichera des listes vides.

---

## 6. Résumé des Actions à Mener

| # | Issue | Priorité | Effort | Fichier |
|---|---|---|---|---|
| 3.1 | Calls live event mishandled | 🔴 Haute | S | `calls_collector.dart` (Option B recommandée) |
| 3.2 | battery_status rejeté | 🟡 Basse | XS | `battery_monitor_service.dart` (retirer queue) |
| 3.3 | SMS ne remonte rien | 🔴 Haute | M | `sms_collector.dart` + Kotlin natif |
| 3.4 | Location désactivée | 🟢 UX | S | `location_collector.dart` + UI permissions |
| 3.5 | Media permissions NO_ACTIVITY | 🟡 Moyenne | S | `advanced_media_service.dart` |

---

**Frontend Team Contact** : Eric Vekout (ericvekout@gmail.com)
**Date du rapport** : 2026-05-09
