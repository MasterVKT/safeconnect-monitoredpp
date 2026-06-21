# Issue Monitor App - Normalisation uniforme des durees media

**Type d'Issue** : MO_ISSUE_FORMAT  
**App Cible** : monitor_app (`flutter_apps/monitor_app`)  
**Origine** : unification de `duration` dans `monitored_app`  
**Date de Creation** : 2026-06-07  
**Statut** : Bloque - implementation monitor_app requise  
**Priorite** : Moyenne  
**Type de Donnees Affecte** : Medias

## 1. Resume de l'Issue

Monitored_app envoie desormais toutes les durees audio/video en millisecondes.
Monitor_app doit convertir uniformement ces valeurs en secondes pour son modele
et ses widgets d'affichage.

## 2. Contexte et Origine

Fichiers monitored_app modifies :

- `lib/core/utils/media_duration_utils.dart`
- `lib/core/collectors/media_collector.dart`
- `lib/core/database/tables.dart`

Un clip de dix secondes est maintenant envoye avec `duration: 10000`, quelle
que soit sa provenance.

## 3. Comportement Attendu

`MediaFile.duration` reste exprime en secondes dans monitor_app. La conversion
millisecondes vers secondes doit avoir lieu une seule fois a la frontiere JSON.

## 4. Comportement Actuel

`lib/features/media/services/media_service.dart` divise uniquement les medias
dont `source_type == 'DEVICE_ORIGINAL'`. Les captures `MANUAL`, `SCHEDULED`,
`TRIGGERED` ou `EMERGENCY` conserveraient donc une valeur mille fois trop
grande apres le deploiement du nouveau monitored_app.

## 5. Changement de Contrat de Donnees

Avant, selon la source :

```json
{ "source_type": "MANUAL", "duration": 10 }
```

Apres, pour toutes les sources :

```json
{ "source_type": "MANUAL", "duration": 10000 }
```

## 6. Changements Requis dans Monitor App

Dans `lib/features/media/services/media_service.dart`, remplacer la logique
conditionnelle sur `source_type` par une conversion uniforme :

```dart
static int? _normalizeMediaDurationSeconds(Map<String, dynamic> json) {
  final raw = json['duration'];
  if (raw is! num) return null;
  return raw.toInt() ~/ Duration.millisecondsPerSecond;
}
```

Conserver les sliders et parametres de commande en secondes :
`audio_duration` et `duration_seconds` sont des durees de commande, pas le champ
de metadonnees `MediaFile.duration`.

Ne retirer le mode de compatibilite qu'apres migration des anciennes lignes
backend encore stockees en secondes.

## 7. Changements Monitored App Deja Effectues

- Conversion robuste des retours natifs en millisecondes.
- Meme valeur utilisee dans la base locale et le payload API.
- Tests unitaires pour entier, decimal, texte numerique et fallback invalide.

## 8. Etapes de Verification

1. Parser `duration: 10000` pour chaque `source_type`.
2. Verifier que le modele monitor_app contient `duration == 10`.
3. Verifier l'affichage `0:10` dans la grille et le detail.
4. Verifier que le slider de capture reste en secondes.
5. Tester une ligne historique en secondes pendant la phase de migration.

