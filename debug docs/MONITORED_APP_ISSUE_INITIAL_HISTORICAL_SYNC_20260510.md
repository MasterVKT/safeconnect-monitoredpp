# Monitored_app Issue — Aucun bootstrap historique : SMS/calls/médias antérieurs au pairing ne sont jamais synchronisés

**Issue Type**: MONITORED_APP_ISSUE_BOOTSTRAP_MISSING
**Date Created**: 2026-05-10
**Status**: 🔴 Critique — L'utilisateur voit toujours des listes vides côté monitor_app pour SMS/calls/médias
**Priority**: Haute
**Project Cible**: **monitored_app** (`H:\Projects\XP SafeConnect\flutter_apps\monitored_app\`)
**Assigné à**: Équipe monitored_app

---

## 1. Issue Summary

Les collecteurs `SmsCollector`, `CallsCollector` (et probablement médias) initialisent `_lastCheckTime = DateTime.now()` à la construction. Tous les filtres natifs (`getNewSms`, `getNewCalls`) utilisent ce timestamp pour filtrer `content://sms` et `CallLog.Calls`. Conséquence : **aucun SMS, appel ou média antérieur au moment du jumelage n'est jamais remonté au backend**, même s'ils existent sur l'appareil depuis des mois.

De plus, `_lastCheckTime` n'est **jamais persisté** : à chaque redémarrage de l'application, le pointeur reset à `now()`, ce qui peut aussi faire perdre les SMS arrivés pendant que l'app était fermée.

---

## 2. Context & When It Occurred

**Date** : 2026-05-10
**Appareil testé** : HONOR NLA-LX2P (Android 15)
**Action utilisateur** : Jumelage réussi, ouverture normale de monitored_app. L'appareil contient des centaines de SMS/calls historiques antérieurs au pairing.

**Logs concernés** (monitored_app) :
```
D/SmsCollectorPlugin(16731): getNewSms query returned 0 rows since 1778440846085
I/flutter (16731): [SMS] getNewSms returned 0 entries since 2026-05-10 20:20:46.085949
D/SmsCollectorPlugin(16731): getNewSms query returned 0 rows since 1778440846085
I/flutter (16731): [SMS] getNewSms returned 0 entries since 2026-05-10 20:20:46.085949
```

Le timestamp `1778440846085` correspond à `2026-05-10 20:20:46` UTC — quelques minutes AVANT le pairing. La requête native filtre `WHERE date > ?` donc tout SMS plus ancien est ignoré.

Idem côté `CallsCollector` (vu dans le code, `DateTime _lastCheckTime = DateTime.now();` ligne 15 de `calls_collector.dart`).

**Fréquence** : 100% à chaque premier pairing. Persistant à chaque redémarrage de l'app.

---

## 3. Issues Détaillées

### Issue 3.1 — `_lastCheckTime` initialisé à `DateTime.now()` (SMS, Calls)

**Fichiers** :
- `lib/core/collectors/sms_collector.dart` ligne 15
- `lib/core/collectors/calls_collector.dart` ligne 15

**Code BUGGY** :
```dart
class SmsCollector extends BaseCollector {
  static const MethodChannel _channel = ...;
  Timer? _checkTimer;
  DateTime _lastCheckTime = DateTime.now();   // ❌ Bloque la lecture historique
```

**Impact** :
- SMS antérieurs au pairing : **jamais remontés**
- Appels antérieurs au pairing : **jamais remontés**
- Listes vides perpétuelles côté monitor_app

### Issue 3.2 — Pas de persistance de `_lastCheckTime`

À chaque relance de l'app (kill/restart, redémarrage device, etc.), `_lastCheckTime` revient à `DateTime.now()`. Conséquence :
- SMS reçus pendant que l'app était fermée : potentiellement perdus si arrivés AVANT le redémarrage et que la requête capture seulement depuis le restart.
- Pas de garantie de continuité de la sync.

---

## 4. Required Monitored_app Changes

### 4.1. Bootstrap historique au premier démarrage

**Stratégie** :
1. Détecter si c'est le **premier sync** de ce collecteur (flag persistant en `SharedPreferences` ou `DatabaseService`).
2. Si premier sync : utiliser un timestamp lointain (par exemple `DateTime.now().subtract(Duration(days: 90))`) pour rattraper 3 mois d'historique.
3. Sinon : utiliser le `_lastCheckTime` persisté de la dernière exécution.
4. Marquer le bootstrap comme fait après le premier sync réussi.

**Fichier** : `lib/core/collectors/sms_collector.dart`

```dart
class SmsCollector extends BaseCollector {
  static const MethodChannel _channel =
      MethodChannel('com.xpsafeconnect.monitored_app/sms');

  static const String _kLastCheckTimeKey = 'sms_collector_last_check_ms';
  static const String _kBootstrapDoneKey = 'sms_collector_bootstrap_done';
  static const Duration _bootstrapHistoryWindow = Duration(days: 90);

  Timer? _checkTimer;
  DateTime? _lastCheckTime;  // ← Nullable, chargé depuis storage
  bool _bootstrapDone = false;

  final DatabaseService _databaseService = locator<DatabaseService>();
  // Injecter un service de préférences persistantes (à adapter selon ton DI)
  final SharedPreferencesService _prefs = locator<SharedPreferencesService>();

  @override
  Future<void> initializeSpecific() async {
    _bootstrapDone = await _prefs.getBool(_kBootstrapDoneKey) ?? false;
    final lastCheckMs = await _prefs.getInt(_kLastCheckTimeKey);
    if (lastCheckMs != null) {
      _lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
    }
    debugPrint('[SMS] init — bootstrapDone=$_bootstrapDone, lastCheckTime=$_lastCheckTime');
  }

  DateTime _resolveCheckpoint() {
    if (!_bootstrapDone) {
      // Premier sync : remonter 90 jours d'historique
      return DateTime.now().subtract(_bootstrapHistoryWindow);
    }
    return _lastCheckTime ?? DateTime.now().subtract(const Duration(hours: 24));
  }

  @override
  Future<List<Map<String, dynamic>>> collectData() async {
    try {
      final checkpoint = _resolveCheckpoint();
      final smsList = await _channel.invokeMethod<List<dynamic>>(
        'getNewSms',
        {'since': checkpoint.millisecondsSinceEpoch},
      );

      debugPrint(
        '[SMS] getNewSms returned ${smsList?.length ?? 0} entries since $checkpoint'
        ' (bootstrap=${!_bootstrapDone})',
      );

      final now = DateTime.now();

      if (smsList != null && smsList.isNotEmpty) {
        final processedSms = <Map<String, dynamic>>[];
        for (final sms in smsList) {
          final processed = await _convertSmsData(sms as Map<dynamic, dynamic>);
          if (processed != null) processedSms.add(processed);
        }

        _lastCheckTime = now;
        await _prefs.setInt(_kLastCheckTimeKey, now.millisecondsSinceEpoch);

        if (!_bootstrapDone) {
          _bootstrapDone = true;
          await _prefs.setBool(_kBootstrapDoneKey, true);
          debugPrint('[SMS] Bootstrap completed: ${processedSms.length} historical SMS captured.');
        }

        return processedSms;
      }

      // Même si la liste est vide, persister le checkpoint pour ne pas refaire le bootstrap
      _lastCheckTime = now;
      await _prefs.setInt(_kLastCheckTimeKey, now.millisecondsSinceEpoch);
      if (!_bootstrapDone) {
        _bootstrapDone = true;
        await _prefs.setBool(_kBootstrapDoneKey, true);
      }

      return const [];
    } catch (e) {
      debugPrint('[SMS] Error collecting SMS data: $e');
      return [];
    }
  }
}
```

**Adapter la même logique** dans `calls_collector.dart` avec ses propres clés (`calls_collector_last_check_ms`, `calls_collector_bootstrap_done`).

### 4.2. Garde-fou : limitation du batch initial

Si l'appareil contient des dizaines de milliers de SMS sur 90 jours, l'envoi en un seul batch peut être rejeté ou time-out. Côté native plugin (Kotlin), limiter le nombre maximum de lignes retournées par appel (par ex. 500) et paginer si besoin :

**Fichier** : `android/.../SmsCollectorPlugin.kt` (équivalent à `CallsCollectorPlugin.kt`)

```kotlin
private fun getNewSms(since: Long, limit: Int = 500): List<Map<String, Any>> {
    // ...
    val cursor = context.contentResolver.query(
        Telephony.Sms.CONTENT_URI,
        projection,
        "${Telephony.Sms.DATE} > ?",
        arrayOf(since.toString()),
        "${Telephony.Sms.DATE} ASC LIMIT $limit",  // ← important : ASC + LIMIT
    )
    // ...
}
```

Côté Dart, le collecteur réappelle tant que la liste retournée est == `limit` (suggère qu'il reste des entrées), et avance `_lastCheckTime` au dernier `date` reçu pour la prochaine itération.

### 4.3. Trigger du bootstrap après pairing

Idéalement, juste après que `[PAIRING] Pairing completed successfully!` log apparaisse, déclencher explicitement un cycle de collect pour démarrer le bootstrap historique le plus vite possible.

Dans `pairing_service.dart` ou équivalent, après pairing OK, appeler :
```dart
await dataCollectorService.triggerFullSync();  // déclenche un cycle complet sur tous les collecteurs
```

---

## 5. Issues secondaires (non bloquantes mais à fixer)

### 5.1. Media permissions check incohérent

**Logs** :
```
I/flutter: Camera or storage permissions not granted
I/flutter: Cannot start media collection: permissions not granted
```

Mais le PATCH device envoie :
```
permissions_status: {..., storage: granted, camera: granted, ...}
```

→ Les permissions sont accordées au niveau OS, mais le check côté Dart retourne `false`.

**Action** : Auditer `advanced_media_service.dart` — la méthode qui détermine si les permissions sont "granted". Probablement un appel `Permission.camera.status` qui retourne `denied` malgré l'AndroidManifest correct. Possiblement un manifest mal configuré, ou un appel à la mauvaise constante `Permission` (par ex. `Permission.storage` au lieu de `Permission.photos`/`Permission.videos` sur Android 13+).

### 5.2. `performance_metrics` et `performance_mode_change` rejetés par /data/collect

```
I/flutter: Skipped performance_metrics sync: data type is not supported by /data/collect API
I/flutter: Skipped performance_mode_change sync: data type is not supported by /data/collect API
```

Même situation que `battery_status` documentée précédemment (`MONITORED_APP_ISSUE_COLLECTORS_DATA_LOSS_20260509.md`). Décider : soit retirer la mise en file de ces types, soit demander au backend de les supporter.

---

## 6. Vérification après fix

### Test SMS
1. Sur device avec SMS historiques : nouvelle installation propre + pairing.
2. Attendre 1-2 minutes après pairing.
3. **Attendu logs monitored_app** :
   ```
   [SMS] getNewSms returned <N>>=1</N> entries since 2026-02-10 ... (bootstrap=true)
   [SMS] Bootstrap completed: <N> historical SMS captured.
   Queued messages data for sync with priority X
   Synced messages batch: <N> items
   ```
4. Côté monitor_app : `GET /messages/conversations/?device_id=<uuid>` retourne au moins 1 conversation.

### Test calls
1. Idem avec un appareil ayant un historique d'appels.
2. **Attendu** : logs équivalents pour les calls, et la liste d'appels apparaît dans monitor_app.

### Test persistance
1. Bootstrap fait, fermer l'app monitored_app complètement.
2. Envoyer un SMS test au device.
3. Rouvrir monitored_app.
4. **Attendu** : le SMS test est synchronisé (et pas perdu) parce que `_lastCheckTime` a bien été persisté.

---

## 7. Frontend Actions Already Completed

**Status** : ✅ Le `monitor_app` appelle les bons endpoints. Pas d'action à prendre côté monitor_app — il affichera automatiquement les données dès que monitored_app commencera à les envoyer.

---

**Frontend Team Contact** : Eric Vekout (ericvekout@gmail.com)
**Date du rapport** : 2026-05-10
