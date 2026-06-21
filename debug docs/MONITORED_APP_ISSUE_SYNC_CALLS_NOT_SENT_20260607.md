# Monitored App Issue — Appels non synchronisés (0 sur backend)

**Issue Type**: MONITORED_APP_ISSUE_SYNC
**Date Created**: 2026-06-07
**Status**: 🔴 Bloqué — fix monitored_app requis
**Priority**: Haute
**Cible**: `monitored_app` (Android — HONOR GFY-LX2, Android 14)
**Device ID backend**: `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`

---

## Issue Summary

L'appareil surveillé collecte 246 appels mais **aucun n'est envoyé au backend** (`GET /api/v1/calls/?device=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721` → `count: 0`). Les SMS (444), app_info, app_usage et media_metadata sont synchronisés normalement.

---

## Context & When It Occurred

**Date**: 2026-06-07 (sessions 2026-06-01 → 2026-06-07)
**Écran monitor_app**: Section "Appels" → liste vide
**Action déclenchante**: Sync déclenchée après re-pairing (commit `c14f171`); `restartCollectorsAfterPermissionChange()` relance les collectors.
**Environnement**: Build debug, backend URL dev, Android 14

**Fréquence**: Persistant. Aucun appel jamais synchronisé dans toutes les sessions testées post-pairing.

---

## Expected Behavior (Per Specifications)

**Flux attendu**:
1. `CallsCollector.startCollecting()` collecte périodiquement les appels via `CallLog.ContentUri` (Android)
2. `processData(data)` stocke dans la base SQLite locale via `DatabaseService.queueDataForSync('calls', item)`
3. `DatabaseService._notifyDataCollectorService('calls', item)` → `DataCollectorService.queueForSync('calls', [item])`
4. Sync bulk/individuelle envoie les items via `POST /api/v1/collect/` (bulk) ou endpoint individuel
5. Backend retourne les appels via `GET /api/v1/calls/?device={id}`

**Résultat attendu**: `GET /api/v1/calls/?device=9989a82e...` retourne `count: 246` (ou +) avec la liste des appels.

---

## Actual Behavior (Observed)

**Logs monitored_app** (03:43:42, extrait représentatif):
```
[DataCollector] Sync: starting...
Optimized bulk sync completed: 3 types, 437 items
[DataCollector] Sync: isSyncing=false, queueEmpty=true
```

Aucun log de type:
- `Synced calls batch: N/N items`
- `Follow-up sync: flushing remaining X items`
- `[DataCollector] Calls full sync queued X items`
- `Error syncing calls batch`

**Backend** (`GET /api/v1/calls/?device=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`):
```json
{ "count": 0, "results": [] }
```

**Statistiques `CallsCollector`** (via `getStatistics()`):
- `calls_collected`: 246 (local device count confirmé)
- Backend count: 0

---

## Frontend Code Path (monitor_app — lecture seule)

`lib/features/calls/services/calls_service.dart` appelle:
```
GET /api/v1/calls/?device={deviceId}
```
Retourne une liste vide car le backend n'a rien reçu.
**Aucun bug monitor_app** — le frontend affiche fidèlement ce que le backend expose.

---

## Root Cause Investigation (monitored_app)

### Chemin de code suspects à tracer

**Fichier principal**: `lib/core/services/data_collector_service.dart`

#### Hypothèse 1 — Calls jamais enqueués (pipeline silencieux)

La chaîne `processData → _storeInDatabase → queueDataForSync → _notifyDataCollectorService → queueForSync` comporte plusieurs points de défaillance silencieux :

```dart
// base_collector.dart:441-446
Future<void> _storeInDatabase(List<Map<String, dynamic>> data) async {
  // Si cette méthode jette une exception catchée silencieusement,
  // queueDataForSync n'est jamais appelé.
  await _databaseService.queueDataForSync(dataType, item);
}
```

```dart
// database_service.dart:75-102
Future<void> queueDataForSync(String dataType, ...) async {
  // Si _notifyDataCollectorService n'a pas de callback enregistré
  // (timing race entre initialize() et setDataNotificationCallback),
  // les calls vont en DB mais pas dans _syncQueue.
  _notifyDataCollectorService(dataType, {..., 'sync_item_id': syncItemId});
}
```

**Race condition probable** : `data_collector_service.dart:219-257` — `initialize()` appelle `loadPendingDataToCollector()` (qui `setDataNotificationCallback`) AVANT `_callsCollector.initialize()` et `startCollecting()`. Si la collection se déclenche avant que le callback soit enregistré, les items vont en DB uniquement et ne sont jamais chargés dans `_syncQueue` lors de la passe initiale (limite 1000 items, déjà saturée par SMS).

#### Hypothèse 2 — Calls exclus du bulk sync par `bulkAttemptedDataTypes`

```dart
// data_collector_service.dart:527-598
final bulkCandidate = _identifyBulkSyncCandidate(sortedDataTypes, batteryLevel);
bulkAttemptedDataTypes.addAll(bulkCandidate); // 'calls' ajouté ici

// Bulk attempt pour calls → peut retourner syncedIndexes vides (erreur backend silencieuse)

// Individual loop (ligne 593)
if (bulkAttemptedDataTypes.contains(dataType)) continue; // calls skipé !
```

