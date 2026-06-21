# Monitored App — Data Sync Fixes : Types de données non compatibles avec le backend

**Type** : MONITORED_APP_BUG_DATA_TYPE_MISMATCH
**Date** : 2026-05-07
**Statut** : ✅ Corrigé — Modifications appliquées côté monitored_app
**Priorité** : Haute — SMS et médias ne remontaient pas du tout au backend
**App concernée** : `monitored_app` (application côté appareil surveillé)

---

## 1. Issue Summary

Deux types de données collectées par l'application surveillée ne parvenaient **jamais** au backend :

1. **Les SMS** : `SmsCollector` identifie ses données avec le type interne `sms`, mais le backend rejette `data_type: "sms"` (seul `"messages"` est reconnu). Résultat : toutes les requêtes SMS vers `/api/v1/data/collect/` retournent `{"error": "Type de données non pris en charge: sms"}`.

2. **Les métadonnées média** : `MediaCollector` publie ses données sous la clé interne `media_metadata`. Ce type n'étant pas dans `_collectApiDataTypes`, les éléments sont silencieusement abandonnés par `_markUnsupportedCollectTypeAsHandled` (log : *"Skipped media_metadata sync: data type is not supported by /data/collect API"*).

---

## 2. Context & When It Occurred

**Date de découverte** : 2026-05-07
**Environnement** : Dev (Windows 11, Flutter monitored_app, Django backend)
**Découverte lors** : Audit de la chaîne complète de remontée de données depuis l'application surveillée, suite au fix des routes monitor_app → backend (2026-05-06)

**Fréquence** :

- SMS : 100 % des syncs échouent côté backend (rejet 400)
- Médias metadata : 100 % des items sont silencieusement abandonnés avant même l'envoi

---

## 3. Expected Behavior

### SMS

`SmsCollector` collecte les SMS et les convertit au format :

```dart
{
  'message_type': 'SMS',
  'direction': 'INCOMING' | 'OUTGOING',
  'sender': '<phone_number>',
  'body': '<sms_body>',
  'sent_at': '<ISO8601>',
  'thread_id': '<thread_id>',
  'has_attachment': false,
}
```

Ce format est exactement ce qu'attend le handler `_process_message_data()` du backend, qui crée des objets `Message` avec `message_type='SMS'`.

La requête envoyée au backend devrait être :

```json
POST /api/v1/data/collect/
{
  "device_id": "<uuid>",
  "data_type": "messages",
  "items": [{ "message_type": "SMS", "direction": "INCOMING", "..." : "..." }]
}
```

### Médias

`MediaCollector` collecte les métadonnées fichier (photos, vidéos, audio, screenshots) et les publie. Le backend les traite via `_process_media_data()` qui s'attend à `data_type: "media"`.

---

## 4. Actual Behavior (Observed)

### SMS — comportement observé

`SmsCollector.dataType` retourne `'sms'`. La méthode `_sendDataBatch` envoyait :

```json
{ "data_type": "sms", "items": ["..."] }
```

Réponse backend (400) :

```json
{ "success": false, "error": "Type de données non pris en charge: sms" }
```

Les SMS étaient donc **perdus** : renvoyés à l'infini ou abandonnés après les retries.

### Médias — comportement observé

`MediaCollector._onDataCollected?.call('media_metadata', [mediaMetadata])` publie sous la clé `media_metadata`. Dans `DataCollectorService._syncData()` :

```dart
if (!_isCollectApiDataType(dataType)) {   // 'media_metadata' absent du set → true
  await _markUnsupportedCollectTypeAsHandled(dataType);  // drop silencieux
  continue;
}
```

Log produit : *"Skipped media_metadata sync: data type is not supported by /data/collect API"*

---

## 5. Root Cause Analysis

Le problème vient d'un **décalage entre les noms de types internes** (utilisés pour les queues et la base de données locale) **et les noms de types API** (attendus par le backend) :

| Usage interne (monitored_app) | Type API backend attendu | Statut avant fix |
| --- | --- | --- |
| `sms` | `messages` | ❌ Envoyé tel quel → rejet 400 |
| `media_metadata` | `media` | ❌ Filtré avant envoi → drop silencieux |
| `location` | `location` | ✅ Correct |
| `calls` | `calls` | ✅ Correct |
| `app_usage` | `app_usage` | ✅ Correct |
| `messages` | `messages` | ✅ Correct |

---

## 6. Fix Applied

### Fichier modifié : `lib/core/services/data_collector_service.dart`

**Changement 1** : Ajout de `'media_metadata'` dans `_collectApiDataTypes` pour qu'il ne soit plus filtré avant envoi.

**Changement 2** : Ajout de la méthode `_mapApiDataType()` qui convertit les noms internes en noms attendus par l'API :

```dart
static String _mapApiDataType(String dataType) {
  switch (dataType) {
    case 'sms':
      return 'messages';
    case 'media_metadata':
      return 'media';
    default:
      return dataType;
  }
}
```

**Changement 3** : Utilisation de `_mapApiDataType(dataType)` à la place de `dataType` brut dans les trois méthodes qui construisent le payload API :

