# Monitored App Issue — Médias jamais collectés (permissions média Android 13+/15 non acquises)

**Target Application**: MONITORED_APP (flutter_apps/monitored_app)
**Detected From**: monitor_app (flutter_apps/monitor_app)
**Issue Type**: MONITORED_APP_ISSUE_PERMISSION
**Date Created**: 2026-05-16
**Status**: 🔴 Blocked — implémentation monitored_app requise
**Priority**: High (aucun média — photo/vidéo/audio/screenshot — n'est jamais visible dans monitor_app)
**Data / Feature Affected**: Media (PHOTO, VIDEO, AUDIO, SCREENSHOT)

---

## 1. Issue Summary

monitored_app n'acquiert jamais les permissions média granulaires d'Android 13+ (`READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO`/`READ_MEDIA_AUDIO`) : le scan `MediaStore` est donc systématiquement avorté (`Cannot start scan: media read permissions missing`), aucun fichier média n'est envoyé au backend, et tous les écrans média de monitor_app affichent `count: 0`.

---

## 2. Context & When It Occurred

- **Écran monitor_app affecté** : écrans Médias (PHOTO / VIDEO / AUDIO / SCREENSHOT) consommant `GET /api/v1/media/?device=<id>[&media_type=X]`.
- **Action déclenchante** : après jumelage réussi, ouverture des écrans média ; SMS, appels, localisation, liste d'apps fonctionnent — seuls les médias restent vides.
- **Environnement** : appareil surveillé HONOR NLA-LX2P, **Android 15 (API 35)** ; backend dev `192.168.1.127:8000` ; monitored_app debug.
- **Fréquence** : 100 % systématique.

---

## 3. Expected Behavior (Per Specifications)

D'après `docs/monitor-app-features-guide.md` (section Médias) et la config de collecte renvoyée par le backend :
```
media: {enabled: true, scan_interval_hours: 24, include_thumbnails: false}
```
monitored_app doit scanner périodiquement le `MediaStore` (images/vidéos/audio) et téléverser les métadonnées média vers le backend, qui les expose via `GET /api/v1/media/`. monitor_app doit alors afficher la liste des médias par type.

---

## 4. Actual Behavior (Observed)

### 4.1 Preuve — logs monitored_app (`Log app surveillee.txt`)

```
[MediaStore] Cannot start scan: media read permissions missing      (sections 10, 12, 14 — répété)
[MediaStore] initialized with bootstrapDone=false, lastScanTime=null
```
PATCH statut appareil (section 18) — `permissions_status` envoyé au backend :
```
{location: denied, camera: granted, microphone: granted, contacts: denied,
 sms: granted, call_log: granted, storage: denied}
```
→ La carte de permissions **ne contient même pas** d'entrée média granulaire ; elle ne reporte que `storage` (déprécié sur Android 13+), qui est `denied`.

### 4.2 Preuve — logs backend (`Log backend.txt`, §13)

Toutes les requêtes média répondent `200 52` (réponse paginée vide `{count:0,results:[]}`) :
```
GET /api/v1/media/?device=602fc129...&media_type=PHOTO       200 52
GET /api/v1/media/?device=602fc129...&media_type=SCREENSHOT  200 52
GET /api/v1/media/?device=602fc129...&media_type=AUDIO       200 52
GET /api/v1/media/?device=602fc129...&media_type=VIDEO       200 52
```
→ Le backend stocke et renvoie correctement (réponse vide légitime) : **rien n'a jamais été collecté/envoyé**. La rupture est en **amont**, dans monitored_app (couche collecte).

### 4.3 Analyse de code — où est exactement la rupture

**Le check natif est CORRECT.** `android/app/src/main/kotlin/.../MediaStoreScannerPlugin.kt:62-98` :
```kotlin
private fun hasAnyMediaReadPermission() =
    hasImageReadPermission() || hasVideoReadPermission() || hasAudioReadPermission()
// 13+ → READ_MEDIA_IMAGES/VIDEO/AUDIO via ContextCompat.checkSelfPermission  ✅
```
`AndroidManifest.xml:28-39` déclare correctement `READ_MEDIA_IMAGES/VIDEO/AUDIO` et plafonne `READ_EXTERNAL_STORAGE` à `maxSdkVersion=32`. ✅

**Le défaut est dans l'ACQUISITION des permissions, pas dans leur vérification.** Le scan échoue parce que `READ_MEDIA_IMAGES/VIDEO/AUDIO` ne sont **jamais accordées** sur l'appareil :

1. **`lib/core/collectors/media_store_collector.dart:74-92`** — le fallback Dart de `checkReadPermissions()` (utilisé si le canal natif renvoie `null`/échoue) se termine par :
   ```dart
   return (await Permission.storage.status).isGranted;   // ← FAUX sur Android 13+/15
   ```
   `Permission.storage` (= `READ_EXTERNAL_STORAGE`) est **toujours `denied`** à partir d'Android 13 (déprécié, plafonné `maxSdkVersion=32`). Le bloc 13+ juste au-dessus est correct, mais la dernière ligne reste un piège.

2. **`media_store_collector.dart:94-107`** — `requestReadPermissions()` demande bien `photos/videos/audio` sur 13+, **mais cette méthode n'est appelée par personne dans le flux d'onboarding** : `startCollecting()` se contente de `checkReadPermissions()` puis abandonne si `false`. Aucune demande de permission média n'est donc déclenchée à l'utilisateur.

3. **Onboarding de permissions global** — la carte `permissions_status` (envoyée au backend) mappe les médias sur la clé `storage` et non sur les permissions média granulaires : l'utilisateur n'est jamais invité à accorder `READ_MEDIA_*`, et l'état réel des médias n'est pas reporté.

4. **Android 14+ / accès partiel non géré** — `READ_MEDIA_VISUAL_USER_SELECTED` n'est pas déclaré au manifeste ni traité. Si l'utilisateur choisit « Sélectionner des photos » (accès partiel), `READ_MEDIA_IMAGES` reste `denied` et le scan ne voit rien.

### 4.4 Delta exact

| Attendu | Observé |
|---|---|
| `READ_MEDIA_IMAGES/VIDEO/AUDIO` demandées puis accordées | jamais demandées dans l'onboarding ; fallback teste `Permission.storage` (toujours denied 13+) |
| Scan MediaStore exécuté → médias envoyés | `Cannot start scan: media read permissions missing` |
| `permissions_status.media` reporté au backend | clé absente ; seul `storage: denied` reporté |
| monitor_app affiche les médias | `count: 0` partout |

---

## 5. Monitor App Code Involved

`lib/core/api/safe_connect_api_service.dart` — `getMediaList()` → `GET /media/` (parsing `results` correct, gère la pagination/`results`).
**Preuve que la rupture n'est pas dans monitor_app** : la réponse backend est un `200` paginé **légitimement vide** (`{count:0,results:[]}`, 52 octets). monitor_app affiche fidèlement ce que le backend renvoie ; SMS/appels/localisation/apps fonctionnent via les mêmes briques (même `ApiClient`, même parsing). Aucun POST média n'atteint jamais le backend (logs §13) → la collecte monitored_app est la seule couche en cause.

---

## 6. Required Changes in monitored_app

> Objectif « sûr de fonctionner » : (a) demander explicitement les bonnes permissions, (b) ne plus jamais décider de l'accès média via `Permission.storage` sur Android 13+, (c) gérer l'accès partiel Android 14+, (d) reporter l'état réel au backend.

### 6.1 — Corriger le fallback Dart (obligatoire)

`lib/core/collectors/media_store_collector.dart:91` — remplacer la dernière ligne du `checkReadPermissions()` :
```dart
// AVANT (faux sur 13+/15)
return (await Permission.storage.status).isGranted;

// APRÈS — sur < Android 13 seulement, storage a un sens ; sinon granulaire
if (await _isAndroid13Plus()) {
  final photos = await Permission.photos.status;
  final videos = await Permission.videos.status;
  final audio  = await Permission.audio.status;
  return photos.isGranted || videos.isGranted || audio.isGranted;
}
return (await Permission.storage.status).isGranted;
```
*(Le bloc 13+ existait déjà plus haut ; le but est qu'AUCUN chemin ne retombe sur `Permission.storage` quand `SDK_INT >= 33`.)*

### 6.2 — Demander réellement les permissions média dans l'onboarding (obligatoire)

Brancher `requestReadPermissions()` dans le parcours d'autorisations initial de monitored_app (là où sont déjà demandées SMS/CallLog/etc.), pour Android 13+ :
```dart
await [Permission.photos, Permission.videos, Permission.audio].request();
```
Et **ne plus demander `Permission.storage` sur 13+** (no-op qui fait croire à un refus).

### 6.3 — Déclarer et gérer l'accès partiel Android 14+ (obligatoire pour API 34+)

- `AndroidManifest.xml` — ajouter :
  ```xml
  <uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
  ```
- Native `MediaStoreScannerPlugin.kt` — considérer l'accès accordé si `READ_MEDIA_VISUAL_USER_SELECTED` est `GRANTED` (Android 14+), et scanner alors les éléments visibles (l'accès partiel renvoie le sous-ensemble autorisé via `MediaStore`). Étendre `hasAnyMediaReadPermission()` en conséquence.

### 6.4 — Reporter l'état réel des permissions média au backend (obligatoire)

Dans la construction de `permissions_status` (PATCH `/devices/devices/{id}/`), ajouter des clés explicites reflétant l'état granulaire réel, p.ex. :
```json
"media_images": "granted|denied|partial",
"media_video":  "granted|denied|partial",
"media_audio":  "granted|denied"
```
Cela permet à monitor_app d'afficher « Médias indisponibles : permission refusée sur l'appareil » au lieu d'une liste vide silencieuse.

### 6.5 — Réessayer le scan après obtention tardive de la permission

Si la permission est accordée après le premier `startCollecting()` avorté, déclencher un `_scanAll()` (écouter le retour de `requestReadPermissions()` / un évènement de changement de permission) plutôt que d'attendre le prochain `_scanInterval` (24 h).

---

## 7. Temporary Workaround in monitor_app (If Any)

**Statut** : ⚠️ Atténuation UX possible, ne corrige pas la racine.
monitor_app peut lire `permissions_status` (renvoyé dans le détail appareil) une fois §6.4 livré, et afficher un bandeau explicite sur les écrans Médias (« Permission média refusée sur l'appareil surveillé — demandez à l'utilisateur de l'autoriser ») au lieu d'un état vide ambigu. **Non applicable tant que §6.4 n'expose pas l'état média réel.** Aucun workaround ne peut faire apparaître des médias jamais collectés.

---

## 8. Verification Steps

### 8.1 monitored_app
1. Réinstaller, accorder Photos/Vidéos/Audio à l'invite d'onboarding.
2. `adb logcat -d | findstr /i "MediaStore"` → **plus** de `Cannot start scan: media read permissions missing` ; présence de logs de scan + items collectés.
3. Tester l'accès partiel Android 14+ (« Sélectionner des photos ») → le scan renvoie le sous-ensemble autorisé (pas 0).
4. PATCH appareil : `permissions_status` contient `media_images/video/audio` avec l'état réel.

### 8.2 backend (corrélation, aucun changement requis)
`GET /api/v1/media/?device=<id>` → `count > 0` après le premier scan ; `POST` média visibles dans les logs.

### 8.3 monitor_app (résultat final)
Écrans Médias (PHOTO/VIDEO/AUDIO/SCREENSHOT) : les médias collectés s'affichent ; si permission refusée sur l'appareil, bandeau explicite (après §6.4 + workaround §7).

### 8.4 End-to-end
Ajouter une photo sur l'appareil surveillé → après le cycle de scan → visible dans monitor_app < intervalle de scan configuré.

---

## 9. Monitor App Actions Already Completed

**Statut** : ✅ Aucune modification monitor_app nécessaire pour les **médias** (la couche fautive est monitored_app ; monitor_app affiche fidèlement la réponse vide).

Une amélioration UX monitor_app (bandeau « permission média refusée sur l'appareil ») est **recommandée mais conditionnée à §6.4** (le backend doit d'abord recevoir l'état média réel via `permissions_status`). Elle sera implémentée côté monitor_app une fois §6.4 livré.

*(Note hors périmètre de ce rapport : le problème « liste d'applications partielle » a été résolu côté monitor_app — voir le rapport de session — il s'agissait du filtre `is_system_app` backend + pagination, sans rapport avec les médias.)*

---

## 10. Pointeurs précis dans le code (référence rapide)

| Élément | Fichier | Ligne |
|---|---|---|
| Fallback Dart fautif (`Permission.storage`) | `lib/core/collectors/media_store_collector.dart` | 91 |
| `requestReadPermissions()` non branché à l'onboarding | `lib/core/collectors/media_store_collector.dart` | 94-107 |
| `startCollecting()` avorte sans demander | `lib/core/collectors/media_store_collector.dart` | 51-64 |
| Check natif (correct, à étendre pour accès partiel) | `android/.../MediaStoreScannerPlugin.kt` | 62-98 |
| Manifeste média (ajouter VISUAL_USER_SELECTED) | `android/app/src/main/AndroidManifest.xml` | 28-39 |
| `permissions_status` à enrichir (clés média réelles) | construction du PATCH `/devices/devices/{id}/` (monitored_app) | — |

---

**Fin du rapport.** Document autonome. §6.1 + §6.2 sont obligatoires et suffisants pour Android 13 ; §6.3 obligatoire pour Android 14+/15 (cas de l'appareil testé, API 35) ; §6.4 nécessaire pour un diagnostic correct côté monitor_app. Aucune modification backend requise.
