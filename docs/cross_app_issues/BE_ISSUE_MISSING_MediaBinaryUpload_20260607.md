# Issue Backend - Transfert binaire des medias absent

**Type d'Issue** : BE_ISSUE_MISSING  
**App Cible** : backend (`safeconnect-env/safeconnect`)  
**Origine** : audit du pipeline media dans `monitored_app`  
**Date de Creation** : 2026-06-07  
**Statut** : Bloque - implementation backend requise  
**Priorite** : Haute  
**Type de Donnees Affecte** : Medias  
**Endpoints Affectes** : `POST /api/v1/data/collect/`, API media, WebSocket/P2P

## 1. Resume de l'Issue

Le backend stocke uniquement les metadonnees et un chemin Android local. Il ne
possede aucun endpoint operationnel permettant a `monitored_app` d'envoyer le
fichier ou sa vignette, donc les telechargements backend retournent 404.

## 2. Contexte et Origine

Le collecteur MediaStore et les captures distantes envoient actuellement :

```json
{
  "media_id": "video_123",
  "file_path": "/storage/emulated/0/DCIM/video.mp4",
  "file_name": "video.mp4",
  "mime_type": "video/mp4",
  "file_size": 2048576
}
```

Fichiers monitored_app audites :

- `lib/core/collectors/media_store_collector.dart`
- `lib/core/collectors/media_collector.dart`
- `lib/core/services/data_collector_service.dart`
- `lib/core/network/p2p_command_handler.dart`

Le backend traite ces donnees dans
`services/data_collection_service.py::_process_media_data`, mais :

- `media_id` fourni par monitored_app n'est pas persiste ;
- `local_path` contient un chemin Android inaccessible au serveur ;
- `storage_status` reste `TEMP` ;
- `thumbnail_path` ne peut pas pointer vers un fichier serveur ;
- aucune route d'upload binaire media n'est exposee.

## 3. Comportement Backend Attendu

Le backend doit supporter un transfert a la demande, avec P2P en priorite et
upload HTTPS en fallback :

1. Persister un identifiant client stable (`client_media_id`) lors de la
   collecte des metadonnees.
2. Retourner cet identifiant dans l'API media et les commandes de transfert.
3. Fournir une URL d'upload authentifiee, bornee dans le temps et liee au media.
4. Stocker le fichier dans un stockage gere par le backend.
5. Generer ou accepter une vignette valide.
6. Mettre a jour `storage_status`, `is_transferred`, `local_path` et
   `thumbnail_path` seulement apres verification du fichier.

## 4. Comportement Backend Actuel

`apps/media/views.py::download` tente d'ouvrir `MediaFile.local_path` sur le
serveur. Pour un chemin Android, `os.path.isfile(local_path)` est toujours faux.

Le mecanisme `MediaTransfer` emet `media_transfer_request`, mais l'identifiant
envoye est l'UUID backend. Monitored_app ne peut pas le faire correspondre a son
fichier local, car son `media_id` d'origine n'est pas conserve.

## 5. Changement de Contrat API

Endpoint recommande :

```text
POST /api/v1/media/{media_id}/content/
Authorization: Bearer <device-token>
Content-Type: multipart/form-data
```

Champs :

```text
file: binaire obligatoire
thumbnail: binaire optionnel
checksum_sha256: texte obligatoire
client_media_id: texte obligatoire
```

Reponse :

```json
{
  "id": "backend-media-uuid",
  "client_media_id": "video_123",
  "storage_status": "STORED",
  "is_transferred": true,
  "download_url": "https://.../api/v1/media/.../download/",
  "thumbnail_url": "https://.../api/v1/media/.../thumbnail/"
}
```

Codes attendus : `200/201`, `400`, `401`, `403`, `404`, `409`, `413`, `422`.

## 6. Changements Requis dans le Backend

- Ajouter `client_media_id` a `MediaFile`, unique par appareil.
- Ajouter un endpoint multipart avec limite de taille, validation MIME,
  checksum et ecriture atomique.
- Ne jamais faire confiance au nom ou chemin fourni par le device.
- Generer une vignette serveur pour les images/videos si elle n'est pas fournie.
- Mettre a jour `storage_status='STORED'` uniquement apres succes.
- Ajouter un quota par appareil et une politique Wi-Fi/taille configurable.
- Faire referencer `client_media_id` dans `media_transfer_request`.
- Ajouter des tests d'autorisation, taille, checksum, MIME, doublon et reprise.

## 7. Changements Monitored App Deja Effectues

Aucun faux upload n'a ete ajoute. Le code continue d'envoyer les metadonnees,
car envoyer du base64 dans `/data/collect/` contournerait les limites de lots et
augmenterait fortement la consommation memoire, reseau et batterie.

Le pipeline de duree media a ete fiabilise separement :

- `lib/core/utils/media_duration_utils.dart`
- `lib/core/collectors/media_collector.dart`

## 8. Etapes de Verification

1. Collecter un media et verifier que `client_media_id` est retourne.
2. Demander son transfert depuis monitor_app.
3. Verifier que monitored_app recoit le meme `client_media_id`.
4. Uploader un fichier avec checksum valide.
5. Verifier `storage_status == "STORED"` et `is_transferred == true`.
6. Telecharger le fichier et la vignette avec authentification.
7. Verifier le rejet des fichiers trop grands, MIME interdits et checksums faux.

