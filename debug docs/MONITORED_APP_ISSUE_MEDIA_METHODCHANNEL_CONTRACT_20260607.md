# Monitored App Issue - Contrat MethodChannel de capture media incompatible

**Issue Type**: MONITORED_APP_ISSUE_MEDIA_NATIVE
**Date Created**: 2026-06-07
**Status**: Bloque - implementation Android de production requise
**Priority**: Haute
**Cible**: `monitored_app` Android

## 1. Resume

Le collecteur Dart et le plugin Android n'exposent pas le meme contrat pour
les captures photo, audio et video. Les commandes distantes de capture peuvent
donc retourner `notImplemented`, un type inattendu ou un chemin vers un fichier
inexistant.

## 2. Contrat Dart actuel

`lib/core/collectors/media_collector.dart` invoque :

- `captureAdvancedPhoto` et attend une `Map` ;
- `recordAdvancedAudio` et attend une `Map` ;
- `recordAdvancedVideo` et attend une `Map`.

Les cartes attendues contiennent au minimum `filePath`, `fileSize` et, pour
l'audio ou la video, `duration` en secondes avant normalisation en
millisecondes.

## 3. Contrat Android actuel

`android/app/src/main/kotlin/com/xpsafeconnect/monitored_app/MediaCapturePlugin.kt`
ne gere que :

- `capturePhoto`, avec un retour `String?` ;
- `recordAudio`, avec un retour `String?` ;
- `recordVideo`, avec un retour `Map`.

Les implementations ne sont en outre pas exploitables en production :

- la photo est un bitmap vide genere localement ;
- l'audio est un fichier vide apres une attente d'une seconde ;
- la video retourne des metadonnees sans creer le fichier annonce.

## 4. Impact

- Les captures distantes et d'urgence photo/audio/video peuvent echouer.
- Les metadonnees de duree unifiees ne seront produites que lorsque le plugin
  natif retournera une capture reelle.
- Un futur transfert binaire ne doit pas uploader ces fichiers factices.
- Ajouter uniquement des alias de noms masquerait le probleme sans produire
  un media valide.

## 5. Correction requise

1. Implementer la capture photo avec CameraX ou Camera2.
2. Implementer l'audio avec `MediaRecorder`, arret propre et fichier non vide.
3. Implementer la video avec CameraX VideoCapture ou Camera2/MediaRecorder.
4. Exposer les trois noms avances attendus par Dart, ou renommer les appels
   Dart et leur contrat de facon coordonnee.
5. Retourner une `Map<String, Any>` uniforme contenant :
   `filePath`, `fileSize`, `duration`, dimensions et metadonnees disponibles.
6. Conserver `duration` native en secondes dans la reponse MethodChannel ;
   `MediaCollector` la convertit ensuite en millisecondes pour la base et l'API.
7. Verifier l'existence, la taille et le type MIME du fichier avant succes.
8. Propager des codes d'erreur structures sans chemin ni donnee sensible.

## 6. Tests requis

- Test de contrat MethodChannel pour chaque nom de methode et type de retour.
- Test instrumente confirmant que chaque fichier existe et n'est pas vide.
- Test audio/video avec duree demandee et tolerance explicite.
- Test camera avant/arriere et refus de permission.
- Test d'annulation, timeout, interruption et espace disque insuffisant.
- Test d'integration jusqu'a `DatabaseService.insertMediaData`.

## 7. Travail deja effectue

La normalisation de la duree des retours audio/video a ete rendue robuste dans
`MediaCollector`. Elle accepte un entier, un decimal ou une chaine numerique,
puis stocke et transmet la valeur en millisecondes. Aucun contournement vers les
captures factices du plugin Android n'a ete ajoute.
