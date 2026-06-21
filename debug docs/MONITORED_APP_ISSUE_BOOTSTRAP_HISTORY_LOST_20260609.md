# Monitored App Issue — Bootstrap historique perdu (SMS + Médias)

**Issue Type**: MONITORED_APP_ISSUE_DATA
**Date Created**: 2026-06-09
**Status**: 🔴 Bloqué — fix monitored_app requis
**Priority**: Critique
**Cible**: `monitored_app` (Android — HONOR GFY-LX2, Android 14)
**Device ID backend**: `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`

---

## Issue Summary

`SmsCollector` et `MediaStoreCollector` marquent le bootstrap comme **terminé** et avancent le checkpoint
à `DateTime.now()` même quand le premier scan renvoie 0 résultat (typiquement : permission pas encore
accordée). Le résultat : la fenêtre historique de 90 jours n'est jamais re-scannée et toutes les données
antérieures sont définitivement perdues jusqu'à un reset manuel.

---

## Context & When It Occurred

**Date de constatation** : 2026-06-09  
**Conséquences mesurées** :
- `GET /api/v1/messages/?device=9989a82e...` → `count: 2` (attendu ~444)
- `GET /api/v1/media/?device=9989a82e...` → `count: 0` (attendu ~45)
- Logs monitored_app : `[MediaStore] scanned 0 items since <date> (bootstrap=true)` suivi immédiatement de
  `[MediaStore] Bootstrap completed: 0 items.`
- Le device Honor avait historiquement 444 SMS et des dizaines de médias bien reçus par le backend (sessions
  antérieures). Ils ont disparu après un reinstall de l'APK monitored_app.

**Fréquence** : 100% des reinstalls (remise à zéro du `SharedPreferences` → permissions plus accordées au
démarrage → race condition).

---

## Expected Behavior

Lors du premier démarrage post-reinstall :
1. Le collecteur attend que la permission système correspondante soit **effectivement accordée** avant de
   lancer le scan bootstrap.
