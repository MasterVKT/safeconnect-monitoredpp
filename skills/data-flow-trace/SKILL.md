---
name: data-flow-trace
description: "Trace monitored_app data from Android collection source through the full pipeline to backend delivery, to diagnose exactly where data is lost, corrupted, or not sent. Use when data is missing in monitor_app, when the backend does not receive expected data, when a collector appears to stop in background, or after a device reboot. Maps the complete pipeline: Android sensor/ContentProvider → MethodChannel → Dart collector → local SQLite → background service sync → HTTP/WebSocket to backend. Triggers on: données manquantes, données non reçues, collecteur arrêté, données incorrectes, sync bloquée, arrêt en arrière-plan, après redémarrage, données non affichées dans monitor_app."
argument-hint: "Spécifier le type de données (SMS / appels / localisation / apps / médias / batterie) et le symptôme observé (manquant, valeur incorrecte, s'arrête après X min, après redémarrage, après révocation de permission)."
user-invocable: true
---

# Data Flow Trace — Monitored App (XP SafeConnect)

## Purpose
Diagnostiquer exactement où les données se cassent dans le pipeline de collecte de monitored_app — depuis le capteur Android jusqu'à la livraison au backend.

**Cette skill ne modifie pas de code.** Elle identifie la couche cassée et route vers la skill de correctif appropriée.

## Carte du Pipeline

```
[Android OS / Capteur / ContentProvider]
    ↓ (ContentProvider / BroadcastReceiver / FusedLocationProvider / UsageStatsManager)
[Plugin Kotlin Natif]
    android/app/src/main/kotlin/.../[Plugin].kt
    ↓ (MethodChannel.invokeMethod → Dart)
[Collecteur Dart]
    lib/core/collectors/[type]_collector.dart
    ↓ (BaseCollector → cache / queue)
[Stockage SQLite Local]
    lib/core/services/storage_service.dart
    ↓ (trigger de sync BackgroundService)
[DataCollectorService]
    lib/core/services/data_collector_service.dart
    ↓ (HTTP POST / WebSocket send)
[Backend API]
    docs/API-Endpoints-Application-Surveillee.md
    ↓
[Affichage Monitor App]
    flutter_apps/monitor_app
```

## Catégories de Points de Rupture

| Couche | Point de Rupture | Symptôme |
|---|---|---|
| Android OS | Permission refusée | Le collecteur retourne vide, sans erreur |
| Android OS | Optimisation batterie tue le process | Les données s'arrêtent après ~30 min en arrière-plan |
| Android OS | Doze mode bloque l'exécution | Sync irrégulière en arrière-plan profond |
| Plugin Kotlin | Cursor non fermé / NPE | Crash sur l'appel MethodChannel |
| Plugin Kotlin | Mauvais range de dates en query | Données partielles ou dupliquées |
| MethodChannel | Décalage de nom de méthode | Exception PlatformException côté Dart |
| MethodChannel | Décalage de type retourné | Cast NPE ou ClassCastException dans Dart |
| Collecteur Dart | Erreur de parsing | Exception dans fromJson / cast de type |
| Collecteur Dart | Filtre trop restrictif | Items valides exclus |
| Stockage SQLite | Violation de contrainte | Données non persistées / insert échoue silencieusement |
| Stockage SQLite | Flag pending-sync manquant | Données locales jamais marquées pour sync |
| Service de fond | Service non démarré | File d'attente grossit, jamais envoyée |
| Service de fond | Optimisation batterie | Service tué, redémarrage non géré |
| HTTP/WS | Erreur réseau / auth expirée | 401/403/500, données en file non envoyées |
| Backend API | Mauvais nom de champ / erreur de validation | 400 avec erreur de champ, données rejetées |
| Backend API | Permission insuffisante du device | 403, données rejetées |

