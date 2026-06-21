---
name: task-orchestrator
description: 'Meta-skill orchestrator for Monitored App. Use when a task must be auto-routed to the best project skill: bug-fixing, frontend-development, background-services-collectors, backend-integration-reporting, quality-gates-flutter, session-handoff, cross-app-issue-authoring, spec-audit, or data-flow-trace. Triggers on keywords like bug, fix, error, feature, UI, Riverpod, background service, collector, MethodChannel, API 4xx/5xx, integration issue, données manquantes, spec incorrecte, fin de session, handoff, application surveillante à mettre à jour, backend à modifier, and final validation.'
argument-hint: 'Describe the task goal, observed issue or requested feature, impacted module, platform, and expected output.'
user-invocable: true
---

# Task Orchestrator (Meta-Skill) — Monitored App

## Purpose
Provide a single entry point that selects the right project skill automatically based on task intent.

This avoids duplicating the same orchestration logic per AI agent.

## Scope
This meta-skill is workspace-scoped and reusable by any AI agent that can read project skills from this repository.

## Available Skills
- `bug-fixing` — `skills/bug-fixing/SKILL.md`
- `frontend-development` — `skills/frontend-development/SKILL.md`
- `background-services-collectors` — `skills/background-services-collectors/SKILL.md`
- `backend-integration-reporting` — `skills/backend-integration-reporting/SKILL.md`
- `quality-gates-flutter` — `skills/quality-gates-flutter/SKILL.md`
- `session-handoff` — `skills/session-handoff/SKILL.md`
- `cross-app-issue-authoring` — `skills/cross-app-issue-authoring/SKILL.md`
- `spec-audit` — `skills/spec-audit/SKILL.md`
- `data-flow-trace` — `skills/data-flow-trace/SKILL.md`

## Selection Rules

### Route to `bug-fixing`
Use when the request includes:
- bug, fix, regression, crash, exception, runtime error
- analyzer/compilation failure
- wrong behavior vs expected behavior

### Route to `frontend-development`
Use when the request includes:
- new feature, UI/page/widget update
- Riverpod/provider/state flow edits
- pairing/permission/setup/home screen evolution
- localization additions/changes (FR/EN)

### Route to `background-services-collectors`
Use when the request includes:
- background service lifecycle
- data collection/sync cadence
- collector reliability/performance
- MethodChannel/native bridge coordination
- battery optimization behavior
- BootReceiver / foreground service notification

### Route to `backend-integration-reporting`
Use when the request includes:
- HTTP 4xx/5xx encountered NOW during development
- auth 401/403 blocking current ongoing request
- response schema mismatch causing an immediate error
- WebSocket contract/disconnect issues observed right now

### Route to `quality-gates-flutter`
Use when the request includes:
- final validation, sign-off, readiness check
- analyze/format/test pass request
- non-regression validation before delivery

### Route to `session-handoff`
Use when the request includes:
- fin de session, rapport de session, résumé de session
- contexte pour prochaine session, handoff
- context window approaching limit, session ending
- "génère un rapport de session", "résume la session"

### Route to `cross-app-issue-authoring`
Use when the request includes:
- monitored_app change requires update in monitor_app or backend
- "l'application surveillante doit être mise à jour"
- "le backend doit être modifié suite à ce changement dans MA"
- new payload format, new data type, new endpoint needed as consequence of MA work
- monitored_app evolution creates obligation for MO or BE

### Route to `spec-audit`
Use when the request includes:
- "avant d'implémenter", "vérifier la spec", "est-ce que la spec dit"
- before coding a new collector or new API call
- suspecting mismatch between docs/ and actual behavior
- spec coherence uncertain, "la spec est-elle correcte"

### Route to `data-flow-trace`
Use when the request includes:
- "données manquantes", "données non reçues", "pas de données dans monitor_app"
- collector appears to stop in background
- "pourquoi les données ne sont pas envoyées / collectées"
- data present locally in SQLite but not synced to backend
- data wrong value (wrong timezone, wrong field, duplicated)
- "après redémarrage, les données ne remontent plus"

## Multi-Skill Composition
Chain skills in this order when a task spans multiple intents:
1. `spec-audit` — always first if spec coherence is uncertain before coding
2. `data-flow-trace` — if data is missing/wrong and root cause layer is unknown
3. Primary fix skill (`frontend-development` / `bug-fixing` / `background-services-collectors`)
4. `backend-integration-reporting` — only if immediate API failure is confirmed
5. `cross-app-issue-authoring` — if external app changes are required as consequence
6. `quality-gates-flutter` — always before delivery
7. `session-handoff` — terminal, always last in a session

## Tie-Breaker Policy
When intent is ambiguous:
1. Prefer `spec-audit` when starting a significant new feature or spec accuracy is unknown.
2. Prefer `data-flow-trace` when data is missing/wrong and root cause layer is unknown.
3. Prefer `bug-fixing` if there is a failing behavior now.
4. Prefer `frontend-development` if the request is feature-oriented.
5. Prefer `cross-app-issue-authoring` (not `backend-integration-reporting`) when the issue requires permanent changes in an external app — not just a current API failure.
6. `session-handoff` is always the last skill in any session.

## Skill Interaction Rules

### spec-audit is a prerequisite gate
- Run `spec-audit` BEFORE `frontend-development` or `background-services-collectors` for new features
- Run `spec-audit` when a bug root cause is unclear and spec accuracy is in doubt
- Skip `spec-audit` only for trivial UI-only changes with no data contract involvement

### data-flow-trace routes to issue authoring
- `data-flow-trace` never fixes code directly
- It diagnoses the broken layer, then routes to the appropriate fix skill
- Always run `data-flow-trace` before creating issue docs when root cause layer is unknown

### session-handoff is a terminal skill
- Run `session-handoff` at the END of a session, not as a precondition
- `session-handoff` does not modify code — it produces a report only
- It must always be the last skill used in a session

### cross-app-issue-authoring and backend-integration-reporting are documentation-only skills
- They create documents for external teams — they do not fix code
- Use `cross-app-issue-authoring` for permanent external changes required
- Use `backend-integration-reporting` for immediate API/WS failures blocking current work

## Output Contract
After routing, always return:
1. Selected skill(s) with execution order
2. Why this route was chosen
3. Next concrete action

## Notes
- Do not duplicate this orchestration logic in agent-specific files unless a platform requires it.
- Keep this file as the single source of routing truth for this project.
- `data-flow-trace` and `spec-audit` are diagnostic skills — they never modify code.
- `cross-app-issue-authoring`, `backend-integration-reporting`, and `session-handoff` are documentation-only skills.
