# Issue Backend - Contrat de duree media en millisecondes

**Type d'Issue** : BE_ISSUE_FORMAT  
**App Cible** : backend (`safeconnect-env/safeconnect`)  
**Origine** : unification de `duration` dans `monitored_app`  
**Date de Creation** : 2026-06-07  
**Statut** : Bloque - alignement backend requis avant de retirer les compatibilites  
**Priorite** : Moyenne  
**Type de Donnees Affecte** : Medias  
**Endpoints Affectes** : `POST /api/v1/data/collect/`, `GET /api/v1/media/`

## 1. Resume de l'Issue

Monitored_app normalise desormais toutes les durees audio/video en
millisecondes, alors que le commentaire du modele backend indique encore des
secondes et que les donnees historiques peuvent contenir les deux unites.

## 2. Contexte et Origine

Android MediaStore retourne nativement les durees en millisecondes. Les
captures distantes retournaient des secondes. Monitored_app convertit maintenant
les secondes natives avant la persistance locale et avant le payload :

```json
{ "duration": 10000 }
```

pour un media de dix secondes.

## 3. Comportement Backend Attendu

- `MediaFile.duration` represente toujours des millisecondes.
- L'API conserve la valeur sans conversion implicite.
- La documentation et les tests rendent l'unite explicite.
- Les anciennes lignes en secondes sont migrees avant la suppression des
  compatibilites cote monitor_app.

## 4. Comportement Backend Actuel

`apps/media/models.py` declare :

```python
duration = models.IntegerField(null=True, blank=True)  # en secondes
```

`services/data_collection_service.py::_process_media_data` stocke la valeur
brute, sans unite ni validation. La base peut donc contenir des secondes et des
millisecondes simultanement.

## 5. Changement de Contrat API

Avant :

```json
{ "duration": 10 }
```

Apres :

```json
{ "duration": 10000 }
```

Le nom du champ reste `duration`; son unite contractuelle devient la
milliseconde.

## 6. Changements Requis dans le Backend

- Modifier le commentaire/help text du modele et la documentation API.
- Ajouter une validation `duration >= 0`.
- Ajouter des tests de collecte et de serialization pour audio/video.
- Definir et executer une migration de donnees pour les captures historiques
  stockees en secondes.
- Ne pas utiliser une heuristique fondee uniquement sur la taille de la valeur :
  un media court en millisecondes peut ressembler a un media long en secondes.
- Utiliser la provenance fiable (`source_type`, relation de capture ou date de
  deploiement) pour la migration.

## 7. Changements Monitored App Deja Effectues

- `lib/core/utils/media_duration_utils.dart` convertit les secondes en
  millisecondes et accepte les nombres natifs entiers ou decimaux.
- `lib/core/collectors/media_collector.dart` utilise la valeur normalisee dans
  SQLite et dans le payload.
- `lib/core/database/tables.dart` documente l'unite locale.
- `docs/API-Endpoints-Application-Surveillee.md` documente l'unite API.

## 8. Etapes de Verification

1. Envoyer une capture de dix secondes avec `duration: 10000`.
2. Verifier que la base et `GET /api/v1/media/` retournent `10000`.
3. Migrer un echantillon de captures historiques.
4. Verifier qu'aucun media MediaStore deja en millisecondes n'est multiplie.
5. Executer les tests backend de collecte, liste et detail media.

