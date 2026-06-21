---
name: cross-app-issue-authoring
description: "Create structured, autonomous issue reports targeting the monitor_app (MO) or the backend (BE) when work in the monitored_app reveals that changes are required in those external applications. Use when a fix, feature, data format change, or new capability in monitored_app requires corresponding updates in monitor_app or backend. Explicitly states the target application in every report. Triggers on: application surveillante doit être mise à jour, backend doit être modifié, nouveau format de données, nouveau endpoint nécessaire, MO doit s'adapter, changement de contrat API."
argument-hint: "Décrire: ce qui a changé dans monitored_app, quelle app externe est impactée (monitor_app ou backend), et ce qu'elle doit changer."
user-invocable: true
---

# Cross-App Issue Authoring — Monitored App (XP SafeConnect)

## Purpose
Produire des rapports d'issues complets et autonomes pour les équipes **monitor_app** ou **backend** lorsque le travail effectué dans monitored_app révèle que des changements externes sont requis.

Cette skill est le pendant sortant de `backend-integration-reporting` :
- `backend-integration-reporting` = réactif, documente les échecs API rencontrés MAINTENANT pendant le développement
- `cross-app-issue-authoring` = proactif, documente les changements que d'autres apps DOIVENT faire en conséquence du travail dans monitored_app

**Apps cibles** :
- `MO` = monitor_app (`h:\Projects\XP SafeConnect\flutter_apps\monitor_app`) — l'app de supervision parentale
- `BE` = backend (`safeconnect-env/safeconnect`) — Django REST API

## Quand Utiliser

### Cible : Monitor App (MO)
- Le format de données de monitored_app a changé → MO doit mettre à jour son parser/modèle
- monitored_app a ajouté un nouveau type de données → MO a besoin d'une nouvelle fonctionnalité d'affichage
- La fréquence/mécanisme de sync a changé → MO doit mettre à jour son polling/gestion WS
- De nouveaux types d'événements WebSocket sont émis → MO doit les gérer
- Le modèle de permissions a changé → MO doit afficher un nouvel état de consentement

### Cible : Backend (BE)
- monitored_app a besoin d'un nouveau endpoint API → BE doit le créer
- La structure du payload de monitored_app a changé → BE doit mettre à jour son modèle/sérialiseur
- De nouveaux types de commandes WebSocket sont nécessaires → BE doit les implémenter
- Le flux d'authentification/sync a changé → BE doit s'y adapter

### Les Deux Cibles
- Nouveau type de données collecté → BE a besoin d'un endpoint + MO a besoin d'un affichage
- Créer des rapports séparés pour chaque cible

## Fichiers de Sortie Requis
```
docs/cross_app_issues/MO_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md   ← pour issues monitor_app
docs/cross_app_issues/BE_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md   ← pour issues backend
```

Valeurs TYPE autorisées :
- `FORMAT` — format/schéma de données changé dans monitored_app
- `NEW_DATA` — nouveau type de données ajouté dans monitored_app
- `MISSING` — l'app cible manque d'une fonctionnalité requise par monitored_app
- `SYNC` — protocole, fréquence ou mécanisme de sync changé
- `WEBSOCKET` — événements/commandes WebSocket changés ou ajoutés
- `AUTH` — flux d'authentification ou gestion de tokens changé
- `PERMISSION` — modèle de permissions ou permissions Android changé
- `NATIVE` — changement de comportement Android natif affectant le contrat de données

## Workflow Obligatoire

### 1. Confirmer l'Attribution
Vérifier que l'issue requiert vraiment des changements externes :
- [ ] Le changement dans monitored_app est confirmé et intentionnel
- [ ] L'app cible (MO/BE) ne gère actuellement PAS cela correctement
- [ ] Le décalage n'est pas un bug de monitored_app (i.e., le changement est correct et permanent)

