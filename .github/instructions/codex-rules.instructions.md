---
description: Lightweight index for repository-wide agent rules. Load this for any task in this repository.
applyTo: "**"
---

# Codex Rules Index (Token-Optimized)

This instruction file intentionally avoids duplicating long rule documents.

Global mandatory completion rule:
- Double Check Completion: reject the first completion attempt and run a second-pass verification against the original request before finalizing.

Global backend issue reporting rule:
- If a backend-side issue is identified, create a detailed and structured markdown report in `docs/integration_issues/` with problem description and proposed solution; if and only if part of the issue also concerned frontend and that frontend part is already resolved, include a dedicated detailed section describing what was already implemented on frontend side.

Load order:
1. `CLAUDE.md`
2. `.claude/rules/architecture-detailed.md`
3. `.claude/rules/code-style-detailed.md`
4. `.claude/rules/implementation-checklist.md`
5. `.claude/rules/integration-issue-documentation.md`
6. `.github/shared/mandatory-behavior.md`
7. `.github/shared/token-policy.md`

Agent-specific mirrors:
- GitHub Copilot: `.github/copilot-instructions.md`, `.github/copilot-rules/*`
- Gemini: `.gemini/styleguide.md`, `.gemini/rules/*`

Conflict resolution:
- Canonical rules are `CLAUDE.md`, `.claude/rules/*`, and `.github/shared/*`.
- Mirror files are aliases for compatibility and token optimization.