Si `calls` entre dans `bulkCandidate` mais que le bulk échoue silencieusement pour ce type (ex. endpoint `/api/v1/collect/` rejette les calls ou retourne un format inattendu), les items restent dans `_syncQueue` mais le passage individuel est court-circuité. Le follow-up timer (`_followUpSyncTimer`) relance `_syncData` mais reproduit le même pattern.

#### Hypothèse 3 — Battery gate exclut calls

```dart
// data_collector_service.dart:609-618
final shouldRun = await _batteryOptimizationService.shouldRunTask(
  _getTaskTypeForDataType(dataType), // 'NORMAL' pour calls
  batteryLevel,
);
if (!shouldRun) continue; // calls skipé sans log d'erreur
```

Si la batterie de l'Honor est < seuil (ex. < 20%), `shouldRunTask('NORMAL', batteryLevel)` peut retourner `false`. Vérifier le niveau batterie dans les logs au moment de la sync.

#### Hypothèse 4 — `_syncQueue` saturé lors du `loadPendingDataToCollector`

```dart
// database_service.dart:526
final pendingItems = await getPendingSyncItems(limit: 1000);
```

Avec 444 SMS + 246 appels + app_info + media_metadata = > 1000 items potentiels en DB, la limite 1000 de `getPendingSyncItems` peut exclure les calls si les SMS remplissent le quota en premier (triés par priorité ou ordre d'insertion).

---

## Required Changes (monitored_app)

### Option A — Fix prioritaire : quota par data_type dans le bootstrap

**Fichier**: `lib/core/services/database_service.dart`

Modifier `getPendingSyncItems(limit: 1000)` pour charger au maximum N items **par type** :

```dart
// Exemple : 200 items max par type, 5 types = 1000 total équilibré
Future<List<SyncQueueItem>> getPendingSyncItems({int limitPerType = 200}) async {
  final results = <SyncQueueItem>[];
  for (final dataType in ['sms', 'calls', 'location', 'app_info', 'app_usage', 'media_metadata']) {
    final items = await (_database.select(_database.syncQueue)
      ..where((t) => t.status.equals('pending') & t.type.equals(dataType))
      ..orderBy([(t) => OrderingTerm.asc(t.priority), (t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limitPerType))
      .get();
    results.addAll(items);
  }
  return results;
}
```

### Option B — Fix `bulkAttemptedDataTypes` : retry individuel si bulk échoue

**Fichier**: `lib/core/services/data_collector_service.dart`

Ne pas ajouter `calls` à `bulkAttemptedDataTypes` si ses items ne sont pas confirmés syncs :

```dart
// Après bulk sync, retirer de bulkAttemptedDataTypes les types avec 0 synced items
for (final dataType in bulkCandidate) {
  final syncedCount = bulkSyncedIndexesByType?[dataType]?.length ?? 0;
  if (syncedCount == 0) {
    bulkAttemptedDataTypes.remove(dataType); // Permettre retry individuel
  }
}
```

### Option C — Diagnostic log — à ajouter immédiatement pour confirmer l'hypothèse

**Fichier**: `lib/core/services/data_collector_service.dart`

```dart
// Dans _identifyBulkSyncCandidate, logger les candidats et leurs counts
debugPrint('[BulkSync] Candidates: ${candidates.map((t) => '$t=${_syncQueue[t]?.length}').join(', ')}');

// Dans individual loop, logger le skip calls
if (bulkAttemptedDataTypes.contains(dataType)) {
  debugPrint('[IndividualSync] Skipping $dataType (already in bulk attempt)');
  continue;
}
```

---

## Temporary Workaround (If Any)

**Status**: ⚠️ Fix C (`_followUpSyncTimer`) présent mais inefficace

Le timer 10s de follow-up (`data_collector_service.dart:706-712`) relance `_syncData` mais reproduit le même bug. Pas de workaround efficace côté monitor_app — le problème est exclusivement dans monitored_app.

---

## Verification Steps

### Diagnostic immédiat (étape 1)

1. Ajouter les logs Option C ci-dessus dans `data_collector_service.dart`
2. Rebuild monitored_app : `flutter build apk --debug`
3. Installer sur le device Honor
4. Ouvrir monitor_app → taper "Sync"
5. Dans logcat (filtre `[BulkSync]` / `[IndividualSync]` / `DataCollector`), vérifier :
   - `calls` apparaît-il dans "Candidates" ?
   - `calls` count > 0 dans la queue ?
   - "Skipping calls (already in bulk attempt)" ?
   - "Synced calls batch" apparaît-il ?

### Validation fix (étape 2)

Après implémentation Option A ou B :
```bash
# Backend
curl -H "Authorization: Bearer <TOKEN>" \
  "http://<API_URL>/api/v1/calls/?device=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721"
# Expected: count > 0, results non vide
```

Puis dans monitor_app → Appels → liste non vide.

---

**Équipe frontend (monitor_app)**: Eric Vekout
**Date de notification**: 2026-06-07
**Commits de contexte**: `c14f171` (monitor_app), `479a108` (sync fix pairing)
