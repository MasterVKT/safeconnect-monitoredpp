# Monitored App Issue — Journal d'appels vide : diagnostic et procédure de résolution

**Issue Type**: MONITORED_APP_ISSUE_DIAGNOSTIC
**Date Created**: 2026-06-14
**Status**: 🔴 Bloqué — information de logs manquante ; action utilisateur requise
**Priorité**: Haute — fonctionnalité Appels inutilisable
**Cible**: `monitored_app` (Android, Honor GFY-LX2, Android 14)
**Device ID test**: `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`

---

## 1. Issue Summary

monitor_app affiche « Aucun appel trouvé » en permanence.
`GET /api/v1/calls/?device=9989a82e…` renvoie `{count: 0, results: []}`.
Cause : **0 ligne d'appel dans la base backend pour ce device**, confirmé par diagnostic complet.

---

## 2. Constat décisif : toute la chaîne code est correcte

Chaque maillon a été vérifié (read-only, 2026-06-14) :

| Maillon | Résultat | Preuve |
|---|---|---|
| monitor_app — requête | ✅ | `GET /calls/?device=<id>` ([call_service.dart:31-51](lib/features/calls/services/call_service.dart#L31-L51)), parse `results`, normalise snake/camel |
| backend — liste | ✅ | `CallViewSet` filtre `device` **identique au filtre SMS qui fonctionne** (`DevicePermission`), tri `-start_time` (`apps/calls/views.py:14-50`) |
| backend — ingestion | ✅ | `_process_call_data` dedup par appel distinct (`call:sha256(phone\|type\|start_time)`), `bulk_create(ignore_conflicts=True)` ne supprime pas d'appels différents (`services/data_collection_service.py:636-765`) |
| backend — dispatch | ✅ | `data_type=='calls'` → `_process_call_data` ; alias `'sms'→'messages'` explique pourquoi SMS marche ; `'calls'` mappe directement (`data_collection_service.py:38-44,273`) |
| monitored_app — collector Dart | ✅ | `.toUtc()`, types corrects, bootstrap identique au SmsCollector (`calls_collector.dart`) |
| monitored_app — natif Kotlin | ✅ | `DATE > since`, tri ASC, `QUERY_ARG_LIMIT` + garde `count < safeLimit` — **le bug Kotlin LIMIT antérieur est corrigé** (`CallsCollectorPlugin.kt:154-225`) |

**Conclusion** : 0 ligne = collecte non effectuée côté monitored_app (runtime, pas code).

---

## 3. Cause probable (3 états candidats)

Classés par ordre de probabilité décroissante :

### État A — Permissions non accordées (le plus probable)

Le collecteur vérifie `READ_CALL_LOG` + `READ_PHONE_STATE` avant chaque cycle
(`calls_collector.dart:134-139`). Si l'une est refusée, il saute silencieusement.

**Signal log attendu** :
```
[Calls] Collection deferred: call log permissions are not granted
```

**Résolution** : Sur le Honor GFY-LX2 → Paramètres → Applications → [appli monitored] →
Autorisations → accorder **Journal des appels** et **Téléphone**.

---

### État B — Checkpoint bootstrap déjà « done » + aucun nouvel appel depuis

Si le bootstrap a été marqué terminé lors d'une session antérieure (mais sans avoir récolté d'appels,
ex. permissions pas encore accordées), le collecteur ne retourne plus à 90 jours en arrière.
Il attend seulement les nouveaux appels depuis le dernier checkpoint.

**Signal log attendu** :
```
[Calls] initialized with bootstrapPending=false, lastCheckpoint=<date récente>
[Calls] getNewCalls returned 0 entries since <date> (bootstrap=false)
```

**Résolution** : Appeler `CallsCollector.resetBootstrap()`. En pratique, ajouter temporairement
dans `BackgroundService` ou depuis un écran debug :
```dart
await locator<CallsCollector>().resetBootstrap();
```
Puis relancer l'app pour déclencher un nouveau cycle bootstrap.

---

### État C — Journal d'appels vide sur l'appareil (improbable)

Improbable sur un téléphone réel, mais à exclure en dernier recours.

**Signal log attendu** :
```
[Calls] getNewCalls returned 0 entries since <epoch=0> (bootstrap=true)
Bootstrap completed: 0 historical calls captured.
```

---

## 4. Procédure de capture des logs (CORRIGÉE)

⚠️ **Ne pas piper `flutter run` dans `Select-String`** : Select-String bufferise
stdout et avale les lignes de l'app. C'est ce qui a causé l'arrêt apparent des logs au
dernier test.

### Méthode recommandée (capture complète sans bloquer stdout) :

```powershell
cd "H:\Projects\XP SafeConnect\flutter_apps\monitored_app"
.\.venv\Scripts\Activate.ps1
flutter run --flavor development 2>&1 | Tee-Object -FilePath mo_run.log
```

L'app tourne normalement dans le terminal ET tout est capturé dans `mo_run.log`.

### Extraction des lignes d'appels après coup :

```powershell
Select-String -Path mo_run.log -Pattern "\[Calls\]"
```

### Lignes clés à rechercher :

```
[Calls] initialized with bootstrapPending=<true/false>, lastCheckpoint=<date>
[Calls] getNewCalls returned <N> entries since <date> (bootstrap=<true/false>)
[Calls] Collection deferred: call log permissions are not granted   ← État A
[Calls] Bootstrap completed: <N> historical calls captured.         ← États B/C
```

---

## 5. Arbre de décision

```
[Calls] "Collection deferred: permissions" ? → État A → accorder permissions → redéployer
        ↓ non
[Calls] returned 0 (bootstrap=false) ?      → État B → resetBootstrap() → redéployer
        ↓ non
[Calls] returned 0 (bootstrap=true)  ?      → État C → journal appels vide sur Honor
```

---

## 6. Verification après correction

1. Logs monitored_app : `[Calls] Bootstrap completed: N historical calls captured.` (N > 0).
2. Backend : `GET /api/v1/calls/?device=9989a82e…` → `count > 0`.
3. monitor_app écran Appels : liste non vide, dates/durées cohérentes.

---

## Cross-References

- Diagnostic complet chaîne (read-only 2026-06-14) — confirmation dans le plan de session.
- `MONITORED_APP_ISSUE_TIMESTAMPS_NOT_UTC_20260610.md` — si les appels s'affichent mais avec
  des dates décalées, ce document s'applique (même cause : timestamps locaux naïfs).

---

**Frontend Team Contact**: Eric Vekout — **Date**: 2026-06-14
