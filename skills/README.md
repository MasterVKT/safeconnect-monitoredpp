# Skills Catalog - Monitored App

This folder contains project-specific skills designed to be loaded by AI agents.

## Entry Point

Always start with `task-orchestrator/SKILL.md` for automatic routing.

## Available Skills

### Implémentation & Correctifs

- **bug-fixing** — Diagnostiquer et corriger les bugs Flutter, Riverpod, services de fond, collecteurs, MethodChannel, et issues d'intégration avec un workflow root-cause-first.

- **frontend-development** — Implémenter et faire évoluer les UI et flux de fonctionnalités avec Riverpod/GetIt, i18n FR/EN, et patterns conformes à l'architecture.

- **background-services-collectors** — Concevoir et déboguer les workflows en arrière-plan, lifecycle, sync, comportement battery-aware, et frontières du bridge natif.

- **quality-gates-flutter** — Exécuter les gates de complétion (format, analyze, tests, architecture, i18n, sécurité) avant la livraison.

### Diagnostic (Ne Modifient Pas le Code)

- **spec-audit** — Auditer la cohérence entre les spécifications docs/ et l'implémentation actuelle avant de coder. Utiliser avant toute nouvelle fonctionnalité ou quand la précision de la spec est incertaine.

- **data-flow-trace** — Tracer les données de monitored_app depuis la collecte Android à travers tout le pipeline jusqu'à la livraison au backend. Diagnostique exactement où les données se cassent (capteur → Kotlin → Dart → SQLite → sync → backend).

### Documentation & Rapports (Ne Modifient Pas le Code)

- **backend-integration-reporting** — Détecter les échecs backend ou contract-side rencontrés MAINTENANT et générer des rapports d'intégration structurés dans docs/integration_issues/.

- **cross-app-issue-authoring** — Créer des rapports structurés pour monitor_app ou le backend quand des changements dans monitored_app requièrent des mises à jour externes. Nomme explicitement l'app cible dans chaque rapport. Sortie : docs/cross_app_issues/.

- **session-handoff** — Générer des rapports de handoff de session compacts et optimisés en tokens pour bootstrapper la prochaine session Claude avec un contexte complet.

## Ordre de Chaînage Recommandé

```text
spec-audit → data-flow-trace → bug-fixing / frontend-development / background-services-collectors
→ backend-integration-reporting → cross-app-issue-authoring → quality-gates-flutter → session-handoff
```

## Usage Notes

- Chaque skill est autonome dans son SKILL.md.
- Le champ `description` est la surface de découverte : contient des mots déclencheurs clairs.
- `spec-audit` et `data-flow-trace` sont des skills diagnostiques — elles ne modifient jamais le code.
- `session-handoff`, `cross-app-issue-authoring`, et `backend-integration-reporting` sont des skills de documentation uniquement.
- `session-handoff` est toujours la dernière skill utilisée dans une session.
- `quality-gates-flutter` est toujours exécutée avant toute livraison.
