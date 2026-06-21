---
name: spec-audit
description: "Audit coherence between monitored_app specifications (docs/) and current implementation before coding. Identifies spec gaps, contradictions, stale contracts, and implementation drift across Dart collector, MethodChannel, Kotlin native bridge, and API payload layers. Use before implementing any new collector, background service feature, or API call to prevent building on false assumptions. Triggers on: avant d'implémenter, vérifier la spec, est-ce que la spec dit, spec correcte, spec à jour, docs/ vs code, field name mismatch, contrat API."
argument-hint: "Spécifier le domaine à auditer (ex: 'collecte et sync SMS', 'bridge natif call log', 'service de localisation en arrière-plan', 'commandes WebSocket')."
user-invocable: true
---

# Spec Audit — Monitored App (XP SafeConnect)

## Purpose
Valider que les spécifications du projet dans `docs/` sont complètes, cohérentes, et alignées avec l'implémentation actuelle avant de commencer tout développement.

Cette skill prévient la cause racine la plus fréquente de bugs dans monitored_app :
**implémenter depuis des specs incomplètes ou contradictoires**, notamment quand le comportement du bridge natif diffère des attentes du contrat API.

## Utiliser Quand
- Sur le point d'implémenter un nouveau collecteur de données ou une fonctionnalité de service de fond
- Suspicion de décalage entre docs/API et la sortie réelle du collecteur
- Planification de changements affectant le format de payload monitored_app → backend
- Après un changement backend qui peut nécessiter des mises à jour de la sortie des collecteurs
- Avant d'écrire du code Android natif pour vérifier le contrat MethodChannel attendu
- Avant des changements cross-app (monitored_app + monitor_app + backend)

## Ne Pas Utiliser Quand
- La tâche est purement UI sans contrat de données
- La spec a été auditée dans la même session et est confirmée à jour
- Correctif de bug simple avec cause racine connue et spec confirmée correcte

## Workflow Obligatoire

### 1. Définir la Portée de l'Audit
- Domaine fonctionnel : (ex : "collecte et sync SMS")
- Types de données impliqués : SMS / appels / localisation / apps / médias / batterie
- Couches à auditer : collecteur Dart | contrat MethodChannel | natif Kotlin | payload API
- Profondeur d'audit : rapide (noms de champs) / complet (toutes couches) / cross-app (inclut MO + BE)

### 2. Localiser les Specs Pertinentes
Rechercher dans cet ordre :
1. `docs/API-Endpoints-Application-Surveillee.md` — référence API principale
2. `docs/monitored-app-development-plan.md` — comportement prévu et ordre de livraison
3. `docs/` — autres guides d'architecture et docs d'intégration
4. `.claude/rules/architecture-detailed.md` — contraintes d'architecture en couches
5. `.claude/rules/implementation-checklist.md` — contraintes d'implémentation

Marquer chaque spec :
- `[TROUVÉE]` — fichier existe et est lisible
- `[MANQUANTE]` — aucune spec trouvée pour ce domaine
- `[PARTIELLE]` — spec existe mais a des lacunes

### 3. Lire et Analyser les Specs
Pour chaque spec trouvée :
- Extraire le format de payload attendu (noms de champs, types, requis/optionnel)
- Noter le chemin d'endpoint, méthode, exigences d'auth, codes de statut
- Noter les TODOs, "TBD", ou incohérences dans la spec elle-même

### 4. Comparer Spec vs. Implémentation
Tracer chaque couche :

```
Affirmation spec → Collecteur Dart (lib/core/collectors/)
Affirmation spec → Contrat MethodChannel (lib/core/collectors/ → args invokeMethod)
Affirmation spec → Bridge Kotlin (android/app/src/main/kotlin/.../[Plugin].kt)
Affirmation spec → Payload API envoyé (lib/core/services/data_collector_service.dart ou service de sync)
```

Carte d'hypothèse d'implémentation :
```
Spec: POST /api/sms/ avec champ `body`
→ MA dart: lib/core/collectors/sms_collector.dart (mappe vers `body`?)
→ MA kotlin: android/.../SmsCollectorPlugin.kt (retourne `body` ou `content`?)
→ MA sync: lib/core/services/data_collector_service.dart (payload sérialisé correctement?)
```

Classifier chaque constat :
- `[CORRESPOND]` — le code correspond exactement à la spec
- `[DÉRIVE]` — le code et la spec divergent (décrire la différence exacte)
- `[IMPL_MANQUANTE]` — la spec existe, le code ne l'implémente pas
- `[SPEC_MANQUANTE]` — le code existe, la spec ne le documente pas
- `[CONTRADICTION]` — la spec se contredit ou contredit une autre spec
- `[OBSOLÈTE]` — la spec référence un ancien format/API plus en usage

