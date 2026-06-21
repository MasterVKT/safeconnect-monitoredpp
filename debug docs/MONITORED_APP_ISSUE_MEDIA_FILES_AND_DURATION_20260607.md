# Monitored App Issue — Fichiers média non transférés + incohérence unité durée

**Issue Type**: MONITORED_APP_ISSUE_MEDIA
**Date Created**: 2026-06-07
**Status**: Partiellement résolu — B2 implémenté, B1 bloqué par le contrat backend
**Priority**: Haute (B1) / Moyenne (B2)
**Cible**: `monitored_app` (Android) + décision architecture produit
**Device ID backend**: `9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`

**⚠️ Mise à jour 2026-06-09** : le backend signale désormais `count: 0` pour les médias du device Honor
(`9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`). La cause est un bug de bootstrap premature-done dans
`media_store_collector.dart` qui a effacé le checkpoint historique lors d'un scan sur permission non
accordée. Voir `MONITORED_APP_ISSUE_BOOTSTRAP_HISTORY_LOST_20260609.md` pour le fix. Ce bug est un
**prérequis** : B1 (transfert fichiers) ne peut produire des résultats que si les métadonnées existent.

---

Deux sous-problèmes distincts dans ce fichier :

- **B1** — Les fichiers médias (photos, vidéos, audio) ne sont jamais transférés vers le serveur
- **B2** — La durée des médias galerie est en millisecondes, les captures distantes en secondes : incohérence d'unité qui corrompt l'affichage

**Mise à jour d'implémentation 2026-06-09** :
- **B2 est résolu côté monitored_app** : les captures audio/vidéo sont converties
  en millisecondes avant la persistance locale et avant l'envoi API.
- **B1 reste bloqué côté backend** : l'option retenue est l'upload complet à la
  demande, avec P2P prioritaire et HTTPS en fallback. Le backend doit d'abord
  persister `client_media_id` et exposer un endpoint multipart sécurisé.
- Rapports associés :
  `docs/cross_app_issues/BE_ISSUE_FORMAT_MediaDurationMilliseconds_20260607.md`,
  `docs/cross_app_issues/MO_ISSUE_FORMAT_MediaDurationMilliseconds_20260607.md`
  et
  `docs/cross_app_issues/BE_ISSUE_MISSING_MediaBinaryUpload_20260607.md`.

---

## B1 — Fichiers non transférés

### Issue Summary B1

Tous les médias ont `storage_status = 'TEMP'` et `thumbnail_url = null`. Le backend ne reçoit que les **métadonnées** (chemin Android local, type MIME, taille, dates). Les fichiers eux-mêmes restent sur le device Android. Il est impossible d'afficher les vignettes, les photos, ou de lire les vidéos/audio depuis monitor_app.

### Context B1

**Date de constatation**: 2026-06-07  
**Écran monitor_app**: Médias → grille → icônes placeholder (photo_library, videocam, etc.) sans vignette  
**Action**: Cliquer sur un média → message "Fichier temporaire" (`cloud_off`) car `storage_status == 'TEMP'`  
**Volume**: 45 médias sur backend, tous `TEMP`

### Expected Behavior B1

L'écran médias devrait afficher :
- Une **vignette** miniature pour chaque photo/vidéo
- La possibilité de **télécharger** le fichier original depuis le device surveillé
- Pour les captures distantes (screenshot, audio, vidéo commandée) : même comportement

### Actual Behavior B1

**Backend** (`GET /api/v1/media/?device=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721`) :
```json
{
  "results": [
    {
      "id": "...",
      "media_type": "PHOTO",
      "storage_status": "TEMP",
      "thumbnail_url": null,
      "download_url": "http://.../media/.../download/",
      "local_path": "/storage/emulated/0/DCIM/Camera/IMG_20260601_123456.jpg"
    }
  ]
}
```

`local_path` est un **chemin Android device** — inaccessible depuis le serveur.  
`thumbnail_url` est `null` — pas de vignette.  
`download_url` retourne 404 car `os.path.isfile(local_path)` échoue côté serveur.

### Architectual Root Cause B1

**Fichier**: `monitored_app/lib/core/collectors/media_store_collector.dart`

```dart
// media_store_collector.dart:202 (approximatif)
'duration': _readInt(item['duration']),   // ms
'local_path': item['_data'],              // chemin Android local
// Aucun transfert de fichier vers le backend
// Aucune génération de thumbnail
```

La collecte MediaStore enregistre les métadonnées mais **n'uploade pas le contenu** :
- Pas de code d'upload dans `MediaStoreCollector`
- `MediaCollector` (captures distantes) : même comportement
- `storage_status` reste `'TEMP'` côté backend car le fichier n'arrive jamais

### Required Changes B1 — Décision produit requise

**Trois options (par ordre de complexité croissante) :**

#### Option 1 — Thumbnail uniquement (le plus simple)
Générer une vignette compressée (JPEG, ex. 200×200, qualité 30%) lors de la collecte et l'envoyer avec les métadonnées (base64 ou upload séparé).

**Avantages**: pas de transfert complet; affichage visuel immédiat  
**Limite**: pas de lecture audio/vidéo, pas de téléchargement de l'original

Fichier à modifier: `lib/core/collectors/media_store_collector.dart`
```dart
// Ajouter dans collectItem :
final thumbnail = await _generateThumbnail(localPath, mediaType);
mediaData['thumbnail_base64'] = thumbnail; // ou upload séparé
```

