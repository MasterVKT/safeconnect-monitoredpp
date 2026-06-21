---
name: bug-fixing
description: 'Diagnose and fix Monitored App bugs across Flutter UI, Riverpod state, services, collectors, MethodChannels, and backend integration. Use when handling compilation/runtime errors, regressions, API contract mismatches, background-service failures, or platform-specific issues. Enforces root-cause analysis, minimal-risk patching, and mandatory integration-issue documentation when backend-side defects are detected.'
argument-hint: 'Describe repro steps, observed vs expected behavior, environment (Android/iOS), and impacted module.'
user-invocable: true
---

# Bug Fixing and Error Resolution (Monitored App)

## Purpose
Provide a production-safe debugging workflow for XP SafeConnect Monitored App.

This skill is project-scoped and aligned with:
- docs/
- CLAUDE.md
- .github/copilot-instructions.md
- .claude/rules/*

## Use When
- A feature does not match expected behavior
- Flutter/Dart compile or runtime errors occur
- Riverpod state is inconsistent
- Background collection/sync fails
- MethodChannel/native bridge errors occur on Android/iOS
- API or WebSocket contract mismatch appears

## Mandatory Constraints
- Respect GetIt dependency injection; do not instantiate services directly
- Keep business logic in services/collectors, not widgets
- Keep user-facing text localized (FR/EN ARB)
- Use secure and sanitized error handling (no sensitive data leaks)
- Apply minimal, targeted fixes only

## Workflow

### 1) Reproduce Deterministically
- Capture exact repro steps
- Record observed vs expected behavior
- Record platform and mode (Android/iOS, debug/release)

### 2) Collect Evidence
- Gather logs, stack traces, and failing conditions
- Keep only useful, non-sensitive diagnostics

### 3) Build File Hypothesis First
- Start with a short list of probable files and layers
- Validate quickly before broad search

Example hypothesis for sync failure:
- lib/core/services/background_service.dart
- lib/core/services/data_collector_service.dart
- lib/core/services/websocket_service.dart
- lib/core/services/storage_service.dart
- lib/features/home/**/*.dart
- android/app/src/main/kotlin/**/BackgroundCollectorService.kt

### 4) Identify Root Cause
- Trace event flow from UI or trigger to service/collector/native bridge/backend
- Isolate first incorrect state, transform, permission, or contract mismatch
- Separate symptoms from root cause

### 5) Apply Minimal Safe Fix
- Patch only required files and logic
- Preserve architecture and existing conventions
- Avoid broad refactor unless requested

### 6) Backend/Integration Classification
- Frontend-only issue:
  - Fix directly
- Backend-side issue (HTTP 4xx/5xx, response mismatch, auth failure, WS issue):
  - Create docs/integration_issues/INTEGRATION_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md
  - Fill all 8 template sections from integration-issue-documentation.md

### 7) Validate Non-Regression
- Re-test initial scenario
- Re-test related flows in same module
- Run quality checks relevant to changed files

### 8) Completion Output Contract
Always report:
1. Files changed
2. Root cause
3. Exact fix summary
4. Verification performed
5. Remaining risks or follow-ups

## Diagnostic Commands
- flutter analyze
- flutter test
- dart format .
- flutter run --dart-define=API_BASE_URL=<url>

## Decision Matrix
| Category | Typical signal | Action |
|---|---|---|
| Flutter compile/runtime | Analyzer errors, exceptions | Fix code directly |
| Riverpod/state | Wrong/stale UI state | Fix provider/notifier/state flow |
| Background service | Collection/sync stops | Fix service lifecycle/permissions/trigger path |
| MethodChannel/native | MissingPlugin, platform exception | Fix bridge contract or platform implementation |
| Backend/API/WS | 4xx/5xx/schema mismatch/disconnect | Document integration issue + coordinate backend |

## Security and Privacy
- Never print or expose tokens, personal identifiers, phone numbers, or precise location
- Use flutter_secure_storage through StorageService for secrets
- Keep user-facing errors generic; send technical details to logs/crash reporting

## Quality Checklist
- Repro confirmed
- Root cause proven
- Minimal fix applied
- Non-regression checked
- Integration issue doc created when backend-side, including a detailed frontend-remediation section if and only if frontend was part of the issue and already resolved