### 5. Générer le Rapport d'Audit

```
## RAPPORT D'AUDIT SPEC — [Domaine Fonctionnel]
Date: [YYYY-MM-DD]
Scope: [type de données / collecteur / endpoint]
Profondeur: [Rapide / Complet / Cross-App]

### Specs Trouvées
| Fichier Spec | Statut | Affirmations Clés |
|---|---|---|
| docs/API-Endpoints-Application-Surveillee.md | [TROUVÉE] | POST /api/sms/ attend [...] |
| docs/... | [MANQUANTE] | Aucune spec pour [X] |

### Constats de Cohérence
| Affirmation Spec | Couche | Statut | Détail |
|---|---|---|---|
| Payload inclut champ `body` | SmsCollector → Kotlin | [DÉRIVE] | Kotlin envoie `content` |
| Timestamp en ISO 8601 | Payload API | [CORRESPOND] | Dart formate correctement |
| [affirmation] | [couche] | [statut] | [détail] |

### Issues Critiques (Résoudre Avant de Coder)
- [CONTRADICTION] Spec API dit `phone_number`, Kotlin envoie `number`
- [IMPL_MANQUANTE] thread_id SMS non collecté malgré sa présence dans la spec API

### Issues Non-Critiques (Documenter, Ne Pas Bloquer)
- [OBSOLÈTE] docs/ référence l'ancien endpoint de sync (v1) — maintenant v2 utilisé
- [SPEC_MANQUANTE] Champ `accuracy` de localisation envoyé mais non documenté dans spec API

### Actions Recommandées Avant de Coder
1. [ACTION] Corriger décalage de nom de champ : `phone_number` vs `number` dans SmsCollectorPlugin.kt
2. [SÛRE_PROCÉDER] Contrat du call log vérifié — aucun bloqueur
3. [CROSS_APP] Le parser de MO devra être mis à jour quand le nom de champ de MA sera corrigé
```

### 6. Décision de Routage vers Issue

| Type de Constat | Router Vers |
|---|---|
| Contrat backend ne correspond pas à spec → doit corriger backend | `cross-app-issue-authoring` (cible: BE) |
| Parser monitor_app va casser suite au changement de champ | `cross-app-issue-authoring` (cible: MO) |
| Spec manquante → l'implémentation doit définir le contrat | Documenter la décision, puis `frontend-development` ou `background-services-collectors` |
| Contradiction dans spec | Bloquer, escalader à l'utilisateur |
| Dérive mineure, sans conséquence | Noter dans l'audit, procéder |
| Dérive critique bloque la fonctionnalité | Bloquer jusqu'à résolution |

### 7. Contrat de Complétion d'Audit
Toujours retourner :
1. Specs trouvées vs. manquantes (compte et liste)
2. Tableau des constats de cohérence
3. Issues critiques (doivent être résolues avant de coder)
4. Issues non-critiques (journaliser, ne pas bloquer)
5. Décision Go/No-Go : **PROCÉDER** / **CLARIFIER D'ABORD** / **BLOQUÉ**
6. Routage suggéré si issues trouvées

## Niveaux de Profondeur d'Audit

### Audit Rapide (pour correctifs de bugs)
- Vérifier que la spec existe pour l'endpoint/collecteur affecté
- Vérifier que les noms de champs correspondent au code
- Vérifier la gestion des codes de statut
- Durée : < 5 min

### Audit Complet (pour nouvelles fonctionnalités)
- Toutes les étapes de l'audit rapide
- Vérifier que tous les champs de réponse sont parsés (pas de drops silencieux)
- Vérifier que les exigences d'auth et de permissions correspondent à l'implémentation
- Vérifier la gestion des codes d'erreur pour tous les codes de statut documentés
- Vérifier que les clés i18n existent pour tous les messages utilisateur documentés
- Durée : 10-20 min

### Audit Cross-App (pour issues de flux de données)
- Toutes les étapes de l'audit complet
- Tracer les données depuis la collecte Kotlin → payload API → stockage backend → affichage MO
- Vérifier la cohérence des noms de champs sur les trois apps
- Vérifier la cohérence du fuseau horaire et de l'encodage
- Durée : 20-40 min

## Langue de Sortie
- Français par défaut sauf si l'utilisateur demande autrement
- Les tableaux d'audit peuvent utiliser des termes techniques anglais pour la clarté
