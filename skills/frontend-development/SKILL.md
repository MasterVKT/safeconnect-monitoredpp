---
name: frontend-development
description: 'Develop and evolve Monitored App frontend features in Flutter using Riverpod and GetIt, aligned with background-first architecture and native bridge constraints. Use for UI/pages/widgets, provider logic, setup and consent flows, i18n FR/EN, and frontend-backend integration. Enforces spec-first implementation, minimal-risk changes, and non-regression validation.'
argument-hint: 'Describe the feature, target screens/modules, expected behavior, and constraints.'
user-invocable: true
---

# Frontend Development (Monitored App)

## Purpose
Deliver production-ready frontend changes for XP SafeConnect Monitored App with strict compliance to project architecture and specifications.

## Use When
- Creating/updating screens, widgets, routes, and Riverpod state
- Implementing auth/pairing/permissions/setup/home flows
- Connecting UI behavior to services and providers
- Updating localization keys and user-visible messaging

## Mandatory Constraints
- Follow docs/* and monitored-app-development-plan.md
- Respect GetIt service access (no direct service instantiation)
- Keep build() side-effect free
- Keep user-facing text in ARB files only
- Keep platform-specific behavior guarded for Android/iOS differences

## Workflow

### 1) Clarify Feature and Acceptance
- Define user-visible outcome
- Define acceptance criteria and edge cases

### 2) Hypothesis-First File Targeting
- Start with a short list of likely files
- Validate quickly, then expand only if needed

Example hypothesis for permission-flow updates:
- lib/features/auth/pairing_screen.dart
- lib/features/auth/permission_screen.dart
- lib/features/auth/setup_complete_screen.dart
- lib/core/services/auth_service.dart
- lib/core/services/background_service.dart
- lib/l10n/app_fr.arb
- lib/l10n/app_en.arb

### 3) Spec and Contract Check
- Confirm relevant specs in docs/
- Confirm API contract expectations before coding

### 4) Impact Analysis
- Identify dependent providers/services/collectors
- Check Android/iOS behavior and permission impact

### 5) Implement Minimal Safe Changes
- Prefer focused edits over broad refactor
- Preserve existing patterns and architecture boundaries

### 6) i18n and Security Pass
- Add/adjust FR and EN keys for all new text
- Avoid exposing sensitive information in UI/logging

### 7) Validate Non-Regression
- Re-test changed flow + nearby flows
- Run formatting/analyze/tests as needed

### 8) Completion Output Contract
Always include:
1. Files changed
2. What was implemented
3. i18n compliance note
4. Validation summary
5. Risks or follow-ups

## Validation Commands
- dart format .
- flutter analyze
- flutter test

## Quality Checklist
- Feature behavior matches acceptance criteria
- Riverpod and GetIt rules respected
- No hardcoded user-facing strings
- Android/iOS behavior guarded where needed
- No new analyzer issues from changes

## Notes
- If backend contract gaps are discovered, document exact endpoint/payload/status/error requirements