2. Le scan historique 90 jours est lancé et produit des résultats (si le device a des données).
3. `bootstrapDone = true` est persisté **seulement si** le scan a produit ≥ 1 résultat (ou si la
   permission est confirmée accordée et que le device n'a vraiment aucune donnée).

---

## Actual Behavior

### Fichier A — `lib/core/collectors/media_store_collector.dart`

```dart
// ligne ~97-145 (méthode _scanAll)
final allItems = <Map<String, dynamic>>[];
for (final method in const ['scanImages', 'scanVideos', 'scanAudio']) {
  final items = await _scanMethod(method, startCheckpoint);
  // ... accumulation dans allItems ...
}
// allItems.length = 0 si permissions non accordées

await _persistCheckpoint(
  allItems.isEmpty
      ? DateTime.now()   // ← checkpoint avancé à NOW même si 0 items
      : DateTime.fromMillisecondsSinceEpoch(latestTimestamp),
);

// _persistCheckpoint (lignes ~220-223) :
if (!_bootstrapDone) {
  _bootstrapDone = true;                                      // ← marqué done !
  await _storageService.setBool(_bootstrapDoneKey, true);
}
```

### Fichier B — `lib/core/collectors/sms_collector.dart`

Pattern identique (lignes ~165-200) :
```dart
await _persistCheckpoint(
  processedSms.isEmpty ? DateTime.now() : checkpoint,   // ← NOW si 0
);
// dans _persistCheckpoint :
if (!_bootstrapDone) {
  _bootstrapDone = true;   // ← marqué done inconditionnellement
  await _storageService.setBool(_bootstrapDoneKey, true);
}
```

**Séquence de défaillance** :
1. APK reinstallé → `SharedPreferences` vidé → `bootstrapDone = false`.
2. Collecteur démarre, permission `READ_SMS`/`READ_MEDIA_*` pas encore accordée.
3. Scan natif (`getNewSms`/`scanImages`…) → 0 résultat.
4. `_persistCheckpoint(DateTime.now())` → checkpoint = NOW + `bootstrapDone = true` persisté.
5. Permissions accordées au cycle suivant → scans partent de NOW → **historique antérieur perdu**.

---

## Required Changes — monitored_app

### Fix principal : conditionner `bootstrapDone` au résultat du scan

#### A. `lib/core/collectors/media_store_collector.dart`

Modifier `_persistCheckpoint` (et son appelant `_scanAll`) pour ne pas marquer `bootstrapDone` si la
cause du résultat vide est une permission non accordée :

```dart
// Option 1 — ne marquer done que si le scan a produit des données OU si la
// permission est confirmée accordée (résultat vide = device réellement vide)
Future<void> _persistCheckpoint(DateTime checkpoint, {bool isBootstrap = false, bool hasData = false}) async {
  _lastScanTime = checkpoint;
  await _storageService.setInt(_lastScanKey, checkpoint.millisecondsSinceEpoch);

  if (isBootstrap && (hasData || await _isPermissionGranted())) {
    _bootstrapDone = true;
    await _storageService.setBool(_bootstrapDoneKey, true);
  }
  // Si isBootstrap && !hasData && !permissionGranted → NE PAS marquer done
  // → le prochain cycle re-tentera le bootstrap
}

bool _isPermissionGranted() {
  // Vérifier via Permission.photos / Permission.videos / Permission.audio (Android 13+)
  // ou Permission.storage (Android ≤12) selon la plateforme.
  // Utiliser le package 'permission_handler' déjà présent dans le projet.
}
```

**Appel dans `_scanAll`** :
```dart
await _persistCheckpoint(
  allItems.isEmpty ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(latestTimestamp),
  isBootstrap: isBootstrap,
  hasData: allItems.isNotEmpty,
);
```

#### B. `lib/core/collectors/sms_collector.dart`

Même pattern :
```dart
// Dans _persistCheckpoint :
if (!_bootstrapDone && (hasData || await Permission.sms.isGranted)) {
  _bootstrapDone = true;
  await _storageService.setBool(_bootstrapDoneKey, true);
}
```

**Appel dans `collectData`** :
```dart
await _persistCheckpoint(
  processedSms.isEmpty ? DateTime.now() : checkpoint,
  isBootstrap: isBootstrap,
  hasData: processedSms.isNotEmpty,
);
```

### Re-bootstrap manuel pour récupérer l'historique perdu

Le device Honor a `bootstrapDone = true` avec checkpoint = NOW (données perdues). Un simple fix du
code ne suffira pas : il faut un mécanisme de **re-bootstrap** déclenché manuellement ou post-pairing.

**Options** :
1. **Reset via backend** : endpoint `POST /api/v1/devices/{id}/request-bootstrap/` → monitored_app
   remet les clés `*_bootstrap_done = false` et relance le cycle.
2. **Reset en Settings monitored_app** : bouton "Rescan historical data" visible en mode dev uniquement.
3. **Reset automatique post-pairing** : dans `PairingService.onPairingComplete()`, appeler
   `smsCollector.resetBootstrap()` + `mediaStoreCollector.resetBootstrap()`.

**Recommandation** : option 3 (la plus robuste). `resetBootstrap()` = `_bootstrapDone = false` +
`await _storageService.setBool(_bootstrapDoneKey, false)`.

### Gating permission avant bootstrap

Recommandation additionnelle : ne lancer le scan bootstrap qu'après confirmation des permissions :

```dart
// Dans data_collector_service.dart, avant de démarrer SmsCollector :
if (!await Permission.sms.isGranted) {
  debugPrint('[DataCollector] SMS permission not granted, deferring SMS bootstrap');
  return; // retenter au prochain cycle
}
```

---

## Temporary Workaround

Sur le device Honor de test, pour récupérer les données dès que le fix est déployé :

```bash
# Via ADB (device connecté en mode développeur)
adb shell pm clear com.xpsafeconnect.monitored_app
# Ou seulement effacer les SharedPreferences :
adb shell run-as com.xpsafeconnect.monitored_app \
  rm /data/data/com.xpsafeconnect.monitored_app/shared_prefs/*.xml
```
Puis réinstaller l'APK corrigé → le bootstrap se relancera correctement avec les permissions accordées.

> ⚠️ Cette manipulation efface AUSSI les autres préférences (pairing token, etc.). À utiliser uniquement
> en phase de test.

---

## Verification Steps

1. Installer l'APK corrigé sur le device Honor.
2. Au premier démarrage : **ne pas** accorder READ_SMS / READ_MEDIA_* immédiatement.
3. Vérifier logs : `[SMS] bootstrap=true`, `[SMS] Bootstrap completed: 0 items.` MAIS
   **`bootstrapDone` ne doit PAS être persisté à true**.
4. Accorder les permissions.
5. Au cycle suivant : `[SMS] getNewSms returned N entries since <date 90j avant> (bootstrap=true)`.
6. Après sync backend : `GET /api/v1/messages/?device=9989a82e...` → `count > 100`.
7. Même séquence pour médias : `[MediaStore] scanned N items` → `GET /api/v1/media/` → `count > 0`.

---

## Cross-References

- `MONITORED_APP_ISSUE_MEDIA_FILES_AND_DURATION_20260607.md` — B1 (transfert fichiers) reste requis
  même après ce fix ; B2 (unité durée) déjà contourné côté monitor_app (`media_service.dart`).
- `MONITORED_APP_ISSUE_SYNC_CALLS_NOT_SENT_20260607.md` — problème sync distinct (calls) déjà fixé.

---

**Équipe frontend (monitor_app)** : Eric Vekout  
**Date** : 2026-06-09  
**Commits de contexte** : `c14f171`, `e569590`