### 2. Identifier la Portée de l'Impact
- Quels types de données sont affectés : SMS / appels / localisation / apps / médias / batterie / autre
- Est-ce cassant (l'app cible va planter/erreur) ou additif (nouvelle fonctionnalité nécessaire) ?
- Priorité : bloque la sync ? bloque l'affichage ? nouvelle fonctionnalité ?
- MO et BE impactés ? → créer deux fichiers séparés

### 3. Documenter le Changement de Monitored App
- Ce qui a été changé/ajouté dans monitored_app (fichiers et méthodes spécifiques)
- À quoi ressemble le nouveau comportement/format/données (exemples concrets)
- Quand ce changement prend effet (prochaine release ? déjà déployé ?)
- Rétrocompatibilité : l'ancien comportement fonctionne-t-il encore ? Y a-t-il une période de migration ?

### 4. Rédiger le Rapport Spécifique à la Cible
Utiliser le template correct selon la cible :
- [Cible Monitor App → voir Template A ci-dessous]
- [Cible Backend → voir Template B ci-dessous]

### 5. Définir les Étapes de Vérification
- Comment confirmer que l'app cible gère correctement le nouveau comportement
- Scénarios de test : premier lancement / mise à jour / premier sync / sync en arrière-plan / reconnexion

### 6. Valider la Qualité du Document
- [ ] App cible explicitement indiquée dans l'en-tête
- [ ] Toutes les sections requises présentes (voir templates)
- [ ] Aucune donnée sensible (vrais numéros de téléphone, IMEI, tokens)
- [ ] L'équipe cible peut agir sans clarification supplémentaire

---

## Template A — Issue Monitor App

```markdown
# Issue Monitor App — [Description Courte]

**Type d'Issue** : MO_ISSUE_[TYPE]
**App Cible** : monitor_app (flutter_apps/monitor_app)
**Origine** : changement dans monitored_app
**Date de Création** : [YYYY-MM-DD]
**Statut** : 🔴 Bloqué — implémentation monitor_app requise
**Priorité** : [Haute / Moyenne / Basse]
**Type de Données Affecté** : [SMS / Appels / Localisation / AppUsage / Médias / Batterie / Autre]

## 1. Résumé de l'Issue
Une ligne : ce que monitored_app a changé et ce que monitor_app doit faire en conséquence.

## 2. Contexte & Origine (Dans Monitored App)
- Fonctionnalité/correctif dans monitored_app qui a déclenché cette issue
- Fichiers monitored_app affectés (chemins exacts)
- Quand le changement a été effectué (date, commit si connu)
- Si c'est déjà déployé ou en développement

## 3. Comportement Attendu (Ce que Monitor App Doit Faire)
- Ce que monitor_app DEVRAIT faire après ce changement de monitored_app
- Référence aux specs/docs si applicable
- Expérience utilisateur attendue dans monitor_app

## 4. Comportement Actuel (Ce que Monitor App Fait Maintenant)
- Ce que monitor_app fait actuellement (qui sera cassé ou incorrect)
- Preuves : réponse API observée, capture d'écran UI, extrait de log

## 5. Changement de Contrat de Données (Détaillé)
Avant (ancien comportement monitored_app) :
```json
{ "ancien_champ": "ancien_format" }
```
Après (nouveau comportement monitored_app) :
```json
{ "nouveau_champ": "nouveau_format" }
```
Impact sur le modèle/parser de monitor_app : [spécifier la classe/méthode exacte dans monitor_app]

## 6. Changements Requis dans Monitor App
Instructions d'implémentation précises pour l'équipe monitor_app :
- Fichiers Dart à modifier (chemins exacts dans flutter_apps/monitor_app)
- Modèles de données à mettre à jour (classes Freezed, parsing JSON)
- États UI à ajouter ou modifier
- Changements de Provider/Repository nécessaires
- Nouveaux endpoints API à appeler si le backend a aussi changé

## 7. Changements Monitored App Déjà Effectués
- Fichiers modifiés dans monitored_app (chemins exacts)
- Ce qui a été changé et pourquoi
- Comportement avant/après
- Validation effectuée

## 8. Étapes de Vérification
- Comment vérifier que monitor_app gère correctement le nouveau comportement de monitored_app
- Scénarios de test : nouvelle installation / mise à jour / premier sync / sync en arrière-plan / reconnexion
```

---

## Template B — Issue Backend

```markdown
# Issue Backend — [Description Courte]

**Type d'Issue** : BE_ISSUE_[TYPE]
**App Cible** : backend (safeconnect-env/safeconnect)
**Origine** : changement dans monitored_app
**Date de Création** : [YYYY-MM-DD]
**Statut** : 🔴 Bloqué — implémentation backend requise
**Priorité** : [Haute / Moyenne / Basse]
**Type de Données Affecté** : [SMS / Appels / Localisation / AppUsage / Médias / Batterie / Autre]
**Endpoints Affectés** : [liste des endpoints affectés ou nouveaux]

## 1. Résumé de l'Issue
Une ligne : ce que monitored_app a changé et ce que le backend doit faire en conséquence.

## 2. Contexte & Origine (Dans Monitored App)
- Fonctionnalité/correctif dans monitored_app qui a déclenché cette issue
- Fichiers monitored_app affectés (chemins exacts)
- Quand le changement a été effectué
- Nouveau format de payload ou nouvel appel API que monitored_app va effectuer

## 3. Comportement Backend Attendu
- Ce que le backend DEVRAIT fournir/accepter après le changement de monitored_app
- Référence aux specs API dans docs/ si applicable

## 4. Comportement Backend Actuel (Le Décalage)
- Ce que le backend fait actuellement (qui échouera avec le nouveau monitored_app)
- Preuves : statut HTTP, corps de réponse, décalage de payload

## 5. Changement de Contrat API (Détaillé)
Nouveau endpoint (si applicable) :
- Méthode : [GET / POST / PUT / PATCH]
- URL : [chemin]
- Auth : [Bearer token / session / aucune]
- Corps de la requête : [schéma JSON]
- Corps de la réponse : [schéma JSON]
- Codes de statut : [200, 400, 401, etc.]

Endpoint modifié (si applicable) :
- Quels champs ont été ajoutés/changés/supprimés
- Exigence de rétrocompatibilité (si applicable)

## 6. Changements Requis dans le Backend
Instructions d'implémentation précises :
- Views/viewsets Django nouveaux ou modifiés
- Changements de sérialiseurs
- Changements de modèle/migration
- Changements de routage URL
- Changements de permissions/auth
- Changements de consumer WebSocket (si WS impliqué)

## 7. Changements Monitored App Déjà Effectués
- Fichiers modifiés dans monitored_app (chemins exacts)
- Ce qui a été changé et pourquoi
- Comportement avant/après
- Validation effectuée

## 8. Étapes de Vérification
- Commandes curl/Postman pour vérifier que le endpoint backend fonctionne
- Commandes logcat sur monitored_app pour vérifier le payload correct envoyé
- Vérification d'intégration : flux monitored_app → backend → monitor_app vérifié
```

---

## Contrat de Sortie
Toujours retourner après création du/des document(s) :
1. Nom(s) de fichier(s) créé(s)
2. App cible confirmée : MO / BE / les deux
3. Résumé des changements requis (2-3 points par cible)
4. Évaluation de priorité et d'urgence
5. Workaround temporaire possible dans monitored_app pendant que l'app cible est corrigée

## Langue de Sortie
- Français par défaut sauf si l'utilisateur demande autrement
- Contenu technique (chemins de fichiers, JSON) reste en anglais
