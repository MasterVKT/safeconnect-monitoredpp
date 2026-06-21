# monitored_app

A new Flutter project.

## AI Skill Routing (Quick Decision Table)

Use this table to auto-select the right project skill for AI task handling.

| Task Type | Select Skill | Notes |
|---|---|---|
| Bug, crash, regression, wrong behavior | `bug-fixing` | Root-cause-first remediation workflow |
| Feature/UI/provider flow implementation | `frontend-development` | Riverpod/GetIt + i18n FR/EN constraints |
| Background services, collectors, MethodChannel | `background-services-collectors` | Background-first and platform-safe behavior |
| API 4xx/5xx, auth errors, schema mismatch, WS issues | `backend-integration-reporting` | Create `docs/integration_issues/...` report |
| Final validation before delivery | `quality-gates-flutter` | Format/analyze/test + non-regression checks |

Primary orchestrator:
- `task-orchestrator` at `skills/task-orchestrator/SKILL.md`

Recommended sequence for mixed tasks:
1. Primary implementation/fix skill
2. `backend-integration-reporting` only if backend-side issue is confirmed
3. `quality-gates-flutter` before sign-off

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
