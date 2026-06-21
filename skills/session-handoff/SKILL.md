---
name: session-handoff
description: "Generate a compact, structured session handoff report to serve as entry context for the next Claude session on the Monitored App. Optimizes information density to preserve precision while minimizing token consumption. Use at end of any significant session, when context window approaches its limit, or before handing off to another agent. Triggers on: fin de session, rapport de session, résumé de session, contexte prochaine session, handoff, context window full."
argument-hint: "Optionally specify focus areas (e.g., 'focus on native bridge changes' or 'include all open items'). Leave empty for full report."
user-invocable: true
---

# Session Handoff — Monitored App (XP SafeConnect)

## Purpose
Produce a compact, machine-parseable session report that allows the next AI session to resume work with full context — without re-reading the conversation history.

The report must be:
- **Token-efficient**: no prose, no repeated context, no git-derivable info
- **Precise**: every stated fact is accurate and actionable
- **Self-contained**: next session must be fully bootstrapped from this report alone

## Use When
- A significant working session is ending
- Context window is approaching limits mid-task
- Handing off to another Claude session or agent
- Pausing work that will resume later (hours/days)
- Multiple sequential sessions on the same feature/bug

## Mandatory Abbreviations (use throughout report)
- `MA` = monitored_app (`h:\Projects\XP SafeConnect\flutter_apps\monitored_app`) — notre app
- `MO` = monitor_app (`h:\Projects\XP SafeConnect\flutter_apps\monitor_app`) — l'app parente de surveillance
- `BE` = backend (`safeconnect-env/safeconnect`) — Django REST API
- `[✅]` = terminé et validé
- `[⚠️]` = fait mais nécessite vérification / partiel
- `[❌]` = échoué / cassé / bloqué
- `[🔄]` = en cours
- `[⏳]` = en attente, non démarré
- `[💬]` = question ouverte / décision requise

## Référence des couches de fichiers (pour les tableaux)
- `dart` = `lib/` — code Dart
- `kotlin` = `android/app/src/main/kotlin/` — code natif Android
- `manifest` = `android/app/src/main/AndroidManifest.xml`
- `gradle` = fichiers de build Android
- `ios` = `ios/Runner/` — code Swift iOS

## Mandatory Workflow

### 1. Rassembler les faits de session
Avant d'écrire le rapport :
- Lister chaque fichier modifié (depuis le contexte de conversation, pas git status)
- Lister chaque décision prise avec sa justification
- Identifier ce qui fonctionne vs. ce qui est encore cassé
- Identifier toutes les dépendances externes / bloqueurs (côté MO ou BE)
- Vérifier si des changements de bridge natif requièrent des mises à jour du MethodChannel côté Dart

### 2. Classifier chaque élément
Attribuer un tag de statut par élément : `[✅]` `[⚠️]` `[❌]` `[🔄]` `[⏳]` `[💬]`

### 3. Rédiger le rapport en format compact
Règles strictes :
- Tableaux et puces — aucun paragraphe de prose
- Chemins de fichiers relatifs à la racine du projet (`lib/...`, `android/...`)
- Extraits de code : 5 lignes max, seulement si non-évident depuis le chemin
- Décisions : `Décision: [quoi] | Raison: [pourquoi] | Alt rejeté: [quoi, pourquoi]`
- Aucun récit historique — uniquement l'état actuel

### 4. Définir un point d'entrée unique
La prochaine session doit avoir exactement UNE première action non-ambiguë.
- ❌ Mauvais : "Continuer le travail sur le bridge natif"
- ✅ Bon : "Ouvrir `android/app/src/main/kotlin/.../SmsCollectorPlugin.kt:124` — corriger le cursor.close() manquant causant une fuite de données"

### 5. Valider la complétude du rapport
- [ ] Tous les fichiers modifiés listés avec leur couche (dart/kotlin/manifest/gradle/ios)
- [ ] Tous les bloqueurs identifiés avec l'app cible (MO/BE)
- [ ] Documents de cross-app issues créés si nécessaire
- [ ] Point d'entrée non-ambigu
- [ ] Aucune donnée sensible (tokens, IDs d'appareils, vrais numéros de téléphone, IMEI)
- [ ] Questions ouvertes explicites avec indication de qui décide

## Template de Rapport

```
# SESSION HANDOFF REPORT — MONITORED APP
Date: [YYYY-MM-DD HH:MM]
Branche: [nom de branche git]
Scope: [description 1 ligne de la tâche]
Durée: [approx heures]

## FICHIERS MODIFIÉS
| Fichier (chemin depuis racine) | Couche | Statut | Ce qui a changé |
|---|---|---|---|
| lib/core/collectors/sms_collector.dart | dart | [✅] | Description courte |
| android/.../SmsCollectorPlugin.kt | kotlin | [⚠️] | Description courte |

## DÉCISIONS
- Décision: [quoi] | Raison: [pourquoi] | Alt rejeté: [quoi, pourquoi]

## ÉTAT ACTUEL
### Fonctionnel ✅
- [Fonctionnalité/comportement] → [preuve courte: flutter analyze propre / test manuel / collecteur vérifié]

### Cassé / Incomplet ❌
- [Fonctionnalité/comportement] → [symptôme] → [cause racine si connue]

### En attente ⏳
- [Élément] → [dépend de: MO/BE/décision utilisateur]

## BLOQUEURS CROSS-APP
| Bloqueur | Cible | Composant | Doc d'issue |
|---|---|---|---|
| [description] | MO/BE | [endpoint ou fonctionnalité] | [nom de fichier ou "à créer"] |

## QUESTIONS OUVERTES
- [💬] [Question] → [options considérées] → [qui décide]

## POINT D'ENTRÉE PROCHAINE SESSION
**Première action** : [Action exacte — chemin fichier, ligne, quoi faire]
**Contexte requis** : [Appareil/émulateur, version Android, flavor, permissions nécessaires]
**Deuxième action** (si la première réussit) : [Étape suivante]

## MISES À JOUR MÉMOIRE EFFECTUÉES
- [memory/file.md] — [ce qui a été sauvegardé]
- [aucune] — rien de nouveau à mémoriser
```

## Règles d'efficacité tokens

### Inclure
- Fichiers modifiés et pourquoi (pas comment — le code explique le comment)
- Décisions avec justification (NOT dans git log)
- État exact des choses cassées (symptôme + cause racine)
- Bloqueurs cross-app avec cible (MO/BE)
- Point d'entrée exact pour la prochaine session

### Exclure
- Code qui peut être lu depuis le fichier
- Historique git (dérivable avec `git log`)
- Architecture du projet documentée dans CLAUDE.md ou architecture-detailed.md
- Répétition de la demande originale de l'utilisateur
- Éléments réussis sans action résiduelle

### Techniques de compression
- Format tableau pour listes de fichiers et suivi des bloqueurs
- Décisions en une ligne avec justification inline
- Tags de statut au lieu de descriptions en prose
- Références de chemins de fichiers plutôt que citations de code
- Abréviations : MA / MO / BE

## Format de sortie
- Sortir le rapport dans un bloc de code markdown (copiable pour la prochaine session)
- Nom de fichier suggéré : `SESSION_HANDOFF_[YYYYMMDD_HHMM].md`
- Sauvegarder à la racine du projet seulement si l'utilisateur le demande

## Langue de sortie
- Français par défaut sauf si l'utilisateur demande autrement
- Termes techniques (noms de méthodes, chemins de fichiers) restent en anglais
