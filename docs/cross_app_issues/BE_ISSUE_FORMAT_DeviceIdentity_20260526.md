# Issue Backend - Persistance du nom reel de l'appareil surveille

**Type d'Issue** : BE_ISSUE_FORMAT  
**App Cible** : backend (safeconnect-env/safeconnect)  
**Origine** : changement dans monitored_app  
**Date de Creation** : 2026-05-26  
**Statut** : Rouge - implementation backend requise si le serializer ignore ou rejette ces champs  
**Priorite** : Moyenne  
**Type de Donnees Affecte** : Device identity / statut appareil  
**Endpoints Affectes** : `PATCH /api/v1/devices/devices/{device_id}/`, `GET /api/v1/devices/devices/{device_id}/`, `GET /api/v1/devices/devices/`

## 1. Resume de l'Issue

`monitored_app` envoie maintenant `device_name` et `device_model` pour remplacer les placeholders crees avant jumelage; le backend doit accepter, persister et re-exposer ces champs.

## 2. Contexte & Origine (Dans Monitored App)

- Correctif declenche par `debug docs/MONITORED_APP_ISSUE_DEVICE_NAME_NOT_UPDATED_POST_PAIRING_20260526.md`.
- Fichiers monitored_app affectes :
  - `lib/core/services/device_service.dart`
  - `lib/core/utils/device_utils.dart`
- Nouveau comportement :
  - `DeviceUtils.getDeviceInfo()` inclut `device_name` et `device_model`.
  - `DeviceService.updateDeviceStatus()` inclut `device_name` dans le `PATCH` de statut.
- Effet attendu : apres jumelage, le premier `DeviceService.initialize()` envoie l'identite reelle de l'appareil avec le status update initial.

## 3. Comportement Backend Attendu

- Accepter `device_name` et `device_model` dans `PATCH /api/v1/devices/devices/{device_id}/`.
- Mettre a jour les champs persistants de l'appareil surveille.
- Retourner les valeurs reelles dans les endpoints detail et liste afin que `monitor_app` n'affiche plus :
  - `Mon appareil (en cours de jumelage)`
  - `A configurer`

## 4. Comportement Backend Actuel (Le Decalage)

Le rapport d'origine indique que le backend initialise des placeholders pre-pairing et qu'ils restent visibles apres jumelage. La spec locale `docs/API-Endpoints-Application-Surveillee.md` documente le `PATCH` de statut mais ne liste pas encore `device_name` ni `device_model` dans son body, ce qui suggere un contrat incomplet ou un serializer non aligne.

## 5. Changement de Contrat API (Detaille)

Endpoint modifie :

- Methode : `PATCH`
- URL : `/api/v1/devices/devices/{device_id}/`
- Auth : Bearer token de l'appareil surveille
- Corps de requete attendu, en plus des champs de statut existants :

```json
{
  "device_name": "Samsung Galaxy A52",
  "device_model": "Samsung Galaxy A52"
}
```

- Reponse : la reponse detail/liste doit exposer au moins un de ces formats deja lus par monitor_app :

```json
{
  "device_name": "Samsung Galaxy A52",
  "device_model": "Samsung Galaxy A52"
}
```

ou, pour compatibilite avec la spec actuelle :

```json
{
  "name": "Samsung Galaxy A52",
  "model": "Samsung Galaxy A52"
}
```

## 6. Changements Requis dans le Backend

- Verifier le serializer/viewset device et autoriser `device_name` et `device_model` en update partiel.
- Mapper proprement les alias si le modele backend utilise `name`/`model` au lieu de `device_name`/`device_model`.
- Garantir que l'appareil authentifie ne peut mettre a jour que son propre enregistrement.
- Ajouter ou ajuster les tests API pour :
  - `PATCH` avec `device_name` + `device_model`;
  - persistance en base;
  - presence des valeurs reelles dans `GET detail` et `GET list`.
- Mettre a jour `docs/API-Endpoints-Application-Surveillee.md` pour documenter ces champs.

## 7. Changements Monitored App Deja Effectues

- `lib/core/utils/device_utils.dart`
  - Ajout de `device_name` et `device_model` dans `getDeviceInfo()`.
  - Ajout de `getDeviceName()` et d'un formatage Android stable `Brand Model`.
- `lib/core/services/device_service.dart`
  - Ajout de `device_name` au payload de `updateDeviceStatus()`.

Validation locale :

- `dart format lib/core/utils/device_utils.dart lib/core/services/device_service.dart`
- `dart analyze lib/core/utils/device_utils.dart lib/core/services/device_service.dart` : aucune issue.
- `flutter analyze` et `flutter test` echouent encore sur des erreurs preexistantes hors scope dans les tests/services security, anti-tamper, emergency et database.

## 8. Etapes de Verification

1. Jumeler un appareil avec monitored_app.
2. Verifier dans les logs monitored_app que `Device status updated successfully` apparait apres le jumelage.
3. Depuis Postman/curl, appeler :

```bash
curl -H "Authorization: Bearer <token>" \
  https://<backend>/api/v1/devices/devices/<device_id>/
```

4. Confirmer que `device_name` et `device_model` ne valent plus les placeholders.
5. Ouvrir monitor_app Dashboard et liste des appareils; verifier que le nom reel de l'appareil est affiche.