#### Option 2 — Upload complet sur commande (recommandé)
Ajouter un endpoint de déclenchement dans monitored_app : quand monitor_app demande un média spécifique, monitored_app uploade le fichier vers le backend.

**Avantages**: transfert à la demande, pas de bande passante inutile  
**Limite**: délai asynchrone (l'utilisateur attend)

Nécessite : nouveau MethodChannel ou FCM command dans monitored_app + nouveau endpoint backend `POST /api/v1/media/{id}/upload/`.

#### Option 3 — Background upload automatique (le plus complet)
Uploader tous les nouveaux fichiers médias en arrière-plan lors de chaque sync.

**Avantages**: toujours disponible  
**Limite**: consommation batterie + données mobiles significative

**→ Décision requise avant implémentation** : quelle option ? Avec quota/taille max ?

---

## B2 — Incohérence unité durée (ms vs secondes)

### Issue Summary B2

Les médias de la **galerie** (`source_type = DEVICE_ORIGINAL`) envoient la durée en **millisecondes** (valeur brute Android MediaStore). Les **captures distantes** (`MANUAL`, `SCHEDULED`, `TRIGGERED`, `EMERGENCY`) envoient la durée en **secondes**. Cette incohérence corrompt l'affichage dans monitor_app.

### Context B2

**Date**: 2026-06-07  
**Symptôme observé**: Clip Snapchat de 10s affiché "2:46:40" dans monitor_app  
**Valeur backend**: `duration: 10000` pour un clip de 10s → 10000 ms

### Root Cause B2

**Fichier A** (galerie): `lib/core/collectors/media_store_collector.dart:202`
```dart
'duration': _readInt(item['duration']),
// Android MediaStore.Video.Media.DURATION = MILLISECONDES (norme Android)
// Exemple : clip 10s → 10000
```

**Fichier B** (captures): `lib/core/collectors/media_collector.dart:576`
```dart
'duration': actualDuration.toInt(),
// actualDuration provient de result['duration'] du plugin Flutter audio/vidéo
// = SECONDES (plugin Dart convention)
// Exemple : clip 10s → 10
```

### Contournement actuel (monitor_app — appliqué en c14f171+)

`media_service.dart` normalise à la frontière de parsing via `_normalizeMediaDurationSeconds` :
```dart
// Si source_type == 'DEVICE_ORIGINAL' → divise par 1000 (ms→s)
// Sinon (captures) → conserve tel quel (déjà en secondes)
```
Ce contournement est nécessaire tant que monitored_app n'unifie pas l'unité.

### Required Changes B2 — Unification côté monitored_app (recommandé)

**Objectif**: que `duration` soit toujours en **millisecondes** dans les données envoyées au backend (cohérent avec Android MediaStore, standard natif).

**Fichier à modifier**: `lib/core/collectors/media_collector.dart:576`
```dart
// Avant
'duration': actualDuration.toInt(),

// Après
'duration': (actualDuration * 1000).toInt(), // secondes → ms pour cohérence
```

Et documenter dans le modèle backend (`MediaFile`) que `duration` = millisecondes.

Lorsque ce fix sera déployé, supprimer le contournement `sourceType` de `monitor_app/lib/features/media/services/media_service.dart` et utiliser une conversion ms→s uniforme :
```dart
// Remplacer _normalizeMediaDurationSeconds par :
'duration': (raw as num? ?? null) != null ? (raw as num).toInt() ~/ 1000 : null,
```

**Statut 2026-06-09** : implémenté dans
`lib/core/utils/media_duration_utils.dart` et
`lib/core/collectors/media_collector.dart`, couvert par
`test/unit/utils/media_duration_utils_test.dart`. La suppression du
contournement monitor_app reste conditionnée à la migration des données
historiques backend.

---

## Verification Steps

### B1 — Après implémentation de l'option choisie

1. Installer nouveau APK monitored_app sur le device Honor
2. Déclencher sync (ouvrir monitor_app → "Sync")
3. Vérifier backend :
   ```bash
   curl -H "Authorization: Bearer <TOKEN>" \
     "http://<API_URL>/api/v1/media/?device=9989a82e-fcd6-4ceb-a2fd-3df0dd3dd721"
   # Expected: storage_status != 'TEMP' ET thumbnail_url != null
   ```
4. Dans monitor_app → Médias → vignettes visibles (non placeholder)
5. Cliquer sur un média → téléchargement réussi (pas de 404)

### B2 — Après unification ms côté monitored_app

1. Valeur backend attendue pour clip 10s: `duration: 10000` (ms) pour les deux types
2. monitor_app avec conversion uniforme ms→s : "0:10" affiché pour un clip 10s
3. Slider de capture audio (`media_screen.dart:823`) : non impacté (passe des vraies secondes à `_formatDuration`, indépendant de la normalisation service)

---

## Open Questions

- [x] Option choisie pour le transfert fichiers : Option 2, upload complet à la demande
- [ ] Quota taille max par fichier ? (Ex. photos max 2 MB compressées)
- [ ] Accès WiFi uniquement pour upload ?
- [x] Durée en ms unifiée dans monitored_app
- [ ] Durée en ms documentée et migrée dans le modèle backend (`apps/media/models.py`) ?

---

**Équipe frontend (monitor_app)**: Eric Vekout
**Date de notification**: 2026-06-07
**Commits de contexte**: `c14f171` (monitor_app contournement B2), `47919c8` (fix download 401 backend)