## Utiliser Quand
- Un type de données est entièrement absent dans monitor_app
- Les données s'arrêtent après un certain temps (kill en arrière-plan)
- Les données affichent des valeurs incorrectes (fuseau horaire, encodage, nom de champ)
- Les données sont présentes dans SQLite mais non synchronisées au backend
- Après un redémarrage de l'appareil, la collecte ne redémarre pas
- Après révocation/octroi de permission, l'état de collecte est inconnu
- Données sporadiques (fonctionne parfois, pas toujours)

## Workflow Obligatoire

### 1. Définir la Portée de la Trace
- Type de données : SMS / appels / localisation / apps / médias / batterie
- Symptôme : [manquant / valeur incorrecte / s'arrête après X / redémarrage / permission]
- Dernier état connu correct (si applicable)
- Version Android du device cible (les permissions varient selon API level)
- Conditions de reproduction : toujours / seulement en arrière-plan / seulement après reboot

### 2. Cartographier les Faits Connus
Lister ce qui est confirmé à chaque couche :
```
Plugin Kotlin      : [fonctionne / échoue / non testé]
MethodChannel      : [contrat correct / décalage / non testé]
Collecteur Dart    : [parse correctement / erreur / non testé]
SQLite             : [données présentes / vide / non testé]
Service de fond    : [en cours / arrêté / non testé]
HTTP/WS            : [envoyé / erreur / en file / non testé]
Backend            : [reçu / rejeté / non testé]
```

### 3. Identifier les Points de Rupture Candidats
Selon le pattern de symptôme :

| Symptôme | Couches Candidates |
|---|---|
| Données manquantes, app au premier plan | Plugin Kotlin ou MethodChannel |
| Fonctionne au premier plan, s'arrête en arrière-plan | Lifecycle BackgroundService ou optimisation batterie |
| Données dans SQLite, non synchronisées | Trigger de sync DataCollectorService ou connectivité/auth |
| Synchronisées mais valeurs incorrectes | Parsing Dart, mapping de champs, ou fuseau horaire |
| S'arrête après reboot | BootCompletedReceiver ou redémarrage BackgroundService |
| Données partielles | Range du cursor, pagination, ou logique de filtre dans Kotlin |
| Sporadique | Auth token expiré pendant la fenêtre de sync, ou Doze mode |

### 4. Inspecter Chaque Couche Candidate

#### Couche Kotlin (`android/app/src/main/kotlin/`)
- Le plugin lit-il le ContentProvider correctement ?
- `cursor.close()` s'exécute-t-il toujours (même en cas d'exception) ?
- Tous les champs requis sont-ils présents dans la map retournée ?
- Le résultat MethodChannel est-il un `List<Map<String, Any>>` ?
- La query SQL contient-elle le bon range de dates (pas de dérive d'offset) ?
- Les permissions sont-elles vérifiées avant l'accès aux données sensibles ?

#### Contrat MethodChannel (côté Dart : `lib/core/collectors/[type]_collector.dart`)
- Le nom de `invokeMethod` correspond-il exactement au nom de méthode Kotlin ?
- Le cast Dart correspond-il au type de retour Kotlin ?
- Un try-catch entoure-t-il l'appel `invokeMethod` ?
- L'argument PlatformException est-il géré séparément ?

#### Collecteur Dart (`lib/core/collectors/`)
- `fromJson` gère-t-il tous les champs null possibles ?
- Le timestamp est-il parsé dans le bon fuseau horaire ?
- La liste retournée est-elle safe si vide ?
- Les doublons sont-ils filtrés (même item collecté deux fois) ?

#### Stockage (`lib/core/services/storage_service.dart`)
- L'insert réussit-il (pas de violations de contraintes silencieuses) ?
- La bonne table est-elle utilisée ?
- Le flag pending-sync est-il activé après insert ?
- La capacité du buffer local est-elle dépassée (données les plus anciennes supprimées) ?

#### Service de Fond (`lib/core/services/background_service.dart`, `lib/background_service_entry.dart`)
- Le service est-il réellement en cours ? (vérifier la notification persistante)
- Le trigger de sync se déclenche-t-il à l'intervalle attendu ?
- L'optimisation batterie empêche-t-elle l'exécution ? (vérifier logs BatteryMonitorService)
- Le BootCompletedReceiver redémarre-t-il le service après reboot ?
- Le service se relance-t-il après kill par l'OS (START_STICKY) ?

#### HTTP/WS (`lib/core/api/api_client.dart`, `lib/core/services/websocket_service.dart`)
- Le token d'auth est-il valide ? (vérifier expiry vs timing de sync)
- Le bon endpoint est-il appelé ?
- Le schéma de payload correspond-il à la spec API ?
- Le retry de sync est-il géré en cas d'échec réseau ?

### 5. Identifier la Couche Cassée
Conclure avec l'une des classifications :
- `CASSÉ_À_[COUCHE]` — couche de cause racine confirmée
- `SUSPECTÉ_À_[COUCHE]` — couche la plus probable, pas 100% confirmé
- `COUCHES_MULTIPLES` — ex: Kotlin + MethodChannel tous les deux cassés (décrire chacun)

### 6. Router vers la Skill de Correctif

| Couche Cassée | Router Vers | Notes |
|---|---|---|
| Plugin Kotlin / MethodChannel | `background-services-collectors` | Correctif bridge natif |
| Collecteur Dart | `bug-fixing` | Correctif logique de parsing |
| Stockage SQLite | `bug-fixing` | Correctif schéma/insert stockage |
| Lifecycle BackgroundService | `background-services-collectors` | Correctif redémarrage/batterie |
| Envoi HTTP/WS | `bug-fixing` + éventuellement `backend-integration-reporting` | Correctif auth/réseau |
| Backend rejette le payload | `cross-app-issue-authoring` (cible: BE) | Correctif contrat API requis |
| Monitor app affiche incorrect | `cross-app-issue-authoring` (cible: MO) | Correctif parser monitor_app requis |

### 7. Rapport de Complétion de Trace

```
## RAPPORT DE TRACE DU FLUX DE DONNÉES — [Type de Données]
Date: [YYYY-MM-DD]
Symptôme: [description courte]
Scope: [type de données + plateforme + Android API level]
Conditions: [toujours / seulement arrière-plan / seulement après reboot]

### État du Pipeline
| Couche | Statut | Preuves |
|---|---|---|
| Plugin Kotlin | [✅/❌/⚠️/❓] | [preuve] |
| MethodChannel | [✅/❌/⚠️/❓] | [preuve] |
| Collecteur Dart | [✅/❌/⚠️/❓] | [preuve] |
| Stockage SQLite | [✅/❌/⚠️/❓] | [preuve] |
| Service de Fond | [✅/❌/⚠️/❓] | [preuve] |
| HTTP/WS | [✅/❌/⚠️/❓] | [preuve] |
| Backend | [✅/❌/⚠️/❓] | [preuve] |

### Cause Racine
CASSÉ_À_[COUCHE] : [description]

### Preuves
- [référence de code spécifique, ligne de log, ou comportement observé]

### Route de Correctif
- Principale : [skill + action spécifique]
- Secondaire cross-app (si applicable) : [cross-app-issue-authoring cible: MO/BE]
```

## Référence Rapide des Fichiers par Type de Données

| Type | Plugin Kotlin | Collecteur Dart |
|---|---|---|
| SMS | `SmsCollectorPlugin.kt` | `lib/core/collectors/sms_collector.dart` |
| Appels | `CallsCollectorPlugin.kt` | `lib/core/collectors/calls_collector.dart` |
| Localisation | (FusedLocationProvider) | `lib/core/collectors/location_collector.dart` |
| Applications | `AppsCollectorPlugin.kt` | `lib/core/collectors/apps_collector.dart` |
| Médias | `MediaCapturePlugin.kt` | `lib/core/collectors/media_collector.dart` |
| Service de fond | `BackgroundCollectorService.kt` | `lib/core/services/background_service.dart` |

## Langue de Sortie
- Français par défaut sauf si l'utilisateur demande autrement
- Références techniques de fichiers et extraits de code restent en anglais
