# Mandatory Behavior Summary

This file contains the core mandatory behavior rules that apply to all AI agents working on the Monitored App project.

1. Follow all specs in `docs/`, especially API and development plan.
2. Enforce GetIt DI, Riverpod state management, and background-first architecture.
3. Use native MethodChannels for platform-specific features.
4. Internationalize all UI text (FR/EN), no hardcoded user-facing strings.
5. Use secure error handling, no sensitive data leakage, report failures safely.
6. Prevent regressions; run `flutter analyze` for validation when relevant.
7. If backend integration fails, create a detailed report in `docs/integration_issues/`; if and only if part of the issue also concerned frontend and that frontend part is already resolved, include a dedicated detailed section about what was already implemented on frontend side.
8. Double Check Completion: reject the first completion attempt, then re-verify against the original task requirements before finalizing.