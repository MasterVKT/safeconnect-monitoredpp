# Monitored App Issue — Timestamps envoyés en heure locale naïve (non-UTC)

**Issue Type**: MONITORED_APP_ISSUE_DATA
**Date Created**: 2026-06-10
**Status**: ✅ Résolu — 2026-06-12 (fix complet monitored_app)
**Priority**: Haute (casse l'historique de localisation ; décale dates SMS/médias/app_usage)
**Cible**: `monitored_app` (Android)
**Device ID backend**: `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`

---

## Issue Summary

Tous les collecteurs **sauf `calls_collector`** sérialisent leurs timestamps avec
`DateTime.now().toIso8601String()` — c'est-à-dire **l'heure locale du device, sans suffixe de fuseau**
(ex. `2026-06-10T20:20:27.596663`). Django (`USE_TZ=True`) interprète ces valeurs naïves comme de l'**UTC**
→ toutes les données sont stockées avec un décalage de **+1h** (device au Cameroun, UTC+1).

## Context & When It Occurred

**Date** : 2026-06-10, session de test 20:18–20:22 (UTC+1)

**Conséquence visible n°1 — historique de localisation VIDE dans monitor_app** :
- Le device enregistre une position à 20:20:27 locale → stockée backend comme `2026-06-10T20:20:27Z`.
- monitor_app demande `history/?start_date=2026-06-10T00:00:00&end_date=2026-06-10T19:21:59`
  (= « maintenant » réel en UTC).
- `20:20:27Z > end_date 19:21:59` → la position est **exclue de la fenêtre** → `[]` retourné
  alors que `last_known` (sans filtre temporel) retourne bien la position.

```text
Backend log : GET /api/v1/location/locations/history/?...end_date=2026-06-10T19:21:59 → 200, body = [] (2 octets)
Backend log : GET /api/v1/location/locations/last_known/ → 200, recorded_at: 2026-06-10T20:20:27.596663Z
```

**Conséquence visible n°2 — dates médias/SMS décalées** : une photo prise le 30 mai à 23h30 locale est
stockée comme 23:30 UTC = 00:30 le 31 mai en heure locale d'affichage → regroupements par date faux
(photos « 31 mai » pour des fichiers du 30 mai).

**Preuve par contraste** : les appels s'affichent avec les bonnes heures car `calls_collector`
fait déjà `.toUtc()` (seul collecteur correct).

## Expected Behavior

Tous les timestamps envoyés au backend sont en **UTC avec suffixe** (`...Z`), produits par
`dateTime.toUtc().toIso8601String()`.

## Actual Behavior — lignes exactes à corriger

`Grep toIso8601String()` dans `lib/core/collectors/` :

| Fichier | Lignes | Champs | État |
|---|---|---|---|
| `location_collector.dart` | 226, 329, 368 | `recorded_at`, `timestamp` | ❌ local naïf |
| `sms_collector.dart` | 267, 359, 363 | `sent_at`, `collected_at` | ❌ local naïf |
| `apps_collector.dart` | 173, 190–192, 241–242 | `start_time`, `end_time`, `recorded_at`, `first_install_time`, `last_update_time` | ❌ local naïf |
| `media_collector.dart` | 413, 498, 591, 695 | `created_at` | ❌ local naïf |
| `media_store_collector.dart` | 276 | `created_at` (depuis epoch ms) | ❌ local naïf |
| `base_collector.dart` | 203 | `collected_at` | ❌ local naïf |
| `calls_collector.dart` | 265–268, 378–386 | tous | ✅ `.toUtc()` déjà appliqué |

## Required Changes — monitored_app

Appliquer le pattern de `calls_collector` partout : insérer `.toUtc()` avant chaque `.toIso8601String()`
listé ci-dessus. Exemples :

```dart
// location_collector.dart:226 (et 368)
'recorded_at': recordedAt.toUtc().toIso8601String(),

// sms_collector.dart:267 (et 359)
'sent_at': sentAt.toUtc().toIso8601String(),

// media_store_collector.dart:276
DateTime.fromMillisecondsSinceEpoch(createdAtMs).toUtc().toIso8601String(),
```

Note : `DateTime.fromMillisecondsSinceEpoch` retourne l'heure **locale** par défaut — le `.toUtc()`
est indispensable là aussi.

## Temporary Workaround

Aucun côté monitor_app : élargir la fenêtre de requête history (+2h) masquerait le décalage sans le
corriger et fausserait les regroupements par date. Fix monitored_app requis.

## Verification Steps

1. Déployer le fix sur le device Honor, déclencher une collecte de localisation.
2. Backend : `recorded_at` stocké doit être ≤ heure UTC réelle (plus jamais dans le futur).
3. monitor_app → écran Localisation → l'historique du jour liste les positions (plus de `[]`).
4. Médias/SMS : les regroupements par date correspondent aux dates locales réelles des fichiers/messages.

## Cross-References

- `MONITORED_APP_ISSUE_BOOTSTRAP_HISTORY_LOST_20260609.md` (résolu — bootstrap OK depuis)
- `BACKEND_ISSUE_MISSING_MEDIA_UPLOAD_ENDPOINT_20260610.md` (contenu médias)

---

**Équipe frontend (monitor_app)** : Eric Vekout — **Date de notification** : 2026-06-10

---

## Vérification Post-Fix — 2026-06-17

Sweep complet du working tree effectué le 2026-06-17. Résultat : tous les champs de timestamp
envoyés au backend utilisent bien `.toUtc().toIso8601String()`.

| Fichier | Lignes / champs | Statut vérifié |
| --- | --- | --- |
| `location_collector.dart` | 226, 329, 368 — `recorded_at`, `timestamp` | ✅ `.toUtc()` présent |
| `sms_collector.dart` | 272, 364, 368 — `sent_at`, `collected_at` | ✅ `.toUtc()` présent |
| `apps_collector.dart` | 190–192, 241–242 — `recorded_at`, `start_time`/`end_time`, install times | ✅ `.toUtc()` présent |
| `media_collector.dart` | 413, 498, 591, 695 — `created_at` | ✅ `.toUtc()` présent |
| `media_store_collector.dart` | 276 — `created_at` depuis epoch ms | ✅ `.toUtc()` présent |
| `base_collector.dart` | 203 — `collected_at` | ✅ `.toUtc()` présent |
| `calls_collector.dart` | 265–268, 378–386 | ✅ `.toUtc()` (référence originale) |
| `database_service.dart` | 167, 224–230, 282, 323–325, 371–375, 429 | ✅ `.toUtc()` présent |

**Exceptions intentionnelles (correct as-is)** :

- `apps_collector.dart:173` — clé de groupement par jour calendaire local (`split('T')[0]`) ;
  non envoyé au backend, doit rester local.
- Timestamps internes (SharedPrefs, métriques perf/sync, signaling P2P, télémétrie sécurité)
  — lecture locale uniquement, jamais comparés côté backend.

`flutter analyze` : **0 issues** après corrections de qualité (warnings non liés au bug UTC).

**Statut confirmé** : ✅ Fix 2026-06-12 validé — couverture complète, aucune régression.