- `_sendDataBatch()` → `'data_type': _mapApiDataType(dataType)`
- `_sendBulkDataBatch()` → `'data_type': _mapApiDataType(dataType)`
- `_sendOptimizedBulkBatch()` → `'data_type': _mapApiDataType(dataType)`

Ce design préserve les noms internes dans la queue et la BDD locale (utile pour les logs et le debugging), tout en exposant les noms corrects à l'API backend.

---

## 7. Autres types de données : état complet post-fix

| Type interne | État post-fix | Remarque |
| --- | --- | --- |
| `location` | ✅ Fonctionne | Aucun changement requis |
| `sms` | ✅ Corrigé | Remappé → `messages` à l'envoi |
| `calls` | ✅ Fonctionne | Aucun changement requis |
| `app_usage` | ✅ Fonctionne | Aucun changement requis |
| `media_metadata` | ✅ Corrigé | Ajouté au set + remappé → `media` |
| `messages` | ✅ Fonctionne | Aucun changement requis |
| `emergency_sms` | ⚠️ Abandonné | Non supporté côté backend ; items droppés silencieusement — voir section 8 |
| `emergency_calls` | ⚠️ Abandonné | Idem |
| `battery_status`, `performance_*`, etc. | ℹ️ Stocké offline | Backend les reçoit dans `DEFERRED_DATA_TYPES` — comportement volontaire |

---

## 8. Problèmes Résiduels (Travail Futur)

### Emergency data types (`emergency_sms`, `emergency_calls`)

Ces types sont queués dans la base de données locale par `DatabaseService.queueDataForSync('emergency_sms', ...)` mais absents de `_collectApiDataTypes` → droppés silencieusement. Le backend ne reconnaît pas ces types de toute façon.

**Impact** : Les SMS et appels collectés lors du mode urgence ne remontent pas au backend.

**Solutions possibles** :

- Option A : Remapper aussi `emergency_sms` → `messages` et `emergency_calls` → `calls` dans `_mapApiDataType`, en incluant le flag `emergency: true` déjà présent dans le payload item.
- Option B : Implémenter un endpoint backend dédié `/api/v1/emergency/data/` capable d'ingérer ces types.

Ce point est à traiter dans un sprint dédié urgence.

---

## 9. Verification Steps

### Côté monitored_app

1. Lancer `flutter analyze` dans `monitored_app/` — aucune erreur.
2. Lancer `flutter run --flavor development` sur un émulateur Android avec au moins un SMS dans la boîte de réception.
3. Observer les logs — le sync SMS doit afficher `Synced sms batch: N items` (sans message "Skipped sms sync: data type is not supported").
4. Idem pour les médias — plus aucun log *"Skipped media_metadata sync"*.

### Côté backend

1. Démarrer Django : `daphne -b 0.0.0.0 -p 8000 safeconnect.asgi:application`
2. Vérifier dans la base que des entrées `Message` avec `message_type=SMS` apparaissent bien après sync.
3. Tester manuellement (réponse attendue : `200 OK` avec `{ "success": true, "processed_count": 1 }`) :

   ```bash
   curl -X POST http://localhost:8000/api/v1/data/collect/ \
     -H "Authorization: Bearer <TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{
       "device_id": "<uuid>",
       "data_type": "messages",
       "items": [{
         "message_type": "SMS",
         "direction": "INCOMING",
         "sender": "+33600000000",
         "body": "Test message",
         "sent_at": "2026-05-07T10:00:00Z",
         "thread_id": "1",
         "has_attachment": false
       }]
     }'
   ```

4. Vérifier que `monitor_app` affiche les messages SMS dans l'écran Messages de l'appareil surveillé.

---

## 10. Impact Induit sur le Monitor App

Une fois les SMS correctement stockés dans le backend (modèle `Message` avec `message_type='SMS'`), le `monitor_app` peut les lire via `GET /api/v1/messages/?device_id={id}`.

**Cependant**, l'affichage d'une conversation individuelle via `MessageService.getConversationMessages()` appelle `GET /api/v1/messages/conversations/{id}/messages/` — endpoint **absent du backend** (`ConversationViewSet` n'a pas d'action imbriquée `messages`). Ce point est documenté et tracé dans `BACKEND_ISSUE_MISSING_MONITORING_ENDPOINTS_20260506.md` (section "Endpoints non-monitoring manquants").

---

## 11. Impact on Backend

Le fix monitored_app suffit pour les SMS et médias de base. Cependant, le backend doit aussi ajouter `'sms'` comme alias de `'messages'` dans `DataCollectionService` pour se protéger contre des clients mobiles non encore mis à jour :

```python
# Dans services/data_collection_service.py — ajouter dans process_data_batch()
# avant le routing par data_type :
DATA_TYPE_ALIASES = {
    'sms': 'messages',
    'media_metadata': 'media',
}
data_type = DATA_TYPE_ALIASES.get(data_type, data_type)
```

Cette normalisation est documentée dans `BACKEND_ISSUE_MISSING_MONITORING_ENDPOINTS_20260506.md` (section "Priorité 0 — Robustesse : Alias de types de données").

---

**Auteur** : <ericvekout@gmail.com>
**Fichiers modifiés** : `lib/core/services/data_collector_service.dart` — Ajout `_mapApiDataType`, `media_metadata` dans `_collectApiDataTypes`, application du mapping dans les 3 méthodes de sync
